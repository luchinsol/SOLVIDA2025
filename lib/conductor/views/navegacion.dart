import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app2025/conductor/model/pedido_model.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:app2025/conductor/providers/pedidos_provider.dart';
import 'package:app2025/conductor/providers/pedidos_provider2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class NavegacionPedido extends StatefulWidget {
  const NavegacionPedido({Key? key}) : super(key: key);

  @override
  State<NavegacionPedido> createState() => _NavegacionPedidoState();
}

class _NavegacionPedidoState extends State<NavegacionPedido>
    with TickerProviderStateMixin {
  //VARIABLES GLOBALES
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  final LatLng _destination =
      const LatLng(-16.410472367054158, -71.57064420197324);

  GoogleMapController? _mapController;
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _destinationIcon;
  List<LatLng> _polypoints = [];
  Marker? _carMarker;
  Marker? _startMarker;
  LocationData? _currentLocation;
  final Location _location = Location();
  String _mapStyle = '';
  Timer? _animationTimer;
  LatLng? _lastPosition;
  LatLng? _nextPosition;
  double _lastRotation = 0;
  bool _hasArrived = false; // Nueva variable de control
  bool _isExpanded = false;
  bool _isExpandedProductos = false;
  Pedido? _currentPedido;
  String microUrl = dotenv.env['MICRO_URL'] ?? '';
  int? conductorId = 0;

  void _expandirDraggable() {
    _draggableController.animateTo(
      0.85, // Expandir al máximo
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showDestinationAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("¡Destino alcanzado!"),
          content: const Text("Has llegado a tu destino."),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
                _expandirDraggable();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // en metros
    double dLat = (end.latitude - start.latitude) * pi / 180.0;
    double dLon = (end.longitude - start.longitude) * pi / 180.0;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * pi / 180.0) *
            cos(end.latitude * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _makePhoneCall() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+51964269494', // Reemplaza con el número al que quieras llamar
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw Exception('No se pudo iniciar la llamada al número');
    }
  }

  Future<void> _loadMapStyle() async {
    String style =
        await rootBundle.loadString('lib/conductor/stylemap/estilomap.json');
    setState(() {
      _mapStyle = style;
    });
  }

  void _updateCarPosition(LatLng newPosition, [double? rotation]) {
    if (!mounted) return; // Verifica si el widget sigue en el árbol
    setState(() {
      _carMarker = Marker(
        markerId: const MarkerId("car"),
        position: newPosition,
        icon: _carIcon!,
        rotation: rotation ?? 0,
        anchor: const Offset(0.5, 0.5),
      );
    });

    // Asegurar que la cámara siga al vehículo
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
    double distance = _calculateDistance(newPosition, _destination);
    if (distance < 50 && !_hasArrived) {
      _hasArrived = true; // Evitar múltiples activaciones
      _showDestinationAlert(); // Llamar al diálogo
    }
  }

  Future<void> _checkLocationPermission() async {
    bool _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        throw Exception("El servicio de ubicación no está habilitado.");
      }
    }

    PermissionStatus _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        throw Exception("Permiso de ubicación denegado.");
      }
    }
  }

  Future<void> _loadMarkerIcons() async {
    _carIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(20, 20)),
      'lib/imagenes/mini3D.png',
    );

    _startIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(20, 20)),
      'lib/imagenes/pin3d.png',
    );

    _destinationIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(20, 20)),
      'lib/imagenes/house3d.png',
    );
  }

  Future<List<LatLng>> _getPolypoints(LatLng origin, LatLng destination) async {
    List<LatLng> polyPoints = [];
    try {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey:
            "AIzaSyA45xOgppdm-PXYDE5r07eDlkFuPzYmI9g", // Asegúrate de usar tu API Key
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.status == "OK" && result.points.isNotEmpty) {
        for (PointLatLng point in result.points) {
          polyPoints.add(LatLng(point.latitude, point.longitude));
        }
      }
    } catch (e) {
      print("Error al obtener la ruta: $e");
    }
    return polyPoints;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * pi / 180.0;
    double lon1 = start.longitude * pi / 180.0;
    double lat2 = end.latitude * pi / 180.0;
    double lon2 = end.longitude * pi / 180.0;

    double dLon = lon2 - lon1;
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    return (atan2(y, x) * 180.0 / pi + 360.0) % 360.0;
  }

  Future<void> _initializeRoute(LatLng startLatLng) async {
    _polypoints = await _getPolypoints(startLatLng, _destination);
    _startMarker = Marker(
      markerId: const MarkerId("start"),
      position: startLatLng,
      icon: _startIcon ?? BitmapDescriptor.defaultMarker,
    );
  }

  void _animateCarMovement() {
    if (_animationTimer != null) _animationTimer!.cancel();
    const int animationDuration = 1000; // Duración en milisegundos
    const int frames = 60; // Número de fotogramas
    final int frameDuration = animationDuration ~/ frames;

    int frameCount = 0;
    LatLng start = _lastPosition!;
    LatLng end = _nextPosition!;
    double initialRotation = _lastRotation;
    double targetRotation = _calculateBearing(start, end);

    _animationTimer = Timer.periodic(
      Duration(milliseconds: frameDuration),
      (timer) {
        frameCount++;
        if (frameCount > frames) {
          _lastPosition = end;
          _lastRotation = targetRotation;
          timer.cancel();
          return;
        }

        // Interpolación lineal
        double t = frameCount / frames;
        double lat = start.latitude + (end.latitude - start.latitude) * t;
        double lng = start.longitude + (end.longitude - start.longitude) * t;
        double rotation =
            initialRotation + (targetRotation - initialRotation) * t;

        LatLng interpolatedPosition = LatLng(lat, lng);
        _updateCarPosition(interpolatedPosition, rotation);
      },
    );
  }

  Future<void> _initializeMap() async {
    await _checkLocationPermission();
    await _loadMarkerIcons();

    _currentLocation = await _location.getLocation();
    if (_currentLocation != null) {
      final LatLng startLatLng =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
      await _initializeRoute(startLatLng);
      _updateCarPosition(startLatLng);
      setState(() {});
    }

    _location.onLocationChanged.listen((LocationData locationData) {
      final LatLng newLatLng =
          LatLng(locationData.latitude!, locationData.longitude!);

      if (_lastPosition == null) {
        _lastPosition = newLatLng;
        _updateCarPosition(newLatLng);
        return;
      }

      _nextPosition = newLatLng;
      _animateCarMovement();
    });
  }

  Future<void> entregarPedido(
      BuildContext context, String pedidoId, int almacenId) async {
    try {
      // 1. Obtener el provider
      final pedidoProvider =
          Provider.of<PedidosProvider2>(context, listen: false);

      // 2. Actualizar en la base de datos
      final url = Uri.parse('${microUrl}/pedido_estado/$pedidoId');

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conductor_id': conductorId!,
          'estado': 'entregado',
          'almacen_id': almacenId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar estado: ${response.body}');
      }

      print("------------------------->>>>> UI NAVEGACION--->>> NAVEGACION");
      print(pedidoId);
      // 3. Actualizar el provider y eliminar de la lista de aceptados
      await pedidoProvider.entregarPedido(pedidoId);

      // 4. Navegar a la pantalla de calificación
      context.push('/drive/calificar');
    } catch (e) {
      print('Error al entregar pedido: $e');
      // Mostrar un mensaje de error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al entregar el pedido: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final conductorProvider =
        Provider.of<ConductorProvider>(context, listen: false);
    setState(() {
      conductorId = conductorProvider.conductor!.id;
    });
    _loadMapStyle();
    _initializeMap();
    _loadPedidoDetails();
  }

  void _loadPedidoDetails() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final pedidosProvider =
            Provider.of<PedidosProvider2>(context, listen: false);
        //final activePedidos = pedidosProvider.getActivePedidos();
        final pedidoAceptado = pedidosProvider.ultimoPedidoAceptado;
        print("-----------------------> VISTA NAVEGACION");

        print("MEJORA ------>");
        print(pedidoAceptado?.id);
        if (pedidoAceptado != null) {
          setState(() {
            _currentPedido = pedidoAceptado;
          });
        } else {
          print("No se encontró pedido aceptado");
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No hay pedidos activos')));
        }
      } catch (e) {
        print('Error cargando pedidos: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al cargar los pedidos')));
      }
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _draggableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pedidosProvider = context.watch<PedidosProvider2>();
    final activePedidos = pedidosProvider.getActivePedidos();
    final departamento = _currentPedido?.ubicacion?['departamento'];
    final provincia = _currentPedido?.ubicacion?['provincia'];
    final distrito = _currentPedido?.ubicacion?['distrito'];
    final direccion = _currentPedido?.ubicacion?['direccion'];
    final direccionCompleta =
        '${direccion},${distrito},${provincia},${departamento}';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Pedido en curso",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Mapa de Google
          _currentLocation == null
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.only(
                      top: 10.0, left: 10, right: 10, bottom: 0),
                  child: Container(
                    height: 615.h,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_currentLocation!.latitude!,
                              _currentLocation!.longitude!),
                          zoom: 14,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _mapController?.setMapStyle(_mapStyle);
                        },
                        polylines: {
                          Polyline(
                            polylineId: const PolylineId("route"),
                            points: _polypoints,
                            color: Colors.blue,
                            width: 5,
                          ),
                        },
                        markers: {
                          if (_startMarker != null) _startMarker!,
                          if (_carMarker != null) _carMarker!,
                          Marker(
                            markerId: const MarkerId("destination"),
                            position: _destination,
                            icon: _destinationIcon ??
                                BitmapDescriptor.defaultMarker,
                          ),
                        },
                        mapType: MapType.normal,
                      ),
                    ),
                  ),
                ),
          // DraggableScrollableSheet
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: DraggableScrollableSheet(
              controller: _draggableController,
              initialChildSize: 0.21, // Tamaño inicial
              minChildSize: 0.21, // Tamaño mínimo
              maxChildSize: 0.85, // Tamaño máximo
              builder: (BuildContext context, ScrollController controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 238, 238, 238).withOpacity(0.95),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10.r),
                      topLeft: Radius.circular(10.r),
                    ),
                  ),
                  child: Skeletonizer(
                    enabled: false,
                    effect: ShimmerEffect(
                        baseColor: Colors.white,
                        highlightColor: Colors.grey.shade500),
                    child: ListView(
                      controller: controller, // Vinculamos el controlador
                      padding: EdgeInsets.all(16.0),
                      children: [
                        // Indicador para deslizar
                        Center(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 16),
                            width: 75.w,
                            height: 3.h,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 155, 155, 155),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // TARJETA

                        Container(
                          height: 111.h,
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            //  color: const Color.fromARGB(255, 255, 255, 255)
                          ),
                          // Contenido
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                color: Color.fromARGB(
                                                    255, 255, 255, 255),
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
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Text(
                                            _currentPedido?.cliente.nombre ??
                                                'Cargando...',
                                            style: GoogleFonts.manrope(
                                                fontSize: 14.sp,
                                                color: Colors.grey.shade600),
                                          ),
                                          Text(
                                            _currentPedido?.total.toString() ??
                                                '0.00',
                                            style: GoogleFonts.manrope(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold),
                                          ),
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
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "ID: #${_currentPedido?.id?.toString()}",
                                      style: GoogleFonts.manrope(
                                          fontSize: 14.sp,
                                          color: const Color.fromARGB(
                                              255, 66, 66, 66)),
                                    ),
                                    Text(
                                      _currentPedido?.pedidoinfo?['tipo'] ??
                                          'Tipo no disponible',
                                      style: GoogleFonts.manrope(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Material(
                                      elevation: 10.r,
                                      borderRadius: BorderRadius.circular(50.r),
                                      child: Container(
                                          width: 35.w,
                                          height: 35.w,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(50.r),
                                            color:
                                                Color.fromRGBO(42, 75, 160, 1),
                                          ),
                                          child: Center(
                                            child: IconButton(
                                                onPressed: () {
                                                  _makePhoneCall();
                                                },
                                                icon: Icon(
                                                  size: 17.sp,
                                                  Icons.call_sharp,
                                                  color: Colors.white,
                                                )),
                                          )),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 21.5.h,
                        ),
                        Divider(
                          height: 2.5.h,
                          color: Colors.grey,
                        ),
                        SizedBox(
                          height: 21.5.h,
                        ),

                        // TIME LINE
                        Row(
                          //crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              // color: Colors.white,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Color.fromRGBO(42, 75, 160, 1),
                                  ),
                                  SizedBox(
                                    height: 9.5.h,
                                  ),
                                  Icon(Icons.circle,
                                      color: Colors.grey.shade400, size: 8),
                                  SizedBox(
                                    height: 9.5.h,
                                  ),
                                  Icon(Icons.circle,
                                      color: Colors.grey.shade500, size: 10),
                                  SizedBox(
                                    height: 9.5.h,
                                  ),
                                  const Icon(Icons.circle,
                                      color: Colors.grey, size: 12),
                                  SizedBox(
                                    height: 9.5.h,
                                  ),
                                  const Icon(
                                    Icons.place_outlined,
                                    color: Color.fromRGBO(42, 75, 160, 1),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 10.w,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  // color: Colors.amber,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Tiempo de entrega",
                                        style: GoogleFonts.manrope(
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade700),
                                      ),
                                      SizedBox(
                                        height: 4.h,
                                      ),
                                      Text("15 minutos",
                                          style: GoogleFonts.manrope(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600))
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 45.h,
                                ),
                                Container(
                                  // color: Colors.amber,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Dirección",
                                        style: GoogleFonts.manrope(
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade700),
                                      ),
                                      SizedBox(
                                        height: 4.h,
                                      ),
                                      Text(direccionCompleta,
                                          style: GoogleFonts.manrope(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600))
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                        SizedBox(
                          height: 21.5.h,
                        ),
                        Divider(
                          height: 2.5.h,
                          color: Colors.grey,
                        ),
                        SizedBox(
                          height: 6.5.h,
                        ),

                        // Elementos de la lista

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _isExpanded ? 230.h : 60.h,
                          width: double.infinity,
                          decoration: const BoxDecoration(

                              //  borderRadius: BorderRadius.circular(10),
                              border: Border(bottom: BorderSide(width: 0.50))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Notas",
                                    style: GoogleFonts.manrope(
                                        fontSize: 13.sp,
                                        color: Colors.grey.shade700),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_isExpanded)
                                Container(
                                  height:
                                      150, // Altura fija para que el ListView sea scrollable
                                  child: ListView(
                                    children: [
                                      Text(
                                        _currentPedido
                                                ?.pedidoinfo['observacion'] ??
                                            "N/A",
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: const Color.fromARGB(
                                              255, 0, 0, 0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: 6.5.h,
                        ),
                        // PRODUCTOS
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _isExpandedProductos ? 230.h : 60.h,
                          width: double.infinity,
                          decoration: const BoxDecoration(

                              //  borderRadius: BorderRadius.circular(10),
                              border: Border(bottom: BorderSide(width: 0.50))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Lista de productos (${(_currentPedido?.productos?.length ?? 0) + (_currentPedido?.promociones?.length ?? 0)})",
                                    style: GoogleFonts.manrope(
                                        fontSize: 13.sp,
                                        color: Colors.grey.shade700),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _isExpandedProductos
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isExpandedProductos =
                                            !_isExpandedProductos;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_isExpandedProductos)
                                Container(
                                    color: Colors.amber,
                                    height:
                                        150, // Altura fija para que el ListView sea scrollable
                                    child: ListView.builder(
                                      itemCount:
                                          (_currentPedido?.productos?.length ??
                                                  0) +
                                              (_currentPedido
                                                      ?.promociones?.length ??
                                                  0),
                                      itemBuilder: (context, index) {
                                        dynamic item;
                                        String name;

                                        if (index <
                                            (_currentPedido
                                                    ?.productos?.length ??
                                                0)) {
                                          // Productos
                                          item =
                                              _currentPedido?.productos?[index];
                                          name = item?.nombre ?? 'N/A';
                                        } else {
                                          // Promociones
                                          item = _currentPedido?.promociones?[
                                              index -
                                                  (_currentPedido
                                                          ?.productos?.length ??
                                                      0)];
                                          name = item?.nombre ?? 'N/A';
                                        }
                                        return Column(
                                          children: [
                                            Container(
                                              height: 56.h,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    "Producto",
                                                    style: GoogleFonts.manrope(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13.sp),
                                                  ),
                                                  SizedBox(
                                                    width: 20.w,
                                                  ),
                                                  Text(
                                                    name,
                                                    style: GoogleFonts.manrope(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13.sp),
                                                  )
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 340.w,
                                              child: Divider(
                                                height: 1,
                                              ),
                                            )
                                          ],
                                        );
                                      },
                                    )),
                            ],
                          ),
                        ),

                        // BOTONES

                        SizedBox(
                          height: 21.5.h,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 56, // Altura del botón
                              width: 143, // Ancho del botón
                              child: ElevatedButton(
                                onPressed: () {
                                  // Acción al presionar el botón
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                    const Color.fromRGBO(
                                        255, 255, 255, 1), // Color de fondo
                                  ),
                                  shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          20.r), // Bordes rectos
                                      side: const BorderSide(
                                        color: Color.fromRGBO(
                                            42, 75, 160, 1), // Color del borde
                                        width: 1.0, // Ancho del borde
                                      ),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "Cancelar",
                                  style: GoogleFonts.manrope(
                                    fontSize: 14.sp, // Tamaño de texto
                                    fontWeight: FontWeight.bold, // Negrita
                                    color: const Color.fromRGBO(
                                        42, 75, 160, 1), // Color del texto
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 56, // Altura del botón
                              width: 153, // Ancho del botón
                              child: ElevatedButton(
                                onPressed: () {
                                  // Acción al presionar el botón
                                  //context.push('/drive/calificar');
                                  final pedidoProvider =
                                      Provider.of<PedidosProvider2>(context,
                                          listen: false);
                                  if (pedidoProvider
                                      .pedidosAceptados.isNotEmpty) {
                                    final pedido2 = _currentPedido;
                                    /*
                                    final pedido = pedidoProvider
                                            .pedidosAceptados[
                                        0]; // Tomamos el primer pedido de la lista
                                    */
                                    print("UI ---->> LOGS PARA DEPURAR");
                                    print(pedido2?.id);
                                    // Llamamos a la función para entregar el pedido
                                    entregarPedido(context, pedido2!.id,
                                        pedido2!.almacenId);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'No hay pedidos para entregar')),
                                    );
                                  }
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                    const Color.fromRGBO(
                                        42, 75, 160, 1), // Color de fondo
                                  ),
                                  shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          20.r), // Bordes rectos
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "Entregar",
                                  style: GoogleFonts.manrope(
                                    fontSize: 14.sp, // Tamaño de texto
                                    fontWeight: FontWeight.bold, // Negrita
                                    color: Colors.white, // Color del texto
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 40.5.h,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
