import 'package:app2025/conductor/providers/pedidos_provider2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NOTIFICACIONES PARA MOSTRARSE COMO ALERT

class NotificationProvider extends ChangeNotifier {
  String? _mensaje;

  String? get mensaje => _mensaje;

  // Notificaciones se inician en el constructor
  NotificationProvider(BuildContext context) {
    _loadMensaje();

    // Escuchar cambios en ProviderA
    Provider.of<PedidosProvider2>(context, listen: false).addListener(() async {
      await _loadMensaje(); // Cargar el nuevo mensaje
      notifyListeners(); // Notificar cambios
    });
  }

  Future<void> _loadMensaje() async {
    SharedPreferences pedidoJson = await SharedPreferences.getInstance();
    _mensaje = pedidoJson.getString('pedidoJson');
  }

  void setMensaje(String nuevoMensaje) {
    _mensaje = nuevoMensaje;

    // Evitar actualizar el estado durante el build
    Future.microtask(() {
      notifyListeners();
    });
  }

  void clearMensaje() async {
    _mensaje = null;
    SharedPreferences pedidoJson = await SharedPreferences.getInstance();
    pedidoJson.clear();

    Future.microtask(() {
      notifyListeners();
    });
  }
}
