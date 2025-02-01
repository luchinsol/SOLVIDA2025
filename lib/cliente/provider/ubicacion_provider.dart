import 'package:app2025/cliente/models/ubicacion_model.dart';
import 'package:flutter/material.dart';

class UbicacionProvider extends ChangeNotifier {
  // CREAS UNA INSTANCIA DE LA CLASE
  UbicacionModel? _ubicacion;

  // OBTIENES EL USUARIO
  UbicacionModel? get ubicacion => _ubicacion;

  // ACTUALIZAS EL VALOR DEL OBJETO Y NOTIFICAMOS A LOS RECEPTORES
  void updateUbicacion(UbicacionModel newUbicacion) {
    _ubicacion = newUbicacion;
    notifyListeners();
  }
}
