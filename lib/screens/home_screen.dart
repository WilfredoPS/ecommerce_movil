import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../utils/logger.dart';
import 'dashboard_screen.dart';
import 'productos_screen.dart';
import 'almacenes_screen.dart';
import 'tiendas_screen.dart';
import 'empleados_screen.dart';
import 'compras_screen.dart';
import 'ventas_screen.dart';
import 'transferencias_screen.dart';
import 'inventario_screen.dart';
import 'reportes_screen.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  List<_NavItem> _navItems = [];
  String? _lastEmployeeId;

  @override
  void initState() {
    super.initState();
    _updateNavItems();
  }

  void _updateNavItems() {
    final authState = ref.read(authProvider);
    final auth = ref.read(authProvider.notifier);
    final currentEmployeeId = authState.currentEmpleado?.codigo;
    
    // Solo actualizar si cambió el empleado
    if (_lastEmployeeId != currentEmployeeId) {
      _lastEmployeeId = currentEmployeeId;
      
      AppLog.d('HomeScreen._updateNavItems: Actualizando elementos de navegación');
      AppLog.d('HomeScreen._updateNavItems: Empleado actual: ${authState.currentEmpleado?.nombres} ${authState.currentEmpleado?.apellidos}');
      AppLog.d('HomeScreen._updateNavItems: Rol: ${authState.currentEmpleado?.rol}');
      
      _navItems = [
        _NavItem(
          icon: Icons.dashboard,
          label: 'Dashboard',
          screen: const DashboardScreen(),
          permission: 'ver_dashboard',
        ),
        if (auth.hasPermission('gestionar_productos'))
          _NavItem(
            icon: Icons.inventory,
            label: 'Productos',
            screen: const ProductosScreen(),
            permission: 'gestionar_productos',
          ),
        if (auth.hasPermission('gestionar_almacenes'))
          _NavItem(
            icon: Icons.warehouse,
            label: 'Almacenes',
            screen: const AlmacenesScreen(),
            permission: 'gestionar_almacenes',
          ),
        if (auth.hasPermission('gestionar_tiendas'))
          _NavItem(
            icon: Icons.store,
            label: 'Tiendas',
            screen: const TiendasScreen(),
            permission: 'gestionar_tiendas',
          ),
        if (auth.hasPermission('gestionar_empleados'))
          _NavItem(
            icon: Icons.people,
            label: 'Empleados',
            screen: const EmpleadosScreen(),
            permission: 'gestionar_empleados',
          ),
        if (auth.hasPermission('realizar_compras'))
          _NavItem(
            icon: Icons.shopping_cart,
            label: 'Compras',
            screen: const ComprasScreen(),
            permission: 'realizar_compras',
          ),
        if (auth.hasPermission('realizar_ventas'))
          _NavItem(
            icon: Icons.point_of_sale,
            label: 'Ventas',
            screen: const VentasScreen(),
            permission: 'realizar_ventas',
          ),
        _NavItem(
          icon: Icons.sync_alt,
          label: 'Transferencias',
          screen: const TransferenciasScreen(),
          permission: null, // Todos pueden ver sus transferencias
        ),
        _NavItem(
          icon: Icons.storage,
          label: 'Inventario',
          screen: const InventarioScreen(),
          permission: null, // Todos pueden ver inventario según su ubicación
        ),
        if (auth.hasPermission('ver_reportes'))
          _NavItem(
            icon: Icons.assessment,
            label: 'Reportes',
            screen: const ReportesScreen(),
            permission: 'ver_reportes',
          ),
      ];
      
      AppLog.d('HomeScreen._updateNavItems: Se crearon ${_navItems.length} elementos de navegación');
      for (int i = 0; i < _navItems.length; i++) {
        AppLog.d('HomeScreen._updateNavItems: [$i] ${_navItems[i].label}');
      }
      
      // Resetear índice si es necesario
      if (_selectedIndex >= _navItems.length) {
        _selectedIndex = 0;
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro de que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _syncData() async {
    try {
      await ref.read(syncProvider.notifier).syncAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización completada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final syncState = ref.watch(syncProvider);
    final empleado = authState.currentEmpleado;
    
    // Actualizar elementos de navegación si es necesario
    _updateNavItems();
    
    // Asegurar que el índice seleccionado sea válido
    final selectedIndex = _selectedIndex >= _navItems.length ? 0 : _selectedIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[selectedIndex].label),
        actions: [
          // Indicador de sincronización
          if (syncState.isSyncing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sincronizar',
              onPressed: _syncData,
            ),
          IconButton(
            icon: const Icon(Icons.password),
            tooltip: 'Cambiar contraseña',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                empleado != null
                    ? '${empleado.nombres} ${empleado.apellidos}'
                    : 'Usuario',
              ),
              accountEmail: Text(empleado?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  empleado != null
                      ? empleado.nombres[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ...List.generate(
              _navItems.length,
              (index) => ListTile(
                leading: Icon(_navItems[index].icon),
                title: Text(_navItems[index].label),
                selected: selectedIndex == index,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(),
            // ListTile(
            //   leading: const Icon(Icons.slideshow),
            //   title: const Text('Presentación (capturas)'),
            //   subtitle: const Text('Generar imágenes de pantallas'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     Navigator.of(context).push(
            //       MaterialPageRoute(builder: (_) => const PresentacionScreen()),
            //     );
            //   },
            // ),
            const Divider(),
            if (syncState.lastSyncTime != null)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Última sincronización'),
                subtitle: Text(
                  _formatDateTime(syncState.lastSyncTime!),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      body: _navItems[selectedIndex].screen,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds} segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  final String? permission;

  _NavItem({
    required this.icon,
    required this.label,
    required this.screen,
    this.permission,
  });
}





