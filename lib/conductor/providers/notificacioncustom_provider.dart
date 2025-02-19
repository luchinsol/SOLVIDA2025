import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  String? _mensaje;

  String? get mensaje => _mensaje;

  void setMensaje(String nuevoMensaje) {
    _mensaje = nuevoMensaje;

    // Evitar actualizar el estado durante el build
    Future.microtask(() {
      notifyListeners();
    });
  }

  void clearMensaje() {
    _mensaje = null;

    Future.microtask(() {
      notifyListeners();
    });
  }
}
