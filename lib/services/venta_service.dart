import 'package:drift/drift.dart';
import '../utils/logger.dart';
import '../models/venta.dart';
import 'database_service.dart';
import 'inventario_service.dart';
import 'authorization_service.dart';

class VentaService {
  final DatabaseService _dbService = DatabaseService();
  final InventarioService _inventarioService = InventarioService();
  final AuthorizationService _authz = AuthorizationService();

  Venta _fromRow(VentasData row) {
    final v = Venta()
      ..id = row.id
      ..numeroVenta = row.numeroVenta
      ..fechaVenta = row.fechaVenta
      ..tiendaId = row.tiendaId
      ..empleadoId = row.empleadoId
      ..cliente = row.cliente
      ..clienteDocumento = row.clienteDocumento
      ..clienteTelefono = row.clienteTelefono
      ..subtotal = row.subtotal
      ..descuento = row.descuento
      ..impuesto = row.impuesto
      ..total = row.total
      ..metodoPago = row.metodoPago
      ..estado = row.estado
      ..observaciones = row.observaciones
      ..supabaseId = row.supabaseId
      ..createdAt = row.createdAt
      ..updatedAt = row.updatedAt
      ..sincronizado = row.sincronizado
      ..eliminado = row.eliminado;
    return v;
  }

  DetalleVenta _detalleFromRow(DetalleVentasData row) {
    final d = DetalleVenta()
      ..id = row.id
      ..ventaId = row.ventaId
      ..productoId = row.productoId
      ..cantidad = row.cantidad
      ..precioUnitario = row.precioUnitario
      ..descuento = row.descuento
      ..subtotal = row.subtotal
      ..supabaseId = row.supabaseId
      ..sincronizado = row.sincronizado
      ..createdAt = row.createdAt
      ..updatedAt = row.updatedAt;
    return d;
  }

  VentasCompanion _toCompanion(Venta v, {bool includeId = false}) {
    return VentasCompanion(
      id: includeId && v.id != null ? Value(v.id!) : const Value.absent(),
      numeroVenta: Value(v.numeroVenta),
      fechaVenta: Value(v.fechaVenta),
      tiendaId: Value(v.tiendaId),
      empleadoId: Value(v.empleadoId),
      cliente: Value(v.cliente),
      clienteDocumento: Value(v.clienteDocumento),
      clienteTelefono: Value(v.clienteTelefono),
      subtotal: Value(v.subtotal),
      descuento: Value(v.descuento),
      impuesto: Value(v.impuesto),
      total: Value(v.total),
      metodoPago: Value(v.metodoPago),
      estado: Value(v.estado),
      observaciones: Value(v.observaciones),
      supabaseId: Value(v.supabaseId),
      createdAt: Value(v.createdAt),
      updatedAt: Value(v.updatedAt),
      sincronizado: Value(v.sincronizado),
      eliminado: Value(v.eliminado),
    );
  }

  DetalleVentasCompanion _detalleToCompanion(DetalleVenta d, {bool includeId = false}) {
    return DetalleVentasCompanion(
      id: includeId && d.id != null ? Value(d.id!) : const Value.absent(),
      ventaId: Value(d.ventaId),
      productoId: Value(d.productoId),
      cantidad: Value(d.cantidad),
      precioUnitario: Value(d.precioUnitario),
      descuento: Value(d.descuento),
      subtotal: Value(d.subtotal),
      supabaseId: Value(d.supabaseId),
      sincronizado: Value(d.sincronizado),
      createdAt: Value(d.createdAt),
      updatedAt: Value(d.updatedAt),
    );
  }

