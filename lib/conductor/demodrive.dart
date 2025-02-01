/*import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class NavegacionPedido2 extends StatefulWidget {
  const NavegacionPedido2({Key? key}) : super(key: key);

  @override
  State<NavegacionPedido2> createState() => _NavegacionPedido2State();
}

class _NavegacionPedido2State extends State<NavegacionPedido2> {
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

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initializeMap();
  }

  Future<void> _loadMapStyle() async {
    String style = await rootBundle.loadString('lib/stylemap/estilomap.json');
    setState(() {
      _mapStyle = style;
    });
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
      _updateCarPosition(newLatLng);
      _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
    });
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

  Future<void> _initializeRoute(LatLng startLatLng) async {
    _polypoints = await _getPolypoints(startLatLng, _destination);
    _startMarker = Marker(
      markerId: const MarkerId("start"),
      position: startLatLng,
      icon: _startIcon ?? BitmapDescriptor.defaultMarker,
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

  void _updateCarPosition(LatLng newPosition) {
    double rotation = 0;
    if (_carMarker != null) {
      LatLng oldPosition = _carMarker!.position;
      rotation = _calculateBearing(oldPosition, newPosition);
    }

    setState(() {
      _carMarker = Marker(
        markerId: const MarkerId("car"),
        position: newPosition,
        icon: _carIcon!,
        rotation: rotation,
        anchor: const Offset(0.5, 0.5),
      );
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seguimiento en tiempo real"),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    _currentLocation!.latitude!, _currentLocation!.longitude!),
                zoom: 14,
              ),
              onMapCreated: (controller) => _mapController = controller,
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
                  icon: _destinationIcon ?? BitmapDescriptor.defaultMarker,
                ),
              },
              mapType: MapType.normal,
              style: _mapStyle,
            ),
    );
  }
}
*/

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class NavegacionPedido2 extends StatefulWidget {
  const NavegacionPedido2({Key? key}) : super(key: key);

  @override
  State<NavegacionPedido2> createState() => _NavegacionPedido2State();
}

class _NavegacionPedido2State extends State<NavegacionPedido2>
    with TickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initializeMap();
  }

  Future<void> _loadMapStyle() async {
    String style = await rootBundle.loadString('lib/stylemap/estilomap.json');
    setState(() {
      _mapStyle = style;
    });
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

  Future<void> _initializeRoute(LatLng startLatLng) async {
    _polypoints = await _getPolypoints(startLatLng, _destination);
    _startMarker = Marker(
      markerId: const MarkerId("start"),
      position: startLatLng,
      icon: _startIcon ?? BitmapDescriptor.defaultMarker,
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
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _updateCarPosition(LatLng newPosition, [double? rotation]) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seguimiento en tiempo real"),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    _currentLocation!.latitude!, _currentLocation!.longitude!),
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
                  icon: _destinationIcon ?? BitmapDescriptor.defaultMarker,
                ),
              },
              mapType: MapType.normal,
            ),
    );
  }
}
