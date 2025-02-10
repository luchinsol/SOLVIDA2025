import 'dart:convert';

import 'package:app2025/conductor/model/notificaciones_model.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Notificaciones extends StatefulWidget {
  const Notificaciones({Key? key}) : super(key: key);
  @override
  State<Notificaciones> createState() => _NotificacionesState();
}

class _NotificacionesState extends State<Notificaciones> {
  // Lista de notificaciones (simulada)
  String microUrl = dotenv.env['MICRO_URL'] ?? '';
  List<NotificacionesModel> notificacionesNew = [];

  Future<dynamic> getNotificacionesAlmaid() async {
    final conductorProvider =
        Provider.of<ConductorProvider>(context, listen: false);
    int? almacen_id = conductorProvider.conductor?.evento_id;
    print("---------------");
    print("$almacen_id");
    String fechaActual = DateFormat('yyyy-MM-dd').format(DateTime.now());
    print("........");
    print(fechaActual);
    try {
      if (conductorProvider.conductor != null) {
        SharedPreferences tokenUser = await SharedPreferences.getInstance();
        String? token = tokenUser.getString('token'); // Recupera el token

        if (token == null) {
          print("No hay token almacenado");
          return;
        }

        var res = await http.get(
            Uri.parse(microUrl +
                '/notificacion/' +
                fechaActual +
                '/' +
                almacen_id.toString()),
            headers: {"Authorization": "Bearer $token"});

        print(microUrl +
            '/notificacion/' +
            fechaActual +
            '/' +
            almacen_id.toString());
        if (res.statusCode == 200) {
          var data = json.decode(res.body);
          List<NotificacionesModel> tempNotificaciones =
              data.map<NotificacionesModel>((i) {
            return NotificacionesModel(
                id: i['id'],
                mensaje: i['mensaje'],
                tipo: i['tipo'],
                estado: i['estado'],
                fechacreacion: i['fecha_creacion'],
                fechaenvio: i['fecha_envio']);
          }).toList();
          if (mounted) {
            setState(() {
              notificacionesNew = tempNotificaciones;
            });
          }
          print("Notificaciones $notificacionesNew");
        }
      }
    } catch (e) {
      throw Exception('Error fetch notify $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getNotificacionesAlmaid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Notificaciones (${notificacionesNew.length})",
              style: GoogleFonts.manrope(fontSize: 16.sp),
            ),
          ],
        ),
      ),
      body: Padding(
        padding:
            EdgeInsets.only(top: 32.r, bottom: 20.r, left: 17.r, right: 17.r),
        child: notificacionesNew.length > 0
            ? ListView.builder(
                itemCount: notificacionesNew.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Container(
                        height: 64.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(left: 17.r, right: 17.r),
                          child: Row(
                            children: [
                              Container(
                                height: 50.w,
                                width: 50.w,
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 224, 224, 224),
                                  borderRadius: BorderRadius.circular(50.r),
                                ),
                              ),
                              SizedBox(
                                width: 18.w,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sistema - ${notificacionesNew[index].tipo}",
                                    style: GoogleFonts.manrope(fontSize: 16.sp),
                                  ),
                                  SizedBox(
                                    height: 7.h,
                                  ),
                                  Container(
                                    width: 250.w,
                                    child: Text(
                                      notificacionesNew[index].mensaje,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style:
                                          GoogleFonts.manrope(fontSize: 13.sp),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 12.h,
                      ),
                      Container(
                        width: 345.w,
                        child: Divider(
                          height: 1.h,
                          color: const Color.fromARGB(255, 231, 231, 231),
                        ),
                      ),
                      SizedBox(
                        height: 12.h,
                      ),
                    ],
                  );
                },
              )
            : Center(
                child: Text("Sin notificaciones hoy día"),
              ),
      ),
    );
  }
}