  Future<List<Venta>> getAll() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.ventas)
          ..where((t) => t.eliminado.equals(false)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Venta>> getByTienda(String tiendaId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.ventas)
          ..where((t) => t.eliminado.equals(false) & t.tiendaId.equals(tiendaId)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<Venta?> getById(int id) async {
    final db = await _dbService.db;
    final row = await (db.select(db.ventas)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Venta?> getByNumeroVenta(String numeroVenta) async {
    final db = await _dbService.db;
    final row = await (db.select(db.ventas)
          ..where((t) => t.numeroVenta.equals(numeroVenta)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<double> getTotalVentasDelDia(String tiendaId) async {
    final db = await _dbService.db;
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
    final rows = await (db.select(db.ventas)
          ..where((t) => t.eliminado.equals(false) &
              t.tiendaId.equals(tiendaId) & t.fechaVenta.isBetweenValues(inicio, fin)))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.total);
  }

  Future<Map<String, double>> getTotalVentasGlobalDelDia() async {
    final db = await _dbService.db;
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
    final rows = await (db.select(db.ventas)
          ..where((t) => t.eliminado.equals(false) & t.fechaVenta.isBetweenValues(inicio, fin)))
        .get();
    final Map<String, double> porTienda = {};
    for (var r in rows) {
      porTienda[r.tiendaId] = (porTienda[r.tiendaId] ?? 0.0) + r.total;
    }
    return porTienda;
  }

  Future<String> generarNumeroVenta(String tiendaId) async {
    final db = await _dbService.db;
    final hoy = DateTime.now();
    final fecha = '${hoy.year}${hoy.month.toString().padLeft(2, '0')}${hoy.day.toString().padLeft(2, '0')}';
    for (int intento = 0; intento < 10; intento++) {
      final prefix = 'V$tiendaId$fecha';
      final rows = await (db.select(db.ventas)
            ..where((t) => t.numeroVenta.like('$prefix%')))
          .get();
      int maxNum = 0;
      for (var r in rows) {
        final tail = r.numeroVenta.substring(r.numeroVenta.length - 4);
        final num = int.tryParse(tail) ?? 0;
        if (num > maxNum) maxNum = num;
      }
      if (intento > 0) await Future.delayed(Duration(milliseconds: 10 + intento * 5));
      final siguiente = maxNum + 1 + intento;
      final numStr = siguiente.toString().padLeft(4, '0');
      final numero = '$prefix$numStr';
      final existe = await (db.select(db.ventas)
            ..where((t) => t.numeroVenta.equals(numero)))
          .getSingleOrNull();
      if (existe == null) {
        AppLog.d('VentaService.generarNumeroVenta: Generando número único: $numero (siguiente: $siguiente)');
        return numero;
      }
      AppLog.d('VentaService.generarNumeroVenta: Número $numero ya existe, reintentando...');
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final numero = 'V$tiendaId$fecha$timestamp';
    AppLog.d('VentaService.generarNumeroVenta: Usando timestamp como fallback: $numero');
    return numero;
  }

  Future<int> crear(Venta venta, List<DetalleVenta> detalles) async {
    _authz.ensure('realizar_ventas');
    final db = await _dbService.db;
    try {
      AppLog.d('VentaService.crear: Iniciando creación de venta ${venta.numeroVenta}');
      AppLog.d('VentaService.crear: Detalles a crear: ${detalles.length}');
      return await db.transaction(() async {
        venta.createdAt = DateTime.now();
        venta.updatedAt = DateTime.now();
        venta.sincronizado = false;
        final id = await db.into(db.ventas).insert(_toCompanion(venta));
        for (int i = 0; i < detalles.length; i++) {
          final d = detalles[i];
          AppLog.d('VentaService.crear: Guardando detalle ${i + 1}: ${d.productoId} - ${d.cantidad}');
          await db.into(db.detalleVentas).insert(_detalleToCompanion(d));
        }
        for (var d in detalles) {
          await _inventarioService.ajustarStock(d.productoId, 'tienda', venta.tiendaId, -d.cantidad);
        }
        AppLog.i('VentaService.crear: Venta creada exitosamente con ID: $id');
        return id;
      });
    } catch (e) {
      AppLog.e('VentaService.crear: Error creando venta', e, StackTrace.current);
      rethrow;
    }
  }

  Future<List<DetalleVenta>> getDetallesByNumeroVenta(String numeroVenta) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.detalleVentas)
          ..where((t) => t.ventaId.equals(numeroVenta)))
        .get();
    return rows.map(_detalleFromRow).toList();
  }

  Future<List<DetalleVenta>> getDetallesNoSincronizados(String numeroVenta) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.detalleVentas)
          ..where((t) => t.ventaId.equals(numeroVenta) & t.sincronizado.equals(false)))
        .get();
    return rows.map(_detalleFromRow).toList();
  }

  Future<void> marcarDetalleSincronizado(int? id, String supabaseId) async {
    if (id == null) return;
    final db = await _dbService.db;
    await (db.update(db.detalleVentas)..where((t) => t.id.equals(id))).write(
      DetalleVentasCompanion(
        sincronizado: const Value(true),
        supabaseId: Value(supabaseId),
      ),
    );
  }

  Future<void> actualizar(Venta venta) async {
    final db = await _dbService.db;
    venta.updatedAt = DateTime.now();
    venta.sincronizado = false;
    await (db.update(db.ventas)..where((t) => t.id.equals(venta.id ?? -1)))
        .write(_toCompanion(venta));
  }

  Future<void> eliminar(int id) async {
    final venta = await getById(id);
    if (venta != null) {
      venta.eliminado = true;
      venta.updatedAt = DateTime.now();
      venta.sincronizado = false;
      await actualizar(venta);
    }
  }

  Future<void> anularVenta(String numeroVenta) async {
    _authz.ensure('realizar_ventas');
    final db = await _dbService.db;
    final row = await (db.select(db.ventas)
          ..where((t) => t.numeroVenta.equals(numeroVenta)))
        .getSingleOrNull();
    if (row != null) {
      final venta = _fromRow(row);
      venta.estado = 'anulada';
      venta.updatedAt = DateTime.now();
      venta.sincronizado = false;
      await actualizar(venta);
      final detallesRows = await (db.select(db.detalleVentas)
            ..where((t) => t.ventaId.equals(numeroVenta)))
          .get();
      final detalles = detallesRows.map(_detalleFromRow).toList();
      for (var d in detalles) {
        await _inventarioService.ajustarStock(d.productoId, 'tienda', venta.tiendaId, d.cantidad);
      }
    }
  }

  Future<List<Venta>> getNoSincronizados() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.ventas)
          ..where((t) => t.sincronizado.equals(false)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> marcarSincronizado(int id, String supabaseId) async {
    final db = await _dbService.db;
    await (db.update(db.ventas)..where((t) => t.id.equals(id))).write(
      VentasCompanion(
        sincronizado: const Value(true),
        supabaseId: Value(supabaseId),
      ),
    );
  }
}