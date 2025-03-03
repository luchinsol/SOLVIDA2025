class PedidosAlmacen {
  final int id;
  final int clienteId;
  final double subtotal;
  final double descuento;
  final double total;
  final DateTime fecha;
  String? tipo;
  String? foto;
  String? estado;
  String? observacion;
  String? tipoPago;
  final int? beneficiadoId;
  final int? ubicacionId;
  final int? conductorId;
  final int? almacenId;

  PedidosAlmacen({
    required this.id,
    required this.clienteId,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.fecha,
    this.tipo,
    this.foto,
    required this.estado,
    required this.observacion,
    required this.tipoPago,
    this.beneficiadoId,
    required this.ubicacionId,
    this.conductorId,
    required this.almacenId,
  });

  // Convertir JSON a modelo
  factory PedidosAlmacen.fromJson(Map<String, dynamic> json) {
    return PedidosAlmacen(
      id: json['id'],
      clienteId: json['cliente_id'],
      subtotal: (json['subtotal'] as num).toDouble(),
      descuento: (json['descuento'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha']),
      tipo: json['tipo'],
      foto: json['foto'],
      estado: json['estado'],
      observacion: json['observacion'],
      tipoPago: json['tipo_pago'],
      beneficiadoId: json['beneficiado_id'],
      ubicacionId: json['ubicacion_id'],
      conductorId: json['conductor_id'],
      almacenId: json['almacen_id'],
    );
  }

  // Convertir modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo,
      'foto': foto,
      'estado': estado,
      'observacion': observacion,
      'tipo_pago': tipoPago,
      'beneficiado_id': beneficiadoId,
      'ubicacion_id': ubicacionId,
      'conductor_id': conductorId,
      'almacen_id': almacenId,
    };
  }
}
