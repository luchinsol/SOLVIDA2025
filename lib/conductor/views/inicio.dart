import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class InicioDriver extends StatefulWidget {
  const InicioDriver({Key? key}) : super(key: key);
  @override
  State<InicioDriver> createState() => _InicioDriverState();
}

class _InicioDriverState extends State<InicioDriver> {
  // VARIABLES
  String? tipoPago;
  List<String> _tipoPagoItems = [
    "Arequipa",
    "Moquegua",
    "San Juan de Lima asd a asdf"
  ];
  bool light = false;

  bool enabled = true;

  @override
  Widget build(BuildContext context) {
    final conductorProvider = context.watch<ConductorProvider>();
    if (conductorProvider.conductor != null) {
      setState(() {
        enabled = false;
      });
    }

    return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          child: Column(
            children: [
              Container(
                height: 320.h,
                color: const Color.fromARGB(255, 43, 40, 195),
                child: Padding(
                  padding: EdgeInsets.only(
                      top: 35.0.r, right: 20.r, left: 20.r, bottom: 20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 45.h,
                            width: 45.h,
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                borderRadius: BorderRadius.circular(50.r),
                                image: DecorationImage(
                                    image: NetworkImage(
                                        'https://cdn-icons-png.flaticon.com/512/10987/10987390.png'))),
                          ),
                          Container(
                            height: 45.h,
                            width: 45.h,
                            decoration: const BoxDecoration(
                                image: DecorationImage(
                                    image:
                                        AssetImage('lib/imagenes/nuevito.png'))
                                // color: const Color.fromARGB(255, 255, 255, 255),
                                //borderRadius: BorderRadius.circular(50.r)
                                ),
                          ),
                          Container(
                            height: 45.h,
                            width: 45.h,
                            //color: Colors.grey,
                            child: Center(
                                child: badges.Badge(
                                    position: badges.BadgePosition.topEnd(
                                        top: -5, end: -0),
                                    badgeContent: Text(
                                      '3',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.3.sp),
                                    ),
                                    badgeStyle: badges.BadgeStyle(
                                        badgeColor: Colors.amber,
                                        padding: EdgeInsets.all(6.8.r)),
                                    child: IconButton(
                                        onPressed: () {
                                          context.push('/drive/notificacion');
                                        },
                                        icon: Icon(
                                          Icons.notifications_none,
                                          size: 30.sp,
                                          color: Colors.white,
                                        )))),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 18.h,
                      ),
                      Skeletonizer(
                        enabled: enabled,
                        effect: ShimmerEffect(
                            baseColor: Colors.white,
                            highlightColor: Colors.grey.shade500),
                        child: Text(
                          "Hola, ${conductorProvider.conductor?.nombres}",
                          style: GoogleFonts.manrope(
                              fontSize: 22.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      SizedBox(
                        height: 18.h,
                      ),
                      Text(
                        "VALORACIÓN",
                        style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      SizedBox(
                        height: 8.h,
                      ),
                      Row(
                        children: [
                          Skeletonizer(
                            enabled: enabled,
                            effect: ShimmerEffect(
                                baseColor: Colors.white,
                                highlightColor: Colors.grey.shade500),
                            child: Text(
                              "${conductorProvider.conductor?.valoracion}",
                              style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 13.93.w,
                          )
                        ],
                      ),
                      SizedBox(
                        height: 24.h,
                      ),
                      Text(
                        "ACTUALMENTE EN",
                        style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      SizedBox(
                        height: 4.h,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            //color: Colors.amber,
                            width:
                                173.94.w, // Ajusta el ancho según el contenido
                            height: 25.h,
                            child: Skeletonizer(
                              enabled: enabled,
                              effect: ShimmerEffect(
                                  baseColor: Colors.white,
                                  highlightColor: Colors.grey.shade500),
                              child: Text(
                                  "${conductorProvider.conductor?.departamento}",
                                  style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16.sp)),
                            ),

                            /* DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                dropdownColor: Colors.grey,
                                isDense:
                                    true, // Reduce el espacio entre el texto y el ícono
                                hint: Text(
                                  'Zona de reparto',
                                  style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold),
                                ),
                                value: tipoPago,
                                items: _tipoPagoItems.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      overflow: TextOverflow
                                          .ellipsis, // Puntos suspensivos para texto largo
                                      maxLines: 1,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    tipoPago = newValue!;
                                  });
                                },
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_outlined,
                                  color: Colors.white,
                                ),
                                selectedItemBuilder: (BuildContext context) {
                                  return _tipoPagoItems.map((String value) {
                                    return Container(
                                      width: 140
                                          .w, // Limita el ancho del texto seleccionado
                                      child: Text(
                                        value,
                                        overflow: TextOverflow
                                            .ellipsis, // Aplica truncamiento
                                        maxLines: 1,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),*/
                          ),
                          Switch(
                              activeColor: Colors.amber, //.shade400,
                              value: light,
                              onChanged: (bool value) {
                                setState(() {
                                  light = value;
                                });
                              })
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              //SizedBox(height:27.h),

              Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Material(
                            elevation: 5.r,
                            borderRadius: BorderRadius.circular(20.r),
                            child: Container(
                              height: 139.h,
                              width: 84.w,
                              padding: EdgeInsets.only(top: 30.r),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.r),
                                  color: Colors.grey.shade100),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Pedidos",
                                    style: GoogleFonts.manrope(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Icon(Icons.assignment_outlined),
                                  Skeletonizer(
                                    enabled: enabled,
                                    effect: ShimmerEffect(
                                        baseColor: Colors.grey.shade500,
                                        highlightColor: Colors.grey.shade200,
                                        duration: Duration(milliseconds: 1700)),
                                    child: Text(
                                      "60",
                                      style: GoogleFonts.manrope(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Material(
                            elevation: 5.r,
                            borderRadius: BorderRadius.circular(20.r),
                            child: Container(
                              height: 139.h,
                              width: 84.w,
                              padding: EdgeInsets.only(top: 30.r),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.r),
                                  color: Colors.grey.shade100),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Horas",
                                    style: GoogleFonts.manrope(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Icon(Icons.access_time),
                                  Skeletonizer(
                                    enabled: enabled,
                                    effect: ShimmerEffect(
                                        baseColor: Colors.grey.shade500,
                                        highlightColor: Colors.grey.shade200,
                                        duration: Duration(milliseconds: 1700)),
                                    child: Text(
                                      "60",
                                      style: GoogleFonts.manrope(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Material(
                            elevation: 5.r,
                            borderRadius: BorderRadius.circular(20.r),
                            child: Container(
                              height: 139.h,
                              width: 84.w,
                              padding: EdgeInsets.only(top: 30.r),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.r),
                                  color: Colors.grey.shade100),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Distancia",
                                    style: GoogleFonts.manrope(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Icon(Icons.speed_outlined),
                                  Skeletonizer(
                                    enabled: enabled,
                                    effect: ShimmerEffect(
                                        baseColor: Colors.grey.shade500,
                                        highlightColor: Colors.grey.shade200,
                                        duration: Duration(milliseconds: 1700)),
                                    child: Text(
                                      "60",
                                      style: GoogleFonts.manrope(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 42.h),
                      Text(
                        "Último pedido",
                        style: GoogleFonts.manrope(
                            fontSize: 20.sp, fontWeight: FontWeight.w400),
                      ),
                      SizedBox(height: 40.h),
                      Skeletonizer(
                        // ignoreContainers: true,
                        //  containersColor: Colors.blue,
                        effect: ShimmerEffect(
                            baseColor: Colors.grey.shade500,
                            highlightColor: Colors.grey.shade200,
                            duration: Duration(milliseconds: 1700)),
                        enabled: enabled,
                        child: Material(
                          elevation: 10.r,
                          borderRadius: BorderRadius.circular(20.r),
                          child: Container(
                            height: 111.h,
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                                color: Colors.grey.shade100),
                            // Contenido
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 153.h,
                                  // color: Colors.green,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        // color: const Color.fromARGB(255, 194, 177, 183),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                              width: 45.h,
                                              height: 45.h,
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          50.r)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        //color: Color.fromARGB(255, 200, 216, 164),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Luis Gonzáles",
                                              style: GoogleFonts.manrope(
                                                  fontSize: 14.sp,
                                                  color: Colors.grey.shade600),
                                            ),
                                            Text(
                                              "S/.7.90",
                                              style: GoogleFonts.manrope(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              "02/10/2024",
                                              style: GoogleFonts.manrope(
                                                  fontSize: 14.sp,
                                                  color: Colors.grey.shade600),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 153.h,
                                  // color: Colors.green,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "ID: #7654321",
                                        style: GoogleFonts.manrope(
                                            fontSize: 14.sp,
                                            color: const Color.fromARGB(
                                                255, 66, 66, 66)),
                                      ),
                                      Text(
                                        "Normal",
                                        style: GoogleFonts.manrope(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Container(
                                        width: 85.w,
                                        height: 26.h,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(6.r),
                                            color: Colors.grey.shade300),
                                        child: Center(
                                          child: Text(
                                            "Entregado",
                                            style: GoogleFonts.manrope(
                                                color: Color.fromARGB(
                                                    255, 53, 41, 158)),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ))
            ],
          ),
        ));
  }
}
