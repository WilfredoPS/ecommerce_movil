import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../models/empleado.dart';
import 'supabase_service.dart';
import 'empleado_service.dart';
import '../utils/password_policy.dart';
import '../utils/hash_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final EmpleadoService _empleadoService = EmpleadoService();

  Empleado? _currentEmpleado;
  
  Empleado? get currentEmpleado => _currentEmpleado;
  bool get isAuthenticated => _currentEmpleado != null;

  Future<void> initialize() async {
    AppLog.d('AuthService.initialize: Iniciando servicio de autenticación...');
    
    // Limpieza opcional de bloqueos expirados (best-effort)
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('auth_locked_until_'));
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final key in keys) {
        final lockedUntil = prefs.getInt(key) ?? 0;
        if (lockedUntil > 0 && lockedUntil <= now) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
    
    // Intentar restaurar sesión guardada
    final prefs = await SharedPreferences.getInstance();
    final empleadoEmail = prefs.getString('empleado_email');
    
    AppLog.d('AuthService.initialize: Email guardado: $empleadoEmail');
    
    // Preferir sesión real de Supabase si existe
    if (_supabaseService.isAuthenticated) {
      final user = _supabaseService.currentUser;
      final email = user?.email;
      AppLog.d('AuthService.initialize: Sesión Supabase detectada: $email');
      if (email != null) {
        _currentEmpleado = await _empleadoService.getByEmail(email);
        if (_currentEmpleado == null) {
          AppLog.w('AuthService.initialize: Usuario autenticado en Supabase pero no existe en BD local: $email');
        }
        // Persistir email para siguiente inicio
        await prefs.setString('empleado_email', email);
        return;
      }
    }

    // Fallback a sesión por preferencias (modo dev)
    if (empleadoEmail != null) {
      _currentEmpleado = await _empleadoService.getByEmail(empleadoEmail);
      AppLog.d('AuthService.initialize: Empleado encontrado: ${_currentEmpleado?.nombres} ${_currentEmpleado?.apellidos}');
      AppLog.d('AuthService.initialize: Rol del empleado: ${_currentEmpleado?.rol}');
    } else {
      AppLog.d('AuthService.initialize: No hay sesión guardada, usuario debe hacer login manual');
      _currentEmpleado = null;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockedKey = 'auth_locked_until_$email';
      final attemptsKey = 'auth_failed_attempts_$email';
      final localSaltKey = 'auth_pwd_salt_$email';
      final localHashKey = 'auth_pwd_hash_$email';
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final lockedUntilMs = prefs.getInt(lockedKey) ?? 0;
      if (lockedUntilMs > nowMs) {
        final remainingSec = ((lockedUntilMs - nowMs) / 1000).ceil();
        throw Exception('Cuenta bloqueada temporalmente. Intente en ${remainingSec}s.');
      }

      // 1) Autenticar con Supabase (obtiene JWT para RLS)
      AuthResponse? response;
      try {
        response = await _supabaseService.signIn(email, password);
      } catch (e) {
        // Falla (posible red/servidor). Intentar verificación offline con hash.
        AppLog.w('AuthService.login: Error con Supabase, intentando modo offline: $e');
        
        // Verificar si el empleado existe localmente
        final empleado = await _empleadoService.getByEmail(email);
        if (empleado == null) {
          final currentAttempts = prefs.getInt(attemptsKey) ?? 0;
          final nextAttempts = currentAttempts + 1;
          await prefs.setInt(attemptsKey, nextAttempts);
          if (nextAttempts >= 5) {
            final lockUntil = DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch;
            await prefs.setInt(lockedKey, lockUntil);
            await prefs.setInt(attemptsKey, 0);
            throw Exception('Demasiados intentos fallidos. Cuenta bloqueada por 15 minutos.');
          }
          throw Exception('Empleado no encontrado. Intentos fallidos: $nextAttempts/5');
        }
        
        if (!empleado.activo) {
          throw Exception('Empleado desactivado');
        }
        
        // Verificar hash local si existe
        final salt = prefs.getString(localSaltKey);
        final hash = prefs.getString(localHashKey);
        if (salt != null && hash != null) {
          final ok = HashUtils.verifySha256(password, salt, hash);
          if (ok) {
            _currentEmpleado = empleado;
            await prefs.setString('empleado_email', email);
            await prefs.remove(attemptsKey);
            await prefs.remove(lockedKey);
            AppLog.i('AuthService.login: Login offline exitoso para $email');
            return true;
          }
        }
        
        // Modo desarrollo: Si no hay hash local y es el admin, permitir login con cualquier contraseña
        // (solo para desarrollo/testing)
        if (empleado.rol == 'admin' && (salt == null || hash == null)) {
          AppLog.w('AuthService.login: Modo desarrollo - permitiendo login admin sin hash local');
          _currentEmpleado = empleado;
          await prefs.setString('empleado_email', email);
          await prefs.remove(attemptsKey);
          await prefs.remove(lockedKey);
          // Crear hash para futuros logins
          final newSalt = HashUtils.generateSalt();
          final newHash = HashUtils.sha256WithSalt(password, newSalt);
          await prefs.setString(localSaltKey, newSalt);
          await prefs.setString(localHashKey, newHash);
          return true;
        }
        
        // Si no hay credenciales locales válidas, contamos intento
        final currentAttempts = prefs.getInt(attemptsKey) ?? 0;
        final nextAttempts = currentAttempts + 1;
        await prefs.setInt(attemptsKey, nextAttempts);
        if (nextAttempts >= 5) {
          final lockUntil = DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch;
          await prefs.setInt(lockedKey, lockUntil);
          await prefs.setInt(attemptsKey, 0);
          throw Exception('Demasiados intentos fallidos. Cuenta bloqueada por 15 minutos.');
        }
        throw Exception('Credenciales inválidas. Intentos fallidos: $nextAttempts/5');
      }
      if (response == null || response.user == null) {
        // fallo de autenticación
        final currentAttempts = prefs.getInt(attemptsKey) ?? 0;
        final nextAttempts = currentAttempts + 1;
        await prefs.setInt(attemptsKey, nextAttempts);
        // Política: 5 intentos → 15 minutos de bloqueo
        if (nextAttempts >= 5) {
          final lockMinutes = 15;
          final lockUntil = DateTime.now().add(Duration(minutes: lockMinutes)).millisecondsSinceEpoch;
          await prefs.setInt(lockedKey, lockUntil);
          await prefs.setInt(attemptsKey, 0); // reset after lock
          throw Exception('Demasiados intentos fallidos. Cuenta bloqueada por $lockMinutes minutos.');
        }
        throw Exception('Credenciales inválidas. Intentos fallidos: $nextAttempts/5');
      }

      // 2) Validar que el empleado exista localmente y esté activo
      final empleado = await _empleadoService.getByEmail(email);
      if (empleado == null) {
        throw Exception('Empleado no encontrado en la base local');
      }
      if (!empleado.activo) {
        throw Exception('Empleado desactivado');
      }

      _currentEmpleado = empleado;

      // 3) Guardar sesión local
      // Resetear intentos fallidos y bloqueo si existiesen
      await prefs.remove(attemptsKey);
      await prefs.remove(lockedKey);
      // Guardar email
      await prefs.setString('empleado_email', email);
      return true;
    } catch (e) {
      AppLog.e('Error en login', e);
      rethrow;
    }
  }

  // Registro de usuario con validación de políticas de contraseña (opcional)
  Future<void> registerUser({
    required String email,
    required String password,
    required Empleado empleado,
  }) async {
    // Validar políticas de contraseña
    final result = PasswordPolicy.validate(password);
    if (!result.isValid) {
      throw Exception(result.errorMessage ?? 'La contraseña no cumple la política.');
    }
    // Registrar en Supabase
    final response = await _supabaseService.signUp(email, password);
    if (response.user == null) {
      throw Exception('No fue posible crear el usuario en Supabase.');
    }
    // Asociar supabase_user_id al empleado local
    empleado.supabaseUserId = response.user!.id;
    await _empleadoService.actualizar(empleado);

    // Guardar hash con sal local para verificación offline (no almacena la contraseña)
    final prefs = await SharedPreferences.getInstance();
    final salt = HashUtils.generateSalt();
    final hash = HashUtils.sha256WithSalt(password, salt);
    await prefs.setString('auth_pwd_salt_$email', salt);
    await prefs.setString('auth_pwd_hash_$email', hash);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentEmpleado == null) {
      throw Exception('No hay sesión activa');
    }
    final email = _currentEmpleado!.email;
    // Validar nueva contraseña
    final res = PasswordPolicy.validate(newPassword);
    if (!res.isValid) {
      throw Exception(res.errorMessage ?? 'La contraseña no cumple la política.');
    }
    // Verificar credenciales actuales (reauth) y actualizar en Supabase
    try {
      await _supabaseService.signIn(email, currentPassword);
    } catch (_) {
      throw Exception('La contraseña actual es incorrecta.');
    }
    try {
      await _supabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      AppLog.e('Error actualizando contraseña en Supabase', e);
      throw Exception('No fue posible actualizar la contraseña.');
    }
    // Actualizar hash local para login offline y fecha de cambio
    final prefs = await SharedPreferences.getInstance();
    final salt = HashUtils.generateSalt();
    final hash = HashUtils.sha256WithSalt(newPassword, salt);
    await prefs.setString('auth_pwd_salt_$email', salt);
    await prefs.setString('auth_pwd_hash_$email', hash);
    await prefs.setString('auth_pwd_changed_at_$email', DateTime.now().toIso8601String());
  }

  Future<void> logout() async {
    try {
      await _supabaseService.signOut();
    } catch (e) {
      AppLog.e('Error al cerrar sesión en Supabase', e);
    }

    _currentEmpleado = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('empleado_email');
  }

  bool hasPermission(String permission) {
    if (_currentEmpleado == null) {
      AppLog.w('AuthService.hasPermission: No hay empleado autenticado');
      return false;
    }

    AppLog.d('AuthService.hasPermission: Verificando permiso "$permission" para rol "${_currentEmpleado!.rol}"');

    // Definir permisos por rol
    final permisos = {
      'admin': [
        'ver_dashboard',
        'gestionar_productos',
        'gestionar_almacenes',
        'gestionar_tiendas',
        'gestionar_empleados',
        'realizar_compras',
        'realizar_ventas',
        'realizar_transferencias',
        'ver_reportes',
        'ver_inventario_global',
      ],
      'encargado_tienda': [
        'ver_dashboard',
        'gestionar_tiendas',
        'realizar_ventas',
        'solicitar_transferencias',
        'ver_inventario_tienda',
        'ver_reportes_tienda',
      ],
      'encargado_almacen': [
        'ver_dashboard',
        'gestionar_almacenes',
        'realizar_compras',
        'gestionar_transferencias',
        'ver_inventario_almacen',
        'ver_reportes_almacen',
      ],
      'vendedor': [
        'realizar_ventas',
        'ver_inventario_tienda',
      ],
    };

    final permisosRol = permisos[_currentEmpleado!.rol] ?? [];
    final tienePermiso = permisosRol.contains(permission);
    AppLog.d('AuthService.hasPermission: Permisos del rol: $permisosRol');
    AppLog.d('AuthService.hasPermission: Tiene permiso "$permission": $tienePermiso');
    return tienePermiso;
  }

  String? get tiendaActual => _currentEmpleado?.tiendaId;
  String? get almacenActual => _currentEmpleado?.almacenId;
}




