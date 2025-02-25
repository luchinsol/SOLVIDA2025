import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ConexionStatusProvider with ChangeNotifier {
  // Atributos
  bool hasInternet = true;
  bool hasServerup = true;
  String microUrl = dotenv.env['MICRO_URL'] ?? '';
  late Timer _temporizador;

  ConexionStatusProvider() {
    _monitoreoRedes();
  }

  Future<bool> _revisarServerUp() async {
    try {
      var res = await http
          .get(Uri.parse('$microUrl/ping'))
          .timeout(Duration(seconds: 5));

      print("revisando mi back ${res.statusCode}");

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _revisarWifi() async {
    var conexionResult = await Connectivity().checkConnectivity();
    return conexionResult != ConnectivityResult.none;
  }

  void _monitoreoRedes() async {
    _temporizador = Timer.periodic(Duration(seconds: 10), (tiempo) async {
      print("revisando mi back");
      // Conexión servidor
      hasServerup = await _revisarServerUp();
      // Conexión wifi
      hasInternet = await _revisarWifi();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _temporizador.cancel();
    super.dispose();
  }
}
