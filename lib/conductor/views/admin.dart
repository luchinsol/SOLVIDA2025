import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:app2025/cliente/provider/pedido_provider.dart';
import 'package:app2025/cliente/views/pedido.dart';

import 'package:app2025/conductor/model/clientelast_model.dart';
import 'package:app2025/conductor/model/lastpedido_model.dart';
import 'package:app2025/conductor/model/pedido_model.dart';
import 'package:app2025/conductor/providers/chipspedidos_provider.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:app2025/conductor/providers/conexionstatus_provider.dart';
import 'package:app2025/conductor/providers/conexionswitch_provider.dart';
import 'package:app2025/conductor/providers/lastpedido_provider.dart';
import 'package:app2025/conductor/providers/notificacioncustom_provider.dart';
import 'package:app2025/conductor/providers/notificaciones_provider.dart';
import 'package:app2025/conductor/providers/pedidos_provider2.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AdminDriver extends StatefulWidget {
  const AdminDriver({Key? key}) : super(key: key);
  @override
  State<AdminDriver> createState() => _AdminDriverState();
}

class _AdminDriverState extends State<AdminDriver> {
  // VARIABLES
  String? tipoPago;
  List<String> _tipoPagoItems = [
    "Arequipa",
    "Moquegua",
    "San Juan de Lima asd a asdf"
  ];
  bool light = false;
  String microUrl = dotenv.env['MICRO_URL'] ?? '';
  bool enabled = false;
  int cantidad = 0;
  List<Flushbar> _notificaciones = [];
  bool _expandido = false;

//Inicializar con valores por defecto

  String formatoFecha(DateTime fecha) {
    return "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
  }

  String formatCantidad(int cantidad) {
    if (cantidad > 999) {
      return "${(cantidad / 1000).toStringAsFixed(1)}K";
    }
    return cantidad.toString();
  }

  @override
  void initState() {
    // getPedidos();
    // getlastPedido();
    super.initState();
  }

