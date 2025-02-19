import 'dart:convert';

import 'package:app2025/cliente/provider/pedido_provider.dart';
import 'package:app2025/cliente/views/pedido.dart';
import 'package:app2025/conductor/model/clientelast_model.dart';
import 'package:app2025/conductor/model/lastpedido_model.dart';
import 'package:app2025/conductor/model/pedido_model.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:app2025/conductor/providers/conexionswitch_provider.dart';
import 'package:app2025/conductor/providers/lastpedido_provider.dart';
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
  String microUrl = dotenv.env['MICRO_URL'] ?? '';
  bool enabled = true;
  int cantidad = 0;
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

  Future<void> getlastPedido() async {
    try {
      print("entrando ");
      final conductorProvider =
          Provider.of<ConductorProvider>(context, listen: false);
      final pedidolastProvider =
          Provider.of<LastpedidoProvider>(context, listen: false);

      int? idconductor = conductorProvider.conductor?.id;
      var res = await http
          .get(Uri.parse('$microUrl/conductor_lastpedido/$idconductor'));

      if (res.statusCode == 200) {
        var data = json.decode(res.body);

        // Parseamos la fecha si es necesario
        DateTime? fecha =
            data['fecha'] != null ? DateTime.parse(data['fecha']) : null;

        // Creamos el modelo de Cliente
        ClientelastModel cliente = ClientelastModel(
            nombre: data['cliente']['nombre'], foto: data['cliente']['foto']);

        // Creamos el modelo de Lastpedido
        LastpedidoModel lastpedido = LastpedidoModel(
            id: data['id'],
            tipo: data['tipo'],
            total: data['total'].toDouble(),
            fecha: fecha,
            estado: data['estado'],
            cliente: cliente);

        // Actualizamos el proveedor con el nuevo Lastpedido
        pedidolastProvider.updateLastPedido(lastpedido);
        print("....");
        print("${pedidolastProvider.lastPedido?.cliente!.nombre}");
        print("....kataaa");
        pedidolastProvider.lastPedido?.fecha = DateTime(
            pedidolastProvider.lastPedido!.fecha!.year,
            pedidolastProvider.lastPedido!.fecha!.month,
            pedidolastProvider.lastPedido!.fecha!.day);
      } else {
        print(
            "Respuesta no exitosa (${res.statusCode}), asignando valores por defecto.");

        // Si la respuesta no es 200, asignamos valores por defecto
        ClientelastModel defaultCliente = ClientelastModel(
          nombre: "Cliente Desconocido",
          foto: "https://example.com/default_profile.png",
        );

        LastpedidoModel defaultPedido = LastpedidoModel(
          id: 0,
          tipo: "Desconocido",
          total: 0.0,
          fecha: DateTime.now(),
          estado: "Desconocido",
          cliente: defaultCliente,
        );

        pedidolastProvider.updateLastPedido(defaultPedido);
      }
    } catch (e) {
      throw Exception("Error query $e");
    }
  }

  Future<void> getPedidos() async {
    try {
      final conductorProvider =
          Provider.of<ConductorProvider>(context, listen: false);
      int? idconductor = conductorProvider.conductor?.id;

      var res = await http.get(
          Uri.parse('$microUrl/conductor_pedidos/$idconductor'),
          headers: {"Content-type": "application/json"});

      var data = json.decode(res.body);

      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        if (mounted) {
          setState(() {
            cantidad = int.parse(data['total_pedidos']);
          });
        }
      }
    } catch (e) {
      throw Exception('Error get count $e');
    }
  }

  @override
  void initState() {
    getPedidos();
    getlastPedido();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final notificacionProvider = context.watch<NotificacionesInicioProvider>();
    final conductorProvider = context.watch<ConductorProvider>();
    final pedidolast = context.watch<LastpedidoProvider>();
    final pedidoProvider =
        Provider.of<PedidosProvider2>(context, listen: false);
    final conexionTrabajo =
        Provider.of<ConductorConnectionProvider>(context, listen: false);
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
                                      "${notificacionProvider.notificaciones.length}",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 10.3.sp),
                                    ),
                                    badgeStyle: badges.BadgeStyle(
                                        badgeColor: notificacionProvider
                                                .notificaciones.isEmpty
                                            ? Colors.grey.shade200
                                            : Colors.amber,
                                        padding: EdgeInsets.all(6.8.r)),
                                    child: IconButton(
                                        onPressed: () {
                                          context.go('/drive/notificacion');
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
                                  "${conductorProvider.conductor?.departamento} - ${conductorProvider.conductor?.nombre}",
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
                              activeColor: conexionTrabajo.isConnected
                                  ? Colors.amber
                                  : Colors.grey, //.shade400,
                              value: conexionTrabajo.isConnected,
                              onChanged: (bool value) {
                                setState(() {
                                  light = value;
                                });
                                conexionTrabajo.updateConnect(value);

                                if (value) {
                                  conexionTrabajo.connect();
                                  pedidoProvider.conectarSocket(
                                      context,
                                      conductorProvider.conductor!.evento_id,
                                      conductorProvider.conductor!.nombre);
                                }
                              })
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              //SizedBox(height:27.h),

              conexionTrabajo.isConnected
                  ? Padding(
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
                                              highlightColor:
                                                  Colors.grey.shade200,
                                              duration:
                                                  Duration(milliseconds: 1700)),
                                          child: Text(
                                            formatCantidad(cantidad),
                                            style: GoogleFonts.manrope(
                                                fontSize: cantidad > 999
                                                    ? 16.sp
                                                    : (cantidad > 99
                                                        ? 20.sp
                                                        : 32.sp),
                                                fontWeight: FontWeight.bold),
                                          ))
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
                                            highlightColor:
                                                Colors.grey.shade200,
                                            duration:
                                                Duration(milliseconds: 1700)),
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
                                            highlightColor:
                                                Colors.grey.shade200,
                                            duration:
                                                Duration(milliseconds: 1700)),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                                      image: DecorationImage(
                                                          image: NetworkImage(
                                                              'https://i.pinimg.com/736x/17/ec/61/17ec61d172c7e0860fba0de51dad4ffe.jpg')),
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "${pedidolast.lastPedido?.cliente!.nombre}",
                                                  style: GoogleFonts.manrope(
                                                      fontSize: 14.sp,
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                                Text(
                                                  'S/.${pedidolast.lastPedido?.total}',
                                                  style: GoogleFonts.manrope(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  "${formatoFecha(pedidolast.lastPedido!.fecha!)}",
                                                  style: GoogleFonts.manrope(
                                                      fontSize: 14.sp,
                                                      color:
                                                          Colors.grey.shade600),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "ID: #${pedidolast.lastPedido?.id}",
                                            style: GoogleFonts.manrope(
                                                fontSize: 14.sp,
                                                color: const Color.fromARGB(
                                                    255, 66, 66, 66)),
                                          ),
                                          Text(
                                            "${pedidolast.lastPedido?.tipo}",
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
                                                "${pedidolast.lastPedido?.estado}",
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
                  : Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 300.w,
                            height: 300.w,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: AssetImage(
                                        'lib/imagenes/centralgirl.png'))),
                          ),
                          Text(
                            "Conéctate al servidor de pedidos",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                                fontSize: 20.sp, fontWeight: FontWeight.w400),
                          )
                        ],
                      ),
                    )
            ],
          ),
        ));
  }
}
