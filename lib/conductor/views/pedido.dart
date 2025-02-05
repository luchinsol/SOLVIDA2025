import 'package:app2025/config/socketcentral.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DrivePedidos extends StatefulWidget {
  const DrivePedidos({Key? key}) : super(key: key);
  @override
  State<DrivePedidos> createState() => _DrivePedidosState();
}

class _DrivePedidosState extends State<DrivePedidos> {
  // ATRIBUTOS
  late List<bool>
      selected; // Lista para controlar el estado expandido de cada ítem

  late List<List<Color>> colorDeploy;
  List<LatLng> polypoints = [];
  LatLng _currentPosition = const LatLng(-16.4014, -71.5343);
  BitmapDescriptor? _destinationIcon;
  String _mapStyle = '';
  final SocketService socketService = SocketService();

  // FUNCIONES
  Future<void> _loadMarkerIcons() async {
    _destinationIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(100, 80)),
      'lib/imagenes/house3d.png',
    );
  }

  Future<void> _loadMapStyle() async {
    String style = await rootBundle.loadString('lib/stylemap/estilomap.json');
    setState(() {
      _mapStyle = style;
    });
  }

  Future<List<LatLng>> getPolypoints(LatLng origin, LatLng destination) async {
    List<LatLng> polyPoints = [];

    // Validación de coordenadas fuera de rango
    if (origin.latitude < -90 ||
        origin.latitude > 90 ||
        origin.longitude < -180 ||
        origin.longitude > 180 ||
        destination.latitude < -90 ||
        destination.latitude > 90 ||
        destination.longitude < -180 ||
        destination.longitude > 180) {
      print("Las coordenadas ingresadas están fuera de rango.");
      return polyPoints; // Retorna la lista vacía
    }

    try {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey:
            "AIzaSyA45xOgppdm-PXYDE5r07eDlkFuPzYmI9g", // Asegúrate de usar tu API Key
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving, // Puedes cambiar a walking, biking, etc.
        ),
      );

      if (result.status == "OK" && result.points.isNotEmpty) {
        result.points.forEach((PointLatLng point) {
          polyPoints.add(LatLng(point.latitude, point.longitude));
        });
        print("Puntos de la ruta obtenidos correctamente.");
      } else if (result.status == "ZERO_RESULTS") {
        print("No se encontraron resultados para la ruta.");
      } else {
        print("Error al obtener la ruta: ${result.status}");
      }
    } catch (e) {
      print("Error al obtener la ruta: $e");
    }

    return polyPoints;
  }

  @override
  void initState() {
    super.initState();
    socketService.loadConductorEvent(3);
    socketService.onHolapedido((data) {
      print("$data");
    });

    /* socketService.

    socketService.emitEvent('register_driver', 1);

    socketService.((data) {
      print("Llegué tarde $data");
    });

    socketService.onPedidoNow((data) {
      print("A tiempo $data");
    });*/

    _loadMarkerIcons();
    _loadMapStyle();
    selected = List.generate(
        50, (_) => false); // Inicializa todos los ítems como "no seleccionados"

    // Inicializar las listas dinámicamente con el número recibido

    colorDeploy = List.generate(
      50,
      (_) => [
        const Color.fromARGB(255, 216, 217, 234).withOpacity(0.2),
        const Color.fromARGB(255, 43, 40, 195),
      ], // Colores por defecto
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          //foregroundColor: Colors.white,
          //shadowColor: Colors.white,
          backgroundColor: Colors.white,
          title: Text(
            "Pedidos (5)",
            style: GoogleFonts.manrope(fontSize: 16.sp),
          ),
        ),
        body: Padding(
          padding:
              EdgeInsets.only(top: 32.r, bottom: 20.r, left: 17.r, right: 17.r),
          child: Container(
            // color: Colors.grey,
            height: 1.sh,
            child: ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Skeletonizer(
                      enabled: false,
                      effect: ShimmerEffect(
                          baseColor: Colors.white,
                          highlightColor: Colors.grey.shade500),
                      child: Material(
                        elevation: 5.r,
                        borderRadius: BorderRadius.circular(20.r),
                        child: AnimatedContainer(
                          padding: EdgeInsets.all(7.r),
                          alignment: Alignment.topCenter,
                          height: selected[index] ? 990.0.h : 225.5.h,
                          decoration: BoxDecoration(
                            border: Border.all(
                                // color: const Color.fromRGBO(42, 75, 160, 0.575),
                                width: 0.05),
                            color: selected[index]
                                ? colorDeploy[index][0]
                                : colorDeploy[index][1],
                            //color: const Color.fromARGB(255, 255, 255, 255),
                            // color: const Color.fromARGB(255, 27, 51, 160),
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
                                height: 145.h,
                                //color: Colors.green,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // FOTO Y NOMBRE
                                        Container(
                                          //color: Colors.amber,
                                          width: 153.h,
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        width: 45.h,
                                                        height: 45.h,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color
                                                              .fromARGB(255,
                                                              224, 224, 224),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      50.r),
                                                        ),
                                                      ),
                                                      /*Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            "4.5",
                                                            style: GoogleFonts.manrope(
                                                                fontSize: 14.sp),
                                                          ),
                                                          Icon(
                                                            Icons.star_rate_rounded,
                                                            color: Colors.amber,
                                                          ),
                                                        ],
                                                      ),*/
                                                    ],
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
                                                        "Luis Gonzáles",
                                                        style: GoogleFonts.manrope(
                                                            fontSize: 14.sp,
                                                            color: selected[
                                                                    index]
                                                                ? Colors.grey
                                                                    .shade600
                                                                : Colors.white

                                                            //Colors.grey.shade600

                                                            ),
                                                      ),
                                                      Text(
                                                        "S/.7.90",
                                                        style: GoogleFonts.manrope(
                                                            fontSize: 14.sp,
                                                            color: selected[
                                                                    index]
                                                                ? const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    45,
                                                                    45,
                                                                    45)
                                                                : Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Text(
                                                        "02/10/2024",
                                                        style:
                                                            GoogleFonts.manrope(
                                                                fontSize: 14.sp,
                                                                color: selected[
                                                                        index]
                                                                    ? Colors
                                                                        .grey
                                                                        .shade600
                                                                    : Colors
                                                                        .white),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // ID Y TIPO
                                        Container(
                                          width: 153.h,
                                          //color: Colors.white,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "ID: #7654321",
                                                style: GoogleFonts.manrope(
                                                    fontSize: 14.sp,
                                                    color: selected[index]
                                                        ? Colors.grey.shade600
                                                        : Colors.white),
                                              ),
                                              Text(
                                                "Normal",
                                                style: GoogleFonts.manrope(
                                                    fontSize: 14.sp,
                                                    color: selected[index]
                                                        ? const Color.fromARGB(
                                                            255, 23, 3, 154)
                                                        : const Color.fromARGB(
                                                            255, 255, 217, 0),
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 18.h,
                                    ),
                                    Text(
                                      "Dirección",
                                      style: GoogleFonts.manrope(
                                          fontSize: 14.sp,
                                          color: selected[index]
                                              ? Colors.grey.shade600
                                              : Colors.white),
                                    ),
                                    SizedBox(
                                      height: 8.h,
                                    ),
                                    Text(
                                      "Av. Los Cristales, Socabaya, Tumbes 8, Arequipa",
                                      style: GoogleFonts.manrope(
                                          fontSize: 14.sp,
                                          color: selected[index]
                                              ? Colors.grey.shade600
                                              : Colors.white,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(height: 8.h),
                                  ],
                                ),
                              ),

                              // Contenido que se muestra/oculta

                              Visibility(
                                visible: selected[index],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 20.h),
                                    Container(
                                      // width: double.infinity,
                                      height: 400.h,
                                      decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: GoogleMap(
                                        initialCameraPosition: CameraPosition(
                                          zoom: 12,
                                          target: LatLng(-16.413450316315654,
                                              -71.54644357515753),
                                        ),
                                        /* polylines: {
                                          Polyline(
                                              polylineId: PolylineId("IDruta"),
                                              points: polypoints,
                                              color: Colors.blue,
                                              width: 5)
                                        },*/
                                        markers: {
                                          if (_destinationIcon != null)
                                            Marker(
                                                markerId: MarkerId("destino"),
                                                icon: _destinationIcon!,
                                                position: LatLng(
                                                    -16.410472367054158,
                                                    -71.57064420197324))
                                        },
                                        // mapType: MapType.normal,
                                        style: _mapStyle,
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      "Lista de productos (5)",
                                      style: GoogleFonts.manrope(
                                          fontSize: 14.sp,
                                          color: Colors.grey.shade600),
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                        height: 220.h,
                                        color: Colors.amber,
                                        child: ListView.builder(
                                            itemCount: 10,
                                            itemBuilder: (context, index) {
                                              return Column(
                                                children: [
                                                  Container(
                                                    height: 66.h,
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          "Producto",
                                                          style: GoogleFonts
                                                              .manrope(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      14.sp),
                                                        ),
                                                        SizedBox(
                                                          width: 20.w,
                                                        ),
                                                        Text(
                                                          "4",
                                                          style: GoogleFonts
                                                              .manrope(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      14.sp),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  Divider(
                                                    height: 0.1.h,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ],
                                              );
                                            })),
                                    SizedBox(height: 20.h),
                                    Row(
                                      // crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 44.h,
                                          width: 121.w,
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ButtonStyle(
                                              shape: WidgetStatePropertyAll(
                                                  RoundedRectangleBorder(
                                                      side: const BorderSide(
                                                        width: 1.0,
                                                        color: Color.fromRGBO(
                                                            42, 75, 160, 1),
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.r))),
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                      Colors.white),
                                            ),
                                            child: Text(
                                              "Ignorar",
                                              style: GoogleFonts.manrope(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                color: const Color.fromRGBO(
                                                    42, 75, 160, 1),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 45.w,
                                        ),
                                        Container(
                                          height: 44.h,
                                          width: 121.w,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              context.push('/drive/cargar');
                                            },
                                            style: ButtonStyle(
                                              shape: WidgetStatePropertyAll(
                                                  RoundedRectangleBorder(
                                                      side: const BorderSide(
                                                        width: 1.0,
                                                        color: Color.fromRGBO(
                                                            42, 75, 160, 1),
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.r))),
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                const Color.fromRGBO(
                                                    42, 75, 160, 1),
                                              ),
                                            ),
                                            child: Text(
                                              "Aceptar",
                                              style: GoogleFonts.manrope(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Muesca
                              IconButton(
                                onPressed: () async {
                                  /*LatLng destino = LatLng(
                                      -16.410472367054158, -71.57064420197324);*/
                                  /* List<LatLng> routePoints =
                                      await getPolypoints(
                                          _currentPosition, destino);*/
                                  setState(() {
                                    // polypoints = routePoints;
                                    selected[index] = !selected[index];
                                  });
                                },
                                icon: Icon(
                                  size: 28.9.sp,
                                  color: selected[index]
                                      ? Colors.grey.shade600
                                      : Colors.white,
                                  selected[index]
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_sharp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10.5.h,
                    ),
                    Container(
                      width: 345.w,
                      child: Divider(
                        height: 10.h,
                        color: const Color.fromARGB(255, 207, 233, 12),
                      ),
                    ),
                    SizedBox(
                      height: 10.5.h,
                    ),
                  ],
                );
              },
            ),
          ),
        ));
  }
}
