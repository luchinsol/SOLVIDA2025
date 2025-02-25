import 'dart:convert';

class Cliente {
  final int id;
  final int usuario_id;
  final String nombre;
  final String apellidos;
  final String ruc;
  final DateTime fecha_nacimiento;
  final DateTime fecha_creacion_cuenta;
  final String sexo;
  final String dni;
  final String codigo;
  final double calificacion;
  final double saldo_beneficios;
  final String suscripcion;
  final String telefono;
  final String email;

  Cliente({
    required this.id,
    required this.usuario_id,
    required this.nombre,
    required this.apellidos,
    required this.ruc,
    required this.fecha_nacimiento,
    required this.fecha_creacion_cuenta,
    required this.sexo,
    required this.dni,
    required this.codigo,
    required dynamic calificacion,
    required dynamic saldo_beneficios,
    required this.suscripcion,
    this.telefono = '',
    this.email = '',
  })  : calificacion = (calificacion is int)
            ? calificacion.toDouble()
            : (calificacion as double),
        saldo_beneficios = (saldo_beneficios is int)
            ? saldo_beneficios.toDouble()
            : (saldo_beneficios as double);

  // Método toMap para convertir el objeto Cliente a un Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuario_id,
      'nombre': nombre,
      'apellidos': apellidos,
      'ruc': ruc,
      'fecha_nacimiento': fecha_nacimiento.toIso8601String(),
      'fecha_creacion_cuenta': fecha_creacion_cuenta.toIso8601String(),
      'sexo': sexo,
      'dni': dni,
      'codigo': codigo,
      'calificacion': calificacion,
      'saldo_beneficios': saldo_beneficios,
      'suscripcion': suscripcion,
      'telefono': telefono,
      'email': email,
    };
  }

  // Método fromMap para crear un objeto Cliente desde un Map
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] ?? 0,
      usuario_id: map['usuario_id'] ?? 0,
      nombre: map['nombre'] ?? 'Cliente Desconocido',
      apellidos: map['apellidos'] ?? '',
      ruc: map['ruc'] ?? '',
      fecha_nacimiento: DateTime.parse(map['fecha_nacimiento']),
      fecha_creacion_cuenta: DateTime.parse(map['fecha_creacion_cuenta']),
      sexo: map['sexo'] ?? '',
      dni: map['dni'] ?? '',
      codigo: map['codigo'] ?? '',
      calificacion: map['calificacion'] ?? 0.0,
      saldo_beneficios: map['saldo_beneficios'] ?? 0.0,
      suscripcion: map['suscripcion'] ?? '',
      telefono: map['telefono'] ?? '',
      email: map['email'] ?? '',
    );
  }

  // Método toJson para convertir el objeto Cliente a JSON
  String toJson() => json.encode(toMap());

  // Método fromJson para crear un objeto Cliente desde JSON
  factory Cliente.fromJson(String source) =>
      Cliente.fromMap(json.decode(source));
}
