import 'package:drift/drift.dart';
import '../models/tienda.dart';
import 'database_service.dart';

class TiendaService {
  final DatabaseService _dbService = DatabaseService();

  Tienda _fromRow(TiendasData row) {
    final t = Tienda()
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
    return t;
  }

  TiendasCompanion _toCompanion(Tienda t, {bool includeId = false}) {
    return TiendasCompanion(
      id: includeId && t.id != null ? Value(t.id!) : const Value.absent(),
      codigo: Value(t.codigo),
      nombre: Value(t.nombre),
      direccion: Value(t.direccion),
      telefono: Value(t.telefono),
      responsable: Value(t.responsable),
      activo: Value(t.activo),
      supabaseId: Value(t.supabaseId),
      createdAt: Value(t.createdAt),
      updatedAt: Value(t.updatedAt),
      sincronizado: Value(t.sincronizado),
      eliminado: Value(t.eliminado),
    );
  }

  Future<List<Tienda>> getAll({bool incluirEliminados = false}) async {
    final db = await _dbService.db;
    final query = db.select(db.tiendas);
    if (!incluirEliminados) {
      query.where((t) => t.eliminado.equals(false));
    }
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Tienda>> getActivas() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.tiendas)
          ..where((t) => t.eliminado.equals(false) & t.activo.equals(true)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<Tienda?> getByCodigo(String codigo) async {
    final db = await _dbService.db;
    final row = await (db.select(db.tiendas)
          ..where((t) => t.codigo.equals(codigo)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Tienda?> getById(int id) async {
    final db = await _dbService.db;
    final row = await (db.select(db.tiendas)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<int> crear(Tienda tienda) async {
    final db = await _dbService.db;
    final now = DateTime.now();
    tienda.createdAt = now;
    tienda.updatedAt = now;
    tienda.sincronizado = false;
    return await db.into(db.tiendas).insert(_toCompanion(tienda));
  }

  Future<void> actualizar(Tienda tienda) async {
    final db = await _dbService.db;
    tienda.updatedAt = DateTime.now();
    tienda.sincronizado = false;
    await (db.update(db.tiendas)
          ..where((t) => t.id.equals(tienda.id ?? -1)))
        .write(_toCompanion(tienda));
  }

  Future<void> eliminar(int? id) async {
    if (id == null) return;
    final tienda = await getById(id);
    if (tienda != null) {
      tienda.eliminado = true;
      tienda.updatedAt = DateTime.now();
      tienda.sincronizado = false;
      await actualizar(tienda);
    }
  }

  Future<List<Tienda>> getNoSincronizados() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.tiendas)
          ..where((t) => t.sincronizado.equals(false)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> marcarSincronizado(int? id, String supabaseId) async {
    if (id == null) return;
    final db = await _dbService.db;
    await (db.update(db.tiendas)..where((t) => t.id.equals(id))).write(
      TiendasCompanion(
        sincronizado: const Value(true),
        supabaseId: Value(supabaseId),
      ),
    );
  }
}