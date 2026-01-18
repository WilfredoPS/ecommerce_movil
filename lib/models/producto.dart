class Producto {
  int? id;
  late String codigo;
  late String nombre;
  String? descripcion;
  late String categoria; // ropa deportiva, calzado deportivo, equipamiento, suplementos, accesorios
  late String unidadMedida; // pieza, par, unidad, caja
  late double precioCompra;
  late double precioVenta;
  int stockMinimo = 0;

  // Imagen del producto
  String? imagenPath; // Ruta local de la imagen
  String? imagenUrl; // URL de la imagen en Supabase (para sincronización)

  // Para sincronización
  String? supabaseId;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool sincronizado = false;
  bool eliminado = false;
}


