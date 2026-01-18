import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto.dart';
import '../models/almacen.dart';
import '../models/tienda.dart';
import '../providers/inventario_provider.dart';
import '../services/almacen_service.dart';
import '../services/tienda_service.dart';
import 'inventario_ubicacion_screen.dart';

class InventarioScreen extends ConsumerStatefulWidget {
  const InventarioScreen({super.key});

  @override
  ConsumerState<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends ConsumerState<InventarioScreen> {
  final AlmacenService _almacenService = AlmacenService();
  final TiendaService _tiendaService = TiendaService();
  
  List<Almacen> _almacenes = [];
  List<Tienda> _tiendas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('InventarioScreen._loadData: Cargando datos...');
    
    // Cargar ubicaciones
    final almacenes = await _almacenService.getAll();
    final tiendas = await _tiendaService.getAll();
    
    // Log detallado de tiendas
    for (var tienda in tiendas) {
      print('InventarioScreen._loadData: Tienda encontrada: ${tienda.nombre} (${tienda.codigo}) - Activa: ${tienda.activo}');
    }
    
    print('InventarioScreen._loadData: Almacenes cargados: ${almacenes.length}');
    print('InventarioScreen._loadData: Tiendas cargadas: ${tiendas.length}');
    
    setState(() {
      _almacenes = almacenes;
      _tiendas = tiendas;
    });
    
    // Cargar inventario usando el provider
    await ref.read(inventarioProvider.notifier).loadInventario();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final inventarioState = ref.watch(inventarioProvider);
        final inventario = ref.read(inventarioProvider.notifier);
        return Scaffold(
          appBar: AppBar(
            title: Text(inventarioState.vistaActual == 'global' ? 'Inventario Global' : 
                       inventarioState.vistaActual == 'almacenes' ? 'Inventario por Almacén' : 
                       'Inventario por Tienda'),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  inventario.cambiarVista(value);
                },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'global',
                child: Row(
                  children: [
                    Icon(Icons.dashboard, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Vista Global'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'almacenes',
                child: Row(
                  children: [
                    Icon(Icons.warehouse, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Por Almacén'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'tiendas',
                child: Row(
                  children: [
                    Icon(Icons.store, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Por Tienda'),
                  ],
                ),
              ),
            ],
          ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => inventario.refreshInventario(),
                tooltip: 'Actualizar Inventario',
              ),
            ],
          ),
          body: inventarioState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : inventarioState.inventarioDetallado.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay productos en inventario',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => inventario.refreshInventario(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: inventarioState.inventarioDetallado.length,
                    itemBuilder: (context, index) {
                      final item = inventarioState.inventarioDetallado[index];
                      final producto = item['producto'] as Producto;
                      final stockTotal = item['stockTotal'] as double;
                      final stockAlmacenes = item['stockAlmacenes'] as double;
                      final stockTiendas = item['stockTiendas'] as double;
                      final bajoStock = item['bajoStock'] as bool;

                      return Card(
                        color: bajoStock ? Colors.red.shade50 : null,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: bajoStock
                              ? const Icon(Icons.warning, color: Colors.red)
                              : const Icon(Icons.inventory_2),
                          title: Text(
                            producto.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Código: ${producto.codigo}'),
                              Text('Categoría: ${producto.categoria}'),
                              if (inventarioState.vistaActual == 'global') ...[
                                Text('Almacenes: ${stockAlmacenes.toStringAsFixed(2)} ${producto.unidadMedida}'),
                                Text('Tiendas: ${stockTiendas.toStringAsFixed(2)} ${producto.unidadMedida}'),
                              ],
                              if (bajoStock)
                                Text(
                                  'Stock mínimo: ${producto.stockMinimo}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                stockTotal.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: bajoStock ? Colors.red : Colors.green.shade700,
                                ),
                              ),
                              Text(
                                producto.unidadMedida,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          floatingActionButton: inventarioState.vistaActual != 'global' ? FloatingActionButton(
            onPressed: _mostrarOpcionesUbicacion,
            backgroundColor: inventarioState.vistaActual == 'almacenes' ? Colors.orange.shade700 : Colors.green.shade700,
            child: const Icon(Icons.location_on),
          ) : null,
        );
      },
    );
  }

  void _mostrarOpcionesUbicacion() {
    final vistaActual = ref.read(inventarioProvider).vistaActual;
    print('InventarioScreen._mostrarOpcionesUbicacion: Vista actual: $vistaActual');
    print('InventarioScreen._mostrarOpcionesUbicacion: Almacenes disponibles: ${_almacenes.length}');
    print('InventarioScreen._mostrarOpcionesUbicacion: Tiendas disponibles: ${_tiendas.length}');
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vistaActual == 'almacenes' ? 'Seleccionar Almacén' : 'Seleccionar Tienda',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: vistaActual == 'almacenes' ? _almacenes.length : _tiendas.length,
                itemBuilder: (context, index) {
                  if (ref.read(inventarioProvider).vistaActual == 'almacenes') {
                    final almacen = _almacenes[index];
                    return ListTile(
                      leading: const Icon(Icons.warehouse, color: Colors.orange),
                      title: Text(almacen.nombre),
                      subtitle: Text(almacen.codigo),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InventarioUbicacionScreen(
                              tipoUbicacion: 'almacen',
                              ubicacionId: almacen.codigo,
                              nombreUbicacion: almacen.nombre,
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    final tienda = _tiendas[index];
                    return ListTile(
                      leading: const Icon(Icons.store, color: Colors.green),
                      title: Text(tienda.nombre),
                      subtitle: Text(tienda.codigo),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InventarioUbicacionScreen(
                              tipoUbicacion: 'tienda',
                              ubicacionId: tienda.codigo,
                              nombreUbicacion: tienda.nombre,
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}






