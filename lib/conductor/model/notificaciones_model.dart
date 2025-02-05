class NotificacionesModel {
  int id;
  String mensaje;
  String tipo;
  String estado;
  DateTime fechacreacion;
  DateTime fechaenvio;

  NotificacionesModel({
    required this.id,
    required this.mensaje,
    required this.tipo,
    required this.estado,
    required this.fechacreacion,
    required this.fechaenvio,
  });
}
