import 'package:app2025/conductor/model/lastpedido_model.dart';
import 'package:flutter/material.dart';

class LastpedidoProvider extends ChangeNotifier {
  LastpedidoModel? _lastpedidoModel;

  // Getter para obtener el último pedido
  LastpedidoModel? get lastPedido => _lastpedidoModel;

  // Método para actualizar el último pedido
  void updateLastPedido(LastpedidoModel newLastpedido) {
    _lastpedidoModel = newLastpedido;
    notifyListeners(); // Notifica a los listeners para que actualicen la UI
  }
}
