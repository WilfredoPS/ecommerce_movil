class Inventario {
  int? id;
  late String productoId;
  late String ubicacionTipo; // tienda, almacen
  late String ubicacionId; // ID de la tienda o almacén
  late double cantidad;
  late DateTime ultimaActualizacion;

  // Para sincronización
  String? supabaseId;
  bool sincronizado = false;
}

