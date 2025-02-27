import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:app2025/conductor/model/pedido_model.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:app2025/conductor/providers/notificacioncustom_provider.dart';
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
    with TickerProviderStateMixin
    implements WidgetsBindingObserver {
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
  // Añade esta variable en la parte superior de tu clase de estado
  StreamController<int>? _timerController;
  StreamSubscription? _pedidoAnuladoSubscription;
  Timer? _timer;
  bool _isTimerRunning = false;
  bool _showAnulacionDialog = false;
  bool _hasHandledAnulacion = false;
  bool _expandido = false;
  String? idpedidoActualDialog = "NA";

  void _showCancelarPedido() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            shadowColor: Colors.white,
            surfaceTintColor: Colors.white,
            child: Container(
              width: 1.sw / 2.5,
              height: 1.sw / 2.5,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: const Color.fromARGB(255, 255, 255, 255)),
              child: Padding(
                padding: EdgeInsets.all(8.0.r),
                child: Column(
                  children: [
                    Text(
                      "Anular pedido",
                      style: GoogleFonts.manrope(
                          fontSize: 15.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 105.w,
                          height: 105.w,
                          // color: Colors.yellow,
                          child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  final response = await http.put(
                                    Uri.parse(
                                        '${microUrl}/pedido_anulado/${_currentPedido?.id}'),
                                    headers: {
                                      'Content-Type': 'application/json'
                                    },
                                    body: jsonEncode({
                                      'observacion': 'Falla técnica',
                                    }),
                                  );

                                  if (response.statusCode == 200) {
                                    // Cerrar el diálogo
                                    Navigator.of(context).pop();

                                    // Usa el contexto original para la navegación
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      // Navega después de que el frame se haya completado
                                      context.go('/drive');

                                      // Muestra el mensaje de éxito
                                      Flushbar(
                                        message:
                                            "Pedido cancelado correctamente",
                                        duration: Duration(seconds: 3),
                                      ).show(context);
                                    });
                                  } else {
                                    // Cerrar el diálogo
                                    Navigator.of(context).pop();

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  "Error: ${response.body}")));
                                    });
                                  }
                                } catch (e) {
                                  // Cerrar el diálogo
                                  Navigator.of(context).pop();

                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Error de conexión: ${e.toString()}")));
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.r)),
                                  backgroundColor: Colors.yellow),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    Icons.car_repair,
                                    size: 40.sp,
                                  ),
                                  Text(
                                    "Falla técnica",
                                    style: GoogleFonts.manrope(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              )),
                        ),
                        Container(
                          width: 105.w,
                          height: 105.w,
                          // color: Colors.yellow,
                          child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  final response = await http.put(
                                    Uri.parse(
                                        '${microUrl}/pedido_anulado/${_currentPedido?.id}'),
                                    headers: {
                                      'Content-Type': 'application/json'
                                    },
                                    body: jsonEncode({
                                      'observacion': 'Cliente no responde',
                                    }),
                                  );

                                  if (response.statusCode == 200) {
                                    // Cerrar el diálogo
                                    Navigator.of(context).pop();

                                    // Usa el contexto original para la navegación
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      // Navega después de que el frame se haya completado
                                      context.go('/drive');

                                      // Muestra el mensaje de éxito
                                      Flushbar(
                                        message:
                                            "Pedido cancelado correctamente",
                                        duration: Duration(seconds: 3),
                                      ).show(context);
                                    });
                                  } else {
                                    // Cerrar el diálogo
                                    Navigator.of(context).pop();

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  "Error: ${response.body}")));
                                    });
                                  }
                                } catch (e) {
                                  // Cerrar el diálogo
                                  Navigator.of(context).pop();

                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Error de conexión: ${e.toString()}")));
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.r)),
                                  backgroundColor: Colors.yellow),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    Icons.bedtime_outlined,
                                    size: 40.sp,
                                  ),
                                  Text(
                                    "Cliente no responde",
                                    style: GoogleFonts.manrope(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              )),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

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
          title: Text("¡Destino alcanzado!",
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
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

  void _makePhoneCall(String telefono) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+51$telefono', // Reemplaza con el número al que quieras llamar
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

  void _initializeTimer() {
    if (_timerController?.isClosed ?? true) {
      _timerController = StreamController<int>();
    }

    if (!_isTimerRunning) {
      _isTimerRunning = true;
      int timeLeft = 6300;

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        timeLeft--;
        if (!_timerController!.isClosed) {
          _timerController!.add(timeLeft);
        }

        print('Tiempo restante: $timeLeft'); // Para depuración

        if (timeLeft == 0) {
          _timer?.cancel();
          _isTimerRunning = false;

          if (mounted) {
            print('Temporizador expirado en: $timeLeft segundos');
            // Debug 1: Verificar pedido antes de toMap()
            print('🔥 _currentPedido RAW: ${_currentPedido?.toString()}');
            print('🔥 ==== DATOS DEL CLIENTE ANTES DE EXPIRAR ====');
            print('🔥 Cliente ID: ${_currentPedido?.cliente.id}');
            print('🔥 Nombre: ${_currentPedido?.cliente.nombre}');
            print('🔥 DNI: ${_currentPedido?.cliente.dni}');
            print(
                '🔥 Teléfono: ${_currentPedido?.cliente.codigo}'); // Asumiendo que codigo es teléfono

            final pedidoData = _currentPedido?.toMap();

            // Debug 2: Estructura completa del mapa
            print('🔥 pedidoData MAP:');
            pedidoData?.forEach((key, value) => print('$key: $value'));

            // Debug 3: Almacenes pendientes específico
            print(
                '🔥 AlmacenesPendientes: ${pedidoData?['AlmacenesPendientes'] ?? "NO EXISTE CLAVE"}');
            print(
                '🔥 Tipo de AlmacenesPendientes: ${pedidoData?['AlmacenesPendientes']?.runtimeType}');
            print('🔥 Cliente en mapa: ${pedidoData?['Cliente']}');

            if (pedidoData != null) {
              final provider =
                  Provider.of<PedidosProvider2>(context, listen: false);
              provider.ignorarPedido(pedidoData);
            }

            context.go('/drive');
          }
        }
      });
    }
  }

  void _showCancelDialog(BuildContext context) {
    // Create a TextEditingController if it doesn't exist
    final _observacionController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        // Use a separate context for the dialog
        return AlertDialog(
          title: Text("Cancelar Pedido #${_currentPedido?.id}",
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Ingrese el motivo de cancelación:",
                style: GoogleFonts.manrope(),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _observacionController,
                decoration: InputDecoration(
                  hintText: "Ej: Problemas de tráfico, clima...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Use the dialog context
                Navigator.of(dialogContext).pop();
              },
              child: Text("Cancelar",
                  style: GoogleFonts.manrope(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(42, 75, 160, 1.0)),
              onPressed: () async {
                if (_observacionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Debe ingresar un motivo")));
                  return;
                }

                // Cierra el diálogo usando el contexto del diálogo primero
                Navigator.of(dialogContext).pop();

                try {
                  final response = await http.put(
                    Uri.parse(
                        '${microUrl}/pedido_anulado/${_currentPedido?.id}'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'observacion': _observacionController.text,
                    }),
                  );

                  if (response.statusCode == 200) {
                    // Usa el contexto original para la navegación
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      // Navega después de que el frame se haya completado
                      context.go('/drive');

                      // Muestra el mensaje de éxito
                      Flushbar(
                        message: "Pedido cancelado correctamente",
                        duration: Duration(seconds: 3),
                      ).show(context);
                    });
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: ${response.body}")));
                    });
                  }
                } catch (e) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error al cancelar: $e")));
                  });
                }
              },
              child: Text("Confirmar",
                  style: GoogleFonts.manrope(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimerWidget() {
    return StreamBuilder<int>(
      stream: _timerController?.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text(
            '01:00',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          );
        }

        final secondsRemaining = snapshot.data!;

        // En el widget _buildTimerWidget
        if (secondsRemaining <= 0) {
          return const Text(
            'Tiempo expirado',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          );
        }

        final minutes = (secondsRemaining / 60).floor();
        final seconds = secondsRemaining % 60;
        final color = secondsRemaining < 10
            ? Colors.red
            : const Color.fromARGB(255, 220, 235, 2);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, size: 16.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.manrope(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final conductorProvider =
        Provider.of<ConductorProvider>(context, listen: false);
    setState(() {
      conductorId = conductorProvider.conductor!.id;
    });
    _loadMapStyle();
    _initializeMap();
    // _loadPedidoDetails();
    _initializeTimer();
    // Escuchar el stream de pedidos anulados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pedidosProvider =
          Provider.of<PedidosProvider2>(context, listen: false);

      // Suscribirse al stream solo para el pedido actual
      /* _pedidoAnuladoSubscription =
          pedidosProvider.pedidoAnuladoStream.listen((pedidoId) {
        if (pedidoId == _currentPedido && !_hasHandledAnulacion) {
          _showPedidoAnuladoDialog(context);
        }
      });*/
    });
  }

  void _showPedidoAnuladoDialog() {
    // Verifica si el widget sigue montado antes de mostrar el diálogo
    if (!mounted) return;

    _timer?.cancel();
    _isTimerRunning = false;
    _timerController?.close();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pedido Actual Anulado"),
          content: Text(
              "El pedido ha sido anulado y no puede continuar con la entrega."),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
                if (mounted) {
                  // Verificar nuevamente antes de navegar
                  context.go('/drive');
                }
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  void _loadPedidoDetails() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final pedidosProvider =
            Provider.of<PedidosProvider2>(context, listen: false);
        //final activePedidos = pedidosProvider.getActivePedidos();
        final pedidoAceptado = pedidosProvider.primerPedidoAceptado;
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

// notificación
  void mostrarNotificacion(BuildContext context, String mensaje) {
    Map<String, dynamic> pedidoMap = jsonDecode(mensaje);
    print("#########......... ${pedidoMap['detalles']['promociones'].length}");

    String estadoPedido = pedidoMap['pedidoinfo']['estado'];

    Flushbar(
      duration: Duration(seconds: 20),
      flushbarPosition: FlushbarPosition.TOP,
      margin: EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: Colors.amber.withOpacity(0.8),
      isDismissible: true,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      mainButton: ElevatedButton(
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                  const Color.fromARGB(255, 18, 29, 110))),
          onPressed: () {
            print(".........ACEPTE");

            //LOGICA DE ACEPTAR PEDIDO
            // Llamar al método aceptarPedido del provider
            Provider.of<PedidosProvider2>(context, listen: false)
                .aceptarPedido(pedidoMap['id'], pedidoData: pedidoMap)
                .then((_) {
              // Cerrar la notificación después de aceptar
              Navigator.of(context, rootNavigator: true).pop();
            }).catchError((error) {
              // Manejo de error opcional
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al aceptar pedido: ${error.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            });
            //FIN DE LOGICA DE ACEPTAR PEDIDO
          },
          child: Text("Aceptar",
              style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 12.sp))),
      messageText: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Pedido #${pedidoMap['id']}",
                      style: GoogleFonts.manrope(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 4, 27, 159))),
                ],
              ),
              Text(
                  "Cliente:${pedidoMap['Cliente']?['nombre']} ${pedidoMap['Cliente']['apellidos']} ",
                  style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 4, 1, 176),
                      fontSize: 12.sp)),
              Text("Total: S/.${pedidoMap['total']}",
                  style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 4, 1, 176),
                      fontSize: 12.sp)),
              Text(
                  "Dirección: ${pedidoMap['ubicacion']['distrito']} ${pedidoMap['ubicacion']['direccion']} ${pedidoMap['ubicacion']['provincia']}",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 4, 1, 176),
                      fontSize: 12.sp)),
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                child: _expandido
                    ? Container(
                        height: 250.w,
                        decoration: BoxDecoration(color: Colors.white),
                        child: ListView.builder(
                          itemCount:
                              pedidoMap['detalles']['promociones'].length +
                                  pedidoMap['detalles']['productos'].length,
                          itemBuilder: (context, index) {
                            // Obtener la cantidad de promociones
                            int promoCount =
                                pedidoMap['detalles']['promociones'].length;

                            if (index < promoCount) {
                              // Mostrar una promoción
                              var promocion =
                                  pedidoMap['detalles']['promociones'][index];
                              return ListTile(
                                title: Text(promocion['nombre'],
                                    style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        fontSize: 14.5.sp)),
                                subtitle: Text(
                                    "Cantidad: ${promocion['cantidad']}",
                                    style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        fontSize: 12.sp)),
                              );
                            } else {
                              // Mostrar un producto después de las promociones
                              var producto = pedidoMap['detalles']['productos']
                                  [index - promoCount];
                              return ListTile(
                                title: Text(producto['nombre'],
                                    style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        fontSize: 14.5.sp)),
                                subtitle: Text(
                                    "Cantidad: ${producto['cantidad']}",
                                    style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        fontSize: 12.sp)),
                              );
                            }
                          },
                        ))
                    : SizedBox(),
                // : SizedBox(),
              ),
              SizedBox(
                height: 13.h,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.grey)),
                  onPressed: () {
                    setState(() {
                      _expandido = !_expandido;
                    });
                  },
                  child: Text(_expandido ? "Ver menos" : "Ver más",
                      style: GoogleFonts.manrope(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 255, 255, 255))),
                ),
              )
            ],
          );
        },
      ),
    ).show(context);
  }

  void _mostrarAlertaVolverAEntregar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("¡Atención!"),
        content: Text("No olvides marcar el pedido como entregado."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Aquí puedes mostrar una alerta o reenfocar la vista en la app.
      _mostrarAlertaVolverAEntregar();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerController?.close();
    _animationTimer?.cancel();
    _draggableController.dispose();
    _pedidoAnuladoSubscription?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pedidosProvider =
        Provider.of<PedidosProvider2>(context, listen: true);
    _currentPedido = pedidosProvider.primerPedidoAceptado;
    setState(() {
      idpedidoActualDialog = _currentPedido?.id;
    });

    // Suscribirse al stream solo para el pedido actual
    /*_pedidoAnuladoSubscription =
        pedidosProvider.pedidoAnuladoStream.listen((pedidoId) {
      if (pedidoId == _currentPedido && !_hasHandledAnulacion) {
        print("1NUMERO UNOOOOOOOOOOOOOOO ----->>>>>>>>>>>>>>>>>>>");
        _showPedidoAnuladoDialog(context);
      }
    });*/

    bool mostrarDialogoAhora = false;

    print("....NAV CURRENT $_currentPedido");
    print("VARIABLES ANTES DE LA FUNCION -------------------->*******");
    print(_currentPedido);
    // print(pedidosProvider.estaAnulado(_currentPedido!.id));
    print(_hasHandledAnulacion);

    if (_currentPedido == null && !_hasHandledAnulacion) {
      print("*******------DENTRO DE LA VERIFICACION DEL FUNCION ---->>>");
      print(_currentPedido);
      print(_hasHandledAnulacion);
      // Solo mostraremos el diálogo si venimos de un evento real de anulación
      // y no por un cambio de estado general en la aplicación
      setState(() {
        mostrarDialogoAhora = true;

        // Marcar que ya manejamos esta anulación para no volver a mostrar el diálogo
        _hasHandledAnulacion = true;
      });
    }

    // Mostrar el diálogo después de construir el widget, pero solo si es necesario
    if (mostrarDialogoAhora) {
      // Usar un pequeño delay para evitar conflictos con transiciones de navegación
      Future.delayed(Duration.zero, () {
        if (mounted) {
          print(
              "1NUMERO DOSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS ----->>>>>>>>>>>>>>>>>>>");
          // Verificar que el widget aún está montado
          _showPedidoAnuladoDialog();
        }
      });
    }
    // final activePedidos = pedidosProvider.getActivePedidos();
    final departamento = _currentPedido?.ubicacion?['departamento'];
    final provincia = _currentPedido?.ubicacion?['provincia'];
    final distrito = _currentPedido?.ubicacion?['distrito'];
    final direccion = _currentPedido?.ubicacion?['direccion'];
    final direccionCompleta =
        '${direccion},${distrito},${provincia},${departamento}';
    final notifyProvider = context.watch<NotificationProvider>();
    if (notifyProvider.mensaje != null && notifyProvider.mensaje!.isNotEmpty) {
      print("mensaje -******************** ${notifyProvider.mensaje}");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        /*NotificationOverlay.showNotification(
            context, "Este es un mensaje de prueba");*/
        mostrarNotificacion(context, notifyProvider.mensaje!);
        // agregarNotificacion(context);
        /* Flushbar(
          title: 'Hey Ninja',
          message:
              'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
          duration: Duration(seconds: 10),
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);*/
        notifyProvider
            .clearMensaje(); // Limpiar el mensaje después de mostrar la alerta
      });
    }
    return PopScope(
      canPop: false, //IMPIDE AL USUARIO RETROCEDER
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          bool salir = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Advertencia",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  content: Text(
                      "Si retrocedes, perderás tu pedido. ¿Deseas continuar?",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(false), // No salir
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () {
                        context.pop(true);
                      },
                      child: const Text("Salir"),
                    ),
                  ],
                ),
              ) ??
              false;

          if (salir) {
            GoRouter.of(context).pop(); // Vuelve atrás con go_router
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 202, 202, 202),
        appBar: AppBar(
          leading: Icon(
            Icons.arrow_back_ios,
            size: 16.sp,
          ),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: Row(
            children: [
              Text(
                "Pedido en curso:",
                style: GoogleFonts.manrope(fontSize: 16.sp),
              ),
              Text(
                " ID# ${_currentPedido?.id}",
                style: GoogleFonts.manrope(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 194, 144, 6)),
              )
            ],
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
                            zoom: 18,
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
                      color: Color.fromARGB(255, 58, 41, 127).withOpacity(0.95),
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
                        padding:
                            EdgeInsets.only(left: 5.r, right: 5.r, top: 10.r),
                        children: [
                          // Indicador para deslizar
                          Center(
                            child: Container(
                              margin: EdgeInsets.only(bottom: 16),
                              width: 75.w,
                              height: 2.5.h,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          // TARJETA

                          Container(
                            height: 119.h,
                            //padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            // Contenido
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 163.w,
                                  //color: Colors.green,
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
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                              "${_currentPedido?.cliente.nombre} ${_currentPedido?.cliente.apellidos}" ??
                                                  'Cargando...',
                                              style: GoogleFonts.manrope(
                                                  fontSize: 14.sp,
                                                  color: Colors.white),
                                            ),
                                            Text(
                                              "S/.${_currentPedido?.total.toString() ?? '0.00'}",
                                              style: GoogleFonts.manrope(
                                                  color: Colors.white,
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
                                  //color: Colors.green,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "ID: #${_currentPedido?.id?.toString()}",
                                        style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.sp,
                                            color: const Color.fromARGB(
                                                255, 253, 222, 83)),
                                      ),

                                      // CRONÓMETRO DE ENTREGA
                                      _buildTimerWidget(),

                                      Text(
                                        _currentPedido?.pedidoinfo?['tipo'] ??
                                            'Tipo no disponible',
                                        style: GoogleFonts.manrope(
                                            color: Colors.white,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold),
                                      ),

                                      // USO MATERIAL PARA HACER LA ELEVACIÓN DE ESTE WIDGET
                                      Material(
                                        elevation: 10.r,
                                        borderRadius:
                                            BorderRadius.circular(50.r),
                                        child: Container(
                                            width: 35.w,
                                            height: 35.w,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(50.r),
                                                color: Colors.white),
                                            child: Center(
                                              child: IconButton(
                                                  onPressed: () {
                                                    _makePhoneCall(
                                                        _currentPedido!.cliente
                                                                .telefono ??
                                                            "+51123");
                                                  },
                                                  icon: Icon(
                                                    size: 17.sp,
                                                    Icons.call_sharp,
                                                    color: Color.fromRGBO(
                                                        42, 75, 160, 1),
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
                          Container(
                            color: Colors.white,
                            // height: 150.h,
                            child: Row(
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
                                          color: Colors.grey.shade500,
                                          size: 10),
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
                                          Text("1 h. 35 minutos",
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
                                      width: 1.sw / 1.4,
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
                                              textAlign: TextAlign.justify,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
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
                                border:
                                    Border(bottom: BorderSide(width: 0.50))),
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.sp,
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255)),
                                    ),
                                    Container(
                                      width: 35.w,
                                      height: 35.0.w,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(50.r)),
                                      child: IconButton(
                                        icon: Icon(
                                          _isExpanded
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          size: 20.sp,
                                          color: const Color.fromARGB(
                                              255, 9, 28, 126),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isExpanded = !_isExpanded;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5.h,
                                ),
                                if (_isExpanded)
                                  Container(
                                    color: Colors.white,
                                    height:
                                        150, // Altura fija para que el ListView sea scrollable
                                    child: ListView(
                                      children: [
                                        Text(
                                          _currentPedido
                                                  ?.pedidoinfo['observacion'] ??
                                              "N/A",
                                          style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13.5,
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
                                border:
                                    Border(bottom: BorderSide(width: 0.50))),
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
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255)),
                                    ),
                                    Container(
                                      height: 35.w,
                                      width: 35.w,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(50.r)),
                                      child: IconButton(
                                        icon: Icon(
                                          _isExpandedProductos
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: const Color.fromARGB(
                                              255, 28, 14, 106),
                                          size: 20.sp,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isExpandedProductos =
                                                !_isExpandedProductos;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5.h,
                                ),
                                if (_isExpandedProductos)
                                  Container(
                                      color: Colors.amber,
                                      height:
                                          150, // Altura fija para que el ListView sea scrollable
                                      child: ListView.builder(
                                        itemCount: (_currentPedido
                                                    ?.productos?.length ??
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
                                            item = _currentPedido
                                                ?.productos?[index];
                                            name = item?.nombre ?? 'N/A';
                                          } else {
                                            // Promociones
                                            item = _currentPedido?.promociones?[
                                                index -
                                                    (_currentPedido?.productos
                                                            ?.length ??
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
                                                      style:
                                                          GoogleFonts.manrope(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 13.sp),
                                                    ),
                                                    SizedBox(
                                                      width: 20.w,
                                                    ),
                                                    Text(
                                                      name,
                                                      style:
                                                          GoogleFonts.manrope(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 13.sp),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 340.w,
                                                color: Colors.white,
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

                                    //_showCancelDialog(context);
                                    _showCancelarPedido();
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
                                            color: Color.fromRGBO(42, 75, 160,
                                                1), // Color del borde
                                            width: 1.0, // Ancho del borde
                                          ),
                                        ),
                                      )),
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

                                    if (pedidosProvider
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                              )
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
      ),
    );
  }

  @override
  void didChangeAccessibilityFeatures() {
    // TODO: implement didChangeAccessibilityFeatures
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // TODO: implement didChangeLocales
  }

  @override
  void didChangeMetrics() {
    // TODO: implement didChangeMetrics
  }

  @override
  void didChangePlatformBrightness() {
    // TODO: implement didChangePlatformBrightness
  }

  @override
  void didChangeTextScaleFactor() {
    // TODO: implement didChangeTextScaleFactor
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    // TODO: implement didChangeViewFocus
  }

  @override
  void didHaveMemoryPressure() {
    // TODO: implement didHaveMemoryPressure
  }

  @override
  Future<bool> didPopRoute() {
    // TODO: implement didPopRoute
    throw UnimplementedError();
  }

  @override
  Future<bool> didPushRoute(String route) {
    // TODO: implement didPushRoute
    throw UnimplementedError();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    // TODO: implement didPushRouteInformation
    throw UnimplementedError();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() {
    // TODO: implement didRequestAppExit
    throw UnimplementedError();
  }

  @override
  void handleCancelBackGesture() {
    // TODO: implement handleCancelBackGesture
  }

  @override
  void handleCommitBackGesture() {
    // TODO: implement handleCommitBackGesture
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    // TODO: implement handleStartBackGesture
    throw UnimplementedError();
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    // TODO: implement handleUpdateBackGestureProgress
  }
}
