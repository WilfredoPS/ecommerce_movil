import 'package:connectivity_plus/connectivity_plus.dart';
import 'supabase_service.dart';
import '../utils/logger.dart';
import '../models/producto.dart';
import '../models/almacen.dart';
import '../models/tienda.dart';
import '../models/empleado.dart';
import 'producto_service.dart';
import 'almacen_service.dart';
import 'tienda_service.dart';
import 'empleado_service.dart';
import 'inventario_service.dart';
import 'compra_service.dart';
import 'venta_service.dart';
import 'transferencia_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final ProductoService _productoService = ProductoService();
  final AlmacenService _almacenService = AlmacenService();
  final TiendaService _tiendaService = TiendaService();
  final EmpleadoService _empleadoService = EmpleadoService();
  final InventarioService _inventarioService = InventarioService();
  final CompraService _compraService = CompraService();
  final VentaService _ventaService = VentaService();
  final TransferenciaService _transferenciaService = TransferenciaService();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<bool> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Helpers para mapear códigos (TDA001/ALM001/EMP001) a UUIDs reales en Supabase
  bool _looksLikeUuid(String value) {
    final r = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return r.hasMatch(value);
  }

  Future<String?> _resolveTiendaId(String? tiendaCodigoOrId) async {
    if (tiendaCodigoOrId == null || tiendaCodigoOrId.isEmpty) return null;
    if (_looksLikeUuid(tiendaCodigoOrId)) return tiendaCodigoOrId;
    final tienda = await _supabaseService.getTiendaByCodigo(tiendaCodigoOrId);
    return tienda != null ? tienda['id'] as String? : null;
  }

  Future<String?> _resolveAlmacenId(String? almacenCodigoOrId) async {
    if (almacenCodigoOrId == null || almacenCodigoOrId.isEmpty) return null;
    if (_looksLikeUuid(almacenCodigoOrId)) return almacenCodigoOrId;
    final almacen = await _supabaseService.getAlmacenByCodigo(almacenCodigoOrId);
    return almacen != null ? almacen['id'] as String? : null;
  }

  Future<String?> _resolveEmpleadoId(String? empleadoCodigoOrId) async {
    if (empleadoCodigoOrId == null || empleadoCodigoOrId.isEmpty) return null;
    if (_looksLikeUuid(empleadoCodigoOrId)) return empleadoCodigoOrId;
    final emp = await _supabaseService.getEmpleadoByCodigo(empleadoCodigoOrId);
    return emp != null ? emp['id'] as String? : null;
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;

    final hasConnection = await checkConnectivity();
    if (!hasConnection) {
      throw Exception('Sin conexión a internet');
    }

    _isSyncing = true;

    try {
      // Sincronizar en orden: datos maestros primero, luego transacciones
      await _syncProductos();
      await _syncAlmacenes();
      await _syncTiendas();
      await _syncEmpleados();
      await _syncInventarios();
      await _syncCompras();
      await _syncVentas();
      await _syncTransferencias();

      // Luego descargar cambios desde Supabase (delta si hay lastSync)
      await _downloadFromSupabase(since: _lastSyncTime);

      _lastSyncTime = DateTime.now();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncProductos() async {
    final noSincronizados = await _productoService.getNoSincronizados();
    
    for (var producto in noSincronizados) {
      try {
        final data = {
          'codigo': producto.codigo,
          'nombre': producto.nombre,
          'descripcion': producto.descripcion,
          'categoria': producto.categoria,
          'unidad_medida': producto.unidadMedida,
          'precio_compra': producto.precioCompra,
          'precio_venta': producto.precioVenta,
          'stock_minimo': producto.stockMinimo,
          'eliminado': producto.eliminado,
          'updated_at': producto.updatedAt.toIso8601String(),
        };

        if (producto.supabaseId == null) {
          try {
          final response = await _supabaseService.createProducto(data);
          await _productoService.marcarSincronizado(producto.id, response['id']);
          } catch (e) {
            // Fallback por duplicado de codigo: actualizar existente
            final existente = await _supabaseService.getProductoByCodigo(producto.codigo);
            if (existente != null && existente['id'] != null) {
              final id = existente['id'] as String;
              await _supabaseService.updateProducto(id, data);
              await _productoService.marcarSincronizado(producto.id, id);
            } else {
              final msg = 'Error creando producto ${producto.codigo}: $e';
              AppLog.e(msg, e);
              rethrow;
            }
          }
        } else {
          await _supabaseService.updateProducto(producto.supabaseId!, data);
          await _productoService.marcarSincronizado(producto.id, producto.supabaseId!);
        }
      } catch (e) {
        final errorText = e.toString();
        if (errorText.contains('42501') || errorText.toLowerCase().contains('insufficient_privilege')) {
          final msg = 'Permisos insuficientes (RLS) al sincronizar producto ${producto.codigo}. Habilita SELECT/INSERT/UPDATE para el rol en la tabla productos o autentícate.';
          AppLog.e(msg, e);
          throw Exception(msg);
        }
        final msg = 'Error sincronizando producto ${producto.codigo}: $e';
        AppLog.e(msg, e);
        rethrow;
      }
    }
  }

  Future<void> _syncAlmacenes() async {
    final noSincronizados = await _almacenService.getNoSincronizados();
    
    for (var almacen in noSincronizados) {
      try {
        final data = {
          'codigo': almacen.codigo,
          'nombre': almacen.nombre,
          'direccion': almacen.direccion,
          'telefono': almacen.telefono,
          'responsable': almacen.responsable,
          'activo': almacen.activo,
          'eliminado': almacen.eliminado,
          'updated_at': almacen.updatedAt.toIso8601String(),
        };

        if (almacen.supabaseId != null) {
          await _supabaseService.updateAlmacen(almacen.supabaseId!, data);
          await _almacenService.marcarSincronizado(almacen.id, almacen.supabaseId!);
        } else {
          // Pre-chequeo por código para evitar duplicados
          final existente = await _supabaseService.getAlmacenByCodigo(almacen.codigo);
          if (existente != null && existente['id'] != null) {
            final id = existente['id'] as String;
            await _supabaseService.updateAlmacen(id, data);
            await _almacenService.marcarSincronizado(almacen.id, id);
          } else {
            final response = await _supabaseService.createAlmacen(data);
            await _almacenService.marcarSincronizado(almacen.id, response['id']);
          }
        }
      } catch (e) {
        final msg = 'Error sincronizando almacén ${almacen.codigo}: $e';
        AppLog.e(msg, e);
        rethrow;
      }
    }
  }

  Future<void> _syncTiendas() async {
    final noSincronizados = await _tiendaService.getNoSincronizados();
    
    for (var tienda in noSincronizados) {
      try {
        final data = {
          'codigo': tienda.codigo,
          'nombre': tienda.nombre,
          'direccion': tienda.direccion,
          'telefono': tienda.telefono,
          'responsable': tienda.responsable,
          'activo': tienda.activo,
          'eliminado': tienda.eliminado,
          'updated_at': tienda.updatedAt.toIso8601String(),
        };

        if (tienda.supabaseId != null) {
          await _supabaseService.updateTienda(tienda.supabaseId!, data);
          await _tiendaService.marcarSincronizado(tienda.id, tienda.supabaseId!);
        } else {
          // Pre-chequeo por código para evitar duplicados
          final existente = await _supabaseService.getTiendaByCodigo(tienda.codigo);
          if (existente != null && existente['id'] != null) {
            final id = existente['id'] as String;
            await _supabaseService.updateTienda(id, data);
            await _tiendaService.marcarSincronizado(tienda.id, id);
          } else {
            final response = await _supabaseService.createTienda(data);
            await _tiendaService.marcarSincronizado(tienda.id, response['id']);
          }
        }
      } catch (e) {
        final msg = 'Error sincronizando tienda ${tienda.codigo}: $e';
        AppLog.e(msg, e);
        rethrow;
      }
    }
  }

  Future<void> _syncEmpleados() async {
    final noSincronizados = await _empleadoService.getNoSincronizados();
    
    for (var empleado in noSincronizados) {
      try {
        final data = {
          'codigo': empleado.codigo,
          'nombres': empleado.nombres,
          'apellidos': empleado.apellidos,
          'email': empleado.email,
          'telefono': empleado.telefono,
          'rol': empleado.rol,
          'tienda_id': empleado.tiendaId,
          'almacen_id': empleado.almacenId,
          'activo': empleado.activo,
          'supabase_user_id': empleado.supabaseUserId,
          'eliminado': empleado.eliminado,
          'updated_at': empleado.updatedAt.toIso8601String(),
        };

        if (empleado.supabaseId != null) {
          await _supabaseService.updateEmpleado(empleado.supabaseId!, data);
          await _empleadoService.marcarSincronizado(empleado.id, empleado.supabaseId!);
        } else {
          // Pre-chequeo por código para evitar duplicados
          final existente = await _supabaseService.getEmpleadoByCodigo(empleado.codigo);
          if (existente != null && existente['id'] != null) {
            final id = existente['id'] as String;
            await _supabaseService.updateEmpleado(id, data);
            await _empleadoService.marcarSincronizado(empleado.id, id);
          } else {
            final response = await _supabaseService.createEmpleado(data);
            await _empleadoService.marcarSincronizado(empleado.id, response['id']);
          }
        }
      } catch (e) {
        final msg = 'Error sincronizando empleado ${empleado.codigo}: $e';
        AppLog.e(msg, e);
        rethrow;
      }
    }
  }

  Future<void> _syncInventarios() async {
    final noSincronizados = await _inventarioService.getNoSincronizados();
    
    for (var inventario in noSincronizados) {
      try {
        // Resolver ubicaciones a UUID si es necesario
        String ubicacionIdForSupabase = inventario.ubicacionId;
        if (inventario.ubicacionTipo == 'tienda') {
          final resolved = await _resolveTiendaId(inventario.ubicacionId);
          if (resolved != null) ubicacionIdForSupabase = resolved;
        } else if (inventario.ubicacionTipo == 'almacen') {
          final resolved = await _resolveAlmacenId(inventario.ubicacionId);
          if (resolved != null) ubicacionIdForSupabase = resolved;
        }

        final data = {
          'producto_id': inventario.productoId,
          'ubicacion_tipo': inventario.ubicacionTipo,
          'ubicacion_id': ubicacionIdForSupabase,
          'cantidad': inventario.cantidad,
          'ultima_actualizacion': inventario.ultimaActualizacion.toIso8601String(),
        };

        if (inventario.supabaseId != null) {
          data['id'] = inventario.supabaseId!;
        }

        await _supabaseService.updateInventario(
          inventario.supabaseId ?? '',
          data,
        );
        
        final idSync = inventario.supabaseId ?? (data['id'] as String?) ?? '';
        await _inventarioService.marcarSincronizado(
          inventario.id,
          idSync,
        );
      } catch (e) {
        final msg = 'Error sincronizando inventario: $e';
        AppLog.e(msg, e);
        rethrow;
      }
    }
  }

  Future<void> _syncCompras() async {
    final noSincronizados = await _compraService.getNoSincronizados();
    
    for (var compra in noSincronizados) {
      try {
        // TODO: Implementar sincronización de compras con detalles
        AppLog.d('Sincronizando compra ${compra.numeroCompra}');
      } catch (e) {
        AppLog.e('Error sincronizando compra ${compra.numeroCompra}', e);
      }
    }
  }

  Future<void> _syncVentas() async {
    final noSincronizados = await _ventaService.getNoSincronizados();
    for (var venta in noSincronizados) {
      try {
        AppLog.d('SyncService._syncVentas: Preparando venta ${venta.numeroVenta}');
        final detalles = await _ventaService.getDetallesByNumeroVenta(venta.numeroVenta);

        // Resolver IDs de tienda/empleado a UUID si es necesario
        final tiendaIdResolved = await _resolveTiendaId(venta.tiendaId) ?? venta.tiendaId;
        final empleadoIdResolved = await _resolveEmpleadoId(venta.empleadoId) ?? venta.empleadoId;

        final ventaData = {
          'numero_venta': venta.numeroVenta,
          'fecha_venta': venta.fechaVenta.toIso8601String(),
          'tienda_id': tiendaIdResolved,
          'empleado_id': empleadoIdResolved,
          'cliente': venta.cliente,
          'cliente_documento': venta.clienteDocumento,
          'cliente_telefono': venta.clienteTelefono,
          'subtotal': venta.subtotal,
          'descuento': venta.descuento,
          'impuesto': venta.impuesto,
          'total': venta.total,
          'metodo_pago': venta.metodoPago,
          'estado': venta.estado,
          'observaciones': venta.observaciones,
          'updated_at': venta.updatedAt.toIso8601String(),
        };

        final detalleData = detalles.map((d) => {
              'producto_id': d.productoId,
              'cantidad': d.cantidad,
              'precio_unitario': d.precioUnitario,
              'descuento': d.descuento,
              'subtotal': d.subtotal,
            }).toList();

        if (venta.supabaseId == null) {
          try {
            final resp = await _supabaseService.createVenta(ventaData, detalleData);
            final ventaSupabaseId = resp['id'] as String;
            await _ventaService.marcarSincronizado(venta.id!, ventaSupabaseId);
          } catch (e) {
            // Si falla por duplicado de numero_venta, hacemos update
            final existente = await _supabaseService.getVentaByNumero(venta.numeroVenta);
            if (existente != null && existente['id'] != null) {
              final id = existente['id'] as String;
              await _supabaseService.updateVenta(id, ventaData);
              await _supabaseService.deleteDetalleVentasByVenta(id);
              await _supabaseService.upsertDetalleVentasByVenta(id, detalleData);
              await _ventaService.marcarSincronizado(venta.id!, id);
            } else {
              final msg = 'Error al crear venta ${venta.numeroVenta}: $e';
              AppLog.e(msg, e);
              rethrow;
            }
          }
        } else {
          try {
            await _supabaseService.updateVenta(venta.supabaseId!, ventaData);
            await _supabaseService.deleteDetalleVentasByVenta(venta.supabaseId!);
            await _supabaseService.upsertDetalleVentasByVenta(venta.supabaseId!, detalleData);
            await _ventaService.marcarSincronizado(venta.id!, venta.supabaseId!);
          } catch (e) {
            final msg = 'Error al actualizar venta ${venta.numeroVenta} en Supabase: $e';
            AppLog.e(msg, e);
            rethrow;
          }
        }

        AppLog.i('SyncService._syncVentas: Venta ${venta.numeroVenta} sincronizada (estado: ${venta.estado})');
      } catch (e) {
        AppLog.e('Error sincronizando venta ${venta.numeroVenta}', e);
        // Propagar para que la UI muestre el mensaje
        rethrow;
      }
    }
  }

  Future<void> _syncTransferencias() async {
    final noSincronizados = await _transferenciaService.getNoSincronizados();
    
    for (var transferencia in noSincronizados) {
      try {
        // TODO: Implementar sincronización de transferencias con detalles
        AppLog.d('Sincronizando transferencia ${transferencia.numeroTransferencia}');
      } catch (e) {
        AppLog.e('Error sincroncronizando transferencia ${transferencia.numeroTransferencia}', e);
      }
    }
  }

  Future<void> _downloadFromSupabase({DateTime? since}) async {
    AppLog.i('SyncService._downloadFromSupabase: Descargando datos desde Supabase...');

    // 1) Productos
    try {
      final productos = await _supabaseService.getProductos(since: since);
      for (final p in productos) {
        final codigo = (p['codigo'] as String).trim();
        final existente = await _productoService.getByCodigo(codigo);

        final nombre = (p['nombre'] as String).trim();
        final descripcion = (p['descripcion'] as String?);
        final categoria = (p['categoria'] as String).trim();
        final unidadMedida = (p['unidad_medida'] as String).trim();
        final precioCompra = (p['precio_compra'] as num).toDouble();
        final precioVenta = (p['precio_venta'] as num).toDouble();
        final stockMinimo = (p['stock_minimo'] as int?) ?? 0;
        final updatedAt = DateTime.tryParse(p['updated_at']?.toString() ?? '') ?? DateTime.now();
        final createdAt = DateTime.tryParse(p['created_at']?.toString() ?? '') ?? updatedAt;
        final supabaseId = p['id']?.toString() ?? '';

        if (existente == null) {
          final nuevo = Producto()
            ..codigo = codigo
            ..nombre = nombre
            ..descripcion = descripcion
            ..categoria = categoria
            ..unidadMedida = unidadMedida
            ..precioCompra = precioCompra
            ..precioVenta = precioVenta
            ..stockMinimo = stockMinimo
            ..createdAt = createdAt
            ..updatedAt = updatedAt
            ..sincronizado = false
            ..eliminado = false;
          final idLocal = await _productoService.crear(nuevo);
          await _productoService.marcarSincronizado(idLocal, supabaseId);
        } else {
          existente
            ..nombre = nombre
            ..descripcion = descripcion
            ..categoria = categoria
            ..unidadMedida = unidadMedida
            ..precioCompra = precioCompra
            ..precioVenta = precioVenta
            ..stockMinimo = stockMinimo
            ..updatedAt = updatedAt
            ..eliminado = false;
          await _productoService.actualizar(existente);
          await _productoService.marcarSincronizado(existente.id, supabaseId);
        }
      }
      AppLog.i('SyncService._downloadFromSupabase: Productos descargados: ${productos.length}');
    } catch (e) {
      final msg = 'Error descargando productos: $e';
      AppLog.e('SyncService._downloadFromSupabase: $msg', e);
      rethrow;
    }

    // 2) Almacenes
    try {
      final almacenes = await _supabaseService.getAlmacenes(since: since);
      for (final a in almacenes) {
        final codigo = (a['codigo'] as String).trim();
        final existente = await _almacenService.getByCodigo(codigo);

        final nombre = (a['nombre'] as String).trim();
        final direccion = (a['direccion'] as String).trim();
        final telefono = (a['telefono'] as String?);
        final responsable = (a['responsable'] as String).trim();
        final activo = (a['activo'] as bool?) ?? true;
        final updatedAt = DateTime.tryParse(a['updated_at']?.toString() ?? '') ?? DateTime.now();
        final createdAt = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? updatedAt;
        final supabaseId = a['id']?.toString() ?? '';

        if (existente == null) {
          final nuevo = Almacen()
            ..codigo = codigo
            ..nombre = nombre
            ..direccion = direccion
            ..telefono = telefono
            ..responsable = responsable
            ..activo = activo
            ..createdAt = createdAt
            ..updatedAt = updatedAt
            ..sincronizado = false
            ..eliminado = false;
          final idLocal = await _almacenService.crear(nuevo);
          await _almacenService.marcarSincronizado(idLocal, supabaseId);
        } else {
          existente
            ..nombre = nombre
            ..direccion = direccion
            ..telefono = telefono
            ..responsable = responsable
            ..activo = activo
            ..updatedAt = updatedAt
            ..eliminado = false;
          await _almacenService.actualizar(existente);
          await _almacenService.marcarSincronizado(existente.id, supabaseId);
        }
      }
      AppLog.i('SyncService._downloadFromSupabase: Almacenes descargados: ${almacenes.length}');
    } catch (e) {
      final msg = 'Error descargando almacenes: $e';
      AppLog.e('SyncService._downloadFromSupabase: $msg', e);
      rethrow;
    }

    // 3) Tiendas
    try {
      final tiendas = await _supabaseService.getTiendas(since: since);
      for (final t in tiendas) {
        final codigo = (t['codigo'] as String).trim();
        final existente = await _tiendaService.getByCodigo(codigo);

        final nombre = (t['nombre'] as String).trim();
        final direccion = (t['direccion'] as String).trim();
        final telefono = (t['telefono'] as String?);
        final responsable = (t['responsable'] as String).trim();
        final activo = (t['activo'] as bool?) ?? true;
        final updatedAt = DateTime.tryParse(t['updated_at']?.toString() ?? '') ?? DateTime.now();
        final createdAt = DateTime.tryParse(t['created_at']?.toString() ?? '') ?? updatedAt;
        final supabaseId = t['id']?.toString() ?? '';

        if (existente == null) {
          final nuevo = Tienda()
            ..codigo = codigo
            ..nombre = nombre
            ..direccion = direccion
            ..telefono = telefono
            ..responsable = responsable
            ..activo = activo
            ..createdAt = createdAt
            ..updatedAt = updatedAt
            ..sincronizado = false
            ..eliminado = false;
          final idLocal = await _tiendaService.crear(nuevo);
          await _tiendaService.marcarSincronizado(idLocal, supabaseId);
        } else {
          existente
            ..nombre = nombre
            ..direccion = direccion
            ..telefono = telefono
            ..responsable = responsable
            ..activo = activo
            ..updatedAt = updatedAt
            ..eliminado = false;
          await _tiendaService.actualizar(existente);
          await _tiendaService.marcarSincronizado(existente.id, supabaseId);
        }
      }
      AppLog.i('SyncService._downloadFromSupabase: Tiendas descargadas: ${tiendas.length}');
    } catch (e) {
      final msg = 'Error descargando tiendas: $e';
      AppLog.e('SyncService._downloadFromSupabase: $msg', e);
      rethrow;
    }

    // 4) Empleados
    try {
      final empleados = await _supabaseService.getEmpleados(since: since);
      for (final e in empleados) {
        final codigo = (e['codigo'] as String).trim();
        final existente = await _empleadoService.getByCodigo(codigo);

        final nombres = (e['nombres'] as String).trim();
        final apellidos = (e['apellidos'] as String).trim();
        final email = (e['email'] as String).trim();
        final telefono = (e['telefono'] as String?);
        final rol = (e['rol'] as String).trim();
        final tiendaId = (e['tienda_id'] as String?);
        final almacenId = (e['almacen_id'] as String?);
        final activo = (e['activo'] as bool?) ?? true;
        final supabaseUserId = (e['supabase_user_id'] as String?);
        final updatedAt = DateTime.tryParse(e['updated_at']?.toString() ?? '') ?? DateTime.now();
        final createdAt = DateTime.tryParse(e['created_at']?.toString() ?? '') ?? updatedAt;
        final supabaseId = e['id']?.toString() ?? '';

        if (existente == null) {
          final nuevo = Empleado()
            ..codigo = codigo
            ..nombres = nombres
            ..apellidos = apellidos
            ..email = email
            ..telefono = telefono ?? ''
            ..rol = rol
            ..tiendaId = tiendaId
            ..almacenId = almacenId
            ..activo = activo
            ..supabaseUserId = supabaseUserId
            ..createdAt = createdAt
            ..updatedAt = updatedAt
            ..sincronizado = false
            ..eliminado = false;
          final idLocal = await _empleadoService.crear(nuevo);
          await _empleadoService.marcarSincronizado(idLocal, supabaseId);
        } else {
          existente
            ..nombres = nombres
            ..apellidos = apellidos
            ..email = email
            ..telefono = telefono ?? ''
            ..rol = rol
            ..tiendaId = tiendaId
            ..almacenId = almacenId
            ..activo = activo
            ..supabaseUserId = supabaseUserId
            ..updatedAt = updatedAt
            ..eliminado = false;
          await _empleadoService.actualizar(existente);
          await _empleadoService.marcarSincronizado(existente.id, supabaseId);
        }
      }
      AppLog.i('SyncService._downloadFromSupabase: Empleados descargados: ${empleados.length}');
    } catch (e) {
      final msg = 'Error descargando empleados: $e';
      AppLog.e('SyncService._downloadFromSupabase: $msg', e);
      rethrow;
    }

    // 5) Inventarios
    try {
      final inventarios = await _supabaseService.getInventarios(since: since);
      for (final inv in inventarios) {
        final productoId = (inv['producto_id'] as String).trim();
        final ubicacionTipo = (inv['ubicacion_tipo'] as String).trim();
        final ubicacionId = (inv['ubicacion_id'] as String).trim();
        final cantidad = (inv['cantidad'] as num).toDouble();
        final supabaseId = inv['id']?.toString() ?? '';

        await _inventarioService.actualizarStock(productoId, ubicacionTipo, ubicacionId, cantidad);
        // Marcar sincronizado con el id de Supabase
        final existente = await _inventarioService.getInventario(productoId, ubicacionTipo, ubicacionId);
        if (existente != null) {
          await _inventarioService.marcarSincronizado(existente.id, supabaseId);
        }
      }
      AppLog.i('SyncService._downloadFromSupabase: Inventarios descargados: ${inventarios.length}');
    } catch (e) {
      final msg = 'Error descargando inventarios: $e';
      AppLog.e('SyncService._downloadFromSupabase: $msg', e);
      rethrow;
    }
  }
}

