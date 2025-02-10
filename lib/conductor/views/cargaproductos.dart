import 'dart:convert';

import 'package:app2025/conductor/model/almacenes_model.dart';
import 'package:app2025/conductor/providers/almacen_provider.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:http/http.dart' as http;

class Almacenes extends StatefulWidget {
  const Almacenes({Key? key}) : super(key: key);

  @override
  State<Almacenes> createState() => _AlmacenesState();
}

class _AlmacenesState extends State<Almacenes> {
  int? selectedRadioIndex = 0; // Para controlar qué opción está seleccionada.
  String _mapStyle = '';
  bool selected =
      false; // Lista para controlar el estado expandido de cada ítem

  BitmapDescriptor? _destinationIcon;
  String microUrl = dotenv.env['MICRO_URL'] ?? '';

  Future<void> _loadMapStyle() async {
    String style =
        await rootBundle.loadString('lib/conductor/stylemap/estilomap.json');
    setState(() {
      _mapStyle = style;
    });
  }

  Future<void> _loadMarkerIcons() async {
    _destinationIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(100, 80)),
      'lib/imagenes/almacen3d.png',
    );
  }

  Future<void> cargaAlmacenID() async {
    int? almacenId = 0;
    String? token = '';

    try {
      final conductorProvider =
          Provider.of<ConductorProvider>(context, listen: false);

      if (conductorProvider.conductor != null) {
        setState(() {
          almacenId = conductorProvider.conductor?.evento_id;
        });

        SharedPreferences tokenUser = await SharedPreferences.getInstance();
        setState(() {
          token = tokenUser.getString('token'); // Recupera el token
        });

        if (token == null) {
          print("No hay token almacenado");
          return;
        }
      }

      var res = await http.get(
          Uri.parse(microUrl + '/almacen/' + almacenId.toString()),
          headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        print("alma...............");
        print(data['id']);
        print(data['nombre']);
        print(data['latitud']);
        if (data != null && data is Map<String, dynamic>) {
          // Asegurar que es un mapa válido
          AlmacenModel newAlmacen = AlmacenModel(
            id: data['id'],
            nombre: data['nombre'],
            latitud: data['latitud'],
            longitud: data['longitud'],
            horario: data['horario'],
            departamento: data['departamento'],
            provincia: data['provincia'],
            direccion: data['direccion'],
          );
          Provider.of<AlmacenProvider>(context, listen: false)
              .updateAlmacen(newAlmacen);
        }
      }
    } catch (e) {
      throw Exception('Error get almacen $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadMarkerIcons();
    cargaAlmacenID();
    // Inicializa todos los ítems como "no seleccionados"
  }

  @override
  Widget build(BuildContext context) {
    final almacenProvider = context.watch<AlmacenProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Carga de productos",
          style: GoogleFonts.manrope(fontSize: 16.sp),
        ),
      ),
      body: Padding(
          padding:
              EdgeInsets.only(top: 32.r, bottom: 20.r, left: 17.r, right: 17.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Skeletonizer(
                enabled: false,
                effect: ShimmerEffect(
                    baseColor: Colors.white,
                    highlightColor: Colors.grey.shade500),
                child: AnimatedContainer(
                  padding: EdgeInsets.only(
                      top: 14.r, bottom: 2.r, left: 17.r, right: 17.r),
                  alignment: Alignment.topCenter,
                  height: selected ? 573.0.h : 150.5.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 0.80),
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  clipBehavior: Clip.hardEdge,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Cabecera: Siempre visible
                      Container(
                        height: 70.h,
                        //  color: Colors.green,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // FOTO Y NOMBRE
                            Container(
                              //color: Colors.amber,
                              width: 153.h,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Almacén ${almacenProvider.almacen?.nombre}",
                                    style: GoogleFonts.manrope(
                                        fontSize: 14.sp,
                                        color: Colors.grey.shade600),
                                  ),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Horario: ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 25, 43, 145),
                                            fontSize: 16,
                                          ),
                                        ),
                                        TextSpan(
                                          text: almacenProvider
                                                  .almacen?.horario ??
                                              '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${almacenProvider.almacen?.direccion}, ${almacenProvider.almacen?.provincia}",
                                    style: GoogleFonts.manrope(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            // ID Y TIPO
                            /*Container(
                                width: 153.h,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Radio<int>(
                                      value: index,
                                      groupValue: selectedRadioIndex,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedRadioIndex = value;
                                        });
                                      },
                                      activeColor: Colors
                                          .black, // Color del punto seleccionado
                                      fillColor: MaterialStateProperty.all(
                                        Color.fromRGBO(42, 75, 160, 1),
                                      ), // Color del círculo deseleccionado
                                    ),
                                  ],
                                ),
                              ),*/
                          ],
                        ),
                      ),

                      // Contenido que se muestra/oculta
                      Visibility(
                        visible: selected,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 15.h),
                            Container(
                              // width: double.infinity,
                              height: 400.h,
                              decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(20)),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  zoom: 15.5,
                                  target: LatLng(
                                      -16.413450316315654, -71.54644357515753),
                                ),
                                mapType: MapType.normal,
                                style: _mapStyle,
                                markers: {
                                  if (_destinationIcon != null)
                                    Marker(
                                        markerId: MarkerId("destino"),
                                        icon: _destinationIcon!,
                                        position: LatLng(-16.410472367054158,
                                            -71.57064420197324))
                                },
                              ),
                            ),
                            SizedBox(height: 10.h),
                          ],
                        ),
                      ),

                      // Muesca
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selected = !selected;
                          });
                        },
                        icon: Icon(
                          size: 28.9.sp,
                          selected
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_sharp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 20.h,
              ),
              Container(
                height: 60.h,
                width: 1.sw,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/drive/navegar');
                  },
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1.0.w,
                          color: Color.fromRGBO(42, 75, 160, 1),
                        ),
                        borderRadius: BorderRadius.circular(20.r))),
                    backgroundColor: WidgetStateProperty.all(
                      const Color.fromRGBO(42, 75, 160, 1),
                    ),
                  ),
                  child: Text(
                    "Comenzar",
                    style: GoogleFonts.manrope(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }
}

/*
Radio<int>(
                    value: index,
                    groupValue: selectedRadioIndex,
                    onChanged: (value) {
                      setState(() {
                        selectedRadioIndex = value;
                      });
                    },
                    activeColor: Colors.black, // Color del punto seleccionado
                    fillColor: MaterialStateProperty.all(Colors.grey), // Color del círculo deseleccionado
                  ),*/
