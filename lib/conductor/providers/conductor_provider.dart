import 'dart:convert';

import 'package:app2025/conductor/model/conductor_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConductorProvider extends ChangeNotifier {
  ConductorModel? _conductor;

  ConductorModel? get conductor => _conductor;

  ConductorProvider() {}

  Future<void> initConductor() async {
    await _loadConductorFromPrefs();
  }

  Future<void> _saveConductorToPrefs(ConductorModel conductor) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String conductorJson = jsonEncode(conductor.toJson());
    await prefs.setString('conductor', conductorJson);
  }

  Future<void> updateConductor(ConductorModel newConductor) async {
    _conductor = newConductor;
    await _saveConductorToPrefs(newConductor);
    notifyListeners();
  }

  Future<void> _loadConductorFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? conductorJson = prefs.getString('conductor');

    if (conductorJson != null) {
      _conductor = ConductorModel.fromJson(jsonDecode(conductorJson));
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _conductor = null; // Remove the conductor from memory
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('conductor'); // Remove from persistent storage
    notifyListeners(); // Notify widgets depending on this provider
  }
}
