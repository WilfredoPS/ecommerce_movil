import 'package:drift/drift.dart';
import '../models/inventario.dart';
import '../utils/logger.dart';
import 'database_service.dart';
import 'producto_service.dart';

class InventarioService {
  final DatabaseService _dbService = DatabaseService();
  final ProductoService _productoService = ProductoService();

  Inventario _fromRow(InventariosData row) {
    final i = Inventario()
      ..id = row.id
      ..productoId = row.productoId
      ..ubicacionTipo = row.ubicacionTipo
      ..ubicacionId = row.ubicacionId
      ..cantidad = row.cantidad
      ..ultimaActualizacion = row.ultimaActualizacion
      ..supabaseId = row.supabaseId
      ..sincronizado = row.sincronizado;
    return i;
  }

  InventariosCompanion _toCompanion(Inventario i, {bool includeId = false}) {
    return InventariosCompanion(
      id: includeId && i.id != null ? Value(i.id!) : const Value.absent(),
      productoId: Value(i.productoId),
      ubicacionTipo: Value(i.ubicacionTipo),
      ubicacionId: Value(i.ubicacionId),
      cantidad: Value(i.cantidad),
      ultimaActualizacion: Value(i.ultimaActualizacion),
      supabaseId: Value(i.supabaseId),
      sincronizado: Value(i.sincronizado),
    );
  }

