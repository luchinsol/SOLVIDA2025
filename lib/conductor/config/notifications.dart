import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class NotificationsService {
  static final NotificationsService _instance =
      NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  bool _isSilenced = false;

  bool _isInitialized = false;
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

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
    print("Response type: ${response.notificationResponseType}");
    switch (actionId) {
      case 'accept_action':
        print("La acción 'Aceptar' fue seleccionada");
        // Lógica para aceptar
        break;
      case 'deny_action':
        print("La acción 'Denegar' fue seleccionada");
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
      'daily_channel',
      'Action Notifications',
      channelDescription: 'Notificaciones con acciones',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      setAsGroupSummary: false,
      actions: [
        AndroidNotificationAction(
            'accept_action', // ID de la acción
            'Aceptar', // Título del botón
            showsUserInterface: true),
        AndroidNotificationAction(
            'deny_action', // ID de la acción
            'Denegar', // Título del botón
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
