import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class Notificaciones extends StatefulWidget {
  const Notificaciones({Key? key}) : super(key: key);
  @override
  State<Notificaciones> createState() => _NotificacionesState();
}

class _NotificacionesState extends State<Notificaciones> {
  // Lista de notificaciones (simulada)
  List<String> notificaciones = List.generate(
    122,
    (index) => "Pedido ID: #75432${index} ha sido entregado",
  );

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
              "Notificaciones (${notificaciones.length})",
              style: GoogleFonts.manrope(fontSize: 16.sp),
            ),
            IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          'Eliminar notificaciones',
                          style:
                              GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          '¿Estás seguro de que deseas eliminar todas las notificaciones?',
                          style: GoogleFonts.manrope(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              context.pop(); // Cerrar el diálogo
                            },
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.manrope(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                // items.clear(); // Eliminar todos los elementos
                              });
                              context.pop(); // Cerrar el diálogo
                            },
                            child: Text(
                              'Eliminar',
                              style: GoogleFonts.manrope(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: Icon(Icons.delete_outline))
          ],
        ),
      ),
      body: Padding(
        padding:
            EdgeInsets.only(top: 32.r, bottom: 20.r, left: 17.r, right: 17.r),
        child: ListView.builder(
          itemCount: notificaciones.length,
          itemBuilder: (context, index) {
            return Dismissible(
              key: Key(
                  notificaciones[index]), // Clave única para cada notificación
              direction:
                  DismissDirection.endToStart, // Desliza de izquierda a derecha
              onDismissed: (direction) {
                // Eliminar la notificación de la lista
                setState(() {
                  notificaciones.removeAt(index);
                });

                // Mostrar mensaje de confirmación
                /*ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Notificación eliminada"),
                  ),
                );*/
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.white),
                    SizedBox(width: 10.w),
                    Text(
                      "Eliminar",
                      style: GoogleFonts.manrope(
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              child: Column(
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
                              color: const Color.fromARGB(255, 224, 224, 224),
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
                                "Sistema",
                                style: GoogleFonts.manrope(fontSize: 16.sp),
                              ),
                              SizedBox(
                                height: 7.h,
                              ),
                              Container(
                                width: 250.w,
                                child: Text(
                                  notificaciones[index],
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.manrope(fontSize: 13.sp),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