  Future<Inventario?> getInventario(
      String productoId, String ubicacionTipo, String ubicacionId) async {
    final db = await _dbService.db;
    final row = await (db.select(db.inventarios)
          ..where((t) => t.productoId.equals(productoId) &
              t.ubicacionTipo.equals(ubicacionTipo) &
              t.ubicacionId.equals(ubicacionId)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<List<Inventario>> getInventarioPorUbicacion(
      String ubicacionTipo, String ubicacionId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.inventarios)
          ..where((t) =>
              t.ubicacionTipo.equals(ubicacionTipo) & t.ubicacionId.equals(ubicacionId)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Inventario>> getInventarioPorProducto(String productoId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.inventarios)
          ..where((t) => t.productoId.equals(productoId)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<double> getStockTotal(String productoId) async {
    final lista = await getInventarioPorProducto(productoId);
    return lista.fold<double>(0.0, (sum, inv) => sum + inv.cantidad);
  }

  Future<double> getStockEnUbicacion(
      String productoId, String ubicacionTipo, String ubicacionId) async {
    final inv = await getInventario(productoId, ubicacionTipo, ubicacionId);
    return inv?.cantidad ?? 0.0;
  }

  Future<void> actualizarStock(String productoId, String ubicacionTipo,
      String ubicacionId, double cantidad) async {
    final db = await _dbService.db;
    final existing = await getInventario(productoId, ubicacionTipo, ubicacionId);
    final now = DateTime.now();
    if (existing == null) {
      final inv = Inventario()
        ..productoId = productoId
        ..ubicacionTipo = ubicacionTipo
        ..ubicacionId = ubicacionId
        ..cantidad = cantidad
        ..ultimaActualizacion = now
        ..sincronizado = false;
      await db.into(db.inventarios).insert(_toCompanion(inv));
    } else {
      existing.cantidad = cantidad;
      existing.ultimaActualizacion = now;
      existing.sincronizado = false;
      await (db.update(db.inventarios)
            ..where((t) => t.id.equals(existing.id ?? -1)))
          .write(_toCompanion(existing));
    }
  }

  Future<void> ajustarStock(String productoId, String ubicacionTipo,
      String ubicacionId, double ajuste) async {
    AppLog.d('InventarioService.ajustarStock: Ajustando stock para $productoId en $ubicacionTipo:$ubicacionId por $ajuste');
    final actual = await getStockEnUbicacion(productoId, ubicacionTipo, ubicacionId);
    AppLog.d('InventarioService.ajustarStock: Stock actual: $actual');
    final nuevo = actual + ajuste;
    AppLog.d('InventarioService.ajustarStock: Nuevo stock: $nuevo');
    await actualizarStock(productoId, ubicacionTipo, ubicacionId, nuevo);
  }

  Future<void> transferirStock(
      String productoId,
      String origenTipo,
      String origenId,
      String destinoTipo,
      String destinoId,
      double cantidad) async {
    await ajustarStock(productoId, origenTipo, origenId, -cantidad);
    await ajustarStock(productoId, destinoTipo, destinoId, cantidad);
  }

  Future<List<Inventario>> getInventarioBajo() async {
    final db = await _dbService.db;
    final rows = await db.select(db.inventarios).get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Inventario>> getNoSincronizados() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.inventarios)
          ..where((t) => t.sincronizado.equals(false)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> marcarSincronizado(int? id, String supabaseId) async {
    if (id == null) return;
    final db = await _dbService.db;
    await (db.update(db.inventarios)..where((t) => t.id.equals(id))).write(
      InventariosCompanion(
        sincronizado: const Value(true),
        supabaseId: Value(supabaseId),
      ),
    );
  }

  Future<void> inicializarStockInicial() async {
    AppLog.i('InventarioService.inicializarStockInicial: Inicializando stock por defecto');
    final productos = await _productoService.getAll();
    AppLog.i('InventarioService.inicializarStockInicial: Creando stock para ${productos.length} productos');
    for (var producto in productos) {
      final existente = await getInventario(producto.codigo, 'almacen', 'ALM001');
      if (existente == null) {
        final inv = Inventario()
          ..productoId = producto.codigo
          ..ubicacionTipo = 'almacen'
          ..ubicacionId = 'ALM001'
          ..cantidad = 10.0
          ..ultimaActualizacion = DateTime.now()
          ..sincronizado = false;
        final db = await _dbService.db;
        await db.into(db.inventarios).insert(_toCompanion(inv));
          AppLog.i('InventarioService.inicializarStockInicial: Creado stock inicial para ${producto.nombre}: 10 unidades');
      } else {
        existente.cantidad = 10.0;
        existente.ultimaActualizacion = DateTime.now();
        existente.sincronizado = false;
        final db = await _dbService.db;
        await (db.update(db.inventarios)..where((t) => t.id.equals(existente.id ?? -1)))
            .write(_toCompanion(existente));
          AppLog.i('InventarioService.inicializarStockInicial: Actualizado stock para ${producto.nombre}: 10 unidades');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getInventarioGlobal() async {
    AppLog.d('InventarioService.getInventarioGlobal: Iniciando cálculo de inventario global');
    final productos = await _productoService.getAll();
    final inventarioGlobal = <Map<String, dynamic>>[];
    for (var producto in productos) {
      final total = await getStockTotal(producto.codigo);
      final almacenes = await getStockEnAlmacenes(producto.codigo);
      final tiendas = await getStockEnTiendas(producto.codigo);
      AppLog.d('InventarioService.getInventarioGlobal: ${producto.nombre} - Total: $total, Almacenes: $almacenes, Tiendas: $tiendas');
      inventarioGlobal.add({
        'producto': producto,
        'stockTotal': total,
        'stockAlmacenes': almacenes,
        'stockTiendas': tiendas,
        'bajoStock': total <= producto.stockMinimo && producto.stockMinimo > 0,
      });
    }
    AppLog.d('InventarioService.getInventarioGlobal: Inventario global calculado para ${inventarioGlobal.length} productos');
    return inventarioGlobal;
  }

  Future<List<Map<String, dynamic>>> getInventarioPorAlmacen(String almacenId) async {
    final productos = await _productoService.getAll();
    final inventarioAlmacen = <Map<String, dynamic>>[];
    for (var producto in productos) {
      final stock = await getStockEnUbicacion(producto.codigo, 'almacen', almacenId);
      if (stock > 0) {
        inventarioAlmacen.add({'producto': producto, 'stock': stock, 'bajoStock': stock <= producto.stockMinimo && producto.stockMinimo > 0});
      }
    }
    return inventarioAlmacen;
  }

  Future<List<Map<String, dynamic>>> getInventarioPorTienda(String tiendaId) async {
    final productos = await _productoService.getAll();
    final inventarioTienda = <Map<String, dynamic>>[];
    for (var producto in productos) {
      final stock = await getStockEnUbicacion(producto.codigo, 'tienda', tiendaId);
      if (stock > 0) {
        inventarioTienda.add({'producto': producto, 'stock': stock, 'bajoStock': stock <= producto.stockMinimo && producto.stockMinimo > 0});
      }
    }
    return inventarioTienda;
  }

  Future<double> getStockEnAlmacenes(String productoId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.inventarios)
          ..where((t) => t.productoId.equals(productoId) & t.ubicacionTipo.equals('almacen')))
        .get();
    final stock = rows.fold<double>(0.0, (sum, r) => sum + r.cantidad);
    AppLog.d('InventarioService.getStockEnAlmacenes: $productoId - Encontrados ${rows.length} registros, stock total: $stock');
    return stock;
  }

  Future<double> getStockEnTiendas(String productoId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.inventarios)
          ..where((t) => t.productoId.equals(productoId) & t.ubicacionTipo.equals('tienda')))
        .get();
    final stock = rows.fold<double>(0.0, (sum, r) => sum + r.cantidad);
    AppLog.d('InventarioService.getStockEnTiendas: $productoId - Encontrados ${rows.length} registros, stock total: $stock');
    return stock;
  }

  Future<Map<String, double>> getStockDetalladoPorUbicacion(String productoId) async {
    final lista = await getInventarioPorProducto(productoId);
    final stockDetallado = <String, double>{};
    for (var inv in lista) {
      final key = '${inv.ubicacionTipo}:${inv.ubicacionId}';
      stockDetallado[key] = inv.cantidad;
    }
    return stockDetallado;
  }

  Future<List<Map<String, dynamic>>> getInventarioBajoStock() async {
    final productos = await _productoService.getAll();
    final inventarioBajo = <Map<String, dynamic>>[];
    for (var producto in productos) {
      if (producto.stockMinimo > 0) {
        final total = await getStockTotal(producto.codigo);
        if (total <= producto.stockMinimo) {
          final det = await getStockDetalladoPorUbicacion(producto.codigo);
          inventarioBajo.add({
            'producto': producto,
            'stockTotal': total,
            'stockMinimo': producto.stockMinimo,
            'stockDetallado': det,
            'diferencia': producto.stockMinimo - total,
          });
        }
      }
    }
    return inventarioBajo;
  }
}

