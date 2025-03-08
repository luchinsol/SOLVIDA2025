import 'dart:convert';

import 'package:app2025/conductor/config/notifications.dart';
import 'package:app2025/conductor/config/socketcentral.dart';
import 'package:app2025/conductor/model/pedido_model.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:app2025/conductor/providers/conexionswitch_provider.dart';
import 'package:app2025/conductor/providers/notificacioncustom_provider.dart';
//import 'package:app2025/conductor/providers/pedidos_provider.dart';
import 'package:app2025/conductor/providers/pedidos_provider2.dart';
import 'package:app2025/conductor/views/navegacion.dart';
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

class DrivePedidos2 extends StatefulWidget {
  const DrivePedidos2({Key? key}) : super(key: key);
  @override
  State<DrivePedidos2> createState() => _DrivePedidos2State();
}

class _DrivePedidos2State extends State<DrivePedidos2> {
  // ATRIBUTOS

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
  bool loadingAceptar = false; // Variable de estado

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
      setState(() {
        loadingAceptar = true;
      });

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
    setState(() {
      loadingAceptar = true;
    });
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

  @override
  Widget build(BuildContext context) {
    final conductorProvider =
        Provider.of<ConductorProvider>(context, listen: false);

    final conexionTrabajo =
        Provider.of<ConductorConnectionProvider>(context, listen: false);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 186, 189, 197),
        appBar: AppBar(
          //foregroundColor: Colors.white,
          //shadowColor: Colors.white,
          backgroundColor: Colors.white,
          title:
              Consumer<PedidosProvider2>(builder: (context, provider, child) {
            return Text(
              "Pedidos (${provider.getActivePedidos().length})",
              style: GoogleFonts.manrope(fontSize: 16.sp),
            );
          }),
        ),
        body: Padding(
            padding: EdgeInsets.only(
                top: 32.r, bottom: 20.r, left: 17.r, right: 17.r),
            child: Container(
              // color: Colors.grey,
              height: 1.sh,
              child: conexionTrabajo.isConnected
                  ? Consumer<PedidosProvider2>(
                      builder: (context, provider, child) {
                      final pedidos = provider.getActivePedidos();
                      print("------------lIST PROVIDER ${pedidos.length}");
                      return ListView.builder(
                        itemCount: pedidos.length,
                        itemBuilder: (context, index) {
                          final pedido = pedidos[index];
                          final clienteNombre =
                              pedido.cliente.nombre ?? 'Cliente sin nombre';
                          final total = pedido.total ?? 0.0;
                          final estado = pedido.estado ?? 'Estado pendiente';
                          final emittedTime =
                              pedido.emittedTime ?? DateTime.now();
                          final latitud = pedido.ubicacion['latitud'] ?? -16;
                          final longitud = pedido.ubicacion['longitud'] ?? -71;
                          final departamento = pedido.ubicacion['departamento'];
                          final provincia = pedido.ubicacion['provincia'];
                          final distrito = pedido.ubicacion['distrito'];
                          final direccion = pedido.ubicacion['direccion'];
                          final direccionCompleta =
                              '${pedido.ubicacion['direccion']}, ${pedido.ubicacion['distrito']}, ${pedido.ubicacion['provincia']}, ${pedido.ubicacion['departamento']}';

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
                                  // TARJETA DEL PEDIDO
                                  child: Container(
                                    height: 500.h,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.r),
                                      color: const Color.fromARGB(
                                          255, 43, 31, 212),
                                    ),
                                    padding: EdgeInsets.all(8.r),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        // Cabecera: Siempre visible
                                        Container(
                                          height: 175.h,
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
                                                                  height: 45.h,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    image: DecorationImage(
                                                                        image: NetworkImage(
                                                                            'https://i.pinimg.com/736x/17/ec/61/17ec61d172c7e0860fba0de51dad4ffe.jpg')),
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
                                                                      fontSize:
                                                                          14.sp,
                                                                      color: Colors
                                                                          .white

                                                                      //Colors.grey.shade600

                                                                      ),
                                                                ),
                                                                Text(
                                                                  "S/.${total.toStringAsFixed(2)}",
                                                                  style: GoogleFonts.manrope(
                                                                      fontSize:
                                                                          14.sp,
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                                Text(
                                                                  pedido
                                                                      .emittedTime
                                                                      .toString()
                                                                      .split(
                                                                          ' ')[0],
                                                                  style: GoogleFonts.manrope(
                                                                      fontSize:
                                                                          14.sp,
                                                                      color: Colors
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
                                                          style: GoogleFonts
                                                              .manrope(
                                                                  fontSize:
                                                                      16.5.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .yellow),
                                                        ),
                                                        Text(
                                                          pedido.pedidoinfo[
                                                              'estado'],
                                                          style: GoogleFonts
                                                              .manrope(
                                                                  fontSize:
                                                                      14.sp,
                                                                  color: Colors
                                                                      .white,
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
                                                            final tiempoRestante =
                                                                pedido
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
                                                                      fontSize:
                                                                          12.sp,
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500),
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
                                                    color: Colors.white),
                                              ),
                                              SizedBox(
                                                height: 8.h,
                                              ),
                                              Text(
                                                direccionCompleta ??
                                                    "Cargando dirección...",
                                                style: GoogleFonts.manrope(
                                                    fontSize: 14.sp,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                              SizedBox(height: 3.h),
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
                                                MainAxisAlignment.spaceBetween,
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
                                                    provider.ignorarPedidoBoton(
                                                        pedido.toMap());
                                                  },
                                                  style: ButtonStyle(
                                                    shape: MaterialStateProperty
                                                        .all(
                                                      RoundedRectangleBorder(
                                                        side: const BorderSide(
                                                          width: 1.0,
                                                          color: Color.fromRGBO(
                                                              42, 75, 160, 1),
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15.r),
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        MaterialStateProperty
                                                            .all(Colors.white),
                                                  ),
                                                  child: Text(
                                                    "Ignorar",
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          const Color.fromRGBO(
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
                                                    setState(() =>
                                                        loadingAceptar = true);
                                                    try {
                                                      await provider
                                                          .aceptarYActualizarPedido(
                                                              pedido.id,
                                                              pedido.almacenId,
                                                              conductorProvider
                                                                  .conductor!
                                                                  .id);

                                                      print(
                                                          "ENTRANDO AL BOTON ACEPTAR******");
                                                      /*
                                                          context.go(
                                                              '/drive/navegar'); // Verifica nuevamente antes de navegar
                                      */
                                                      GoRouter.of(context)
                                                          .go('/drive/navegar');
                                                      setState(() =>
                                                          loadingAceptar =
                                                              false);
                                                    } catch (e) {
                                                      throw Exception(e);
                                                    }
                                                  },
                                                  style: ButtonStyle(
                                                    shape: MaterialStateProperty
                                                        .all(
                                                      RoundedRectangleBorder(
                                                        side: const BorderSide(
                                                          width: 1.0,
                                                          color: Color.fromRGBO(
                                                              255, 255, 255, 1),
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15.r),
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        MaterialStateProperty
                                                            .all(
                                                      const Color.fromRGBO(
                                                          42, 75, 160, 1),
                                                    ),
                                                  ),
                                                  child: loadingAceptar
                                                      ? CircularProgressIndicator(
                                                          color: Colors.white)
                                                      : Text(
                                                          "Aceptar",
                                                          style: GoogleFonts
                                                              .manrope(
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

                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 20.h),
                                            Text(
                                              "Lista de productos (${pedido.productos.length + pedido.promociones.length})",
                                              style: GoogleFonts.manrope(
                                                  fontSize: 14.sp,
                                                  color: Colors.white),
                                            ),
                                            SizedBox(height: 10.h),

                                            // LIST VIEW PRODUCTOS
                                            Container(
                                                padding: EdgeInsets.all(8.r),
                                                height: 170.h,
                                                //width: 110.w,
                                                decoration: BoxDecoration(
                                                    color: Colors.amber,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.r)),
                                                child: ListView.builder(
                                                    //Sumamos las cantidades de pedidos y productos para tener un total
                                                    shrinkWrap: true,
                                                    itemCount: pedido
                                                            .productos.length +
                                                        pedido
                                                            .promociones.length,
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
                                                            .productos[index];
                                                        name = item.nombre;
                                                        quantity =
                                                            item.cantidad;
                                                      } else {
                                                        // en caso no hayan productos recorre las promociones
                                                        item = pedido
                                                                .promociones[
                                                            index -
                                                                pedido.productos
                                                                    .length];
                                                        name = item.nombre;
                                                        quantity =
                                                            item.cantidad;
                                                      }
                                                      return Column(
                                                        children: [
                                                          Container(
                                                            height: 66.h,
                                                            //width: 100.w,
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  name.toUpperCase(),
                                                                  style: GoogleFonts.manrope(
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
                                                                  quantity
                                                                      .toString(),
                                                                  style: GoogleFonts.manrope(
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
                                                            color: const Color
                                                                .fromARGB(255,
                                                                11, 8, 179),
                                                          ),
                                                        ],
                                                      );
                                                    })),
                                            SizedBox(height: 20.h),
                                          ],
                                        ),

                                        // Muesca
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
                      );
                    })
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
            )));
  }
}
