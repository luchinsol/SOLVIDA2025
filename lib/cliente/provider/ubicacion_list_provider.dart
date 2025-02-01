import 'package:app2025/cliente/models/ubicacion_list_model.dart';
import 'package:app2025/cliente/models/ubicacion_model.dart';

import 'package:flutter/material.dart';

class UbicacionListProvider extends ChangeNotifier {
  // CREAS UNA INSTANCIA DE LA CLASE
  UbicacionListaModel? _ubicacion;

  // OBTIENES EL USUARIO
  UbicacionListaModel? get ubicacion => _ubicacion;

  // ACTUALIZAS EL VALOR DEL OBJETO Y NOTIFICAMOS A LOS RECEPTORES
  void updateUbicacionList(UbicacionListaModel newUbicacion) {
    _ubicacion = newUbicacion;
    notifyListeners();
  }

  // Agregar una nueva ubicación
  void addUbicacion(UbicacionModel nuevaUbicacion) {
    _ubicacion?.listaUbisObjeto.add(nuevaUbicacion);
    _ubicacion?.listaUbisString.add(nuevaUbicacion.direccion);
    notifyListeners(); // Notificar a los receptores que hay una nueva ubicación
  }
}
