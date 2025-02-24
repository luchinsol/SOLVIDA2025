import 'dart:convert';

import 'package:app2025/conductor/config/notifications.dart';
import 'package:app2025/conductor/config/socketcentral.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:app2025/conductor/providers/conexionswitch_provider.dart';
import 'package:app2025/conductor/providers/notificacioncustom_provider.dart';
//import 'package:app2025/conductor/providers/pedidos_provider.dart';
import 'package:app2025/conductor/providers/pedidos_provider2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

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
  //final SocketService socketService = SocketService();
  //static const int _conductorId = 3;
  late PedidosProvider2 _provider;
  // Creamos un Map que actúa como caché para almacenar las direcciones
  // La llave es el ID del pedido y el valor es la dirección en texto
  Map<String, String> addresses = {};
  bool _isLoading = true; // Nuevo flag para controlar el estado de carga
  String microUrl = dotenv.env['MICRO_URL'] ?? '';
  int? conductorId = 0;
  //notifactions

  // FUNCIONES
  Future<void> _loadMarkerIcons() async {
    _destinationIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(100, 80)),
      'lib/imagenes/house3d.png',
    );
  }

  Future<void> _loadMapStyle() async {
    String style =
        await rootBundle.loadString('lib/conductor/stylemap/estilomap.json');
    setState(() {
      _mapStyle = style;
    });
  }
