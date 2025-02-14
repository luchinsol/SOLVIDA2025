import 'dart:convert';

import 'package:app2025/conductor/providers/pedidos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class NotificationsService {
  //ESTA VARIABLE SE AGREGO PARA OBTENER EL CONTEXTO DEBIDO A QUE NECESITAMOS ESTO PARA PODER AGREGAR A LA LSITA DE PEDIDOS ACEPTADOS
  late BuildContext _context;
  // Método para inicializar el contexto
  void initContext(BuildContext context) {
    _context = context;
  }

  late PedidosProvider _pedidosProvider;

  static final NotificationsService _instance =
      NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  bool _isSilenced = false;

  bool _isInitialized = false;
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  //CAMBIOS
  void initProvider(PedidosProvider provider) {
    _pedidosProvider = provider;
  }

  // Solicitar permisos de notificación
  Future<void> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        await Permission.notification.request();
      }
    }
  }

  // Inicialización de las notificaciones
  Future<void> initNotification() async {
    if (_isInitialized) return;

    // Configuración para Android
    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_notification');

    // Configuración para iOS
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuración general
    final initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    try {
      // Inicializar las notificaciones y manejar respuestas
      await notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onNotificationResponse,
      );
      _isInitialized = true;
    } catch (e) {
      print('Error al inicializar las notificaciones: $e');
    }
  }

  // Manejo de respuestas a las acciones de la notificación
  void onNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;
    if (payload == null) return;
    print("Response type: ${response.notificationResponseType}");
    final pedidoData = json.decode(payload);
    print("PEDIDO DATA NOTIFIACACIONES.------------------>${pedidoData}");
    final pedidoId = pedidoData['id']?.toString();
    print("PEDIDO DATA NOTIFIACACIONES.------------------>${pedidoId}");
    if (pedidoId == null) return;
    switch (actionId) {
      case 'accept_order':
        print("La acción 'Aceptar' fue seleccionada");
        // Lógica para aceptar
        // Obtener la instancia de provider ya no una diferente sino una que contenga la misma
        _pedidosProvider.aceptarPedido(pedidoId, pedidoData: pedidoData);
        print(
            "ULTIMO PEDIDO ID -------->>>>>>${_pedidosProvider.ultimoPedidoAceptado?.id}");
        break;
      case 'view_order':
        print("Acción 'Ver' seleccionada para pedido: $pedidoId");
        // Lógica para denegar
        break;
      default:
        print("Otra acción seleccionada: $actionId");
        // Acción no manejada
        break;
    }
  }

  void silenceNotifications(bool silence) {
    _isSilenced = silence;
  }

  // Manejo de clics en las notificaciones
  void onSelectNotification(String? payload) async {
    if (payload != null) {
      print('Notification payload: $payload');
      // Aquí puedes manejar la lógica al hacer clic en una acción
    }
  }

  // Detalles de la notificación con acciones
  NotificationDetails notificationDetailsWithActions() {
    final androidChannel = AndroidNotificationDetails(
      'orders_channel',
      'Order Notifications',
      channelDescription: 'Notificaciones de pedidos nuevos',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      setAsGroupSummary: false,
      actions: [
        AndroidNotificationAction(
            'accept_order', // ID de la acción
            'Aceptar', // Título del botón
            showsUserInterface: true),
        AndroidNotificationAction(
            'view_order', // ID de la acción
            'Ver', // Título del botón
            showsUserInterface: true),
      ],
    );

    final iOSChannel = DarwinNotificationDetails();
    return NotificationDetails(android: androidChannel, iOS: iOSChannel);
  }

  // Mostrar una notificación con acción
  Future<void> showOrderNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!_isInitialized) await initNotification();
    try {
      await notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetailsWithActions(),
        payload: payload, // Verifica que el payload se pase correctamente
      );
    } catch (e) {
      print('Error al mostrar la notificación: $e');
    }
  }
}
