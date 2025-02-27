import 'dart:convert';

import 'package:app2025/conductor/config/notifications.dart';
import 'package:app2025/conductor/config/socketcentral.dart';
import 'package:app2025/conductor/model/pedido_model.dart';
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
    // Mostrar un diálogo de carga antes de iniciar el proceso

    try {
      /*if (mounted) {
        showDialog(
          context: context,
          barrierDismissible:
              false, // El usuario no puede cerrar el diálogo tocando fuera
          builder: (BuildContext dialogContext) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        'Procesando pedido...',
                        style: GoogleFonts.manrope(fontSize: 16.sp),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }*/

      // Obtener el provider
      final provider = Provider.of<PedidosProvider2>(context, listen: false);

      // Realizar la aceptación del pedido
      await provider.aceptarPedido(pedidoid);

      // Actualizar el estado
      await actualizarEstadoPedido(pedidoid, almacenid);

      // Cerrar el diálogo de carga si el widget está montado
      /*if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo de carga

        // Navegar a la siguiente pantalla
       
      }*/
      GoRouter.of(context).go('/drive/navegar');
    } catch (e) {
      print('Error al manejar la aceptación del pedido: $e');

      // Cerrar el diálogo de carga si sigue abierto
      /*if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo de carga

        // Mostrar el error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Este Pedido Fue Tomado por Otro Conductor',
              style: GoogleFonts.manrope(
                  fontSize: 16.sp, fontWeight: FontWeight.w300),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }*/
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

  void _mostrarMapa(BuildContext context, Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: 1.sh / 1.85,
            child: Column(
              children: [
                Text(
                  "Pedido #${pedido.id}",
                  style: GoogleFonts.manrope(
                      fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                Container(
                  height: 410.h, // Ajusta según necesites
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleMap(
                      key: ValueKey(
                          pedido.id), // 🔑 Evita recreaciones innecesarias
                      initialCameraPosition: CameraPosition(
                        zoom: 16,
                        target: LatLng(
                          pedido.ubicacion['latitud'],
                          pedido.ubicacion['longitud'],
                        ),
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId("destino"),
                          position: LatLng(
                            pedido.ubicacion['latitud'],
                            pedido.ubicacion['longitud'],
                          ),
                        ),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

      /*if (selected.length != activePedidos.length) {
        selected = List.generate(activePedidos.length, (_) => false);
        colorDeploy = List.generate(
            activePedidos.length,
            (_) => [
                  Colors.white,
                  const Color.fromRGBO(42, 75, 160, 1),
                ]);
      }*/
      if (selected.length < activePedidos.length) {
        // Agregar solo nuevos pedidos sin resetear los existentes
        selected.addAll(List.generate(
            activePedidos.length - selected.length, (_) => false));
        colorDeploy.addAll(List.generate(
            activePedidos.length - colorDeploy.length,
            (_) => [Colors.white, const Color.fromRGBO(42, 75, 160, 1)]));
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
                                      key: ValueKey(activePedidos[index]
                                          .id), // Asigna una clave única
                                      padding: EdgeInsets.all(7.r),
                                      alignment: Alignment.topCenter,
                                      height:
                                          selected[index] ? 600.0.h : 286.5.h,
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
                                            height: 155.h,
                                            // color: Colors.green,
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
                                                                      image: DecorationImage(
                                                                          image:
                                                                              NetworkImage('https://i.pinimg.com/736x/17/ec/61/17ec61d172c7e0860fba0de51dad4ffe.jpg')),
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
                                                      //color: Colors.grey,
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
                                                                fontSize:
                                                                    16.5.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: selected[
                                                                        index]
                                                                    ? Colors
                                                                        .grey
                                                                        .shade600
                                                                    : const Color
                                                                        .fromARGB(
                                                                        255,
                                                                        246,
                                                                        255,
                                                                        118)),
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
                                                              return Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .timer_outlined,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                  Text(
                                                                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                                                    style: GoogleFonts.manrope(
                                                                        fontSize: 12
                                                                            .sp,
                                                                        color: selected[index]
                                                                            ? const Color.fromARGB(
                                                                                255,
                                                                                23,
                                                                                3,
                                                                                154)
                                                                            : Colors
                                                                                .white,
                                                                        fontWeight:
                                                                            FontWeight.w500),
                                                                  ),
                                                                ],
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                                SizedBox(height: 8.h),
                                              ],
                                            ),
                                          ),

                                          // Reemplaza la sección de los botones con este código

                                          SizedBox(
                                            height: 10.h,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 5.h),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // Google Map
                                                Container(
                                                  height: 40.h,
                                                  width: 80.w,
                                                  child: ElevatedButton(
                                                      onPressed: () {
                                                        _mostrarMapa(
                                                            context, pedido);
                                                      },
                                                      style: ButtonStyle(
                                                        shape:
                                                            MaterialStateProperty
                                                                .all(
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
                                                                        15.r),
                                                          ),
                                                        ),
                                                        backgroundColor:
                                                            MaterialStateProperty
                                                                .all(Colors
                                                                    .white),
                                                      ),
                                                      child: Icon(
                                                          Icons.location_pin)),
                                                ),

                                                // Botón Ignorar
                                                Container(
                                                  height: 40.h,
                                                  width: 130.w,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      final provider = Provider
                                                          .of<PedidosProvider2>(
                                                              context,
                                                              listen: false);
                                                      provider
                                                          .ignorarPedidoBoton(
                                                              pedido.toMap());
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
                                                Container(
                                                  height: 40.h,
                                                  width: 130.w,
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      await handlePedidoAcceptance(
                                                        pedido.id,
                                                        pedido.almacenId,
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
                                                                    255,
                                                                    255,
                                                                    255,
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

                                          // Contenido que se muestra/oculta

                                          Visibility(
                                            visible: selected[index],
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: 20.h),
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
                                              ],
                                            ),
                                          ),

                                          // Muesca
                                          IconButton(
                                            onPressed: () async {
                                              setState(() {
                                                // polypoints = routePoints;
                                                selected[index] =
                                                    !selected[index];
                                              });
                                            },
                                            icon: Icon(
                                              size: 23.9.sp,
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
