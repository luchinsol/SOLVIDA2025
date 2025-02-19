import 'package:flutter/material.dart';
import 'package:app2025/conductor/model/notificaciones_model.dart';

class NotificacionesInicioProvider extends ChangeNotifier {
  List<NotificacionesModel> _notificaciones = [];

  List<NotificacionesModel> get notificaciones => _notificaciones;

  void updateNotificaciones(List<NotificacionesModel> nuevasNotificaciones) {
    _notificaciones = nuevasNotificaciones;
    notifyListeners(); // Notifica a la UI para que se actualice
  }
}
