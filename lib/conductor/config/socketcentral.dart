/*import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late io.Socket socket;
  final Set<String> _registeredEvents = {};

  factory SocketService() {
    return _instance;
  }

  SocketService._internal() {
    // Initialization logic
    connectToServer();
  }

  void connectToServer() {
    final apiUrl = "http://147.182.251.164"; // Pon aquí tu URL de API

    socket = io.io(apiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnect': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
      'reconnectionDelayMax': 2000,
      'timeout':10000
    });

    socket.connect();

    socket.onConnect((_) {
      print('Conexión establecida');
    });

    socket.onDisconnect((_) {
      print('Conexión desconectada');
    });

    socket.onConnectError((error) {
      print('Error de conexión: $error');
    });

    socket.onError((error) {
      print('Otro error: $error');
    });
  }

  void listenToEvent(String eventName, Function(dynamic) callback) {
    if (_registeredEvents.contains(eventName)) {
      // Si el evento ya está registrado, no lo registres de nuevo
      return;
    }

    socket.on(eventName, callback);
    _registeredEvents.add(eventName); // Marca el evento como registrado
  }

  void emitEvent(String eventName, dynamic data) {
    socket.emit(eventName, data);
  }

  void disconnet(){
    if(socket.connected){
      socket.disconnect();
      print("Conexión cerrada manualente");
    }
  }

  void dispose() {
    disconnet();
    //socket.dispose();
  }
}
*/
/*
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late io.Socket socket;
  final Set<String> _registeredEvents = {};

  factory SocketService() {
    return _instance;
  }

  SocketService._internal() {
    // Initialization logic
    connectToServer();
  }

  void connectToServer() {
    final apiUrl = "http://147.182.251.164:5010"; // Pon aquí tu URL de API
    //const apiUrl = "http://10.0.2.2:3000";
    socket = io.io(apiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnect': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
      'reconnectionDelayMax': 2000,
      'timeout': 10000,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Conexión establecida');
    });

    socket.onDisconnect((_) {
      print('Conexión desconectada');
    });

    socket.onConnectError((error) {
      print('Error de conexión: $error');
    });

    socket.onError((error) {
      print('Otro error: $error');
    });
  }

  void listenToEvent(String eventName, Function(dynamic) callback) {
    if (_registeredEvents.contains(eventName)) {
      // Si el evento ya está registrado, no lo registres de nuevo
      return;
    }

    socket.on(eventName, callback);
    _registeredEvents.add(eventName); // Marca el evento como registrado
  }

  void emitEvent(String eventName, dynamic data) {
    socket.emit(eventName, data);
  }

  void disconnet() {
    if (socket.connected) {
      socket.disconnect();
      print("Conexión cerrada manualmente");
    }
  }

  void dispose() {
    disconnet();
  }

  // Aquí manejamos eventos de rutas y pedidos
  void onRutaCreada(Function(dynamic) callback) {
    listenToEvent('creadoRuta', callback);
  }

  void onPedidoAnadido(Function(dynamic) callback) {
    listenToEvent('pedidoañadido', callback);
  }

  void onHolapedido(Function(dynamic) callback) {
    listenToEvent('holaPedido', callback);
  }

  void onPedidoNuevo(Function(dynamic) callback) {
    listenToEvent('initial_orders', callback);
  }

  void onPedidoNow(Function(dynamic) callback) {
    listenToEvent('almacen_1', callback);
  }

  /* void notificarClientess(Function(dynamic) callback){
    listenToEvent('depósito', callback);
  }*/
}*/

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:convert';
import 'package:http/http.dart' as http;

