import 'package:app2025/conductor/model/almacenes_model.dart';
import 'package:flutter/material.dart';

class AlmacenProvider extends ChangeNotifier {
  AlmacenModel? _almacen;

  AlmacenModel? get almacen => _almacen;

  void updateAlmacen(AlmacenModel newAlmacen) {
    _almacen = newAlmacen;
    notifyListeners();
  }
}
