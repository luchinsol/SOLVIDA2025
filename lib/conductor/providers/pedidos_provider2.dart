import 'package:app2025/conductor/config/socketCentral2.dart';
import 'package:app2025/conductor/model/pedido_model.dart';
import 'package:flutter/material.dart';

class PedidosProvider2 extends ChangeNotifier {
  // Lista privada de pedidos
  List<Pedido> _pedidos = [];
  final SocketService2 _socketService;

  // Getter para obtener los pedidos
  List<Pedido> get pedidos => _pedidos;

  PedidosProvider2(this._socketService) {
    print("EN EL PEDIDOSPROVIDER2  ------------------------------------->");
    // Inicializamos la escucha de eventos
    _initSocketListeners();
    // _initialEmit();
  }

//CONFIGURACION DE SOCKET -INICIO

/**EVENTOS DE ESCUCHA */
  void _initSocketListeners() {
    print("Escuchando eventos en el socket...");
    // Escuchamos el evento de nuevos pedidos
    _socketService.on('almacen_3', (data) {
      print("data--");
      print(data);
      // Convertimos la data recibida a un objeto Pedido
      //final nuevoPedido = Pedido.fromJson(data);
      //agregarPedido(nuevoPedido);
    });

    _socketService.on('initial_orders', (data) {
      print("INITIAL ORDER.---");
      if (data is List) {
        print("Es una lista");
      }
    });
    // Podemos agregar más listeners según necesitemos
    _socketService.on('pedido_actualizado', (data) {
      // Lógica para actualizar un pedido existente
      // actualizarPedido(data);
    });
  }

/**EVENTOS DE EMISION */
  // Métodos para emitir eventos (EMIT)
/*
  void _initialEmit() {
    _socketService.emit("register_driver", {'almacenId': 3});
  }*/

  void confirmarRecepcionPedido(String pedidoId) {
    _socketService.emit('confirmar_recepcion',
        {'pedidoId': pedidoId, 'timestamp': DateTime.now().toIso8601String()});
  }

//CONFIGURACION DE SOCKET -FIN

// METODOS DE PROVIDER
  // Método para agregar un nuevo pedido
  void agregarPedido(Pedido pedido) {
    _pedidos.add(pedido);
    notifyListeners(); // Notifica a los widgets que están escuchando
  }
}
