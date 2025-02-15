import 'dart:convert';

import 'package:app2025/conductor/model/pedidos_history_model.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:http/http.dart' as http;

class Historial extends StatefulWidget {
  const Historial({Key? key}) : super(key: key);

  @override
  State<Historial> createState() => _HistorialState();
}

class _HistorialState extends State<Historial> {
  // Lista inicial (puedes reemplazarla al consumir la API)
  //List<String> items = List.generate(10, (index) => 'Elemento ${index + 1}');
  String microUrl = dotenv.env['MICRO_URL'] ?? '';
  late DateTime _currentDate;
  late List<DateTime> _days;
  List<Pedido> pedidosConductor = [];
  bool cargando = true;
  bool esperando = true;

  Future<void> getHistorialConductor(String fecha) async {
    try {
      int? idConductor = 0;

      final conductorProvider =
          Provider.of<ConductorProvider>(context, listen: false);
      if (conductorProvider.conductor != null) {
        SharedPreferences tokenUser = await SharedPreferences.getInstance();
        String? token = tokenUser.getString('token');
        if (token == null) {
          return;
        }

        if (mounted) {
          setState(() {
            idConductor = conductorProvider.conductor?.id;
            pedidosConductor = [];
          });
        }

        var res = await http.get(
            Uri.parse('$microUrl/pedido_history/$idConductor/$fecha'),
            headers: {"Authorization": "Bearer $token"});

        if (res.statusCode == 200) {
          if (mounted) {
            setState(() {
              pedidosConductor = Pedido.fromJsonList(res.body);
              cargando = false;
            });
          }

          await Future.delayed(Duration(milliseconds: 2000));

          if (mounted) {
            setState(() {
              esperando = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              pedidosConductor = []; // Si falla la petición, lista vacía
              cargando = false;
            });
          }
          print("adios");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          pedidosConductor = [];
          cargando = false;
          esperando = false;
        });
      }
      throw Exception("Error get history $e");
    }
  }

  int _selectedIndex = -1;
  @override
  void initState() {
    super.initState();

    _currentDate = DateTime.now();
    _days = _generateDays(_currentDate);
    print(_currentDate);
    print(_days);
  }

  List<DateTime> _generateDays(DateTime startDate) {
    return List.generate(
      7,
      (index) => startDate.subtract(Duration(days: index)),
    ).reversed.toList();
  }

  void _loadPreviousDays() {
    setState(() {
      _currentDate = _currentDate.subtract(Duration(days: 7));
      _days = _generateDays(_currentDate);
    });
  }

  void _onDayTapped(index) {
    setState(() {
      _selectedIndex = index; // Actualiza el índice seleccionado
      cargando = true;
      esperando = true;
    });
    print("...");
    print(_selectedIndex);
    print(_days[_selectedIndex]);
    DateTime diaSeleccionado = _days[index];
    String formatFecha = DateFormat('yyyy-MM-dd').format(diaSeleccionado);
    getHistorialConductor(formatFecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Historial",
          style: GoogleFonts.manrope(fontSize: 16.sp),
        ),
      ),
      body: Padding(
        padding:
            EdgeInsets.only(top: 13.r, bottom: 20.r, left: 17.r, right: 17.r),
        child: Column(
          children: [
            Container(
              height: 100.h,
              //color: Colors.grey,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final date = _days[index];
                  return GestureDetector(
                    onTap: () {
                      _onDayTapped(index);
                    },
                    child: Container(
                      width: 80,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          //color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: 2.w,
                            color: index == _selectedIndex
                                ? Colors
                                    .amber // Borde amarillo si está seleccionado
                                : Colors.grey,
                          )),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE', 'es_ES').format(date),
                            style: GoogleFonts.manrope(
                              fontSize: 14.sp,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            DateFormat('d MMM', 'es_ES').format(date),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 30.h,
            ),
            _selectedIndex != -1
                ? Container(
                    height: 1.sh - 350.h,
                    child: cargando
                        ? Center(child: CircularProgressIndicator())
                        : pedidosConductor.isNotEmpty
                            ? Skeletonizer(
                                enabled: esperando,
                                child: ListView.builder(
                                  itemCount: pedidosConductor.length,
                                  itemBuilder: (context, index1) {
                                    // DISMISSIBLE INICIO
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Skeletonizer(
                                          enabled: false,
                                          effect: ShimmerEffect(
                                              baseColor: Colors.white,
                                              highlightColor:
                                                  Colors.grey.shade500),
                                          child: Container(
                                            height: 111.h,
                                            padding: EdgeInsets.all(10.r),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              color: const Color.fromARGB(
                                                  255, 255, 255, 255),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                  width: 153.h,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Container(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                          children: [
                                                            Container(
                                                              width: 45.h,
                                                              height: 45.h,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    214,
                                                                    214,
                                                                    214),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50.r),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              "${pedidosConductor[index1].clienteNombre}",
                                                              style: GoogleFonts
                                                                  .manrope(
                                                                      fontSize:
                                                                          14.sp,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade600),
                                                            ),
                                                            Text(
                                                              "S/.${pedidosConductor[index1].total}",
                                                              style: GoogleFonts.manrope(
                                                                  fontSize:
                                                                      14.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                            Text(
                                                              "${DateFormat('yyyy-MM-dd').format(pedidosConductor[index1].fecha)}",
                                                              style: GoogleFonts
                                                                  .manrope(
                                                                      fontSize:
                                                                          14.sp,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade600),
                                                            )
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  width: 153.h,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        "ID: #${pedidosConductor[index1].id}",
                                                        style:
                                                            GoogleFonts.manrope(
                                                                fontSize: 14.sp,
                                                                color: const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    66,
                                                                    66,
                                                                    66)),
                                                      ),
                                                      Text(
                                                        "${pedidosConductor[index1].tipo}",
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
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      6.r),
                                                          color: Colors
                                                              .grey.shade300,
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            "${pedidosConductor[index1].estado}",
                                                            style: GoogleFonts
                                                                .manrope(
                                                                    color: const Color
                                                                        .fromARGB(
                                                                        255,
                                                                        53,
                                                                        41,
                                                                        158)),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Skeletonizer(
                                          enabled: false,
                                          effect: ShimmerEffect(
                                              baseColor: Colors.white,
                                              highlightColor:
                                                  Colors.grey.shade500),
                                          child: Container(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Text(
                                                  "Dirección: ",
                                                  style: GoogleFonts.manrope(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w300),
                                                ),
                                                Text(
                                                  "${pedidosConductor[index1].ubicacion.distrito} ${pedidosConductor[index1].ubicacion.direccion}",
                                                  style: GoogleFonts.manrope(
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 20.h,
                                        ),
                                        Skeletonizer(
                                          enabled: false,
                                          effect: ShimmerEffect(
                                              baseColor: Colors.white,
                                              highlightColor:
                                                  Colors.grey.shade500),
                                          child: Container(
                                            height: pedidosConductor[index1]
                                                        .detallesPedido
                                                        .length ==
                                                    1
                                                ? 80.w
                                                : 180.h,
                                            color: Colors.amber,
                                            child: ListView.builder(
                                              itemCount:
                                                  pedidosConductor[index1]
                                                      .detallesPedido
                                                      .length,
                                              itemBuilder: (context, index) {
                                                return Container(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            height: 60.w,
                                                            width: 60.w,
                                                            color: Colors
                                                                .grey.shade200,
                                                          ),
                                                          SizedBox(
                                                            width: 10.w,
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                "${pedidosConductor[index1].detallesPedido[index].productoNombre}",
                                                                style: GoogleFonts.manrope(
                                                                    fontSize:
                                                                        14.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              ),
                                                              Text(
                                                                "${pedidosConductor[index1].detallesPedido[index].cantidad}",
                                                                style: GoogleFonts.manrope(
                                                                    fontSize:
                                                                        16.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400),
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        height: 10.h,
                                                      )
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10.h),
                                        Container(
                                          width: 1.sw,
                                          child: Divider(height: 2.h),
                                        ),
                                        SizedBox(height: 10.h),
                                      ],
                                    );
                                  },
                                ),
                              )
                            : Center(child: Text("No hay pedidos en este día")))
                : Text("Selecciona un día para ver tus pedidos"),
          ],
        ),
      ),
    );
  }
}
