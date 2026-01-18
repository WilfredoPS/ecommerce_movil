import 'package:drift/drift.dart';
import '../models/transferencia.dart';
import 'database_service.dart';
import 'inventario_service.dart';

class TransferenciaService {
  final DatabaseService _dbService = DatabaseService();
  final InventarioService _inventarioService = InventarioService();

  Transferencia _fromRow(TransferenciasData row) {
    final t = Transferencia()
      ..id = row.id
      ..numeroTransferencia = row.numeroTransferencia
      ..fechaTransferencia = row.fechaTransferencia
      ..origenTipo = row.origenTipo
      ..origenId = row.origenId
      ..destinoTipo = row.destinoTipo
      ..destinoId = row.destinoId
      ..empleadoId = row.empleadoId
      ..estado = row.estado
      ..fechaRecepcion = row.fechaRecepcion
      ..empleadoRecepcionId = row.empleadoRecepcionId
      ..observaciones = row.observaciones
      ..supabaseId = row.supabaseId
      ..createdAt = row.createdAt
      ..updatedAt = row.updatedAt
      ..sincronizado = row.sincronizado
      ..eliminado = row.eliminado;
    return t;
  }

  DetalleTransferencia _detalleFromRow(DetalleTransferenciasData row) {
    final d = DetalleTransferencia()
      ..id = row.id
      ..transferenciaId = row.transferenciaId
      ..productoId = row.productoId
      ..cantidadEnviada = row.cantidadEnviada
      ..cantidadRecibida = row.cantidadRecibida
      ..supabaseId = row.supabaseId
      ..sincronizado = row.sincronizado;
    return d;
  }

  TransferenciasCompanion _toCompanion(Transferencia t, {bool includeId = false}) {
    return TransferenciasCompanion(
      id: includeId && t.id != null ? Value(t.id!) : const Value.absent(),
      numeroTransferencia: Value(t.numeroTransferencia),
      fechaTransferencia: Value(t.fechaTransferencia),
      origenTipo: Value(t.origenTipo),
      origenId: Value(t.origenId),
      destinoTipo: Value(t.destinoTipo),
      destinoId: Value(t.destinoId),
      empleadoId: Value(t.empleadoId),
      estado: Value(t.estado),
      fechaRecepcion: Value(t.fechaRecepcion),
      empleadoRecepcionId: Value(t.empleadoRecepcionId),
      observaciones: Value(t.observaciones),
      supabaseId: Value(t.supabaseId),
      createdAt: Value(t.createdAt),
      updatedAt: Value(t.updatedAt),
      sincronizado: Value(t.sincronizado),
      eliminado: Value(t.eliminado),
    );
  }

  DetalleTransferenciasCompanion _detalleToCompanion(DetalleTransferencia d, {bool includeId = false}) {
    return DetalleTransferenciasCompanion(
      id: includeId && d.id != null ? Value(d.id!) : const Value.absent(),
      transferenciaId: Value(d.transferenciaId),
      productoId: Value(d.productoId),
      cantidadEnviada: Value(d.cantidadEnviada),
      cantidadRecibida: Value(d.cantidadRecibida),
      supabaseId: Value(d.supabaseId),
      sincronizado: Value(d.sincronizado),
    );
  }

