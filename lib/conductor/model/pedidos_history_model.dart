import 'dart:convert';

class Pedido {
  final int id;
  final int cliente;
  final double total;
  final DateTime fecha;
  final String? tipo;
  final String? estado;
  final Ubicacion ubicacion;
  final List<DetallePedido> detallesPedido;
  final String? clienteNombre;

  Pedido({
    required this.id,
    required this.cliente,
    required this.total,
    required this.fecha,
    required this.tipo,
    required this.estado,
    required this.ubicacion,
    required this.detallesPedido,
    required this.clienteNombre,
  });

  // Convertir JSON a Pedido
  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'],
      cliente: json['cliente'],
      total: (json['total'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha']),
      tipo: json['tipo'],
      estado: json['estado'],
      ubicacion: Ubicacion.fromJson(json['ubicacion']),
      detallesPedido: (json['detalles_pedido'] as List)
          .map((i) => DetallePedido.fromJson(i))
          .toList(),
      clienteNombre: json['cliente_nombre'],
    );
  }

  // Convertir Pedido a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente': cliente,
      'total': total,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo,
      'estado': estado,
      'ubicacion': ubicacion.toJson(),
      'detalles_pedido': detallesPedido.map((e) => e.toJson()).toList(),
      'cliente_nombre': clienteNombre,
    };
  }

  // Convertir una lista de JSON a una lista de Pedidos
  static List<Pedido> fromJsonList(String jsonString) {
    List<dynamic> decoded = json.decode(jsonString);
    return decoded.map((e) => Pedido.fromJson(e)).toList();
  }
}

class Ubicacion {
  final int id;
  final String? departamento;
  final String? provincia;
  final String? distrito;
  final String? direccion;
  final double latitud;
  final double longitud;
  final int clienteId;
  final int zonaTrabajoId;

  Ubicacion({
    required this.id,
    required this.departamento,
    required this.provincia,
    required this.distrito,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.clienteId,
    required this.zonaTrabajoId,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      id: json['id'],
      departamento: json['departamento'],
      provincia: json['provincia'],
      distrito: json['distrito'],
      direccion: json['direccion'],
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      clienteId: json['cliente_id'],
      zonaTrabajoId: json['zona_trabajo_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departamento': departamento,
      'provincia': provincia,
      'distrito': distrito,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'cliente_id': clienteId,
      'zona_trabajo_id': zonaTrabajoId,
    };
  }
}

class DetallePedido {
  final int id;
  final int productoId;
  final int cantidad;
  final int? promocionId;
  final String? productoNombre;

  DetallePedido({
    required this.id,
    required this.productoId,
    required this.cantidad,
    this.promocionId,
    required this.productoNombre,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) {
    return DetallePedido(
      id: json['id'],
      productoId: json['producto_id'],
      cantidad: json['cantidad'],
      promocionId: json['promocion_id'], // Puede ser null
      productoNombre: json['producto_nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producto_id': productoId,
      'cantidad': cantidad,
      'promocion_id': promocionId,
      'producto_nombre': productoNombre,
    };
  }
}
