import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
import '../models/producto.dart';
import '../services/inventario_service.dart';

final inventarioProvider = NotifierProvider<InventarioNotifier, InventarioState>(InventarioNotifier.new);

class InventarioState {
  final List<Map<String, dynamic>> inventarioDetallado;
  final bool isLoading;
  final String vistaActual;
  const InventarioState({this.inventarioDetallado = const [], this.isLoading = false, this.vistaActual = 'global'});
}

class InventarioNotifier extends Notifier<InventarioState> {
  final InventarioService _inventarioService = InventarioService();
  
  @override
  InventarioState build() => const InventarioState();

  // Getters
  List<Map<String, dynamic>> get inventarioDetallado => state.inventarioDetallado;
  bool get isLoading => state.isLoading;
  String get vistaActual => state.vistaActual;

  // Cargar inventario
  Future<void> loadInventario() async {
    state = InventarioState(inventarioDetallado: state.inventarioDetallado, isLoading: true, vistaActual: state.vistaActual);
    
    try {
      AppLog.d('InventarioProvider.loadInventario: Cargando inventario...');
      final data = await _inventarioService.getInventarioGlobal();
      state = InventarioState(inventarioDetallado: data, isLoading: true, vistaActual: state.vistaActual);
      AppLog.d('InventarioProvider.loadInventario: Inventario cargado: ${data.length} productos');
    } catch (e) {
      AppLog.e('InventarioProvider.loadInventario: Error', e);
    } finally {
      state = InventarioState(inventarioDetallado: state.inventarioDetallado, isLoading: false, vistaActual: state.vistaActual);
    }
  }

  // Cambiar vista
  void cambiarVista(String vista) {
    state = InventarioState(inventarioDetallado: state.inventarioDetallado, isLoading: state.isLoading, vistaActual: vista);
    loadInventario(); // Recargar con la nueva vista
  }

  // Actualizar inventario después de operaciones
  Future<void> refreshInventario() async {
    AppLog.d('InventarioProvider.refreshInventario: Actualizando inventario...');
    await loadInventario();
  }

  // Obtener stock total de un producto
  double getStockTotal(String productoId) {
    final item = state.inventarioDetallado.firstWhere(
      (item) => (item['producto'] as Producto).codigo == productoId,
      orElse: () => {'stockTotal': 0.0},
    );
    return item['stockTotal'] as double;
  }

  // Obtener stock en almacenes de un producto
  double getStockEnAlmacenes(String productoId) {
    final item = state.inventarioDetallado.firstWhere(
      (item) => (item['producto'] as Producto).codigo == productoId,
      orElse: () => {'stockAlmacenes': 0.0},
    );
    return item['stockAlmacenes'] as double;
  }

  // Obtener stock en tiendas de un producto
  double getStockEnTiendas(String productoId) {
    final item = state.inventarioDetallado.firstWhere(
      (item) => (item['producto'] as Producto).codigo == productoId,
      orElse: () => {'stockTiendas': 0.0},
    );
    return item['stockTiendas'] as double;
  }

  // Verificar si un producto está bajo stock
  bool isBajoStock(String productoId) {
    final item = state.inventarioDetallado.firstWhere(
      (item) => (item['producto'] as Producto).codigo == productoId,
      orElse: () => {'bajoStock': false},
    );
    return item['bajoStock'] as bool;
  }
}
