import 'package:app2025/conductor/model/clientelast_model.dart';

class LastpedidoModel {
  int? id;
  String? tipo;
  double? total;
  DateTime? fecha;
  String? estado;
  double? distanciakm;
  ClientelastModel? cliente;

  LastpedidoModel(
      {required this.id,
      required this.tipo,
      required this.total,
      required this.fecha,
      required this.distanciakm,
      required this.cliente,
      required this.estado});
}
