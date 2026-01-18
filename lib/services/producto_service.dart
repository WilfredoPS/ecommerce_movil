import 'package:drift/drift.dart';
import '../models/producto.dart';
import '../utils/logger.dart';
import 'database_service.dart';
import 'authorization_service.dart';

class ProductoService {
  final DatabaseService _dbService = DatabaseService();
  final AuthorizationService _authz = AuthorizationService();

  Producto _fromRow(ProductosData row) {
    final p = Producto()
      ..id = row.id
      ..codigo = row.codigo
      ..nombre = row.nombre
      ..descripcion = row.descripcion
      ..categoria = row.categoria
      ..unidadMedida = row.unidadMedida
      ..precioCompra = row.precioCompra
      ..precioVenta = row.precioVenta
      ..stockMinimo = row.stockMinimo
      ..imagenPath = row.imagenPath
      ..imagenUrl = row.imagenUrl
      ..supabaseId = row.supabaseId
      ..createdAt = row.createdAt
      ..updatedAt = row.updatedAt
      ..sincronizado = row.sincronizado
      ..eliminado = row.eliminado;
    return p;
  }

  ProductosCompanion _toCompanion(Producto p, {bool includeId = false}) {
    return ProductosCompanion(
      id: includeId && p.id != null ? Value(p.id!) : const Value.absent(),
      codigo: Value(p.codigo),
      nombre: Value(p.nombre),
      descripcion: Value(p.descripcion),
      categoria: Value(p.categoria),
      unidadMedida: Value(p.unidadMedida),
      precioCompra: Value(p.precioCompra),
      precioVenta: Value(p.precioVenta),
      stockMinimo: Value(p.stockMinimo),
      imagenPath: Value(p.imagenPath),
      imagenUrl: Value(p.imagenUrl),
      supabaseId: Value(p.supabaseId),
      createdAt: Value(p.createdAt),
      updatedAt: Value(p.updatedAt),
      sincronizado: Value(p.sincronizado),
      eliminado: Value(p.eliminado),
    );
  }

  Future<List<Producto>> getAll({bool incluirEliminados = false}) async {
    final db = await _dbService.db;
    final query = db.select(db.productos);
    if (!incluirEliminados) {
      query.where((tbl) => tbl.eliminado.equals(false));
    }
    final rows = await query.get();
    final productos = rows.map(_fromRow).toList();
    AppLog.d('ProductoService.getAll() - Encontrados ${productos.length} productos');
    for (var producto in productos) {
      AppLog.d('Producto: ${producto.nombre} - imagenPath: ${producto.imagenPath}');
    }
    return productos;
  }

  Future<Producto?> getByCodigo(String codigo) async {
    final db = await _dbService.db;
    final row = await (db.select(db.productos)
          ..where((t) => t.codigo.equals(codigo)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Producto?> getById(int id) async {
    final db = await _dbService.db;
    final row = await (db.select(db.productos)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<List<Producto>> buscar(String queryText) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.productos)
          ..where((t) => t.eliminado.equals(false) &
              (t.nombre.like('%$queryText%') | t.codigo.like('%$queryText%'))))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<Producto>> getByCategoria(String categoria) async {
    final db = await _dbService.db;
    final rows = await (db.select(db.productos)
          ..where((t) => t.eliminado.equals(false) & t.categoria.equals(categoria)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<int> crear(Producto producto) async {
    _authz.ensure('gestionar_productos');
    final db = await _dbService.db;
    final now = DateTime.now();
    producto.createdAt = now;
    producto.updatedAt = now;
    producto.sincronizado = false;
    return await db.into(db.productos).insert(_toCompanion(producto));
  }

  Future<void> actualizar(Producto producto) async {
    _authz.ensure('gestionar_productos');
    final db = await _dbService.db;
    producto.updatedAt = DateTime.now();
    producto.sincronizado = false;
    AppLog.d('ProductoService.actualizar() - Actualizando producto: ${producto.nombre}');
    AppLog.d('ProductoService.actualizar() - imagenPath: ${producto.imagenPath}');
    await (db.update(db.productos)
          ..where((t) => t.id.equals(producto.id ?? -1)))
        .write(_toCompanion(producto, includeId: false));
    AppLog.i('ProductoService.actualizar() - Producto actualizado exitosamente');
  }

  Future<void> eliminar(int? id) async {
    _authz.ensure('gestionar_productos');
    if (id == null) return;
    final producto = await getById(id);
    if (producto != null) {
      producto.eliminado = true;
      producto.updatedAt = DateTime.now();
      producto.sincronizado = false;
      await actualizar(producto);
    }
  }

  Future<List<Producto>> getNoSincronizados() async {
    final db = await _dbService.db;
    final rows = await (db.select(db.productos)
          ..where((t) => t.sincronizado.equals(false)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> marcarSincronizado(int? id, String supabaseId) async {
    if (id == null) return;
    final db = await _dbService.db;
    await (db.update(db.productos)..where((t) => t.id.equals(id))).write(
      ProductosCompanion(
        sincronizado: const Value(true),
        supabaseId: Value(supabaseId),
      ),
    );
  }

  Future<void> seedIfEmpty() async {
    final db = await _dbService.db;
    final existing = await db.select(db.productos).get();
    if (existing.isNotEmpty) return;

    final samples = [
      {
        'codigo': 'ROPA001',
        'nombre': 'Camiseta Deportiva Nike',
        'categoria': 'ropa deportiva',
        'unidad_medida': 'pieza',
        'precio_compra': 45.00,
        'precio_venta': 75.00,
        'stock_minimo': 20,
      },
      {
        'codigo': 'CALZ001',
        'nombre': 'Zapatillas Running Adidas',
        'categoria': 'calzado deportivo',
        'unidad_medida': 'par',
        'precio_compra': 120.00,
        'precio_venta': 200.00,
        'stock_minimo': 15,
      },
      {
        'codigo': 'EQUI001',
        'nombre': 'Pelota de Fútbol',
        'categoria': 'equipamiento',
        'unidad_medida': 'pieza',
        'precio_compra': 25.00,
        'precio_venta': 45.00,
        'stock_minimo': 30,
      },
      {
        'codigo': 'SUPL001',
        'nombre': 'Proteína Whey 1kg',
        'categoria': 'suplementos',
        'unidad_medida': 'unidad',
        'precio_compra': 80.00,
        'precio_venta': 130.00,
        'stock_minimo': 25,
      },
      {
        'codigo': 'ACCE001',
        'nombre': 'Botella Deportiva',
        'categoria': 'accesorios',
        'unidad_medida': 'pieza',
        'precio_compra': 8.00,
        'precio_venta': 15.00,
        'stock_minimo': 50,
      },
    ];

    // Crear productos directamente sin verificar permisos (inicialización)
    for (final p in samples) {
      final now = DateTime.now();
      final prod = Producto()
        ..codigo = p['codigo'] as String
        ..nombre = p['nombre'] as String
        ..categoria = p['categoria'] as String
        ..unidadMedida = p['unidad_medida'] as String
        ..precioCompra = p['precio_compra'] as double
        ..precioVenta = p['precio_venta'] as double
        ..stockMinimo = p['stock_minimo'] as int
        ..sincronizado = false
        ..eliminado = false
        ..createdAt = now
        ..updatedAt = now;
      
      // Insertar directamente en la base de datos sin verificar permisos
      await db.into(db.productos).insert(_toCompanion(prod));
    }
  }
}