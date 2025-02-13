import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadMarkerIcons();
    // Inicializa todos los ítems como "no seleccionados"
  }

  @override
  Widget build(BuildContext context) {
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
                                    "Almacén 1",
                                    style: GoogleFonts.manrope(
                                        fontSize: 14.sp,
                                        color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    "Fátima, KM 2.3, Yanahuara, Arequipa",
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
