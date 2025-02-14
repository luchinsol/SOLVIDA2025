class ConductorModel {
  int id;
  String nombres;
  String apellidos;
  DateTime fecha_nacimiento;
  String? licencia;
  String? soat;
  double? valoracion;
  double? latitud;
  double? longitud;
  String? estado_registro;
  String? estado_trabajo;
  String? departamento;
  String? provincia;
  int? evento_id;
  String? foto_perfil;

  ConductorModel(
      {required this.id,
      required this.nombres,
      required this.apellidos,
      required this.fecha_nacimiento,
      required this.licencia,
      required this.soat,
      this.valoracion,
      required this.latitud,
      required this.longitud,
      required this.estado_registro,
      required this.estado_trabajo,
      required this.departamento,
      required this.provincia,
      required this.evento_id,
      this.foto_perfil});
}
