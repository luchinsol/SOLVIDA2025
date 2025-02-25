import 'dart:convert';
import 'dart:math';

import 'package:app2025/conductor/model/pedidosalmacen_model.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChipspedidosProvider with ChangeNotifier {
  // ATRIBUTOS
  final List<PedidosAlmacen> _pedidosAlmacen = [];
  String microUrl = dotenv.env['MICRO_URL'] ?? '';
  String estadoActual = "pendiente";
  int? almacen;

  // GETTER
  List<PedidosAlmacen> get pedidos => _pedidosAlmacen;

  // CONSTRUCTOR
  ChipspedidosProvider(BuildContext context) {
    final conductorProvider =
        Provider.of<ConductorProvider>(context, listen: false);
    almacen = conductorProvider.conductor?.evento_id;
    print("almacen...$almacen");
    if (almacen != null) {
      getPedidosAlmacen();
    }
  }

  Future<void> getPedidosAlmacen() async {
    if (almacen == null) return;
    try {
      SharedPreferences tokenUser = await SharedPreferences.getInstance();
      String? token = tokenUser.getString('token');
      print("chips ahoy ");
      if (token != null) {
        print('$microUrl/pedido/almacen/${almacen.toString()}/$estadoActual');
        var res = await http.get(
            Uri.parse('$microUrl/pedido/almacen/$almacen/$estadoActual'),
            headers: {"Authorization": "Bearer $token"});
        if (res.statusCode == 200) {
          var data = jsonDecode(res.body);
          print("Datitos de mi chip");
          print(data);
          _pedidosAlmacen.clear();
          _pedidosAlmacen.addAll(
            (data as List).map((e) => PedidosAlmacen.fromJson(e)).toList(),
          );
          print("...CHIP CARGADO");
          print(_pedidosAlmacen);
          notifyListeners();
        }
      }
    } catch (error) {
      throw Exception("Error query get $error");
    }
  }

  void cambiarEstado(String newEstado) {
    if (estadoActual != newEstado) {
      estadoActual = newEstado;
      getPedidosAlmacen();
      notifyListeners();
    }
  }
}
