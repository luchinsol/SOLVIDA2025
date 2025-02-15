import 'package:app2025/conductor/model/conductor_model.dart';
import 'package:flutter/material.dart';

class ConductorProvider extends ChangeNotifier {
  ConductorModel? _conductor;

  ConductorModel? get conductor => _conductor;

  void updateConductor(ConductorModel newConductor) {
    _conductor = newConductor;
    notifyListeners();
  }
}
