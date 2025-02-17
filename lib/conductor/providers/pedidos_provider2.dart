import 'dart:async';

import 'package:app2025/conductor/config/notifications.dart';
import 'package:app2025/conductor/config/socketCentral2.dart';
import 'package:app2025/conductor/model/pedido_model.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef PedidoCallback = void Function(Map<String, dynamic> data);

class PedidosProvider2 extends ChangeNotifier {
  // Para no pasar como
  final SocketService2 _socketService = SocketService2(); // Usa el Singleton
  final List<Pedido> _pedidos = [];
  PedidoCallback? _uniqueCallback;
  final Map<String, Timer> _timers = {};
  final Set<String> _pedidosAceptados = {};
  bool _isInitialized = false;
  bool _isLoading = false;
  final List<Pedido> _pedidosAceptadosList = [];
  final Set<String> _processedOrderIds = {};

  //bool get isLoading => _isLoading;
  //bool get isInitialized => _isInitialized;

  List<Pedido> get pedidos => _pedidos;

  List<Pedido> get pedidosAceptados => List.unmodifiable(_pedidosAceptadosList);

  Pedido? get ultimoPedidoAceptado =>
      _pedidosAceptadosList.isNotEmpty ? _pedidosAceptadosList.last : null;

  PedidosProvider2() {
    print("📡 Inicializando PedidosProvider2...");
    //_socketService.connect();
    //_initSocketListeners();
    //_initialEmit();
    //_socketService.connect();
  }

  // 1. ESCUCHAR EVENTOS

  void _initSocketListeners(String? nombre) {
    print("🔄 Escuchando eventos en el socket...");

    //EVENTO PARA CUANDO EL CONDUCTOR SE CONECTA A TIEMPO
    _socketService.on(nombre!, (data) {
      //_logEvent('[Events] Received order on $_eventName: $data');
      if (_uniqueCallback != null) {
        _uniqueCallback!(data);
      }
    });

    //EVENTO PARA CUANDO EL CONDUCTOR SE CONECTA TARDE
    _socketService.on('initial_orders', (data) {
      print("📥 Evento initial_orders: $data");
      if (data is List) {
        for (var order in data) {
          if (_uniqueCallback != null) {
            _uniqueCallback!(order);
          }
        }
      }
    });

    _socketService.on('order_taken', (data) {
      print('✅ Orden tomada confirmada: $data');
    });

    _socketService.on('pedido_actualizado', (data) {
      print("📥 Pedido actualizado: $data");
    });

    _socketService.onDisconnect(() {
      print('❌ Desconectado del servidor, intentando reconectar...');
      _socketService.reconnect();
    });
  }

  // 2.  EMITIR EVENTOS
  void _initialEmit(int? almacenId) {
    print("📤 Enviando evento register_driver...");
    _socketService.emit("register_driver", {'almacenId': almacenId});
  }

  void emitTakeOrder(String orderId, int almacenId) {
    try {
      if (!_processedOrderIds.contains(orderId)) {
        final takeOrderData = {'orderId': orderId, 'almacenId': almacenId};
        print("---------------------------> SOCKETTTTTTT");
        //Toma un pedido
        _socketService.emit('take_order', takeOrderData);
        _processedOrderIds.add(orderId);

        print('🚀 Pedido Tomado Emitido: $takeOrderData');
      }
    } catch (e) {
      print('❌ Error al emitir take_order: $e');
    }

    //Notificación de orden tomada
    // Listen for order_taken event to confirm deletion
    /*
    socket.on('order_taken', (data) {
      print('✅ Orden tomada confirmada: $data');
    });*/
  }

  void confirmarRecepcionPedido(String pedidoId) {
    _socketService.emit('confirmar_recepcion',
        {'pedidoId': pedidoId, 'timestamp': DateTime.now().toIso8601String()});
  }

  // 3. MÉTODOS DEL PROVIDER

  /*
  void agregarPedido(String pedido) {
    _pedidos.add(pedido);
    notifyListeners();
  }*/

  void onHolapedido(PedidoCallback callback) {
    _uniqueCallback = callback;
    //_logEvent('[Callback] Pedido callback registered');
  }

  Future<void> loadInitialData(int conductorId) async {
    if (_isInitialized) {
      print('📱 [Provider] Already initialized');
      return;
    }

    try {
      _isLoading = true;
      // Usamos addPostFrameCallback para evitar llamar a notifyListeners durante el build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners(); // Llama a notifyListeners después de la construcción
      });

