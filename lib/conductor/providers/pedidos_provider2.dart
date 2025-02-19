import 'dart:async';
import 'dart:convert';

import 'package:app2025/conductor/config/notifications.dart';
import 'package:app2025/conductor/config/socketCentral2.dart';
import 'package:app2025/conductor/model/pedido_model.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:app2025/conductor/providers/notificacioncustom_provider.dart';
import 'package:app2025/conductor/providers/notificaciones_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

typedef PedidoCallback = void Function(Map<String, dynamic> data);
final String microUrl = dotenv.env['MICRO_URL'] ?? '';

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

  bool _llegopedido = false;
  bool get isllego => _llegopedido;
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

  void _initSocketListeners(String? nombre, int? almacenId) {
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
      if (data != null && data is Map<String, dynamic>) {
        String pedidoId = data['id']?.toString() ?? '';

        if (pedidoId.isNotEmpty) {
          print('🎯 Procesando order_taken para pedido: $pedidoId');
          _pedidoTomado(pedidoId);
        } else {
          print('⚠️ order_taken recibido sin ID de pedido válido');
        }
      } else {
        print('⚠️ Datos de order_taken inválidos: $data');
      }
    });

    _socketService.on('pedido_rotado', (data) {
      if (data != null && data is Map<String, dynamic>) {
        String pedidoId = data['pedidoId']?.toString() ?? '';
        int pedidoAlmacenId = data['almacen_id'] ?? 0;
        print("ROTACION ----------->");
        print(pedidoAlmacenId);
        // Solo procesar si el pedido pertenece al almacén actual
        if (pedidoAlmacenId == almacenId) {
          final index = _pedidos.indexWhere((p) => p.id == pedidoId);
          if (index != -1) {
            try {
              final updatedPedido = _pedidos[index].copyWith(
                emittedTime: DateTime.parse(data['emitted_time']),
                expiredTime: DateTime.parse(data['expired_time']),
                //rotationAttempts: data['rotationAttempts']
              );

              _pedidos[index] = updatedPedido;
              _setupExpirationTimer(updatedPedido);

              print('Pedido rotado actualizado - AlmacenID: $almacenId');
              print('Nueva fecha de emisión: ${updatedPedido.emittedTime}');
              print('Nueva fecha de expiración: ${updatedPedido.expiredTime}');

              notifyListeners();
            } catch (e) {
              print('Error actualizando tiempos del pedido rotado: $e');
            }
          }
        } else {
          print(
              'Pedido rotado ignorado - No pertenece a este almacén (${almacenId})');
        }
      }
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

  void rechazarPedido(String data) {
    _socketService.emit('pedido_rechazado', data);
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

    //final localExpiredTime = pedido.expiredTime.toLocal();
    //final timeUntilExpiration = localExpiredTime.difference(DateTime.now());
    final timeUntilExpiration = pedido.expiredTime.difference(DateTime.now());

    if (timeUntilExpiration.isNegative) {
      _handleExpiration(pedido.id);
    } else {
      _timers[pedido.id] = Timer(timeUntilExpiration, () {
        _handleExpiration(pedido.id);
      });
    }
  }

  void llegopedido(bool llego) {
    _llegopedido = llego;
  }

  // PRIMER ENDPOINT EN MI PROVIDER
  Future<bool> postNotificaciones(String mensaje, String tipo, String estado,
      DateTime fecha_creacion, DateTime fecha_envio, int almacen_id) async {
    try {
      SharedPreferences tokenUser = await SharedPreferences.getInstance();
      String? token = tokenUser.getString('token'); // Recupera el token

      if (token == null) {
        print("No hay token almacenado");
        return false;
      }

      String fechaCreacionFormatted =
          DateFormat('yyyy-MM-dd').format(fecha_creacion);
      String fechaEnvioFormatted = DateFormat('yyyy-MM-dd').format(fecha_envio);
      var res = await http.post(Uri.parse('$microUrl/notificacion'),
          headers: {
            "Content-type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode({
            "mensaje": mensaje,
            "tipo": tipo,
            "estado": estado,
            "fecha_creacion": fechaCreacionFormatted,
            "fecha_envio": fechaEnvioFormatted,
            "almacen_id": almacen_id
          }));
      print("....RESSSS");
      print(res.statusCode);
      if (res.statusCode == 201) {
        return true; // Devuelve true si se creó correctamente
      } else {
        return false; // Devuelve false si el código no es 201
      }
    } catch (e) {
      throw Exception("Error post $e");
    }
  }

  Future<bool> addPedido(BuildContext context, Map<String, dynamic> pedidoData,
      bool showNotification) async {
    try {
      final pedido = Pedido.fromMap(pedidoData);
      print('Adding pedido: ${pedido.id}');

      // Verificar si el pedido ya existe o está aceptado
      if (_pedidos.any((p) => p.id == pedido.id) ||
          _pedidosAceptados.contains(pedido.id)) {
        print('Pedido already exists or is accepted: ${pedido.id}');
        return true;
      }
      print("....Fecha obetina");
      print(DateFormat('yyyy-MM-dd').format(DateTime.now()));
      String fechaC = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc());
      bool postexitoso = await postNotificaciones(
          pedido.clienteName,
          pedido.estado,
          pedido.estado,
          DateTime.parse(fechaC),
          pedido.expiredTime,
          pedido.almacenId);
      print("POST EXITOS");
      print(postexitoso);
      if (postexitoso) {
        print("Exitoso POST");
      }

      // AQUÍ SE MUESTRA LA NOTIFICACIÓN
      llegopedido(showNotification);

      _pedidos.add(pedido);
      _setupExpirationTimer(pedido);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding pedido: $e');
      return false;
    }
  }

  Future<void> _processPedidoData(
      BuildContext context, Map<String, dynamic> data) async {
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

      /*NotificationsService().showOrderNotification(
        id: 29999,
        title: 'Pedido #765433',
        body: 'El pedido ha sido anulado.',
        payload: 'order',
      );*/

      if (!_pedidosAceptados.contains(pedido.id)) {
        await addPedido(context, data, true);
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

  Future<void> aceptarPedido(BuildContext context, String pedidoId,
      {Map<String, dynamic>? pedidoData}) async {
    try {
      print("INGRESANDO AL PROVIDER DE PEDIDO---->> METODO ACEPTAR");
      print('Accepting pedido: $pedidoId');

      // Si no está en la lista de pedidos pero tenemos los datos, lo agregamos primero
      if (pedidoData != null && !_pedidos.any((p) => p.id == pedidoId)) {
        await _processPedidoData(context, pedidoData);
      }

      final index = _pedidos.indexWhere((p) => p.id == pedidoId);
      print(index);

      if (index != -1) {
        final pedido = _pedidos[index];

        _pedidosAceptadosList.add(pedido);
        _pedidosAceptados.add(pedidoId);

        await updatePedidoEstado(pedidoId, 'aceptado');
        //_socketService.emitTakeOrder(pedidoId, pedido.almacenId);
        emitTakeOrder(pedidoId, pedido.almacenId);
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
          // Rechaza un pedido
          rechazarPedido(jsonString);
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

  //IGNORAR PEDIDO
  void ignorarPedido(Map<String, dynamic> pedidoData) {
    try {
      // Emitir el evento al socket
      emitPedidoExpirado(pedidoData);
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

  //PEDIDO TOMADO LOGICA
  void _pedidoTomado(String pedidoId) {
    try {
      print('🔄 Manejando pedido tomado: $pedidoId');

      bool pedidoExistente = _pedidos.any((p) => p.id == pedidoId);
      print('Pedido existe en lista: $pedidoExistente');

      if (pedidoExistente) {
        _pedidos.removeWhere((p) => p.id == pedidoId);

        if (_timers.containsKey(pedidoId)) {
          print('Cancelando timer para pedido: $pedidoId');
          _timers[pedidoId]?.cancel();
          _timers.remove(pedidoId);
        }

        print('Notificando cambios en UI...');
        notifyListeners();

        print('🗑️ Pedido $pedidoId removido de la vista');
      } else {
        print('ℹ️ Pedido $pedidoId no encontrado en la lista local');
      }
    } catch (e) {
      print('❌ Error al manejar pedido tomado: $e');
    }
  }

  //PEDIDO TOMADO

  List<Pedido> getActivePedidos() {
    print("PEDIDOS ACTUAL----------------------------------------->>>>");
    print("Cantidad de pedidos: ${_pedidos.length}");

    if (_pedidos.isNotEmpty) {
      print("Estado del primer pedido: ${_pedidos[0].estado}");
      print("Tiempo de emisión: ${_pedidos[0].emittedTime}");
      print("Tiempo de expiración: ${_pedidos[0].expiredTime}");
      print("¿Está aceptado?: ${_pedidosAceptados.contains(_pedidos[0].id)}");
      print("ID del primer pedido: ${_pedidos[0].id}");
    } else {
      print("La lista de pedidos está vacía.");
    }

    print("Cantidad de pedidos aceptados: ${_pedidosAceptados.length}");
    print("Pedidos aceptados: $_pedidosAceptados");

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
  void conectarSocket(BuildContext context, int? almacenId, String? nombre) {
    print("🔌 Conectando manualmente al socket...");
    _socketService.connect();
    _initSocketListeners(nombre, almacenId);
    onHolapedido((data) {
      print("📦 Nuevo pedido recibido en el Provider: $data");
      _processPedidoData(context, data);
    });
    _initialEmit(almacenId);
  }
}
