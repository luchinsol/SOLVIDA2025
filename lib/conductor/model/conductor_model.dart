import 'package:intl/intl.dart';

class ConductorModel {
  int id;
  String nombres;
  String apellidos;
  DateTime? fecha_nacimiento;
  String? licencia;
  String? soat;
  double valoracion;
  double? latitud;
  double? longitud;
  String? estado_registro;
  String? estado_trabajo;
  String? departamento;
  String? provincia;
  int? evento_id;
  String? foto_perfil;
  String? nombre;
  String? nivel;

  ConductorModel(
      {required this.id,
      required this.nombres,
      required this.apellidos,
      required this.fecha_nacimiento,
      required this.licencia,
      required this.soat,
      this.valoracion = 0.0,
      required this.latitud,
      required this.longitud,
      required this.estado_registro,
      required this.estado_trabajo,
      required this.departamento,
      required this.provincia,
      required this.evento_id,
      this.foto_perfil,
      required this.nombre,
      required this.nivel});

  factory ConductorModel.fromJson(Map<String, dynamic> json) {
    // Define the date format
    final DateFormat dateFormat = DateFormat("yyyy-MM-dd");

    return ConductorModel(
        id: json['id'] ?? 0,
        nombres: json['nombres'] ?? '',
        apellidos: json['apellidos'] ?? '',
        fecha_nacimiento: json['fecha_nacimiento'] != null
            ? DateTime.parse(json['fecha_nacimiento'])
            : null,
        licencia: json['licencia'],
        soat: json['soat'],
        valoracion: json['valoracion'] != null
            ? (json['valoracion'] is int
                ? json['valoracion'].toDouble()
                : json['valoracion'])
            : 0.0,
        latitud: json['latitud'] != null
            ? double.tryParse(json['latitud'].toString())
            : null,
        longitud: json['longitud'] != null
            ? double.tryParse(json['longitud'].toString())
            : null,
        estado_registro: json['estado_registro'],
        estado_trabajo: json['estado_trabajo'],
        departamento: json['departamento'],
        provincia: json['provincia'],
        evento_id: json['evento_id'],
        foto_perfil: json['foto_perfil'],
        nombre: json['nombre'],
        nivel: json['nivel']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'fecha_nacimiento': fecha_nacimiento?.toIso8601String(),
      'licencia': licencia,
      'soat': soat,
      'valoracion': valoracion,
      'latitud': latitud,
      'longitud': longitud,
      'estado_registro': estado_registro,
      'estado_trabajo': estado_trabajo,
      'departamento': departamento,
      'provincia': provincia,
      'evento_id': evento_id,
      'foto_perfil': foto_perfil,
      'nombre': nombre,
      'nivel': nivel
    };
  }
}
