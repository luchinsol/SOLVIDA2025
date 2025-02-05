import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class Historial extends StatefulWidget {
  const Historial({Key? key}) : super(key: key);

  @override
  State<Historial> createState() => _HistorialState();
}

class _HistorialState extends State<Historial> {
  // Lista inicial (puedes reemplazarla al consumir la API)
  List<String> items = List.generate(10, (index) => 'Elemento ${index + 1}');

  late DateTime _currentDate;
  late List<DateTime> _days;

  int _selectedIndex = -1;
  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _days = _generateDays(_currentDate);
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
    });
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
              "Historial",
              style: GoogleFonts.manrope(fontSize: 16.sp),
            ),
            IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          'Eliminar historial',
                          style:
                              GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          '¿Estás seguro de que deseas eliminar todo el historial?',
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
                icon: const Icon(Icons.delete_outline)),
          ],
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
            Container(
              height: 1.sh - 350.h,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  // DISMISSIBLE INICIO
                  return Dismissible(
                    key: Key(items[index]),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      setState(() {
                        items.removeAt(index);
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Elemento eliminado')),
                      );
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20.r),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    // DISMISIBLE FIN
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeletonizer(
                          enabled: false,
                          effect: ShimmerEffect(
                              baseColor: Colors.white,
                              highlightColor: Colors.grey.shade500),
                          child: Container(
                            height: 111.h,
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 153.h,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                              width: 45.h,
                                              height: 45.h,
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 214, 214, 214),
                                                borderRadius:
                                                    BorderRadius.circular(50.r),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
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
                                          color: Colors.grey.shade300,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Entregado",
                                            style: GoogleFonts.manrope(
                                                color: const Color.fromARGB(
                                                    255, 53, 41, 158)),
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
                              highlightColor: Colors.grey.shade500),
                          child: Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Dirección: ",
                                  style: GoogleFonts.manrope(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w300),
                                ),
                                Text(
                                  "Av. Dolores 204 - Jose Luis Bustamente y Rivero",
                                  style: GoogleFonts.manrope(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600),
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
                              highlightColor: Colors.grey.shade500),
                          child: Container(
                            height: 180.h,
                            color: Colors.amber,
                            child: ListView.builder(
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                return Container(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 60.w,
                                            width: 60.w,
                                            color: Colors.grey.shade200,
                                          ),
                                          SizedBox(
                                            width: 10.w,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Promo Ositos",
                                                style: GoogleFonts.manrope(
                                                    fontSize: 14.sp,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              Text(
                                                "1",
                                                style: GoogleFonts.manrope(
                                                    fontSize: 16.sp,
                                                    fontWeight:
                                                        FontWeight.w400),
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
