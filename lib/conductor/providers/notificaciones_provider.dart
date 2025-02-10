import 'package:app2025/conductor/model/notificaciones_model.dart';
import 'package:flutter/material.dart';

class NotificacionesProvider extends ChangeNotifier {
  NotificacionesModel? _notify;

  NotificacionesModel? get notify => _notify;

  void updateNotificacion(NotificacionesModel newNotify) {
    _notify = newNotify;
    notifyListeners();
  }
}
