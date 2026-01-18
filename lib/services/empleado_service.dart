import 'package:drift/drift.dart';
import '../models/empleado.dart';
import 'database_service.dart';

class EmpleadoService {
  final DatabaseService _dbService = DatabaseService();

  Empleado _fromRow(EmpleadosData row) {
    final e = Empleado()
      ..id = row.id
      ..codigo = row.codigo
      ..nombres = row.nombres
      ..apellidos = row.apellidos
      ..email = row.email
      ..telefono = row.telefono
      ..rol = row.rol
      ..tiendaId = row.tiendaId
      ..almacenId = row.almacenId
      ..activo = row.activo
      ..supabaseUserId = row.supabaseUserId
      ..supabaseId = row.supabaseId
      ..createdAt = row.createdAt
      ..updatedAt = row.updatedAt
      ..sincronizado = row.sincronizado
      ..eliminado = row.eliminado;
    return e;
  }

  EmpleadosCompanion _toCompanion(Empleado e, {bool includeId = false}) {
    return EmpleadosCompanion(
      id: includeId && e.id != null ? Value(e.id!) : const Value.absent(),
      codigo: Value(e.codigo),
      nombres: Value(e.nombres),
      apellidos: Value(e.apellidos),
      email: Value(e.email),
      telefono: Value(e.telefono),
      rol: Value(e.rol),
      tiendaId: Value(e.tiendaId),
      almacenId: Value(e.almacenId),
      activo: Value(e.activo),
      supabaseUserId: Value(e.supabaseUserId),
      supabaseId: Value(e.supabaseId),
      createdAt: Value(e.createdAt),
      updatedAt: Value(e.updatedAt),
      sincronizado: Value(e.sincronizado),
      eliminado: Value(e.eliminado),
    );
  }

  Future<List<Empleado>> getAll({bool incluirEliminados = false}) async {
    final db = await _dbService.db;
    final query = db.select(db.empleados);
    if (!incluirEliminados) {
      query.where((t) => t.eliminado.equals(false));
    }
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Empleado>> getActivos() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.empleados)
          ..where((t) => t.eliminado.equals(false) & t.activo.equals(true)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<Empleado?> getByEmail(String email) async {
    final db = await _dbService.db;
    final row = await (db.select(db.empleados)
          ..where((t) => t.email.equals(email)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Empleado?> getByCodigo(String codigo) async {
    final db = await _dbService.db;
    final row = await (db.select(db.empleados)
          ..where((t) => t.codigo.equals(codigo)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Empleado?> getById(int id) async {
    final db = await _dbService.db;
    final row = await (db.select(db.empleados)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<List<Empleado>> getByRol(String rol) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.empleados)
          ..where((t) => t.eliminado.equals(false) & t.rol.equals(rol)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Empleado>> getByTienda(String tiendaId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.empleados)
          ..where((t) => t.eliminado.equals(false) & t.tiendaId.equals(tiendaId)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Empleado>> getByAlmacen(String almacenId) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.empleados)
          ..where((t) => t.eliminado.equals(false) & t.almacenId.equals(almacenId)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<int> crear(Empleado empleado) async {
    final db = await _dbService.db;
    final now = DateTime.now();
    empleado.createdAt = now;
    empleado.updatedAt = now;
    empleado.sincronizado = false;
    return await db.into(db.empleados).insert(_toCompanion(empleado));
  }

  Future<void> actualizar(Empleado empleado) async {
    final db = await _dbService.db;
    empleado.updatedAt = DateTime.now();
    empleado.sincronizado = false;
    await (db.update(db.empleados)
          ..where((t) => t.id.equals(empleado.id ?? -1)))
        .write(_toCompanion(empleado));
  }

  Future<void> eliminar(int? id) async {
    if (id == null) return;
    final empleado = await getById(id);
    if (empleado != null) {
      empleado.eliminado = true;
      empleado.updatedAt = DateTime.now();
      empleado.sincronizado = false;
      await actualizar(empleado);
    }
  }

  Future<List<Empleado>> getNoSincronizados() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.empleados)
          ..where((t) => t.sincronizado.equals(false)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> marcarSincronizado(int? id, String supabaseId) async {
    if (id == null) return;
    final db = await _dbService.db;
    await (db.update(db.empleados)..where((t) => t.id.equals(id))).write(
      EmpleadosCompanion(
        sincronizado: const Value(true),
        supabaseId: Value(supabaseId),
      ),
    );
  }
}


