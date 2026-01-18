import 'package:drift/drift.dart';
import '../models/almacen.dart';
import '../utils/logger.dart';
import 'database_service.dart';

class AlmacenService {
  final DatabaseService _dbService = DatabaseService();

  Almacen _fromRow(AlmacenesData row) {
    final a = Almacen()
      ..id = row.id
      ..codigo = row.codigo
      ..nombre = row.nombre
      ..direccion = row.direccion
      ..telefono = row.telefono
      ..responsable = row.responsable
      ..activo = row.activo
      ..supabaseId = row.supabaseId
      ..createdAt = row.createdAt
      ..updatedAt = row.updatedAt
      ..sincronizado = row.sincronizado
      ..eliminado = row.eliminado;
    return a;
  }

  AlmacenesCompanion _toCompanion(Almacen a, {bool includeId = false}) {
    return AlmacenesCompanion(
      id: includeId && a.id != null ? Value(a.id!) : const Value.absent(),
      codigo: Value(a.codigo),
      nombre: Value(a.nombre),
      direccion: Value(a.direccion),
      telefono: Value(a.telefono),
      responsable: Value(a.responsable),
      activo: Value(a.activo),
      supabaseId: Value(a.supabaseId),
      createdAt: Value(a.createdAt),
      updatedAt: Value(a.updatedAt),
      sincronizado: Value(a.sincronizado),
      eliminado: Value(a.eliminado),
    );
  }

  Future<List<Almacen>> getAll({bool incluirEliminados = false}) async {
    AppLog.d('AlmacenService.getAll: Iniciando consulta de almacenes...');
    final db = await _dbService.db;
    final query = db.select(db.almacenes);
    if (!incluirEliminados) {
      query.where((t) => t.eliminado.equals(false));
    }
    final rows = await query.get();
    var almacenes = rows.map(_fromRow).toList();
    AppLog.d('AlmacenService.getAll: Encontrados ${almacenes.length} almacenes');

    // Si no hay almacenes, crear uno por defecto
    if (almacenes.isEmpty) {
      AppLog.d('AlmacenService.getAll: No hay almacenes, creando uno por defecto...');
      final almacenDefault = Almacen()
        ..codigo = 'ALM001'
        ..nombre = 'Almacén Principal'
        ..direccion = 'Calle Industrial #456'
        ..telefono = '5557654321'
        ..responsable = 'María González'
        ..activo = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      final id = await db.into(db.almacenes).insert(_toCompanion(almacenDefault));
      almacenDefault.id = id;
      almacenes = [almacenDefault];
      AppLog.i('AlmacenService.getAll: Almacén por defecto creado');
    }

    for (int i = 0; i < almacenes.length; i++) {
      AppLog.d('AlmacenService.getAll: [$i] ${almacenes[i].nombre} (${almacenes[i].codigo}) - Activo: ${almacenes[i].activo}');
    }
    return almacenes;
  }

  Future<List<Almacen>> getActivos() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.almacenes)
          ..where((t) => t.eliminado.equals(false) & t.activo.equals(true)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<Almacen?> getByCodigo(String codigo) async {
    final db = await _dbService.db;
    final row = await (db.select(db.almacenes)
          ..where((t) => t.codigo.equals(codigo)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Almacen?> getById(int id) async {
    final db = await _dbService.db;
    final row = await (db.select(db.almacenes)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<int> crear(Almacen almacen) async {
    final db = await _dbService.db;
    final now = DateTime.now();
    almacen.createdAt = now;
    almacen.updatedAt = now;
    almacen.sincronizado = false;
    return await db.into(db.almacenes).insert(_toCompanion(almacen));
  }

  Future<void> actualizar(Almacen almacen) async {
    final db = await _dbService.db;
    almacen.updatedAt = DateTime.now();
    almacen.sincronizado = false;
    await (db.update(db.almacenes)
          ..where((t) => t.id.equals(almacen.id ?? -1)))
        .write(_toCompanion(almacen));
  }

  Future<void> eliminar(int? id) async {
    if (id == null) return;
    final almacen = await getById(id);
    if (almacen != null) {
      almacen.eliminado = true;
      almacen.updatedAt = DateTime.now();
      almacen.sincronizado = false;
      await actualizar(almacen);
    }
  }

  Future<List<Almacen>> getNoSincronizados() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.almacenes)
          ..where((t) => t.sincronizado.equals(false)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> marcarSincronizado(int? id, String supabaseId) async {
    if (id == null) return;
    final db = await _dbService.db;
    await (db.update(db.almacenes)..where((t) => t.id.equals(id))).write(
      AlmacenesCompanion(
        sincronizado: const Value(true),
        supabaseId: Value(supabaseId),
      ),
    );
  }
}