      //await _socketService.loadConductorEvent(conductorId);
      _isInitialized = true;
    } catch (e) {
      print('📱 [Provider] Error loading initial data: $e');
      _isInitialized = false;
    } finally {
      _isLoading = false;
      // Usamos addPostFrameCallback para evitar llamar a notifyListeners durante el build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners(); // Llama a notifyListeners después de la construcción
      });
    }
  }

  void _handleExpiration(String pedidoId) {
    try {
      final index = _pedidos.indexWhere((p) => p.id == pedidoId);
      if (index != -1) {
        _pedidos.removeAt(index);
        _timers[pedidoId]?.cancel();
        _timers.remove(pedidoId);
        notifyListeners();
      }
    } catch (e) {
      print('Error handling expiration: $e');
    }
  }

  void _setupExpirationTimer(Pedido pedido) {
    _timers[pedido.id]?.cancel();

    final localExpiredTime = pedido.expiredTime.toLocal();
    final timeUntilExpiration = localExpiredTime.difference(DateTime.now());

    if (timeUntilExpiration.isNegative) {
      _handleExpiration(pedido.id);
    } else {
      _timers[pedido.id] = Timer(timeUntilExpiration, () {
        _handleExpiration(pedido.id);
      });
    }
  }

  Future<bool> addPedido(
      Map<String, dynamic> pedidoData, bool showNotification) async {
    try {
      final pedido = Pedido.fromMap(pedidoData);
      print('Adding pedido: ${pedido.id}');

      // Verificar si el pedido ya existe o está aceptado
      if (_pedidos.any((p) => p.id == pedido.id) ||
          _pedidosAceptados.contains(pedido.id)) {
        print('Pedido already exists or is accepted: ${pedido.id}');
        return true;
      }

/*
      if (showNotification) {
        await _notificationsService.showOrderNotification(
          id: int.parse(pedido.id),
          title: 'Nuevo Pedido #${pedido.id}',
          body:
              'Total: \$${pedido.total.toStringAsFixed(2)}\nCliente: ${pedido.cliente?.nombre ?? 'No especificado'}',
          payload: json.encode(pedidoData),
        );
      }*/

      _pedidos.add(pedido);
      _setupExpirationTimer(pedido);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding pedido: $e');
      return false;
    }
  }

  Future<void> _processPedidoData(Map<String, dynamic> data) async {
    try {
      if (data['estado'] == 'expirado') {
        _pedidos.removeWhere((p) => p.id == data['id']);
        print("TIMERRRRR ${data['id']}");
        print(_timers[data['id']]);
        _timers[data['id']]?.cancel();

        _timers.remove(data['id']);
        notifyListeners();
        return;
      }

      final pedido = Pedido.fromMap(data);

      print("----------> FLUJO INICIAL");
      print('Processing pedido: ${pedido.id}');

      NotificationsService().showOrderNotification(
        id: 29999,
        title: 'Pedido #765433',
        body: 'El pedido ha sido anulado.',
        payload: 'order',
      );

      if (!_pedidosAceptados.contains(pedido.id)) {
        await addPedido(data, true);
      }
    } catch (e) {
      print('Error processing pedido data: $e');
    }
  }

  Future<void> updatePedidoEstado(String pedidoId, String newEstado) async {
    try {
      final index = _pedidos.indexWhere((p) => p.id == pedidoId);
      if (index != -1) {
        final updatedPedido = _pedidos[index].copyWith(estado: newEstado);
        print("UPDATE---zz");
        print(updatedPedido.id);
        //await updatePedidoInDatabase(updatedPedido);
        _pedidos[index] = updatedPedido;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating pedido estado: $e');
      rethrow;
    }
  }

  //aceptar Pedido

  Future<void> aceptarPedido(String pedidoId,
      {Map<String, dynamic>? pedidoData}) async {
    try {
      print("INGRESANDO AL PROVIDER DE PEDIDO---->> METODO ACEPTAR");
      print('Accepting pedido: $pedidoId');

      // Si no está en la lista de pedidos pero tenemos los datos, lo agregamos primero
      if (pedidoData != null && !_pedidos.any((p) => p.id == pedidoId)) {
        await _processPedidoData(pedidoData);
      }

      final index = _pedidos.indexWhere((p) => p.id == pedidoId);
      print(index);

      if (index != -1) {
        final pedido = _pedidos[index];

        _pedidosAceptadosList.add(pedido);
        _pedidosAceptados.add(pedidoId);

        await updatePedidoEstado(pedidoId, 'aceptado');
        //_socketService.emitTakeOrder(pedidoId, pedido.almacenId);

        _timers[pedidoId]?.cancel();
        print(_timers[pedidoId]);
        _timers.remove(pedidoId);
        print("LLego hasta aqui");
        _pedidos.removeAt(index);
        print("PEDIDO ACTUALIZADO SU ID${pedido.id}");
        print('Pedido aceptado y guardado: ${pedido.id}');
        print('Total pedidos aceptados: ${_pedidosAceptadosList.length}');
        print(
            "-------------------------------------------------------->LISTA DE ACEPTADOS");
        print('Pedidos Almacenados en la Lista: ${_pedidosAceptadosList}');
        notifyListeners();
        print('Pedido accepted successfully: $pedidoId');
      }
    } catch (e) {
      print('Error accepting pedido: $e');
      _pedidosAceptados.remove(pedidoId);
      //await updatePedidoEstado(pedidoId, 'pendiente');
      rethrow;
    }
  }

  //LOGICA DE BUCLE
  Future<void> entregarPedido(String pedidoId) async {
    try {
      print("Entregando el Pedido ------>");
      print("ID del pedido a entregar: $pedidoId");
      //BUSCAMOS EL PEDIDO QUE ACEPTAMOS PARA ELIMINARLO DE LA LISTA Y TOMAR EL SIGUIENTE
      final index = _pedidosAceptadosList.indexWhere((p) => p.id == pedidoId);
      if (index != -1) {
        // Remover el pedido de la lista de aceptados
        final pedido = _pedidosAceptadosList[index];
        print(
            'Antes de eliminar - Total pedidos aceptados: ${_pedidosAceptadosList.length}');
        print(
            'Lista de IDs antes de eliminar: ${_pedidosAceptadosList.map((p) => p.id).toList()}');
        _pedidosAceptadosList.removeAt(index);
        _pedidosAceptados.remove(pedidoId);
        print("POSIBLE ERROR------------------------------------------");
        print('Pedido entregado y eliminado de la lista: ${pedido.id}');
        print(
            'Después de eliminar - Total pedidos aceptados: ${_pedidosAceptadosList.length}');
        print(
            'Lista de IDs después de eliminar: ${_pedidosAceptadosList.map((p) => p.id).toList()}');
        //print('${_pedidosAceptadosList[1].id}');
        print('Pedido entregado y eliminado de la lista: ${pedido.id}');
        print('-------------------------->>>>>>>>>>>>><<<<-----------------');
        print(
            'Total pedidos aceptados restantes: ${_pedidosAceptadosList.length}');
        print('-----------------------------------<<<<<<---------------<<<<');
        if (_pedidosAceptadosList.isNotEmpty) {
          print('Siguiente pedido en la lista: ${_pedidosAceptadosList[0].id}');
        } else {
          print('No hay más pedidos en la lista de aceptados');
        }

        notifyListeners();
        print('Pedido entregado exitosamente: $pedidoId');
        print("Saliendo de aqui -------->");
      } else {
        print('Pedido no encontrado en la lista de aceptados: $pedidoId');
      }
    } catch (error) {
      print("Pedido no se Entrego ${error}");
    }
  }

  List<Pedido> getActivePedidos() {
    final now = DateTime.now();
    return _pedidos
        .where((pedido) =>
            pedido.estado != 'expirado' &&
            pedido.expiredTime.isAfter(now) &&
            !_pedidosAceptados.contains(pedido.id))
        .toList();
  }

  // 4. LIBERAR MEMORIA
  @override
  void dispose() {
    print("🔌 Cerrando conexión de Socket...");
    _socketService.disconnect();
    super.dispose();
  }

  // 5. CONEXIÓN MANUAL
  void conectarSocket(int? almacenId, String? nombre) {
    print("🔌 Conectando manualmente al socket...");
    _socketService.connect();
    _initSocketListeners(nombre);
    onHolapedido((data) {
      print("📦 Nuevo pedido recibido en el Provider: $data");
      _processPedidoData(data);
    });
    _initialEmit(almacenId);
  }
}
