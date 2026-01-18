import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database_service.g.dart';

// Definiciones de tablas Drift

@DataClassName('ProductosData')
class Productos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().unique()();
  TextColumn get nombre => text()();
  TextColumn get descripcion => text().nullable()();
  TextColumn get categoria => text()();
  TextColumn get unidadMedida => text()();
  RealColumn get precioCompra => real()();
  RealColumn get precioVenta => real()();
  IntColumn get stockMinimo => integer().withDefault(const Constant(0))();
  TextColumn get imagenPath => text().nullable()();
  TextColumn get imagenUrl => text().nullable()();
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
  BoolColumn get eliminado => boolean().withDefault(const Constant(false))();
}

@DataClassName('AlmacenesData')
class Almacenes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().unique()();
  TextColumn get nombre => text()();
  TextColumn get direccion => text()();
  TextColumn get telefono => text().nullable()();
  TextColumn get responsable => text()();
  BoolColumn get activo => boolean()();
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
  BoolColumn get eliminado => boolean().withDefault(const Constant(false))();
}

@DataClassName('TiendasData')
class Tiendas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().unique()();
  TextColumn get nombre => text()();
  TextColumn get direccion => text()();
  TextColumn get telefono => text().nullable()();
  TextColumn get responsable => text()();
  BoolColumn get activo => boolean()();
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
  BoolColumn get eliminado => boolean().withDefault(const Constant(false))();
}

@DataClassName('EmpleadosData')
class Empleados extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().unique()();
  TextColumn get nombres => text()();
  TextColumn get apellidos => text()();
  TextColumn get email => text().unique()();
  TextColumn get telefono => text()();
  TextColumn get rol => text()();
  TextColumn get tiendaId => text().nullable()();
  TextColumn get almacenId => text().nullable()();
  BoolColumn get activo => boolean()();
  TextColumn get supabaseUserId => text().nullable()();
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
  BoolColumn get eliminado => boolean().withDefault(const Constant(false))();
}

@DataClassName('InventariosData')
class Inventarios extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productoId => text()();
  TextColumn get ubicacionTipo => text()();
  TextColumn get ubicacionId => text()();
  RealColumn get cantidad => real()();
  DateTimeColumn get ultimaActualizacion => dateTime()();
  TextColumn get supabaseId => text().nullable()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {productoId, ubicacionTipo, ubicacionId},
  ];
}

@DataClassName('ComprasData')
class Compras extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get numeroCompra => text().unique()();
  DateTimeColumn get fechaCompra => dateTime()();
  TextColumn get proveedor => text()();
  TextColumn get numeroFactura => text().nullable()();
  TextColumn get destinoTipo => text()();
  TextColumn get destinoId => text()();
  TextColumn get empleadoId => text()();
  RealColumn get subtotal => real()();
  RealColumn get impuesto => real()();
  RealColumn get total => real()();
  TextColumn get estado => text()();
  TextColumn get observaciones => text().nullable()();
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
  BoolColumn get eliminado => boolean().withDefault(const Constant(false))();
}

@DataClassName('DetalleComprasData')
class DetalleCompras extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get compraId => text()();
  TextColumn get productoId => text()();
  RealColumn get cantidad => real()();
  RealColumn get precioUnitario => real()();
  RealColumn get subtotal => real()();
  TextColumn get supabaseId => text().nullable()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
}

@DataClassName('VentasData')
class Ventas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get numeroVenta => text().unique()();
  DateTimeColumn get fechaVenta => dateTime()();
  TextColumn get tiendaId => text()();
  TextColumn get empleadoId => text()();
  TextColumn get cliente => text()();
  TextColumn get clienteDocumento => text().nullable()();
  TextColumn get clienteTelefono => text().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get descuento => real()();
  RealColumn get impuesto => real()();
  RealColumn get total => real()();
  TextColumn get metodoPago => text()();
  TextColumn get estado => text()();
  TextColumn get observaciones => text().nullable()();
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
  BoolColumn get eliminado => boolean().withDefault(const Constant(false))();
}

@DataClassName('DetalleVentasData')
class DetalleVentas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ventaId => text()();
  TextColumn get productoId => text()();
  RealColumn get cantidad => real()();
  RealColumn get precioUnitario => real()();
  RealColumn get descuento => real()();
  RealColumn get subtotal => real()();
  TextColumn get supabaseId => text().nullable()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('TransferenciasData')
class Transferencias extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get numeroTransferencia => text().unique()();
  DateTimeColumn get fechaTransferencia => dateTime()();
  TextColumn get origenTipo => text()();
  TextColumn get origenId => text()();
  TextColumn get destinoTipo => text()();
  TextColumn get destinoId => text()();
  TextColumn get empleadoId => text()();
  TextColumn get estado => text()();
  DateTimeColumn get fechaRecepcion => dateTime().nullable()();
  TextColumn get empleadoRecepcionId => text().nullable()();
  TextColumn get observaciones => text().nullable()();
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
  BoolColumn get eliminado => boolean().withDefault(const Constant(false))();
}

@DataClassName('DetalleTransferenciasData')
class DetalleTransferencias extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transferenciaId => text()();
  TextColumn get productoId => text()();
  RealColumn get cantidadEnviada => real()();
  RealColumn get cantidadRecibida => real()();
  TextColumn get supabaseId => text().nullable()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.db'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [
  Productos,
  Almacenes,
  Tiendas,
  Empleados,
  Inventarios,
  Compras,
  DetalleCompras,
  Ventas,
  DetalleVentas,
  Transferencias,
  DetalleTransferencias,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  AppDatabase? _db;

  Future<AppDatabase> get db async {
    _db ??= AppDatabase();
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}