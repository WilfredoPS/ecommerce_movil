class Compra {
  int? id;
  late String numeroCompra;
  late DateTime fechaCompra;
  late String proveedor;
  String? numeroFactura;

  // Destino (almacén o tienda)
  late String destinoTipo; // tienda, almacen
  late String destinoId;

  late String empleadoId; // Quien registró la compra

  late double subtotal;
  late double impuesto;
  late double total;

  late String estado; // pendiente, completada, anulada
  String? observaciones;

  // Para sincronización
  String? supabaseId;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool sincronizado = false;
  bool eliminado = false;
}

class DetalleCompra {
  int? id;
  late String compraId;
  late String productoId;
  late double cantidad;
  late double precioUnitario;
  late double subtotal;

  // Para sincronización
  String? supabaseId;
  bool sincronizado = false;
}


