import 'dart:convert';
import 'package:app2025/conductor/model/cliente_model.dart';
import 'package:app2025/conductor/model/producto_model.dart';
import 'package:app2025/conductor/model/promocion_model.dart';

class Pedido {
  final String id;
  final Map<String, dynamic> ubicacion;
  final List<Promocion> promociones;
  final List<Producto> productos;
  final int regionId;
  final int almacenId;
  final double subtotal;
  final double descuento;
  final double total;
  final List<dynamic> almacenesPendientes;
  final Cliente cliente;
  final DateTime emittedTime;
  final DateTime expiredTime;
  final Map<String, dynamic> currentStore;
  String estado;
  final DateTime tiempoLimite;
  final Map<String, dynamic> pedidoinfo;

  Pedido({
    required this.id,
    required this.ubicacion,
    required this.promociones,
    required this.productos,
    required this.regionId,
    required this.almacenId,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.almacenesPendientes,
    required this.cliente,
    required this.emittedTime,
    required this.expiredTime,
    required this.currentStore,
    required this.tiempoLimite,
    this.estado = 'pendiente',
    required this.pedidoinfo,
  });

  // Improved copyWith method
  Pedido copyWith(
      {String? id,
      Map<String, dynamic>? ubicacion,
      List<Promocion>? promociones,
      List<Producto>? productos,
      int? regionId,
      int? almacenId,
      double? subtotal,
      double? descuento,
      double? total,
      List<dynamic>? almacenesPendientes,
      Cliente? cliente,
      DateTime? emittedTime,
      DateTime? expiredTime,
      Map<String, dynamic>? currentStore,
      String? estado,
      DateTime? tiempoLimite,
      Map<String, dynamic>? pedidoinfo}) {
    return Pedido(
      id: id ?? this.id,
      ubicacion: ubicacion ?? this.ubicacion,
      promociones: promociones ?? this.promociones,
      productos: productos ?? this.productos,
      regionId: regionId ?? this.regionId,
      almacenId: almacenId ?? this.almacenId,
      subtotal: subtotal ?? this.subtotal,
      descuento: descuento ?? this.descuento,
      total: total ?? this.total,
      almacenesPendientes: almacenesPendientes ?? this.almacenesPendientes,
      cliente: cliente ?? this.cliente,
      emittedTime: emittedTime ?? this.emittedTime,
      expiredTime: expiredTime ?? this.expiredTime,
      currentStore: currentStore ?? this.currentStore,
      estado: estado ?? this.estado,
      tiempoLimite: tiempoLimite ?? this.tiempoLimite,
      pedidoinfo: pedidoinfo ?? this.pedidoinfo,
    );
  }

  // Improved toMap method with null safety and better serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ubicacion': ubicacion,
      'detalles': {
        'promociones': promociones.map((p) => p.toMap()).toList(),
        'productos': productos.map((p) => p.toMap()).toList(),
      },
      'region_id': regionId,
      'almacen_id': almacenId,
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,

      'AlmacenesPendientes': almacenesPendientes, // Clave exacta con mayúsculas
      'Cliente': cliente.toMap(),

