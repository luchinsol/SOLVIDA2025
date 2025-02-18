import 'package:flutter/material.dart';

class ConductorConnectionProvider extends ChangeNotifier {
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void connect() {
    _isConnected = true;
    notifyListeners();
  }

  void disconnect() {
    _isConnected = false;
    notifyListeners();
  }

  void updateConnect(bool conexion) {
    _isConnected = conexion;
    notifyListeners();
  }
}
