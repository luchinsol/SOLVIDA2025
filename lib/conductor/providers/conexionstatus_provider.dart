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

  Future<bool> _revisarInternet() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void _monitoreoRedes() async {
    _temporizador = Timer.periodic(Duration(seconds: 10), (tiempo) async {
      print("revisando mi back");
      // Conexión servidor
      hasServerup = await _revisarServerUp();
      // Conexión wifi
      hasInternet = await _revisarInternet();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _temporizador.cancel();
    super.dispose();
  }
}
