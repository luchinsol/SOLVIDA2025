import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

String microUrl = dotenv.env['MICRO_PEDIDO'] ?? '';

class SocketService2 {
  late IO.Socket socket;

  SocketService2() {
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(microUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnect': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
      'reconnectionDelayMax': 2000,
      'timeout': 10000,
    });

    // Eventos básicos
    socket.onConnect((_) {
      print('Conectado al servidor de Socket.IO');
      print('ESTOY AQUIIIIIII');
      // Importante: Re-registrar al conductor al reconectar
      socket.emit("register_driver", {'almacenId': 3});

      socket.on('initial_orders', (data) {
        // print("INITIAL ORDER.---");
        if (data is List) {
          print("Es una lista 665");
        }
      });
    });

    socket.onDisconnect((_) {
      print('Desconectado del servidor');
    });

    socket.onError((error) {
      print('Error de conexión: $error');
    });
  }

  // Método para escuchar un evento específico
  void on(String eventName, Function(dynamic) callback) {
    socket.on(eventName, (data) => callback(data));
  }

  // Método para emitir un evento
  void emit(String eventName, dynamic data) {
    socket.emit(eventName, data);
  }

  // Método para desconectar el socket
  void disconnect() {
    socket.disconnect();
  }

  // Método para liberar recursos
  void dispose() {
    socket.dispose();
  }
}
