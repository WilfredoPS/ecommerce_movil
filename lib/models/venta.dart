class Venta {
  int? id;
  late String numeroVenta;
  late DateTime fechaVenta;
  late String tiendaId; // Origen de la venta
  late String empleadoId; // Vendedor

  late String cliente; // Nombre del cliente
  String? clienteDocumento;
  String? clienteTelefono;

  late double subtotal;
  late double descuento;
  late double impuesto;
  late double total;

  late String metodoPago; // efectivo, tarjeta, transferencia
  late String estado; // completada, anulada
  String? observaciones;

  // Para sincronización
  String? supabaseId;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool sincronizado = false;
  bool eliminado = false;
}

class DetalleVenta {
  int? id;
  late String ventaId;
  late String productoId;
  late double cantidad;
  late double precioUnitario;
  late double descuento;
  late double subtotal;

  // Para sincronización
  String? supabaseId;
  bool sincronizado = false;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
}






