import '../models/empleado.dart';
import 'logger.dart';
import '../services/empleado_service.dart';
import '../services/tienda_service.dart';
import '../services/almacen_service.dart';
import '../models/tienda.dart';
import '../models/almacen.dart';

class CreateTestEmployee {
  static Future<void> createTestData() async {
    try {
      AppLog.i('Creando datos de prueba...');

      final empleadoService = EmpleadoService();
      final tiendaService = TiendaService();
      final almacenService = AlmacenService();

      // 1. Crear tiendas de prueba
      final tiendas = [
        Tienda()
          ..codigo = 'TDA001'
          ..nombre = 'Tienda Central'
          ..direccion = 'Av. Principal #123'
          ..telefono = '5551234567'
          ..responsable = 'Juan Pérez'
          ..activo = true
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now(),
        Tienda()
          ..codigo = 'TDA002'
          ..nombre = 'Tienda Norte'
          ..direccion = 'Calle Norte #456'
          ..telefono = '5552345678'
          ..responsable = 'María García'
          ..activo = true
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now(),
        Tienda()
          ..codigo = 'TDA003'
          ..nombre = 'Tienda Sur'
          ..direccion = 'Av. Sur #789'
          ..telefono = '5553456789'
          ..responsable = 'Carlos López'
          ..activo = false
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now(),
      ];

      for (final tienda in tiendas) {
        await tiendaService.crear(tienda);
        AppLog.i('✅ Tienda creada: ${tienda.nombre}');
      }

      // 2. Crear almacén de prueba
      final almacen = Almacen()
        ..codigo = 'ALM001'
        ..nombre = 'Almacén Principal'
        ..direccion = 'Calle Industrial #456'
        ..telefono = '5557654321'
        ..responsable = 'María González'
        ..activo = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await almacenService.crear(almacen);
      AppLog.i('✅ Almacén creado: ${almacen.nombre}');

      // 3. Crear empleado admin
      final empleadoAdmin = Empleado()
        ..codigo = 'EMP001'
        ..nombres = 'Admin'
        ..apellidos = 'Sistema'
        ..email = 'admin@ejemplo.com'
        ..telefono = '0000000000'
        ..rol = 'admin'
        ..tiendaId = 'TDA001'
        ..activo = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await empleadoService.crear(empleadoAdmin);
      AppLog.i('✅ Empleado admin creado: ${empleadoAdmin.email}');

      // 4. Crear empleado vendedor
      final empleadoVendedor = Empleado()
        ..codigo = 'EMP002'
        ..nombres = 'Juan'
        ..apellidos = 'Vendedor'
        ..email = 'vendedor@ejemplo.com'
        ..telefono = '1111111111'
        ..rol = 'vendedor'
        ..tiendaId = 'TDA001'
        ..activo = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await empleadoService.crear(empleadoVendedor);
      AppLog.i('✅ Empleado vendedor creado: ${empleadoVendedor.email}');

      // 5. Crear empleado encargado de almacén
      final empleadoAlmacen = Empleado()
        ..codigo = 'EMP003'
        ..nombres = 'María'
        ..apellidos = 'Almacén'
        ..email = 'almacen@ejemplo.com'
        ..telefono = '2222222222'
        ..rol = 'encargado_almacen'
        ..almacenId = 'ALM001'
        ..activo = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await empleadoService.crear(empleadoAlmacen);
      AppLog.i('✅ Empleado almacén creado: ${empleadoAlmacen.email}');

      AppLog.i('\n🎉 ¡Datos de prueba creados exitosamente!');
      AppLog.i('\n📋 Credenciales para login:');
      AppLog.i('👤 Admin: admin@ejemplo.com (cualquier contraseña)');
      AppLog.i('👤 Vendedor: vendedor@ejemplo.com (cualquier contraseña)');
      AppLog.i('👤 Almacén: almacen@ejemplo.com (cualquier contraseña)');
      AppLog.w('\n⚠️  Nota: Para el login completo necesitarás crear estos usuarios en Supabase también.');

    } catch (e) {
      AppLog.e('❌ Error creando datos de prueba', e);
    }
  }
}
