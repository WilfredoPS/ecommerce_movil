import '../utils/logger.dart';
import 'auth_service.dart';

class AuthorizationService {
  static final AuthorizationService _instance = AuthorizationService._internal();
  factory AuthorizationService() => _instance;
  AuthorizationService._internal();

  final AuthService _auth = AuthService();

  bool has(String permission) {
    final ok = _auth.hasPermission(permission);
    AppLog.d('Authorization.check("$permission") => $ok');
    return ok;
  }

  void ensure(String permission) {
    if (!has(permission)) {
      throw Exception('Permiso insuficiente: $permission');
    }
  }
}


