import 'package:app2025/cliente/models/producto_model.dart';
import 'package:app2025/cliente/models/promo_model.dart';

class PedidoModel {
  final List<Producto> seleccionados;
  final List<Promo> seleccionadosPromo;
  final int cantidadProd;
  final double totalProds;
  final double envio;
  PedidoModel({
    required this.seleccionados,
    required this.seleccionadosPromo,
    required this.cantidadProd,
    required this.totalProds,
    required this.envio,
  });
}