typedef PedidoCallback = void Function(Map<String, dynamic> data);

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late io.Socket socket;
  final Set<String> _registeredEvents = {};
  final Set<String> _processedOrderIds = {};
  String? _conductorAlmacen;
  String? _eventName;
  int? _almacenId;
  PedidoCallback? _uniqueCallback;
  Function(String)? notifyOrderTaken;
  Function(String)? onGlobalExpiration;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal() {
    connectToServer();
  }

  void connectToServer() {
    final apiUrl = "http://147.182.251.164:5010";
    socket = io.io(apiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnect': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
      'reconnectionDelayMax': 2000,
      'timeout': 10000,
    });

    socket.connect();

    socket.onConnect((_) {
      print('🔌 Conexión establecida');
      _processedOrderIds.clear();
      if (_almacenId != null) {
        _registerDriver();
      }
      if (_eventName != null) {
        _setupEventListener();
      }
    });

    _setupBaseListeners();
  }

  void _setupBaseListeners() {
    socket.onDisconnect((_) {
      print('Conexión desconectada');
    });

    socket.onConnectError((error) {
      print('Error de conexión: $error');
    });

    socket.onError((error) {
      print('Otro error: $error');
    });
  }

  Future<void> loadConductorEvent(int conductorId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://147.182.251.164:8082/apigw/v1/conductor_evento/$conductorId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        //Obtener el nombre del almacen que le corresponde a partir de la setencia SQL
        _conductorAlmacen = data['nombre'];
        //CAMBIAMOS EL FORMATO DEL EVENTO CON toLowerCase
        _eventName =
            data['nombre'].toString().toLowerCase().replaceAll(' ', '_');
        //ID DEL ALMACEN PARA EL EVENTO
        _almacenId = data['evento_id'];

        print('🏪 Almacén asignado: $_conductorAlmacen (ID: $_almacenId)');
        print('🎯 Escuchando evento: $_eventName');

        //EVENTO PRINCIPAL QUE TE BRINDA
        _registerDriver();
        _setupEventListener();
      } else {
        print('❌ Error al cargar evento del conductor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en la petición HTTP: $e');
    }
  }

  void _registerDriver() {
    if (_almacenId != null) {
      //EVENTO PARA TRAER  EL ALMACEN CORRESPONDIENTE AL CONDUCTOR.
      socket.emit('register_driver', {'almacenId': _almacenId});
      socket.emit('get_initial_orders', {'almacenId': _almacenId});
      print('👨‍💼 Conductor registrado para almacén $_almacenId');
    }
  }

  void _setupEventListener() {
    if (_eventName == null) return;

    socket.off('new_order');
    socket.off(_eventName!);
    socket.off('initial_orders');
    //EVENTO QUE TRAE LAS ORDENES INCIALES DESDE EL CONSUMIDOR DE SU COLA DE COPIA
    socket.on('initial_orders', (data) {
      print('📦 Órdenes iniciales recibidas: $data');
      if (data is List) {
        for (var order in data) {
          if (order['almacen_id'] == _almacenId) {
            _processPedido(order);
          }
        }
      }
    });

    socket.on(_eventName!, (data) {
      print('🔍 Datos recibidos en evento $_eventName: $data');
      if (data['almacen_id'] == _almacenId) {
        _processPedido(data);
      }
    });

    socket.on('order_taken', (data) {
      print('✅ Orden tomada: $data');
      if (data['id'] != null) {
        String orderId = data['id'].toString();
        _processedOrderIds.add(orderId);
        notifyOrderTaken?.call(orderId);
      }
    });

    socket.on('pedido_expirado_global', (data) {
      if (data is Map<String, dynamic> && data['pedidoId'] != null) {
        onGlobalExpiration?.call(data['pedidoId'].toString());
      }
    });
  }

  void _processPedido(dynamic data) {
    try {
      final Map<String, dynamic> pedidoData =
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data);

      print('🔍 Datos convertidos: $pedidoData');

      final orderId = pedidoData['id']?.toString();
      if (orderId == null) {
        print('❌ ID de orden es nulo');
        return;
      }

      if (pedidoData['almacen_id'] != _almacenId) {
        print('⚠️ Pedido no corresponde a este almacén');
        return;
      }

      if (!_processedOrderIds.contains(orderId)) {
        _uniqueCallback?.call(pedidoData);
        _processedOrderIds.add(orderId);
      }
    } catch (e, stackTrace) {
      print('❌ Error en el procesamiento: $e');
      print('❌ Stack Trace: $stackTrace');
    }
  }

  void setOrderTakenCallback(Function(String) callback) {
    notifyOrderTaken = callback;
  }

  void onHolapedido(PedidoCallback callback) {
    _uniqueCallback = callback;
    _processedOrderIds.clear();
    if (_eventName != null) {
      _setupEventListener();
    }
  }

  void listenToEvent(String eventName, Function(dynamic) callback) {
    if (_registeredEvents.contains(eventName)) return;
    socket.on(eventName, callback);
    _registeredEvents.add(eventName);
  }

  void emitEvent(String eventName, dynamic data) {
    socket.emit(eventName, data);
  }

  void disconnect() {
    if (socket.connected) {
      socket.disconnect();
      print("Conexión cerrada manualmente");
    }
  }

  void dispose() {
    disconnect();
  }
}
