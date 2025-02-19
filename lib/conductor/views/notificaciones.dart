import 'dart:convert';

import 'package:app2025/conductor/model/notificaciones_model.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:app2025/conductor/providers/notificacioncustom_provider.dart';
import 'package:app2025/conductor/providers/notificaciones_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final notificacionesProvider =
        Provider.of<NotificacionesInicioProvider>(context, listen: false);
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
            Uri.parse('$microUrl/notificacion/$fechaActual/$almacen_id'),
            headers: {"Authorization": "Bearer $token"});

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
            // Actualizar Provider en lugar de usar setState
            notificacionesProvider.updateNotificaciones(tempNotificaciones);
          }
          print("Notificaciones $notificacionesProvider");
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
    final notificacionProvider = context.watch<NotificacionesInicioProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Icon(
          Icons.arrow_back_ios,
          size: 16.sp,
        ),
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Notificaciones (${notificacionProvider.notificaciones.length})",
              style: GoogleFonts.manrope(fontSize: 16.sp),
            ),
          ],
        ),
      ),
      body: Padding(
        padding:
            EdgeInsets.only(top: 32.r, bottom: 20.r, left: 17.r, right: 17.r),
        child: notificacionProvider.notificaciones.isNotEmpty
            ? ListView.builder(
                itemCount: notificacionProvider.notificaciones.length,
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
                                    "Sistema - ${notificacionProvider.notificaciones[index].tipo}",
                                    style: GoogleFonts.manrope(fontSize: 16.sp),
                                  ),
                                  SizedBox(
                                    height: 7.h,
                                  ),
                                  Container(
                                    width: 250.w,
                                    child: Text(
                                      notificacionProvider
                                          .notificaciones[index].mensaje,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 300.w,
                      height: 300.w,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage('lib/imagenes/nodata.png'))),
                    ),
                    Text(
                      "Hoy día no hay novedades",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                          fontSize: 20.sp, fontWeight: FontWeight.w400),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
