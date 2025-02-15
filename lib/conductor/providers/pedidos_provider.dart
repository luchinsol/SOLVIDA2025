import 'dart:async';
import 'dart:convert';
import 'package:app2025/conductor/config/notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app2025/conductor/model/pedido_model.dart';
import 'package:app2025/conductor/config/socketcentral.dart';

class PedidosProvider extends ChangeNotifier {
  final List<Pedido> _pedidos = [];
  // Nueva lista para pedidos aceptados
  final List<Pedido> _pedidosAceptadosList = [];
  final Map<String, Timer> _timers = {};
  final SocketService _socketService = SocketService(); //c
  final Map<String, List<Map<String, dynamic>>> _orderHistory = {};
  final Set<String> _globallyExpiredOrders = {};
  final Map<String, List<Map<String, dynamic>>> _orderRotations = {};

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isConnected = false;

  List<Pedido> get pedidos => List.unmodifiable(_pedidos);

  List<Pedido> get pedidosAceptados => List.unmodifiable(_pedidosAceptadosList);

  Pedido? get ultimoPedidoAceptado =>
      _pedidosAceptadosList.isNotEmpty ? _pedidosAceptadosList.last : null;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;

  final Set<String> _pedidosAceptados = {};

  final NotificationsService _notificationsService = NotificationsService();

  void _log(String message) {
    print('📱 [Provider] $message');
  }

  Pedido? getPedidoAceptadoById(String id) {
    try {
      return _pedidosAceptadosList.firstWhere((pedido) => pedido.id == id);
    } catch (e) {
      return null;
    }
  }

  PedidosProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    _isLoading = true;
    notifyListeners();

