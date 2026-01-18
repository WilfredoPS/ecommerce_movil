import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/empleado.dart';
import '../services/auth_service.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthState {
  final Empleado? currentEmpleado;
  final bool isAuthenticated;
  final String? tiendaActual;
  final String? almacenActual;
  const AuthState({this.currentEmpleado, this.isAuthenticated = false, this.tiendaActual, this.almacenActual});
}

class AuthNotifier extends Notifier<AuthState> {
  final AuthService _authService = AuthService();

  @override
  AuthState build() => const AuthState();

  Empleado? get currentEmpleado => state.currentEmpleado;
  bool get isAuthenticated => state.isAuthenticated;
  String? get tiendaActual => state.tiendaActual;
  String? get almacenActual => state.almacenActual;

  bool hasPermission(String permission) => _authService.hasPermission(permission);

  Future<void> initialize() async {
    // init
    await _authService.initialize();
    state = AuthState(
      currentEmpleado: _authService.currentEmpleado,
      isAuthenticated: _authService.isAuthenticated,
      tiendaActual: _authService.tiendaActual,
      almacenActual: _authService.almacenActual,
    );
  }

  Future<bool> login(String email, String password) async {
    try {
      final result = await _authService.login(email, password);
      state = AuthState(
        currentEmpleado: _authService.currentEmpleado,
        isAuthenticated: _authService.isAuthenticated,
        tiendaActual: _authService.tiendaActual,
        almacenActual: _authService.almacenActual,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }
}





