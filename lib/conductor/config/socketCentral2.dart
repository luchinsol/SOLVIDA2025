import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService2 {
  // 🔥 PATRÓN SINGLETON
  static final SocketService2 _instance = SocketService2._internal();
  factory SocketService2() => _instance;

  IO.Socket? _socket;

  // 🔒 Constructor privado
  SocketService2._internal();

  // MÉTODOS GENERALES
  void connect() {
    if (_socket == null) {
      String microUrl = dotenv.env['MICRO_PEDIDO'] ?? '';
      print("🌐 Conectando a: $microUrl");

      /* _socket = IO.io(
        microUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(5000)
            .setTimeout(10000)
            .build(),
      );*/

      _socket = IO.io(microUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnect': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 2000,
        'reconnectionDelayMax': 2000,
        'timeout': 10000
      });

      _socket?.onConnect((_) {
        print("CONECTADO A SOCKET.IO");
        _socket?.on('order_taken', (data) {
          print("*****************************Orden Tomadada");
        });
        _reRegistro();
      });
      _socket?.onDisconnect((_) => print('❌ Desconectado de Socket.IO'));
      _socket?.onConnectError((error) => print('⚠️ Error de conexión: $error'));
      _socket
          ?.onError((error) => print('🚨 Error general en el socket: $error'));
      _socket?.on("order_taken", (data) {
        print(' IMPRIMIENDO DATA $data');
      });
    }

    _socket?.connect();
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void reconnect() {
    _socket?.connect();
  }

  void on(String eventName, Function(dynamic) callback) {
    _socket?.on(eventName, (data) => callback(data));
  }

  void _reRegistro() {
    _socket?.on('order_taken', (data) {
      print("*****************************Orden Tomadada");
    });
  }

  void off(String eventName) {
    _socket?.off(eventName);
  }

  void onDisconnect(Function callback) {
    _socket?.onDisconnect((_) => callback());
  }

  void emit(String eventName, dynamic data) {
    print("📤 Emitiendo evento: $eventName con data: $data");
    _socket?.emit(eventName, data);
  }
}