    try {
      _initializeSocket();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // El Provider utiliza SocketService para la comunicación en tiempo real con el servidor
// Se utiliza este enfoque porque:
//   1. Separa la lógica de red (SocketService) de la gestión de estado (Provider)
//   2. Permite reutilizar la conexión socket en múltiples partes de la aplicación
//   3. Facilita el manejo de eventos asíncronos y su transformación a estados de UI

// El método _initializeSocket configura la escucha de eventos
// Se usa para recibir pedidos nuevos sin tener que hacer polling continuo

  void _initializeSocket() {
    _socketService.onHolapedido((data) {
      print('📱 [Provider] Received pedido data: $data');
      _processPedidoData(data);
    });
  }

  Future<void> _handleReconnection() async {
    try {
      await syncWithServer();
    } catch (e) {
      debugPrint('Error during reconnection sync: $e');
    }
  }

  Future<void> loadInitialData(int conductorId) async {
    if (_isInitialized) {
      print('📱 [Provider] Already initialized');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _socketService.loadConductorEvent(conductorId);
      _isInitialized = true;
    } catch (e) {
      print('📱 [Provider] Error loading initial data: $e');
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPedido(
      Map<String, dynamic> pedidoData, bool showNotification) async {
    try {
      final pedido = Pedido.fromMap(pedidoData);
      _log('Adding pedido: ${pedido.id}');

      // Verificar si el pedido ya existe o está aceptado
      if (_pedidos.any((p) => p.id == pedido.id) ||
          _pedidosAceptados.contains(pedido.id)) {
        _log('Pedido already exists or is accepted: ${pedido.id}');
        return true;
      }

      if (showNotification) {
        await _notificationsService.showOrderNotification(
          id: int.parse(pedido.id),
          title: 'Nuevo Pedido #${pedido.id}',
          body:
              'Total: \$${pedido.total.toStringAsFixed(2)}\nCliente: ${pedido.cliente?.nombre ?? 'No especificado'}',
          payload: json.encode(pedidoData),
        );
      }

      _pedidos.add(pedido);
      _setupExpirationTimer(pedido);
      notifyListeners();
      return true;
    } catch (e) {
      _log('Error adding pedido: $e');
      return false;
    }
  }

  // Manejar pedido tomado
  void _handlePedidoTomado(String pedidoId) {
    _pedidos.removeWhere((p) => p.id.toString() == pedidoId);
    notifyListeners();
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
  // Método para manejar la expiración global de pedidos

  void handleGlobalExpiration(String pedidoId) async {
    _globallyExpiredOrders.add(pedidoId);
    await updatePedidoEstado(pedidoId, 'expirado');
    _timers[pedidoId]?.cancel();
    _timers.remove(pedidoId);
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

  //1. ALMACENAR EL PEDIDO PROVIDER
  // ESTE ES EL METODO QUE AGREGA MIS PEDIDOS
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
      _log('Processing pedido: ${pedido.id}');

      if (!_pedidosAceptados.contains(pedido.id)) {
        await addPedido(data, true);
      }
    } catch (e) {
      _log('Error processing pedido data: $e');
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
      _log('Error handling expiration: $e');
    }
  }

  // El método aceptarPedido usa el socket para confirmar aceptación
// Esto permite que otros conductores sean notificados inmediatamente
// cuando un pedido ya no está disponible
  Future<void> aceptarPedido(String pedidoId,
      {Map<String, dynamic>? pedidoData}) async {
    try {
      print("INGRESANDO AL PROVIDER DE PEDIDO---->> METODO ACEPTAR");
      _log('Accepting pedido: $pedidoId');

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
        _socketService.emitTakeOrder(pedidoId, pedido.almacenId);

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
        _log('Pedido accepted successfully: $pedidoId');
      }
    } catch (e) {
      _log('Error accepting pedido: $e');
      _pedidosAceptados.remove(pedidoId);
      //await updatePedidoEstado(pedidoId, 'pendiente');
      rethrow;
    }
  }

  // El método ignorarPedido utiliza el socket para notificar rechazo
// Se hace así para garantizar que tanto el estado local como el servidor
// estén sincronizados cuando un conductor rechaza un pedido

  void ignorarPedido(Map<String, dynamic> pedidoData) {
    try {
      // Emitir el evento al socket
      _socketService.emitPedidoExpirado(pedidoData);

      // Remover el pedido de la lista local
      _pedidos.removeWhere((p) => p.id == pedidoData['id']);

      // Limpiar recursos asociados
      _timers[pedidoData['id']]?.cancel();
      _timers.remove(pedidoData['id']);

      // Notificar a los listeners para actualizar la UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error ignorando pedido: $e');
    }
  }
/*
  void _handleOrderTaken(String pedidoId) {
    _timers[pedidoId]?.cancel();
    _timers.remove(pedidoId);
    _pedidos.removeWhere((pedido) => pedido.id == pedidoId);
    _orderHistory.remove(pedidoId);
    notifyListeners();
  }
*/
/*
  List<Pedido> getActivePedidos() {
    print('🔍 Checking active pedidos');
    var activePedidos = _pedidos.toList();
    print('🚨 Active Pedidos count: ${activePedidos.length}');
    return activePedidos;
  }*/

  Future<void> syncWithServer() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Implementar lógica de sincronización con el servidor
      // Por ejemplo, obtener estados actualizados de pedidos

      //await _loadPedidosFromDatabase();
    } catch (e) {
      debugPrint('Error syncing with server: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Logica del BUCLE
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
        _log('Pedido entregado exitosamente: $pedidoId');
        print("Saliendo de aqui -------->");
      } else {
        _log('Pedido no encontrado en la lista de aceptados: $pedidoId');
      }
    } catch (error) {
      print("Pedido no se Entrego ${error}");
    }
  }

  double getTotalValueOfActivePedidos() {
    return getActivePedidos().fold(0, (sum, pedido) => sum + pedido.total);
  }

  @override
  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _pedidos.clear();
    _orderRotations.clear();
    _globallyExpiredOrders.clear();
    _socketService.dispose();
    super.dispose();
  }
}


/*
El uso de métodos Socket en el Provider sigue un patrón donde:

El SocketService maneja la comunicación de bajo nivel
El Provider traduce eventos de red en cambios de estado de la aplicación
Los cambios de estado en la UI se propagan al servidor a través del SocketService

Este enfoque es adecuado, pero podría mejorarse con una gestión más robusta de errores y reconexiones para evitar la pérdida de eventos.
 */