/*
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
  }*/

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<PedidosProvider2>(context, listen: false);
    final conductorProvider =
        Provider.of<ConductorProvider>(context, listen: false);
    setState(() {
      conductorId = conductorProvider.conductor!.id;
    });

    print('🔄 Initializing DrivePedidos state');
    _initializeAll();
    final notificationsService = NotificationsService();
    notificationsService.initNotification();
    notificationsService.requestNotificationPermission();
  }

  // Versión mejorada de handlePedidoAcceptance
  Future<void> handlePedidoAcceptance(
      dynamic pedidoid, dynamic almacenid) async {
    try {
      // 1. Obtener el provider
      final provider = Provider.of<PedidosProvider2>(context, listen: false);

      // 2. Aceptar el pedido
      await provider.aceptarPedido(pedidoid);

      // 3. Actualizar estado
      await actualizarEstadoPedido(pedidoid, almacenid);

      // 4. Navegación usando GoRouter
      if (!mounted) return;

      // Usar BuildContext.go() dentro de un Future delayed para asegurar que la navegación ocurra
      Future.delayed(Duration.zero, () {
        if (mounted) {
          GoRouter.of(context).go('/drive/cargar');
        }
      });
    } catch (e) {
      print('Error al manejar la aceptación del pedido: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Este Pedido Fue Tomado por Otro Conductor',
            style: GoogleFonts.manrope(
                fontSize: 17.sp, fontWeight: FontWeight.w300),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> actualizarEstadoPedido(String pedidoId, int almacenId) async {
    final url = Uri.parse('${microUrl}/pedido_estado/$pedidoId');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conductor_id': conductorId!,
          'estado': 'en proceso',
          'almacen_id': almacenId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar estado: ${response.body}');
      }
    } catch (e) {
      print('Error en la llamada al API: $e');
      rethrow; // Relanzar el error para manejarlo en handlePedidoAcceptance
    }
  }

  Future<void> _initializeAll() async {
    try {
      setState(() => _isLoading = true);

      await Future.wait([
        _loadMarkerIcons(),
        _loadMapStyle(),
        _provider.loadInitialData(conductorId!),
      ]);

      print('✅ All initialization completed');
      _initializeData();
    } catch (e) {
      print('❌ Error in initialization: $e');
    } finally {
      if (mounted) {
        // Usamos addPostFrameCallback para evitar llamar a setState durante el build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => _isLoading =
              false); // Actualizamos el estado después de la construcción
        });
      }
    }
  }

  void _onPedidosChanged() {
    if (mounted) {
      _initializeData();
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_provider.getActivePedidos().isEmpty) {
      _initializeData();
    }
  }

  void _showDialog(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Notificación"),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _initializeData() {
    if (!mounted) return;

    final activePedidos = _provider.getActivePedidos();
    print('📊 Initializing data with ${activePedidos.length} active pedidos');

    setState(() {
      selected = List.generate(activePedidos.length, (_) => false);
      colorDeploy = List.generate(
        activePedidos.length,
        (_) => [Colors.white, const Color.fromRGBO(42, 75, 160, 1)],
      );
    });
  }

  @override
  void dispose() {
    _provider.removeListener(_onPedidosChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conexionTrabajo =
        Provider.of<ConductorConnectionProvider>(context, listen: false);
    return Consumer<PedidosProvider2>(builder: (context, provider, child) {
      final activePedidos = provider.getActivePedidos();
      if (_isLoading) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      print('🔄 UI - Pedidos activos: ${activePedidos.length}'); // Debug

      if (selected.length != activePedidos.length) {
        selected = List.generate(activePedidos.length, (_) => false);
        colorDeploy = List.generate(
            activePedidos.length,
            (_) => [
                  Colors.white,
                  const Color.fromRGBO(42, 75, 160, 1),
                ]);
      }

      return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            //foregroundColor: Colors.white,
            //shadowColor: Colors.white,
            backgroundColor: Colors.white,
            title: Text(
              "Pedidos (${activePedidos.length})",
              style: GoogleFonts.manrope(fontSize: 16.sp),
            ),
          ),
          body: Padding(
            padding: EdgeInsets.only(
                top: 32.r, bottom: 20.r, left: 17.r, right: 17.r),
            child: Container(
              // color: Colors.grey,
              height: 1.sh,
              child: conexionTrabajo.isConnected
                  ? (activePedidos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 300.w,
                                height: 200.w,
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            'lib/imagenes/truckwait.png'))),
                              ),
                              Text(
                                "Espera tus pedidos aquí",
                                style: GoogleFonts.manrope(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w300),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: activePedidos.length,
                          itemBuilder: (context, index) {
                            final pedido = activePedidos[index];
                            final clienteNombre =
                                pedido.cliente.nombre ?? 'Cliente sin nombre';
                            final total = pedido.total ?? 0.0;
                            final estado = pedido.estado ?? 'Estado pendiente';
                            final emittedTime =
                                pedido.emittedTime ?? DateTime.now();
                            final latitud = pedido.ubicacion['latitud'] ?? -16;
                            final longitud =
                                pedido.ubicacion['longitud'] ?? -71;
                            final departamento =
                                pedido.ubicacion['departamento'];
                            final provincia = pedido.ubicacion['provincia'];
                            final distrito = pedido.ubicacion['distrito'];
                            final direccion = pedido.ubicacion['direccion'];
                            final direccionCompleta =
                                '${pedido.ubicacion['direccion']}, ${pedido.ubicacion['distrito']}, ${pedido.ubicacion['provincia']}, ${pedido.ubicacion['departamento']}';

                            print("VERIFICANDO LAS COORDENADAS");
                            print(longitud);
                            print(latitud);
                            print(direccionCompleta);
                            /*
                          if (!addresses.containsKey(pedido.id)) {
                            getAddress(latitud, longitud, pedido.id);
                          }*/
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
                                      height:
                                          selected[index] ? 1020.0.h : 225.5.h,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            // color: const Color.fromRGBO(42, 75, 160, 0.575),
                                            width: 0.05),
                                        color: selected[index]
                                            ? colorDeploy[index][0]
                                            : colorDeploy[index][1],
                                        //color: const Color.fromARGB(255, 255, 255, 255),
                                        // color: const Color.fromARGB(255, 27, 51, 160),
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      duration:
                                          const Duration(milliseconds: 450),
                                      curve: Curves.easeInOut,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          // Cabecera: Siempre visible
                                          Container(
                                            height: 145.h,
                                            //color: Colors.green,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
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
                                                                    height:
                                                                        45.h,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: const Color
                                                                          .fromARGB(
                                                                          255,
                                                                          224,
                                                                          224,
                                                                          224),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
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
                                                                    clienteNombre,
                                                                    style: GoogleFonts.manrope(
                                                                        fontSize: 14
                                                                            .sp,
                                                                        color: selected[index]
                                                                            ? Colors.grey.shade600
                                                                            : Colors.white

                                                                        //Colors.grey.shade600

                                                                        ),
                                                                  ),
                                                                  Text(
                                                                    "S/.${total.toStringAsFixed(2)}",
                                                                    style: GoogleFonts.manrope(
                                                                        fontSize: 14
                                                                            .sp,
                                                                        color: selected[index]
                                                                            ? const Color.fromARGB(
                                                                                255,
                                                                                45,
                                                                                45,
                                                                                45)
                                                                            : Colors
                                                                                .white,
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                  Text(
                                                                    pedido
                                                                        .emittedTime
                                                                        .toString()
                                                                        .split(
                                                                            ' ')[0],
                                                                    style: GoogleFonts.manrope(
                                                                        fontSize: 14
                                                                            .sp,
                                                                        color: selected[index]
                                                                            ? Colors.grey.shade600
                                                                            : Colors.white),
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
                                                            CrossAxisAlignment
                                                                .end,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            "ID: #${pedido.id}",
                                                            style: GoogleFonts.manrope(
                                                                fontSize: 14.sp,
                                                                color: selected[
                                                                        index]
                                                                    ? Colors
                                                                        .grey
                                                                        .shade600
                                                                    : Colors
                                                                        .white),
                                                          ),
                                                          Text(
                                                            pedido.pedidoinfo[
                                                                'estado'],
                                                            style: GoogleFonts.manrope(
                                                                fontSize: 14.sp,
                                                                color: selected[
                                                                        index]
                                                                    ? const Color
                                                                        .fromARGB(
                                                                        255,
                                                                        23,
                                                                        3,
                                                                        154)
                                                                    : const Color
                                                                        .fromARGB(
                                                                        255,
                                                                        255,
                                                                        217,
                                                                        0),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          StreamBuilder(
                                                            stream:
                                                                Stream.periodic(
                                                                    const Duration(
                                                                        seconds:
                                                                            1)),
                                                            builder: (context,
                                                                snapshot) {
                                                              final tiempoRestante = pedido
                                                                  .expiredTime
                                                                  .difference(
                                                                      DateTime
                                                                          .now());

                                                              if (tiempoRestante
                                                                  .isNegative) {
                                                                return Text(
                                                                  'Expirado',
                                                                  style: GoogleFonts.manrope(
                                                                      fontSize:
                                                                          12.sp,
                                                                      color: Colors
                                                                          .red,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500),
                                                                );
                                                              }

                                                              // Format remaining time as mm:ss
                                                              final minutes =
                                                                  tiempoRestante
                                                                      .inMinutes;
                                                              final seconds =
                                                                  tiempoRestante
                                                                          .inSeconds %
                                                                      60;
                                                              return Text(
                                                                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                                                style: GoogleFonts.manrope(
                                                                    fontSize:
                                                                        12.sp,
                                                                    color: selected[
                                                                            index]
                                                                        ? const Color
                                                                            .fromARGB(
                                                                            255,
                                                                            23,
                                                                            3,
                                                                            154)
                                                                        : Colors
                                                                            .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                              );
                                                            },
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
                                                  direccionCompleta ??
                                                      "Cargando dirección...",
                                                  style: GoogleFonts.manrope(
                                                      fontSize: 14.sp,
                                                      color: selected[index]
                                                          ? Colors.grey.shade600
                                                          : Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                SizedBox(height: 8.h),
                                              ],
                                            ),
                                          ),

                                          // Reemplaza la sección de los botones con este código
// (justo después del SizedBox(height: 8.h) que está debajo del texto de dirección)

                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 5.h),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // Botón Ignorar
                                                SizedBox(
                                                  height: 40.h,
                                                  width: 110.w,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      final provider = Provider
                                                          .of<PedidosProvider2>(
                                                              context,
                                                              listen: false);
                                                      provider.ignorarPedido(
                                                          pedido.toMap());

                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Pedido ignorado',
                                                            style: GoogleFonts
                                                                .manrope(
                                                                    fontSize:
                                                                        14.sp),
                                                          ),
                                                          duration:
                                                              const Duration(
                                                                  seconds: 2),
                                                        ),
                                                      );
                                                    },
                                                    style: ButtonStyle(
                                                      shape:
                                                          MaterialStateProperty
                                                              .all(
                                                        RoundedRectangleBorder(
                                                          side:
                                                              const BorderSide(
                                                            width: 1.0,
                                                            color:
                                                                Color.fromRGBO(
                                                                    42,
                                                                    75,
                                                                    160,
                                                                    1),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      15.r),
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all(
                                                                  Colors.white),
                                                    ),
                                                    child: Text(
                                                      "Ignorar",
                                                      style:
                                                          GoogleFonts.manrope(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: const Color
                                                            .fromRGBO(
                                                            42, 75, 160, 1),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // Botón Aceptar
                                                SizedBox(
                                                  height: 40.h,
                                                  width: 110.w,
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      try {
                                                        await handlePedidoAcceptance(
                                                          pedido.id,
                                                          pedido.almacenId,
                                                        );
                                                      } catch (e) {
                                                        if (!mounted) return;
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Error al aceptar el pedido: $e',
                                                              style: GoogleFonts
                                                                  .manrope(
                                                                      fontSize:
                                                                          14.sp),
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    style: ButtonStyle(
                                                      shape:
                                                          MaterialStateProperty
                                                              .all(
                                                        RoundedRectangleBorder(
                                                          side:
                                                              const BorderSide(
                                                            width: 1.0,
                                                            color:
                                                                Color.fromRGBO(
                                                                    42,
                                                                    75,
                                                                    160,
                                                                    1),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      15.r),
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all(
                                                        const Color.fromRGBO(
                                                            42, 75, 160, 1),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "Aceptar",
                                                      style:
                                                          GoogleFonts.manrope(
                                                        fontSize: 13.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          /*
                                          Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Ignorar
          ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        side: WidgetStateProperty.all(BorderSide(
          color: Color.fromRGBO(42, 75, 160, 1),
          width: 1.0,
        )),
      child: Text(
        "Ignorar",
        style: TextStyle(color: Color.fromRGBO(42, 75, 160, 1)),
      onPressed: () {...},
    ),
          
          // Botón Aceptar
          ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          selected[index] 
            ? Color.fromRGBO(42, 75, 160, 1)
            : Colors.white),
        side: WidgetStateProperty.all(BorderSide(
          color: Color.fromRGBO(42, 75, 160, 1),
          width: 1.0,
        )),
      child: Text(
        "Aceptar",
        style: TextStyle(
          color: selected[index] ? Colors.white : Color.fromRGBO(42, 75, 160, 1)),
      onPressed: () {...},
    ),
        ],
      ),
    ),
  */

                                          // Contenido que se muestra/oculta

                                          Visibility(
                                            visible: selected[index],
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: 20.h),
                                                (latitud == null ||
                                                        longitud == null)
                                                    ? Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                                color: Colors
                                                                    .blue))
                                                    : Container(
                                                        // width: double.infinity,
                                                        height: 400.h,
                                                        decoration: BoxDecoration(
                                                            color: Colors
                                                                .blue.shade100,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20)),
                                                        child: GoogleMap(
                                                          initialCameraPosition:
                                                              CameraPosition(
                                                            zoom: 12,
                                                            target: LatLng(
                                                                pedido.ubicacion[
                                                                    'latitud'],
                                                                pedido.ubicacion[
                                                                    'longitud']),
                                                          ),
                                                          /* polylines: {
                                          Polyline(
                                              polylineId: PolylineId("IDruta"),
                                              points: polypoints,
                                              color: Colors.blue,
                                              width: 5)
                                        },*/
                                                          markers: {
                                                            if (_destinationIcon !=
                                                                null)
                                                              Marker(
                                                                  markerId:
                                                                      MarkerId(
                                                                          "destino"),
                                                                  icon:
                                                                      _destinationIcon!,
                                                                  position: LatLng(
                                                                      pedido.ubicacion[
                                                                          'latitud'],
                                                                      pedido.ubicacion[
                                                                          'longitud']))
                                                          },
                                                          // mapType: MapType.normal,
                                                          style: _mapStyle,
                                                        ),
                                                      ),
                                                SizedBox(height: 10.h),
                                                Text(
                                                  "Lista de productos (${pedido.productos.length + pedido.promociones.length})",
                                                  style: GoogleFonts.manrope(
                                                      fontSize: 14.sp,
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                                SizedBox(height: 10.h),
                                                Container(
                                                    height: 220.h,
                                                    color: Colors.amber,
                                                    child: ListView.builder(
                                                        //Sumamos las cantidades de pedidos y productos para tener un total
                                                        itemCount: pedido
                                                                .productos
                                                                .length +
                                                            pedido.promociones
                                                                .length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          //colocamos valores cambiantes ya que los productos y promociones pasan por 3 condiciones uno es cuando no haya ningun producto otro es cuando no haya ninguna promociones y otra es cuando existan ambas
                                                          dynamic item;
                                                          String name;
                                                          int quantity;
                                                          //condicion para saber si hay productos
                                                          if (index <
                                                              pedido.productos
                                                                  .length) {
                                                            // esto indica que hay productos
                                                            item = pedido
                                                                    .productos[
                                                                index];
                                                            name = item.nombre;
                                                            quantity =
                                                                item.cantidad;
                                                          } else {
                                                            // en caso no hayan productos recorre las promociones
                                                            item = pedido
                                                                    .promociones[
                                                                index -
                                                                    pedido
                                                                        .productos
                                                                        .length];
                                                            name = item.nombre;
                                                            quantity =
                                                                item.cantidad;
                                                          }
                                                          return Column(
                                                            children: [
                                                              Container(
                                                                height: 66.h,
                                                                child: Row(
                                                                  children: [
                                                                    Text(
                                                                      name,
                                                                      style: GoogleFonts.manrope(
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              14.sp),
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          20.w,
                                                                    ),
                                                                    Text(
                                                                      quantity
                                                                          .toString(),
                                                                      style: GoogleFonts.manrope(
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              14.sp),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                              Divider(
                                                                height: 0.1.h,
                                                                color: Colors
                                                                    .grey
                                                                    .shade400,
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
                                                        onPressed: () {
                                                          final provider = Provider
                                                              .of<PedidosProvider2>(
                                                                  context,
                                                                  listen:
                                                                      false);

                                                          // Emitir el evento de pedido expirado
                                                          provider
                                                              .ignorarPedido(
                                                                  pedido
                                                                      .toMap());

                                                          // Opcional: Puedes agregar alguna retroalimentación visual
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  'Pedido ignorado'),
                                                              duration:
                                                                  const Duration(
                                                                      seconds:
                                                                          2),
                                                            ),
                                                          );
                                                        },
                                                        style: ButtonStyle(
                                                          shape: WidgetStatePropertyAll(
                                                              RoundedRectangleBorder(
                                                                  side:
                                                                      const BorderSide(
                                                                    width: 1.0,
                                                                    color: Color
                                                                        .fromRGBO(
                                                                            42,
                                                                            75,
                                                                            160,
                                                                            1),
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20.r))),
                                                          backgroundColor:
                                                              WidgetStateProperty
                                                                  .all(Colors
                                                                      .white),
                                                        ),
                                                        child: Text(
                                                          "Ignorar",
                                                          style: GoogleFonts
                                                              .manrope(
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: const Color
                                                                .fromRGBO(
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
                                                        onPressed: () async {
                                                          await handlePedidoAcceptance(
                                                              pedido.id,
                                                              pedido.almacenId);
                                                          /*
                                                        await provider
                                                            .aceptarPedido(
                                                                pedido.id);

                                                        // Mostrar mensaje de éxito

                                                        await actualizarEstadoPedido(
                                                            pedido.id,
                                                            _conductorId,
                                                            pedido.almacenId);
                                                        context.go(
                                                            '/drive/cargar');*/
                                                        },
                                                        style: ButtonStyle(
                                                          shape: WidgetStatePropertyAll(
                                                              RoundedRectangleBorder(
                                                                  side:
                                                                      const BorderSide(
                                                                    width: 1.0,
                                                                    color: Color
                                                                        .fromRGBO(
                                                                            42,
                                                                            75,
                                                                            160,
                                                                            1),
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20.r))),
                                                          backgroundColor:
                                                              WidgetStateProperty
                                                                  .all(
                                                            const Color
                                                                .fromRGBO(
                                                                42, 75, 160, 1),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          "Aceptar",
                                                          style: GoogleFonts
                                                              .manrope(
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
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
                                                selected[index] =
                                                    !selected[index];
                                              });
                                            },
                                            icon: Icon(
                                              size: 28.9.sp,
                                              color: selected[index]
                                                  ? Colors.grey.shade600
                                                  : Colors.white,
                                              selected[index]
                                                  ? Icons
                                                      .keyboard_arrow_up_rounded
                                                  : Icons
                                                      .keyboard_arrow_down_sharp,
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
                                    color:
                                        const Color.fromARGB(255, 207, 233, 12),
                                  ),
                                ),
                                SizedBox(
                                  height: 10.5.h,
                                ),
                              ],
                            );
                          },
                        ))
                  : Center(
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
                    ),
            ),
          ));
    });
  }
}