  // String estadoSeleccionado = "Pendientes"; // Estado inicial
  @override
  Widget build(BuildContext context) {
    final conexionProvider = context.watch<ConexionStatusProvider>();
    final chipsPedidos = context.watch<ChipspedidosProvider>();
    final conductorProvider =
        Provider.of<ConductorProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      body: conexionProvider.hasInternet
          ? (conexionProvider.hasServerup
              ? Container(
                  child: Column(
                    children: [
                      Container(
                        height: 230.h,
                        color: const Color.fromARGB(255, 43, 40, 195),
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: 35.0.r,
                              right: 20.r,
                              left: 20.r,
                              bottom: 20.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: 45.h,
                                    width: 45.h,
                                    decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        borderRadius:
                                            BorderRadius.circular(50.r),
                                        image: DecorationImage(
                                            image: NetworkImage(
                                                'https://cdn-icons-png.flaticon.com/512/10987/10987390.png'))),
                                  ),
                                  Container(
                                    height: 45.h,
                                    width: 45.h,
                                    decoration: const BoxDecoration(
                                        image: DecorationImage(
                                            image: AssetImage(
                                                'lib/imagenes/nuevito.png'))
                                        // color: const Color.fromARGB(255, 255, 255, 255),
                                        //borderRadius: BorderRadius.circular(50.r)
                                        ),
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
                                  "Hola, ${conductorProvider.conductor!.nombres} ${conductorProvider.conductor!.apellidos}",
                                  style: GoogleFonts.manrope(
                                      fontSize: 22.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    //color: Colors.amber,
                                    width: 173.94
                                        .w, // Ajusta el ancho según el contenido
                                    height: 25.h,
                                    child: Skeletonizer(
                                      enabled: enabled,
                                      effect: ShimmerEffect(
                                          baseColor: Colors.white,
                                          highlightColor: Colors.grey.shade500),
                                      child: Text(
                                          "Arequipa - almacen ${conductorProvider.conductor!.evento_id}",
                                          style: GoogleFonts.manrope(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 16.sp)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // CHIPS DE ESTADOS
                      Padding(
                        padding:
                            EdgeInsets.only(left: 20.r, top: 10.r, right: 20.r),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ChoiceChip(
                              label: Text("Pendientes"),

                              showCheckmark: false,
                              selected:
                                  chipsPedidos.estadoActual == "pendiente",
                              selectedColor: Colors
                                  .orange, // Color cuando está seleccionado
                              backgroundColor:
                                  Colors.white, // Color por defecto
                              shape: StadiumBorder(
                                  side: BorderSide(
                                      color:
                                          Colors.grey)), // Bordes redondeados
                              onSelected: (bool selected) {
                                setState(() {
                                  chipsPedidos.cambiarEstado("pendiente");
                                });
                              },
                            ),
                            ChoiceChip(
                              label: Text("En Proceso"),
                              selected:
                                  chipsPedidos.estadoActual == "en proceso",
                              selectedColor: Colors.blue,
                              showCheckmark: false,
                              backgroundColor: Colors.white,
                              shape: StadiumBorder(
                                  side: BorderSide(color: Colors.grey)),
                              onSelected: (bool selected) {
                                setState(() {
                                  chipsPedidos.cambiarEstado("en proceso");
                                });
                              },
                            ),
                            ChoiceChip(
                              label: Text("Entregados"),
                              selected:
                                  chipsPedidos.estadoActual == "entregado",
                              selectedColor: Colors.green,
                              backgroundColor: Colors.white,
                              showCheckmark: false,
                              shape: StadiumBorder(
                                  side: BorderSide(color: Colors.grey)),
                              onSelected: (bool selected) {
                                setState(() {
                                  chipsPedidos.cambiarEstado("entregado");
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      chipsPedidos.pedidos.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.amber,
                              ),
                            )
                          : Text(
                              "Cantidad: ${chipsPedidos.pedidos.length}",
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      SizedBox(
                        height: 5.0.h,
                      ),
                      // LISTA DE PEDIDOS
                      Padding(
                          padding: EdgeInsets.all(20.r),
                          child: Container(
                            color: Colors.grey.shade200,
                            padding: EdgeInsets.all(5.r),
                            height: 1.sh / 2.2,
                            child: chipsPedidos.pedidos.isEmpty
                                ? Center(
                                    child: Text("No tienes pedidos ahora"),
                                  )
                                : ListView.builder(
                                    reverse: false,
                                    padding: EdgeInsets.zero,
                                    itemCount: chipsPedidos.pedidos.length,
                                    itemBuilder: (context, index) {
                                      return Material(
                                        elevation: 1.r,
                                        color: Colors.white.withOpacity(0.0),
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                        child: Container(
                                          margin: EdgeInsets.only(bottom: 30.h),
                                          height: 111.h,
                                          padding: EdgeInsets.all(10.r),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              color: Colors.grey.shade100),
                                          // Contenido
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                width: 153.h,
                                                // color: Colors.green,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      // color: const Color.fromARGB(255, 194, 177, 183),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          Container(
                                                            width: 45.h,
                                                            height: 45.h,
                                                            decoration: BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                image: DecorationImage(
                                                                    image: NetworkImage(
                                                                        'https://i.pinimg.com/736x/17/ec/61/17ec61d172c7e0860fba0de51dad4ffe.jpg')),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50.r)),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      //color: Color.fromARGB(255, 200, 216, 164),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            "Pedido",
                                                            style: GoogleFonts
                                                                .manrope(
                                                                    fontSize:
                                                                        14.sp,
                                                                    color: Colors
                                                                        .grey
                                                                        .shade600),
                                                          ),
                                                          Text(
                                                            'S/.${chipsPedidos.pedidos[index].total}',
                                                            style: GoogleFonts
                                                                .manrope(
                                                                    fontSize:
                                                                        14.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                          ),
                                                          /*
                                                  Text(
                                                    "${formatoFecha(pedidolast.lastPedido!.fecha!)}",
                                                    style: GoogleFonts.manrope(
                                                        fontSize: 14.sp,
                                                        color:
                                                            Colors.grey.shade600),
                                                  )*/
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
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "ID: #${chipsPedidos.pedidos[index].id}",
                                                      style:
                                                          GoogleFonts.manrope(
                                                              fontSize: 14.sp,
                                                              color: const Color
                                                                  .fromARGB(255,
                                                                  66, 66, 66)),
                                                    ),
                                                    Text(
                                                      "${chipsPedidos.pedidos[index].tipo}",
                                                      style:
                                                          GoogleFonts.manrope(
                                                              fontSize: 14.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                    ),
                                                    Container(
                                                      width: 85.w,
                                                      height: 26.h,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      6.r),
                                                          color: Colors
                                                              .grey.shade300),
                                                      child: Center(
                                                        child: Text(
                                                          "${chipsPedidos.pedidos[index].estado}",
                                                          style: GoogleFonts
                                                              .manrope(
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          53,
                                                                          41,
                                                                          158)),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                          )),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 150.w,
                          height: 150.w,
                          child: Image.asset('lib/imagenes/nuevecito.png')),
                      const SizedBox(height: 20),
                      Text(
                        "¡Ups! Solvida no puede\n conectarse en este momento.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        " Estamos trabajando para solucionarlo. 🚧",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 26, 1, 98)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ))
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off,
                    size: 100,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No tienes conexión a internet",
                    style: GoogleFonts.manrope(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Por favor verifica tu conexión y vuelve a intentar.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w300,
                        color: Color.fromARGB(255, 55, 27, 139)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
