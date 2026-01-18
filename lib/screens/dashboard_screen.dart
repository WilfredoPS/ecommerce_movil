import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/venta_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final VentaService _ventaService = VentaService();
  
  bool _isLoading = true;
  double _ventasDelDia = 0.0;
  Map<String, double> _ventasGlobales = {};
  
  final currencyFormat = NumberFormat.currency(symbol: 'Bs', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final auth = ref.read(authProvider.notifier);
      
      if (authState.tiendaActual != null) {
        _ventasDelDia = await _ventaService.getTotalVentasDelDia(
          authState.tiendaActual!,
        );
      }

      if (auth.hasPermission('ver_inventario_global')) {
        _ventasGlobales = await _ventaService.getTotalVentasGlobalDelDia();
      }
    } catch (e) {
      print('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final auth = ref.read(authProvider.notifier);
    final empleado = authState.currentEmpleado;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Bienvenido, ${empleado?.nombres}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rol: ${empleado?.rol.replaceAll('_', ' ').toUpperCase()}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (authState.tiendaActual != null)
                      Text(
                        'Tienda: ${authState.tiendaActual}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (authState.almacenActual != null)
                      Text(
                        'Almacén: ${authState.almacenActual}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ventas del día
            if (authState.tiendaActual != null) ...[
              Text(
                'Ventas de Hoy',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 48,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Vendido',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            currencyFormat.format(_ventasDelDia),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Ventas globales
            if (_ventasGlobales.isNotEmpty) ...[
              Text(
                'Ventas Globales del Día',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (var entry in _ventasGlobales.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tienda ${entry.key}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                currencyFormat.format(entry.value),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            currencyFormat.format(
                              _ventasGlobales.values.fold(0.0, (a, b) => a + b),
                            ),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Accesos rápidos
            Text(
              'Accesos Rápidos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                if (auth.hasPermission('realizar_ventas'))
                  _buildQuickAccessCard(
                    context,
                    'Nueva Venta',
                    Icons.point_of_sale,
                    Colors.green,
                    () {
                      // Navegar a ventas
                    },
                  ),
                if (auth.hasPermission('realizar_compras'))
                  _buildQuickAccessCard(
                    context,
                    'Nueva Compra',
                    Icons.shopping_cart,
                    Colors.blue,
                    () {
                      // Navegar a compras
                    },
                  ),
                _buildQuickAccessCard(
                  context,
                  'Inventario',
                  Icons.storage,
                  Colors.orange,
                  () {
                    // Navegar a inventario
                  },
                ),
                if (auth.hasPermission('ver_reportes'))
                  _buildQuickAccessCard(
                    context,
                    'Reportes',
                    Icons.assessment,
                    Colors.purple,
                    () {
                      // Navegar a reportes
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


