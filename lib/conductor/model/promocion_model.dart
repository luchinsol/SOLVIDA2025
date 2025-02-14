import 'dart:convert';
import 'producto_model.dart';

class Promocion {
  final int id;
  final String nombre;
  final String descripcion;
  final String? foto;
  final double valoracion;
  final String categoria;
  final double precio;
  final double descuento;
  final double total;
  final int cantidad;
  final double subtotal;
  final List<Producto> productos;

  Promocion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.foto,
    required this.valoracion,
    required this.categoria,
    required this.precio,
    required this.descuento,
    required this.total,
    required this.cantidad,
    required this.subtotal,
    required this.productos,
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
      'total': total,
      'cantidad': cantidad,
      'subtotal': subtotal,
      'productos': productos.map((x) => x.toMap()).toList(),
    };
  }

  factory Promocion.fromMap(Map<String, dynamic> map) {
    return Promocion(
      id: map['id']?.toInt() ?? 0,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      foto: map['foto'],
      valoracion: (map['valoracion']?.toDouble() ?? 0.0),
      categoria: map['categoria'] ?? '',
      precio: (map['precio']?.toDouble() ?? 0.0),
      descuento: (map['descuento']?.toDouble() ?? 0.0),
      total: (map['total']?.toDouble() ?? 0.0),
      cantidad: map['cantidad']?.toInt() ?? 0,
      subtotal: (map['subtotal']?.toDouble() ?? 0.0),
      productos: List<Producto>.from(
        (map['productos'] ?? [])
            .map((x) => Producto.fromMap(x as Map<String, dynamic>)),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Promocion.fromJson(String source) =>
      Promocion.fromMap(json.decode(source) as Map<String, dynamic>);

  Promocion copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? foto,
    double? valoracion,
    String? categoria,
    double? precio,
    double? descuento,
    double? total,
    int? cantidad,
    double? subtotal,
    List<Producto>? productos,
  }) {
    return Promocion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      foto: foto ?? this.foto,
      valoracion: valoracion ?? this.valoracion,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      descuento: descuento ?? this.descuento,
      total: total ?? this.total,
      cantidad: cantidad ?? this.cantidad,
      subtotal: subtotal ?? this.subtotal,
      productos: productos ?? this.productos,
    );
  }
}
