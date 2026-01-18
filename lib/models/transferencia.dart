class Transferencia {
  int? id;
  late String numeroTransferencia;
  late DateTime fechaTransferencia;

  // Origen
  late String origenTipo; // tienda, almacen
  late String origenId;

  // Destino
  late String destinoTipo; // tienda, almacen
  late String destinoId;

  late String empleadoId; // Quien autoriza/registra

  late String estado; // pendiente, en_transito, recibida, anulada
  DateTime? fechaRecepcion;
  String? empleadoRecepcionId;
  String? observaciones;

  // Para sincronización
  String? supabaseId;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool sincronizado = false;
  bool eliminado = false;
}

class DetalleTransferencia {
  int? id;
  late String transferenciaId;
  late String productoId;
  late double cantidadEnviada;
  late double cantidadRecibida;

  // Para sincronización
  String? supabaseId;
  bool sincronizado = false;
}






