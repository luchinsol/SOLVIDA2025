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

      _socket = IO.io(
        microUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(5000)
            .setTimeout(10000)
            .build(),
      );

      _socket?.onConnect((_) => print('✅ Conectado a Socket.IO'));
      _socket?.onDisconnect((_) => print('❌ Desconectado de Socket.IO'));
      _socket?.onConnectError((error) => print('⚠️ Error de conexión: $error'));
      _socket
          ?.onError((error) => print('🚨 Error general en el socket: $error'));
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

  void onDisconnect(Function callback) {
    _socket?.onDisconnect((_) => callback());
  }

  void emit(String eventName, dynamic data) {
    print("📤 Emitiendo evento: $eventName con data: $data");
    _socket?.emit(eventName, data);
  }
}
