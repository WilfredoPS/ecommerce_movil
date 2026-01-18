import 'package:drift/drift.dart';
import '../models/compra.dart';
import 'database_service.dart';
import 'inventario_service.dart';

class CompraService {
  final DatabaseService _dbService = DatabaseService();
  final InventarioService _inventarioService = InventarioService();

  Compra _fromRow(ComprasData row) {
    final c = Compra()
      ..id = row.id
      ..numeroCompra = row.numeroCompra
      ..fechaCompra = row.fechaCompra
      ..proveedor = row.proveedor
      ..numeroFactura = row.numeroFactura
      ..destinoTipo = row.destinoTipo
      ..destinoId = row.destinoId
      ..empleadoId = row.empleadoId
      ..subtotal = row.subtotal
      ..impuesto = row.impuesto
      ..total = row.total
      ..estado = row.estado
      ..observaciones = row.observaciones
      ..supabaseId = row.supabaseId
      ..createdAt = row.createdAt
      ..updatedAt = row.updatedAt
      ..sincronizado = row.sincronizado
      ..eliminado = row.eliminado;
    return c;
  }

  DetalleCompra _detalleFromRow(DetalleComprasData row) {
    final d = DetalleCompra()
      ..id = row.id
      ..compraId = row.compraId
      ..productoId = row.productoId
      ..cantidad = row.cantidad
      ..precioUnitario = row.precioUnitario
      ..subtotal = row.subtotal
      ..supabaseId = row.supabaseId
      ..sincronizado = row.sincronizado;
    return d;
  }

  ComprasCompanion _toCompanion(Compra c, {bool includeId = false}) {
    return ComprasCompanion(
      id: includeId && c.id != null ? Value(c.id!) : const Value.absent(),
      numeroCompra: Value(c.numeroCompra),
      fechaCompra: Value(c.fechaCompra),
      proveedor: Value(c.proveedor),
      numeroFactura: Value(c.numeroFactura),
      destinoTipo: Value(c.destinoTipo),
      destinoId: Value(c.destinoId),
      empleadoId: Value(c.empleadoId),
      subtotal: Value(c.subtotal),
      impuesto: Value(c.impuesto),
      total: Value(c.total),
      estado: Value(c.estado),
      observaciones: Value(c.observaciones),
      supabaseId: Value(c.supabaseId),
      createdAt: Value(c.createdAt),
      updatedAt: Value(c.updatedAt),
      sincronizado: Value(c.sincronizado),
      eliminado: Value(c.eliminado),
    );
  }

  DetalleComprasCompanion _detalleToCompanion(DetalleCompra d, {bool includeId = false}) {
    return DetalleComprasCompanion(
      id: includeId && d.id != null ? Value(d.id!) : const Value.absent(),
      compraId: Value(d.compraId),
      productoId: Value(d.productoId),
      cantidad: Value(d.cantidad),
      precioUnitario: Value(d.precioUnitario),
      subtotal: Value(d.subtotal),
      supabaseId: Value(d.supabaseId),
      sincronizado: Value(d.sincronizado),
    );
  }

  Future<List<Compra>> getAll({bool incluirEliminados = false}) async {
    final db = await _dbService.db;
    final query = db.select(db.compras)
      ..orderBy([(t) => OrderingTerm.desc(t.fechaCompra)]);
    if (!incluirEliminados) {
      query.where((t) => t.eliminado.equals(false));
    }
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  Future<Compra?> getByNumero(String numeroCompra) async {
    final db = await _dbService.db;
    final row = await (db.select(db.compras)
          ..where((t) => t.numeroCompra.equals(numeroCompra)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Compra?> getById(int id) async {
    final db = await _dbService.db;
    final row = await (db.select(db.compras)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<List<DetalleCompra>> getDetalles(String compraId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.detalleCompras)
          ..where((t) => t.compraId.equals(compraId)))
        .get();
    return rows.map(_detalleFromRow).toList();
  }

  Future<List<Compra>> getByFechas(DateTime inicio, DateTime fin) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.compras)
          ..where((t) => t.eliminado.equals(false) &
              t.fechaCompra.isBetweenValues(inicio, fin))
          ..orderBy([(t) => OrderingTerm.desc(t.fechaCompra)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Compra>> getByDestino(String destinoTipo, String destinoId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.compras)
          ..where((t) => t.eliminado.equals(false) &
              t.destinoTipo.equals(destinoTipo) & t.destinoId.equals(destinoId))
          ..orderBy([(t) => OrderingTerm.desc(t.fechaCompra)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<String> generarNumeroCompra() async {
    final ahora = DateTime.now();
    final prefijo = 'COM-${ahora.year}${ahora.month.toString().padLeft(2, '0')}';
    final db = await _dbService.db;
    final row = await (db.select(db.compras)
          ..where((t) => t.numeroCompra.like('$prefijo%'))
          ..orderBy([(t) => OrderingTerm.desc(t.numeroCompra)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return '$prefijo-0001';
    final partes = row.numeroCompra.split('-');
    final ultimoNumero = int.parse(partes.last);
    final nuevoNumero = ultimoNumero + 1;
    return '$prefijo-${nuevoNumero.toString().padLeft(4, '0')}';
  }

  Future<int> crear(Compra compra, List<DetalleCompra> detalles) async {
    final db = await _dbService.db;
    compra.createdAt = DateTime.now();
    compra.updatedAt = DateTime.now();
    compra.sincronizado = false;
    return await db.transaction(() async {
      final compraId = await db.into(db.compras).insert(_toCompanion(compra));
      for (var d in detalles) {
        d.sincronizado = false;
        await db.into(db.detalleCompras).insert(_detalleToCompanion(d));
      }
      if (compra.estado == 'completada') {
        for (var d in detalles) {
          await _inventarioService.ajustarStock(
            d.productoId,
            compra.destinoTipo,
            compra.destinoId,
            d.cantidad,
          );
        }
      }
      return compraId;
    });
  }

  Future<void> actualizar(Compra compra) async {
    final db = await _dbService.db;
    compra.updatedAt = DateTime.now();
    compra.sincronizado = false;
    await (db.update(db.compras)
          ..where((t) => t.id.equals(compra.id ?? -1)))
        .write(_toCompanion(compra));
  }

  Future<void> completarCompra(String compraId) async {
    final db = await _dbService.db;
    final row = await (db.select(db.compras)
          ..where((t) => t.numeroCompra.equals(compraId)))
        .getSingleOrNull();
    if (row != null && row.estado == 'pendiente') {
      final compra = _fromRow(row);
      compra.estado = 'completada';
      await actualizar(compra);
      final detalles = await getDetalles(compraId);
      for (var d in detalles) {
        await _inventarioService.ajustarStock(d.productoId, compra.destinoTipo, compra.destinoId, d.cantidad);
      }
    }
  }

  Future<void> anularCompra(String compraId) async {
    final db = await _dbService.db;
    final row = await (db.select(db.compras)
          ..where((t) => t.numeroCompra.equals(compraId)))
        .getSingleOrNull();
    if (row != null) {
      final compra = _fromRow(row);
      final estadoAnterior = compra.estado;
      compra.estado = 'anulada';
      await actualizar(compra);
      if (estadoAnterior == 'completada') {
        final detalles = await getDetalles(compraId);
        for (var d in detalles) {
          await _inventarioService.ajustarStock(d.productoId, compra.destinoTipo, compra.destinoId, -d.cantidad);
        }
      }
    }
  }

  Future<List<Compra>> getNoSincronizados() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.compras)
          ..where((t) => t.sincronizado.equals(false)))
        .get();
    return rows.map(_fromRow).toList();
  }
}