  Future<List<Transferencia>> getAll({bool incluirEliminados = false}) async {
    final db = await _dbService.db;
    final query = db.select(db.transferencias)
      ..orderBy([(t) => OrderingTerm.desc(t.fechaTransferencia)]);
    if (!incluirEliminados) {
      query.where((t) => t.eliminado.equals(false));
    }
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  Future<Transferencia?> getByNumero(String numeroTransferencia) async {
    final db = await _dbService.db;
    final row = await (db.select(db.transferencias)
          ..where((t) => t.numeroTransferencia.equals(numeroTransferencia)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Transferencia?> getById(int id) async {
    final db = await _dbService.db;
    final row = await (db.select(db.transferencias)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<List<DetalleTransferencia>> getDetalles(String transferenciaId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.detalleTransferencias)
          ..where((t) => t.transferenciaId.equals(transferenciaId)))
        .get();
    return rows.map(_detalleFromRow).toList();
  }

  Future<List<Transferencia>> getByFechas(DateTime inicio, DateTime fin) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.transferencias)
          ..where((t) => t.eliminado.equals(false) &
              t.fechaTransferencia.isBetweenValues(inicio, fin))
          ..orderBy([(t) => OrderingTerm.desc(t.fechaTransferencia)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Transferencia>> getByOrigen(String origenTipo, String origenId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.transferencias)
          ..where((t) => t.eliminado.equals(false) & t.origenTipo.equals(origenTipo) & t.origenId.equals(origenId))
          ..orderBy([(t) => OrderingTerm.desc(t.fechaTransferencia)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Transferencia>> getByDestino(String destinoTipo, String destinoId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.transferencias)
          ..where((t) => t.eliminado.equals(false) & t.destinoTipo.equals(destinoTipo) & t.destinoId.equals(destinoId))
          ..orderBy([(t) => OrderingTerm.desc(t.fechaTransferencia)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<String> generarNumeroTransferencia() async {
    final ahora = DateTime.now();
    final prefijo = 'TRF-${ahora.year}${ahora.month.toString().padLeft(2, '0')}';
    final db = await _dbService.db;
    final row = await (db.select(db.transferencias)
          ..where((t) => t.numeroTransferencia.like('$prefijo%'))
          ..orderBy([(t) => OrderingTerm.desc(t.numeroTransferencia)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return '$prefijo-0001';
    final partes = row.numeroTransferencia.split('-');
    final ultimoNumero = int.parse(partes.last);
    final nuevoNumero = ultimoNumero + 1;
    return '$prefijo-${nuevoNumero.toString().padLeft(4, '0')}';
  }

  Future<int> crear(Transferencia transferencia, List<DetalleTransferencia> detalles) async {
    final db = await _dbService.db;
    transferencia.createdAt = DateTime.now();
    transferencia.updatedAt = DateTime.now();
    transferencia.sincronizado = false;
    return await db.transaction(() async {
      final id = await db.into(db.transferencias).insert(_toCompanion(transferencia));
      for (var d in detalles) {
        d.transferenciaId = transferencia.numeroTransferencia;
        d.sincronizado = false;
        await db.into(db.detalleTransferencias).insert(_detalleToCompanion(d));
      }
      return id;
    });
  }

  Future<void> actualizar(Transferencia transferencia) async {
    final db = await _dbService.db;
    transferencia.updatedAt = DateTime.now();
    transferencia.sincronizado = false;
    await (db.update(db.transferencias)
          ..where((t) => t.id.equals(transferencia.id ?? -1)))
        .write(_toCompanion(transferencia));
  }

  Future<void> enviarTransferencia(String transferenciaId) async {
    final db = await _dbService.db;
    final row = await (db.select(db.transferencias)
          ..where((t) => t.numeroTransferencia.equals(transferenciaId)))
        .getSingleOrNull();
    if (row != null && row.estado == 'pendiente') {
      final transferencia = _fromRow(row);
      transferencia.estado = 'en_transito';
      await actualizar(transferencia);
      final detalles = await getDetalles(transferenciaId);
      for (var d in detalles) {
        await _inventarioService.ajustarStock(d.productoId, transferencia.origenTipo, transferencia.origenId, -d.cantidadEnviada);
      }
    }
  }

  Future<void> recibirTransferencia(String transferenciaId, String empleadoRecepcionId) async {
    final db = await _dbService.db;
    final row = await (db.select(db.transferencias)
          ..where((t) => t.numeroTransferencia.equals(transferenciaId)))
        .getSingleOrNull();
    if (row != null && row.estado == 'en_transito') {
      final transferencia = _fromRow(row);
      transferencia.estado = 'recibida';
      transferencia.fechaRecepcion = DateTime.now();
      transferencia.empleadoRecepcionId = empleadoRecepcionId;
      await actualizar(transferencia);
      final detalles = await getDetalles(transferenciaId);
      for (var d in detalles) {
        await _inventarioService.ajustarStock(d.productoId, transferencia.destinoTipo, transferencia.destinoId, d.cantidadRecibida);
      }
    }
  }

  Future<void> completarTransferencia(int transferenciaId) async {
    final db = await _dbService.db;
    final row = await (db.select(db.transferencias)..where((t) => t.id.equals(transferenciaId))).getSingleOrNull();
    if (row != null && row.estado == 'pendiente') {
      final transferencia = _fromRow(row);
      transferencia.estado = 'completada';
      transferencia.fechaRecepcion = DateTime.now();
      await actualizar(transferencia);
      final detalles = await getDetalles(transferencia.numeroTransferencia);
      for (var d in detalles) {
        await _inventarioService.ajustarStock(d.productoId, transferencia.origenTipo, transferencia.origenId, -d.cantidadEnviada);
        await _inventarioService.ajustarStock(d.productoId, transferencia.destinoTipo, transferencia.destinoId, d.cantidadRecibida);
      }
    }
  }

  Future<void> anularTransferencia(int transferenciaId) async {
    final db = await _dbService.db;
    final row = await (db.select(db.transferencias)..where((t) => t.id.equals(transferenciaId))).getSingleOrNull();
    if (row != null) {
      final transferencia = _fromRow(row);
      final estadoAnterior = transferencia.estado;
      transferencia.estado = 'anulada';
      await actualizar(transferencia);
      if (estadoAnterior == 'completada') {
        final detalles = await getDetalles(transferencia.numeroTransferencia);
        for (var d in detalles) {
          await _inventarioService.ajustarStock(d.productoId, transferencia.origenTipo, transferencia.origenId, d.cantidadEnviada);
          await _inventarioService.ajustarStock(d.productoId, transferencia.destinoTipo, transferencia.destinoId, -d.cantidadRecibida);
        }
      }
    }
  }

  Future<void> anularTransferenciaPorNumero(String transferenciaId) async {
    final db = await _dbService.db;
    final row = await (db.select(db.transferencias)
          ..where((t) => t.numeroTransferencia.equals(transferenciaId)))
        .getSingleOrNull();
    if (row != null) {
      final transferencia = _fromRow(row);
      final estadoAnterior = transferencia.estado;
      transferencia.estado = 'anulada';
      await actualizar(transferencia);
      if (estadoAnterior == 'en_transito') {
        final detalles = await getDetalles(transferenciaId);
        for (var d in detalles) {
          await _inventarioService.ajustarStock(d.productoId, transferencia.origenTipo, transferencia.origenId, d.cantidadEnviada);
        }
      }
    }
  }

  Future<List<Transferencia>> getNoSincronizados() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.transferencias)
          ..where((t) => t.sincronizado.equals(false)))
        .get();
    return rows.map(_fromRow).toList();
  }
}





