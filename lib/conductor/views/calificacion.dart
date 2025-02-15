import 'dart:convert';

import 'package:app2025/conductor/providers/pedidos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:http/http.dart' as http;

class Calificacion extends StatefulWidget {
  const Calificacion({Key? key}) : super(key: key);
  @override
  State<Calificacion> createState() => _CalificacionState();
}

class _CalificacionState extends State<Calificacion> {
  // Variable para mantener la calificación actual
  int _rating = 0;
  String microUrl = dotenv.env['MICRO_URL'] ?? '';

  Future<void> updateCalificationClient(int calificacion) async {
    print("...claificcacion");
    print(calificacion);
    try {
      SharedPreferences tokenUser = await SharedPreferences.getInstance();
      String? token = tokenUser.getString('token');

      if (token == null) {
        return;
      }
      var res = await http.put(Uri.parse(microUrl + '/cliente_calificar/4'),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json", // Especifica que envías JSON
          },
          body: jsonEncode({"calificacion": calificacion}));
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        print(data['calificacion']);
      }
    } catch (e) {
      throw Exception('Error update calification $e');
    }
  }

  void _finishAndNavigate(BuildContext context, int rating) async {
    if (rating == 0) {
      setState(() {
        _rating = 5;
      });
    } else {
      _rating = rating;
    }

    try {
      await updateCalificationClient(_rating);

      // Verificamos antes de la navegación
      if (!mounted) return;

      // Obtenemos el provider para verificar si hay pedidos aceptados
      final pedidosProvider =
          Provider.of<PedidosProvider>(context, listen: false);
      final bool hasPedidos = pedidosProvider.pedidosAceptados.isNotEmpty;

      // Navegamos según la condición
      if (!mounted) return;
      if (hasPedidos) {
        context.go('/drive/navegar');
      } else {
        context.go('/drive');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            "Calificación",
            style: GoogleFonts.manrope(fontSize: 16.sp),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 175.h,
              ),
              Container(
                width: 79.w,
                height: 79.w,
                decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(50.r)),
              ),
              SizedBox(
                height: 35.h,
              ),
              Skeletonizer(
                enabled: false,
                effect: ShimmerEffect(
                    baseColor: Colors.white,
                    highlightColor: Colors.grey.shade500),
                child: Text(
                  "Luis Gonzáles",
                  style: GoogleFonts.manrope(
                      fontSize: 22.5.sp, color: Colors.grey),
                ),
              ),
              SizedBox(
                height: 35.h,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "¿Cómo calificarías al cliente?",
                    style: GoogleFonts.manrope(
                        fontSize: 20.sp, fontWeight: FontWeight.w600),
                  ),
                  Icon(
                    Icons.star_rate_rounded,
                    color: Colors.amber,
                    size: 40.0.sp,
                  )
                ],
              ),
              SizedBox(height: 35.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                      print(_rating);
                    },
                    icon: Icon(
                      _rating >= index + 1
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 50.sp,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    constraints:
                        BoxConstraints(minWidth: 40.w, minHeight: 40.w),
                  );
                }),
              ),
              SizedBox(height: 35.h),
              Text(
                "Tu valoración es importante para las futuras entregas",
                style: GoogleFonts.manrope(fontSize: 20.sp, color: Colors.grey),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 100.h),
              Container(
                height: 70.h,
                width: 1.sw,
                child: ElevatedButton(
                    onPressed: () => _finishAndNavigate(context, _rating),
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          Color.fromRGBO(42, 75, 160, 1),
                        ),
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r)))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Finalizar",
                          style: GoogleFonts.manrope(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          width: 72.w,
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        )
                      ],
                    )),
              )
            ],
          ),
        ));
  }
}
