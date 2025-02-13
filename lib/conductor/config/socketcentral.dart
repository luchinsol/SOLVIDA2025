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

import 'dart:async';
import 'dart:io';

import 'package:app2025/conductor/config/notifications.dart';
import 'package:app2025/conductor/model/cliente_model.dart';
import 'package:app2025/conductor/model/pedido_model.dart';
import 'package:app2025/conductor/model/producto_model.dart';
import 'package:app2025/conductor/model/promocion_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:convert';
import 'package:http/http.dart' as http;

typedef PedidoCallback = void Function(Map<String, dynamic> data);
typedef ConnectionStateCallback = void Function(bool isConnected);

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

  ConnectionStateCallback? _connectionStateCallback;

  final _pedidosStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get pedidosStream =>
      _pedidosStreamController.stream;
  bool _isConnected = false;
  bool _isRegistered = false;
  bool _isListening = false;
  final List<String> _eventLog = [];

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  factory SocketService() {
    print('🚀 [Socket] Initializing SocketService - ${DateTime.now()}');
    return _instance;
  }

  SocketService._internal() {
    print('🚀 Initializing SocketService');
    _initializeSocket();
  }

  void _logEvent(String event) {
    final timestamp = DateTime.now();
    final logMessage = '⏱️ [$timestamp] $event';
    print(logMessage);
    _eventLog.add(logMessage);
  }

  void _initializeSocket() {
    //"http://147.182.251.164:5010"
    final apiUrl = "http://10.0.2.2:5010";
    _logEvent('[Socket] Connecting to: $apiUrl');

    socket = io.io(apiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
      'reconnectionDelayMax': 5000,
      'timeout': 20000,
    });

    _setupBaseListeners();
  }

  void _setupBaseListeners() {
    socket.onConnect((_) {
      _logEvent('[Socket] Connected successfully');
      _isConnected = true;
      if (_almacenId != null && !_isRegistered) {
        _registerDriver();
        _setupEventListener();
      }
    });

    socket.onAny((event, data) {
      _logEvent('[Socket] Received event: $event with data: $data');
      // Procesar eventos específicos
      if (event == 'almacen_1' || event == 'almacen_3') {
        if (_uniqueCallback != null) {
          _uniqueCallback!(data);
        }
      }
    });

    socket.onDisconnect((_) {
      _logEvent('[Socket] Disconnected');
      _isConnected = false;
      _isRegistered = false;
      _isListening = false;
    });
  }

//1. CARGAR EVENTOS DEL CONDUCTOR
  Future<void> loadConductorEvent(int conductorId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/apigw/v1/conductor_evento/$conductorId'),
      );
//'http://147.182.251.164:8082/apigw/v1/conductor_evento/$conductorId'
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _conductorAlmacen = data['nombre'];
        _eventName = 'almacen_${data['evento_id']}';
        _almacenId = data['evento_id'];

        if (socket.connected && !_isRegistered) {
          await _registerDriver();
          await _setupEventListener();
        }
      }
    } catch (e) {
      _logEvent('[Conductor] Error: $e');
      rethrow;
    }
  }

