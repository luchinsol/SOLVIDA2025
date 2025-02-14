import 'package:app2025/cliente/models/pedido_model.dart';
import 'package:flutter/material.dart';

class PedidoProvider extends ChangeNotifier {
  // CREAS UNA INSTANCIA DE LA CLASE
  PedidoModel? _pedido;

  // OBTIENES EL USUARIO
  PedidoModel? get pedido => _pedido;

  PedidoProvider() {
    print("CLIENTE PROVIDER");
  }

  // ACTUALIZAS EL VALOR DEL OBJETO Y NOTIFICAMOS A LOS RECEPTORES
  void updatePedido(PedidoModel newPedido) {
    _pedido = newPedido;
    notifyListeners();
  }
}
