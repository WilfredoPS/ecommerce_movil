import '../models/empleado.dart';
import '../models/tienda.dart';
import '../utils/logger.dart';
import '../models/almacen.dart';
import '../models/producto.dart';
import 'empleado_service.dart';
import 'tienda_service.dart';
import 'almacen_service.dart';
import 'producto_service.dart';
import 'supabase_service.dart';

class DataInitializer {
  static final DataInitializer _instance = DataInitializer._internal();
  factory DataInitializer() => _instance;
  DataInitializer._internal();

  final EmpleadoService _empleadoService = EmpleadoService();
  final TiendaService _tiendaService = TiendaService();
  final AlmacenService _almacenService = AlmacenService();
  final ProductoService _productoService = ProductoService();
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> initializeData() async {
    try {
    AppLog.i('Inicializando datos de prueba...');

      // 1. Crear tienda de prueba
      await _createTiendaPrueba();
      
      // 2. Crear almacén de prueba
      await _createAlmacenPrueba();
      
      // 3. Crear empleado admin de prueba
      await _createEmpleadoAdminPrueba();
      
      // 4. Crear productos de prueba
      await _createProductosPrueba();

      // 5. Crear usuario en Supabase (opcional, para testing)
      await _createSupabaseUserIfNeeded();

      AppLog.i('Datos de prueba inicializados correctamente');
    } catch (e) {
      AppLog.e('Error inicializando datos', e);
    }
  }

  Future<void> _createSupabaseUserIfNeeded() async {
    try {
      // Intentar crear usuario admin en Supabase
      await createSupabaseUser('admin@ejemplo.com', 'admin123');
    } catch (e) {
      AppLog.w('No se pudo crear usuario en Supabase (puede que ya exista): $e');
    }
  }

  Future<void> _createTiendaPrueba() async {
    final tienda = Tienda()
      ..codigo = 'TDA001'
      ..nombre = 'Tienda Central'
      ..direccion = 'Av. Principal #123'
      ..telefono = '5551234567'
      ..responsable = 'Juan Pérez'
      ..activo = true;

    await _tiendaService.crear(tienda);
    AppLog.i('Tienda creada: ${tienda.nombre}');
  }

  Future<void> _createAlmacenPrueba() async {
    final almacen = Almacen()
      ..codigo = 'ALM001'
      ..nombre = 'Almacén Principal'
      ..direccion = 'Calle Industrial #456'
      ..telefono = '5557654321'
      ..responsable = 'María González'
      ..activo = true;

    await _almacenService.crear(almacen);
    AppLog.i('Almacén creado: ${almacen.nombre}');
  }

  Future<void> _createEmpleadoAdminPrueba() async {
    final empleado = Empleado()
      ..codigo = 'EMP001'
      ..nombres = 'Admin'
      ..apellidos = 'Sistema'
      ..email = 'admin@ejemplo.com'
      ..telefono = '0000000000'
      ..rol = 'admin'
      ..tiendaId = 'TDA001'
      ..activo = true;

    await _empleadoService.crear(empleado);
    AppLog.i('Empleado admin creado: ${empleado.email}');
  }

  Future<void> _createProductosPrueba() async {
    final productos = [
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

    for (var data in productos) {
      final producto = Producto()
        ..codigo = data['codigo'] as String
        ..nombre = data['nombre'] as String
        ..categoria = data['categoria'] as String
        ..unidadMedida = data['unidad_medida'] as String
        ..precioCompra = data['precio_compra'] as double
        ..precioVenta = data['precio_venta'] as double
        ..stockMinimo = data['stock_minimo'] as int;

      await _productoService.crear(producto);
    }
    AppLog.i('Productos de prueba creados: ${productos.length}');
  }

  Future<void> createSupabaseUser(String email, String password) async {
    try {
      final response = await _supabaseService.signUp(email, password);
      if (response.user != null) {
        AppLog.i('Usuario creado en Supabase: $email');
        
        // Actualizar el empleado con el ID de Supabase
        final empleado = await _empleadoService.getByEmail(email);
        if (empleado != null) {
          empleado.supabaseUserId = response.user!.id;
          await _empleadoService.actualizar(empleado);
          AppLog.i('Empleado actualizado con ID de Supabase');
        }
      }
    } catch (e) {
      AppLog.e('Error creando usuario en Supabase', e);
    }
  }
}
