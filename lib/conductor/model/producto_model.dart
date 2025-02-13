import 'dart:convert';

class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final String? foto;
  final double valoracion;
  final String categoria;
  final double precio;
  final double descuento;
  final double subtotal;
  final int cantidad;
  final double total;
  final int? cantidadProductos;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.foto,
    required this.valoracion,
    required this.categoria,
    required this.precio,
    required this.descuento,
    required this.subtotal,
    required this.cantidad,
    required this.total,
    this.cantidadProductos,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'foto': foto,
      'valoracion': valoracion,
      'categoria': categoria,
      'precio': precio,
      'descuento': descuento,
      'subtotal': subtotal,
      'cantidad': cantidad,
      'total': total,
      'cantidadProductos': cantidadProductos,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id']?.toInt() ?? 0,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      foto: map['foto'],
      valoracion: (map['valoracion']?.toDouble() ?? 0.0),
      categoria: map['categoria'] ?? '',
      precio: (map['precio']?.toDouble() ?? 0.0),
      descuento: (map['descuento']?.toDouble() ?? 0.0),
      subtotal: (map['subtotal']?.toDouble() ?? 0.0),
      cantidad: map['cantidad']?.toInt() ?? 0,
      total: (map['total']?.toDouble() ?? 0.0),
      cantidadProductos: map['cantidadProductos']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Producto.fromJson(String source) =>
      Producto.fromMap(json.decode(source) as Map<String, dynamic>);

  Producto copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? foto,
    double? valoracion,
    String? categoria,
    double? precio,
    double? descuento,
    double? subtotal,
    int? cantidad,
    double? total,
    int? cantidadProductos,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      foto: foto ?? this.foto,
      valoracion: valoracion ?? this.valoracion,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      descuento: descuento ?? this.descuento,
      subtotal: subtotal ?? this.subtotal,
      cantidad: cantidad ?? this.cantidad,
      total: total ?? this.total,
      cantidadProductos: cantidadProductos ?? this.cantidadProductos,
    );
  }
}
