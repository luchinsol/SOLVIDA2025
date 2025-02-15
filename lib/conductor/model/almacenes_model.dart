class AlmacenModel {
  int id;
  String nombre;
  double latitud;
  double longitud;
  String horario;
  String departamento;
  String provincia;
  String direccion;

  AlmacenModel(
      {required this.id,
      required this.nombre,
      required this.latitud,
      required this.longitud,
      required this.horario,
      required this.departamento,
      required this.provincia,
      required this.direccion});
}