//2. OBTENER EVENTO DE ALMACEN
  Future<void> _registerDriver() async {
    if (_almacenId == null) return;

    socket.emit('register_driver', {'almacenId': _almacenId});
    _isRegistered = true;

    await Future.delayed(const Duration(milliseconds: 500));
    socket.emit('get_initial_orders', {'almacenId': _almacenId});
  }

  //3. ESCUCHA DE EVENTO
  Future<void> _setupEventListener() async {
    if (_eventName == null || _isListening) return;

    socket.on(_eventName!, (data) {
      _logEvent('[Events] Received order on $_eventName: $data');
      if (_uniqueCallback != null) {
        _uniqueCallback!(data);
      }
    });

    socket.on('initial_orders', (data) {
      _logEvent('[Events] Received initial orders: $data');
      if (data is List) {
        for (var order in data) {
          if (_uniqueCallback != null) {
            _uniqueCallback!(order);
          }
        }
      }
    });

    _isListening = true;
  }

  void _processPedido(dynamic data) {
    try {
      if (data == null) {
        _logEvent('[Process] Received null data');
        return;
      }

      final Map<String, dynamic> pedidoData =
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data);

      final orderId = pedidoData['id']?.toString();
      if (orderId == null) {
        _logEvent('[Process] Order ID is null');
        return;
      }

      _logEvent('[Process] Processing order: $orderId');
/*
      NotificationsService.showOrderNotification(
        id: int.parse(orderId), // Convert string ID to int
        title: 'Nuevo Pedido #${orderId}',
        body:
            'Total: \$${pedidoData['total']?.toString() ?? '0.00'}\nCliente: ${pedidoData['Cliente']?['nombre'] ?? 'No especificado'}',
        payload:
            json.encode(pedidoData), // Pass the entire order data as payload
      );*/
      _uniqueCallback?.call(pedidoData);
      _logEvent('[Process] Order processed: $orderId');
    } catch (e, stackTrace) {
      _logEvent('[Process] Error: $e');
      _logEvent('[Process] Stack trace: $stackTrace');
    }
  }

  void setOrderTakenCallback(Function(String) callback) {
    notifyOrderTaken = callback;
  }

  void onHolapedido(PedidoCallback callback) {
    _uniqueCallback = callback;
    _logEvent('[Callback] Pedido callback registered');
  }

  List<String> getEventLogs() {
    return List.unmodifiable(_eventLog);
  }

  void listenToEvent(String eventName, Function(dynamic) callback) {
    if (_registeredEvents.contains(eventName)) return;
    socket.on(eventName, callback);
    _registeredEvents.add(eventName);
  }

  void emitEvent(String eventName, dynamic data) {
    socket.emit(eventName, data);
  }

  void emitPedidoExpirado(Map<String, dynamic> pedidoData) {
    try {
      final pendingStores = pedidoData['AlmacenesPendientes'] ?? [];
      // Ensure the data is converted to a standard JSON format
      if (pendingStores.isNotEmpty) {
        final jsonData = {
          "id": pedidoData['id'],
          "ubicacion": pedidoData['ubicacion'],
          "detalles": {
            "promociones":
                (pedidoData['detalles']['promociones'] as List).map((promo) {
              return {
                "id": promo['id'],
                "nombre": promo['nombre'],
                "descripcion": promo['descripcion'],
                "foto": promo['foto'],
                "valoracion": promo['valoracion'],
                "categoria": promo['categoria'],
                "precio": promo['precio'],
                "descuento": promo['descuento'],
                "total": promo['total'],
                "cantidad": promo['cantidad'],
                "subtotal": promo['subtotal'],
                "productos": (promo['productos'] as List).map((prod) {
                  return {
                    "id": prod['id'],
                    "nombre": prod['nombre'],
                    "descripcion": prod['descripcion'],
                    "foto": prod['foto'],
                    "valoracion": prod['valoracion'],
                    "categoria": prod['categoria'],
                    "precio": prod['precio'],
                    "descuento": prod['descuento'],
                    "total": prod['total'],
                    "cantidad": prod['cantidad'],
                    "cantidadProductos": prod['cantidadProductos']
                  };
                }).toList()
              };
            }).toList(),
            "productos":
                (pedidoData['detalles']['productos'] as List).map((prod) {
              return {
                "id": prod['id'],
                "nombre": prod['nombre'],
                "descripcion": prod['descripcion'],
                "foto": prod['foto'],
                "valoracion": prod['valoracion'],
                "categoria": prod['categoria'],
                "precio": prod['precio'],
                "descuento": prod['descuento'],
                "subtotal": prod['subtotal'],
                "cantidad": prod['cantidad'],
                "total": prod['total']
              };
            }).toList()
          },
          "region_id": pedidoData['region_id'] ?? 1,
          "almacen_id": pedidoData['almacen_id'] ?? 3,
          "subtotal": pedidoData['subtotal'] ?? 0,
          "descuento": pedidoData['descuento'] ?? 0,
          "total": pedidoData['total'] ?? 0,
          "AlmacenesPendientes": pedidoData['AlmacenesPendientes'] ?? [],
          "Cliente": pedidoData["Cliente"],
          "emitted_time": DateTime.now().toIso8601String(),
          "expired_time":
              DateTime.now().add(Duration(minutes: 1)).toIso8601String(),
          'is_rotation': true,
          'accepted': false,
          'rotation_attempts': (pedidoData['rotation_attempts'] ?? 0) + 1,
          'pedidoinfo': pedidoData['pedidoinfo'],
        };

        // Convert to JSON string
        final jsonString = jsonEncode(jsonData);

        if (!_processedOrderIds.contains(pedidoData['id'].toString())) {
          socket.emit('pedido_rechazado', jsonString);
          _processedOrderIds.add(pedidoData['id'].toString());
          print('🚀 Pedido Expirado Emitido: $jsonString');
          if (_uniqueCallback != null) {
            _uniqueCallback!({'id': pedidoData['id'], 'estado': 'expirado'});
          }
        }
      }
    } catch (e) {
      print('❌ Error al procesar pedido expirado: $e');
    }
  }

  void emitTakeOrder(String orderId, int almacenId) {
    try {
      if (!_processedOrderIds.contains(orderId)) {
        final takeOrderData = {'orderId': orderId, 'almacenId': almacenId};
        print("---------------------------> SOCKETTTTTTT");

        socket.emit('take_order', takeOrderData);
        _processedOrderIds.add(orderId);

        print('🚀 Pedido Tomado Emitido: $takeOrderData');
      }
    } catch (e) {
      print('❌ Error al emitir take_order: $e');
    }

    // Listen for order_taken event to confirm deletion
    socket.on('order_taken', (data) {
      print('✅ Orden tomada confirmada: $data');
    });
  }

  void onConnectionStateChange(ConnectionStateCallback callback) {
    _connectionStateCallback = callback;
    // Llamar inmediatamente con el estado actual
    callback(_isConnected);
  }

  void setupOrderTakenListener(Function(String) onOrderTaken) {
    socket.on('order_taken', (data) {
      if (data['id'] != null) {
        onOrderTaken(data['id'].toString());
      }
    });
  }

  void disconnect() {
    if (socket.connected) {
      socket.disconnect();
      print("Conexión cerrada manualmente");
    }
    if (_eventName != null) {
      socket.off(_eventName!);
    }
    _processedOrderIds.clear();
  }

  void dispose() {
    _pedidosStreamController.close();
    disconnect();
  }
}