      'emitted_time': emittedTime.toIso8601String(),
      'expired_time': expiredTime.toIso8601String(),
      'current_store': currentStore,
      'estado': estado,
      'tiempo_limite': tiempoLimite.toIso8601String(),
      'pedidoinfo': pedidoinfo,
    };
  }

  // Improved fromMap method with more robust parsing
  factory Pedido.fromMap(Map<dynamic, dynamic> map) {
    // More robust Cliente parsing
    Cliente clienteObj;
    try {
      // Verifica si el cliente está en 'Cliente' o 'cliente'
      dynamic clienteData = map['Cliente'] ?? map['cliente'];
      clienteObj = Cliente.fromMap(clienteData);
    } catch (e) {
      print('Error parsing Cliente: $e');
      // Fallback to default Cliente if parsing fails
      clienteObj = Cliente(
        id: 0,
        usuario_id: 0,
        nombre: 'Cliente Desconocido',
        apellidos: '',
        ruc: '',
        fecha_nacimiento: DateTime.now(),
        fecha_creacion_cuenta: DateTime.now(),
        sexo: '',
        dni: '',
        codigo: '',
        calificacion: 0.0,
        saldo_beneficios: 0.0,
        suscripcion: '',
        telefono: '',
        email: '',
      );
    }

    return Pedido(
        id: (map['id'] ?? map['_id']).toString(),
        ubicacion: _convertToStringDynamicMap(map['ubicacion'] ?? {}),
        promociones:
            _parsePromocionsList(map['detalles']?['promociones'] ?? []),
        productos: _parseProductosList(map['detalles']?['productos'] ?? []),
        regionId: (map['region_id'] ?? map['regionId'] ?? 1) as int,
        almacenId: (map['almacen_id'] ?? map['almacenId'] ?? 1) as int,
        subtotal: _safeDouble(map['subtotal'] ?? 0.0),
        descuento: _safeDouble(map['descuento'] ?? 0.0),
        total: _safeDouble(map['total'] ?? 0.0),
        almacenesPendientes:
            map['AlmacenesPendientes'] ?? [], // Usar misma clave
        cliente: clienteObj,
        emittedTime: _safeParse(map['emitted_time'] ?? map['emittedTime']),
        expiredTime: _safeParse(map['expired_time'] ?? map['expiredTime']),
        currentStore: _convertToStringDynamicMap(map['current_store'] ?? {}),
        tiempoLimite: _safeParse(
            map['tiempo_limite'] ?? map['tiempoLimite'] ?? map['expired_time']),
        estado: map['estado'] ?? 'pendiente',
        pedidoinfo: _convertToStringDynamicMap(map['pedidoinfo'] ?? {}));
  }

  static Cliente _parseCliente(Map<dynamic, dynamic>? clienteMap) {
    if (clienteMap == null) {
      // Return a default Cliente object if no data is provided
      return Cliente(
        id: 0,
        usuario_id: 0,
        nombre: 'Cliente Desconocido',
        apellidos: '',
        ruc: '',
        fecha_nacimiento: DateTime.now(),
        fecha_creacion_cuenta: DateTime.now(),
        sexo: '',
        dni: '',
        codigo: '',
        calificacion: 0,
        saldo_beneficios: 0,
        suscripcion: '',
        telefono: '',
        email: '',
      );
    }

    return Cliente(
      id: clienteMap['id'] ?? 0,
      usuario_id: clienteMap['usuario_id'] ?? 0,
      nombre: clienteMap['nombre'] ?? 'Cliente Desconocido',
      apellidos: clienteMap['apellidos'] ?? '',
      ruc: clienteMap['ruc'] ?? '',
      fecha_nacimiento: _safeParse(clienteMap['fecha_nacimiento']),
      fecha_creacion_cuenta: _safeParse(clienteMap['fecha_creacion_cuenta']),
      sexo: clienteMap['sexo'] ?? '',
      dni: clienteMap['dni'] ?? '',
      codigo: clienteMap['codigo'] ?? '',
      calificacion: clienteMap['calificacion'] ?? 0,
      saldo_beneficios: clienteMap['saldo_beneficios'] ?? 0,
      suscripcion: clienteMap['suscripcion'] ?? '',
      telefono: clienteMap['telefono'] ?? '',
      email: clienteMap['email'] ?? '',
    );
  }

  static Map<String, dynamic> _convertToStringDynamicMap(dynamic map) {
    if (map is Map<String, dynamic>) return map;
    if (map is Map) {
      return map.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  static List<Promocion> _parsePromocionsList(dynamic promotionsList) {
    if (promotionsList is List) {
      return promotionsList
          .map((x) {
            if (x is Map) {
              return Promocion.fromMap(Map<String, dynamic>.from(x));
            }
            return null;
          })
          .whereType<Promocion>()
          .toList();
    }
    return [];
  }

  static List<Producto> _parseProductosList(dynamic productsList) {
    if (productsList is List) {
      return productsList
          .map((x) {
            if (x is Map) {
              return Producto.fromMap(Map<String, dynamic>.from(x));
            }
            return null;
          })
          .whereType<Producto>()
          .toList();
    }
    return [];
  }

  // Helper method to safely parse doubles
  static double _safeDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper method to safely parse DateTime
  static DateTime _safeParse(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is DateTime) return value;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date: $value');
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  // Improved toJson method
  String toJson() => json.encode(toMap());

  // Improved fromJson method
  factory Pedido.fromJson(String source) {
    try {
      return Pedido.fromMap(json.decode(source));
    } catch (e) {
      print('Error parsing JSON: $e');
      throw FormatException('Failed to parse Pedido from JSON');
    }
  }

  // Helpful getter methods
  String get clienteName => '${cliente.nombre} ${cliente.apellidos}'.trim();
  String get clienteDNI => cliente.dni;
  String get clienteTelefono => cliente.telefono;
  String get clienteEmail => cliente.email;

  // Method to get total number of products
  int get totalProductos => productos.length;

  // Method to get product names
  List<String> get nombreProductos =>
      productos.map((p) => p.nombre ?? 'Producto sin nombre').toList();
}
