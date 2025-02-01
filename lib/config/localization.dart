import 'dart:math';
import 'package:app2025/cliente/provider/user_provider.dart';
import 'package:app2025/config/model/zona_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:location/location.dart' as location_package;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  String apiUrl = dotenv.env['API_URL'] ?? '';
  String apiZona = '/api/zona';
  bool _isloading = false;
  int? zonaIDUbicacion = 0;
  double? latitudUser = 0.0;
  double? longitudUser = 0.0;
  String tituloUbicacion = 'Gracias por compartir tu ubicación!';
  String contenidoUbicacion = '¡Disfruta de Agua Sol!';
  int? clienteID = 0;
  late String direccion;
  late String? distrito;
  List<Zona> listZonas = [];
  List<String> tempString = [];
  Map<int, dynamic> mapaLineasZonas = {};

  Future<dynamic> getZonas() async {
    //print('1) obteniendo las zonas de trabajo');
    var res = await http.get(
      Uri.parse(apiUrl + apiZona),
      headers: {"Content-type": "application/json"},
    );
    try {
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        List<Zona> tempZona = data.map<Zona>((mapa) {
          return Zona(
            id: mapa['id'],
            nombre: mapa['nombre'],
            poligono: mapa['poligono'],
            departamento: mapa['departamento'],
          );
        }).toList();

        if (mounted) {
          setState(() {
            listZonas = tempZona;
            //print('2) esta es la lista de zonas de trabajo');
            //print(listZonas);
          });
          // print('-----------------------------------');
          //print('3) Revisando zona por zona');
          for (var i = 0; i < listZonas.length; i++) {
            // print('zona Nª $i');
            setState(() {
              tempString = listZonas[i].poligono.split(',');
            });

            //print(tempString);
            //el string 'poligono', se separa en strings por las comas en la lista
            //temString
            for (var j = 0; j < tempString.length; j++) {
              //luego se recorre la lista y se hacen puntos con cada dos numeros
              if (j % 2 == 0) {
                //print('es par');
                //es multiplo de dos
                //SI ES PAR
                double x = double.parse(tempString[j]);
                double y = double.parse(tempString[j + 1]);
                //print('$x y $y');
                setState(() {
                  //print('entro al set Statw');
                  listZonas[i].puntos.add(Point(x, y));
                });
              }
            }
            /*print('se llenaron los puntos de esta zona');
            print(listZonas[i].puntos);*/
          }

          //AHORA DE ACUERDO A LA CANTIDAD DE PUTNOS QUE HAY EN LA LISTA DE PUNTOS SE CALCULA LA CANTIDAD
          //DE LINEAS CON LAS QUE S ETRABAJA
          for (var i = 0; i < listZonas.length; i++) {
            //print('entro al for que revisa zona por zona');
            var zonaID = listZonas[i].id;
            //print('esta en la ubicación = $i, con zona ID = $zonaID');
            setState(() {
              /*print(
                  'se crea la key zon ID, con un valor igual a un mapa vacio');*/
              mapaLineasZonas[zonaID] = {};
            });

            for (var j = 0; j < listZonas[i].puntos.length; j++) {
              /*print(
                  'revisa punto por punto en la lista de puntos de cada zona');
              print('zonaID = $zonaID y punto Nº = $j');*/
              //ingresa a un for en el que se obtienen los datos de todas la lineas que forman los puntos del polígono
              if (j == listZonas[i].puntos.length - 1) {
                /*print('-- esta en el ultimo punto');
                print('se hallan las propiedades de la linea');*/
                Point punto1 = listZonas[i].puntos[j];
                Point punto2 = listZonas[i].puntos[0];
                var maxX = max(punto1.x, punto2.x);
                var maxY = max(punto1.y, punto2.y);
                var minY = min(punto1.y, punto2.y);
                var pendiente = (punto2.y - punto1.y) / (punto2.x - punto1.x);
                var constante = punto1.y - (pendiente * punto1.x);
                Map lineaTemporal = {
                  "punto1": punto1,
                  "punto2": punto2,
                  "maxX": maxX,
                  "maxY": maxY,
                  "minY": minY,
                  "pendiente": pendiente,
                  "constante": constante
                };
                //print('$lineaTemporal');

                setState(() {
                  mapaLineasZonas[zonaID][j] = lineaTemporal;
                });
              } else {
                //print('se hallan las propiedades de la linea');
                Point punto1 = listZonas[i].puntos[j];
                Point punto2 = listZonas[i].puntos[j + 1];
                var maxX = max(punto1.x, punto2.x);
                var maxY = max(punto1.y, punto2.y);
                var minY = min(punto1.y, punto2.y);
                var pendiente = (punto2.y - punto1.y) / (punto2.x - punto1.x);
                var constante = punto1.y - (pendiente * punto1.x);
                Map lineaTemporal = {
                  "punto1": punto1,
                  "punto2": punto2,
                  "maxX": maxX,
                  "maxY": maxY,
                  "minY": minY,
                  "pendiente": pendiente,
                  "constante": constante
                };
                //print('$lineaTemporal');
                setState(() {
                  mapaLineasZonas[zonaID][j] = lineaTemporal;
                });
              }
            }
          }
        }
      }
    } catch (e) {
      //print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  // GET UBICACIÓN
  Future<dynamic> creadoUbicacion(clienteId, distrito) async {
    await http.post(Uri.parse("$apiUrl/api/ubicacion"),
        headers: {"Content-type": "application/json"},
        body: jsonEncode({
          "latitud": latitudUser,
          "longitud": longitudUser,
          "direccion": direccion,
          "cliente_id": clienteId,
          "cliente_nr_id": null,
          "distrito": distrito,
          "zona_trabajo_id": zonaIDUbicacion
        }));
  }

  Future<void> obtenerDireccion(x, y) async {
    List<Placemark> placemark = await placemarkFromCoordinates(x, y);
    try {
      if (placemark.isNotEmpty) {
        Placemark lugar = placemark.first;
        setState(() {
          direccion =
              "${lugar.locality}, ${lugar.subAdministrativeArea}, ${lugar.street}";
          setState(() {
            distrito = lugar.locality;
          });
        });
      } else {
        direccion = "Default";
      }
      /*print("x-----y");
      print("${x},${y}");*/
      await puntoEnPoligono(x, y);
    } catch (e) {
      //throw Exception("Error ${e}");
      // Manejo de errores, puedes mostrar un mensaje al usuario indicando que hubo un problema al obtener la ubicación.
      //print("Error al obtener la ubicación: $e");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Error de Ubicación',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            content: const Text(
              'Hubo un problema al obtener la ubicación. Por favor, inténtelo de nuevo.',
              style: TextStyle(fontSize: 16),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  context.pop(); // Cierra el AlertDialog
                  setState(() {
                    _isloading = false;
                  });
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        latitudUser = x;
        longitudUser = y;
        _isloading = false;
        //print('esta es la zonaID $zonaIDUbicacion');
        creadoUbicacion(clienteID, distrito);
        if (zonaIDUbicacion == null) {
          setState(() {
            tituloUbicacion = 'Lo sentimos :(';
            contenidoUbicacion =
                'Todavía no llegamos a tu zona, pero puedes revisar nuestros productos en la aplicación :D';
          });
        }
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              child: Container(
                padding: const EdgeInsets.all(10),
                height: MediaQuery.of(context).size.height / 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage('lib/imagenes/nuevecito.png'))),
                    ),
                    const SizedBox(
                      height: 17,
                    ),
                    Text(
                      "Ubicación añadida exitosamente.",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.width / 25,
                          color: const Color.fromARGB(255, 2, 100, 181)),
                    ),
                    const SizedBox(
                      height: 17,
                    ),
                    TextButton(
                        onPressed: () {
                          context.go('/client');
                        },
                        child: Text(
                          "OK",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width / 25,
                              color: const Color.fromARGB(255, 4, 93, 167)),
                        ))
                  ],
                ),
              ),
            );
          },
        );
        /*showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: Text(
                tituloUbicacion,
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w400,
                    color: Colors.black),
              ),
              content: Text(
                contenidoUbicacion,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                   
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 25,
                        color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );*/
      });
    }
  }

  Future<void> _showlocationpermissiondialogo() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              const Text('Se necesita acceso a la ubicación en segundo plano'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Entendemos y respetamos tu decisión. Sin embargo, queremos informarte que al denegar el permiso de ubicación, es posible que algunas funciones de la aplicación no estén disponibles o no funcionen correctamente.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                context.pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> currentLocation() async {
    var location = location_package.Location();
    location_package.PermissionStatus permissionGranted;
    location_package.LocationData locationData;

    setState(() {
      _isloading = true;
    });

    // Verificar si el servicio de ubicación está habilitado
    var serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      // Solicitar habilitación del servicio de ubicación
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        // Mostrar mensaje al usuario indicando que el servicio de ubicación es necesario
        //_showlocationpermissiondialogo();
        setState(() {
          _isloading = true;
        });
        return;
      }
    }

    // Verificar si se otorgaron los permisos de ubicación
    permissionGranted = await location.hasPermission();
    if (permissionGranted == location_package.PermissionStatus.denied) {
      // Solicitar permisos de ubicación
      permissionGranted = await location.requestPermission();
      if (permissionGranted != location_package.PermissionStatus.granted) {
        // Mostrar mensaje al usuario indicando que los permisos de ubicación son necesarios
        return;
      }
    }

    // Obtener la ubicación
    try {
      locationData = await location.getLocation();

      //updateLocation(locationData);
      await obtenerDireccion(locationData.latitude, locationData.longitude);

      /*print("----ubicación--");
      print(locationData);
      print("----latitud--");
      print(latitudUser);
      print("----longitud--");
      print(longitudUser);*/

      // Aquí puedes utilizar la ubicación obtenida (locationData)
    } catch (e) {
      // Manejo de errores, puedes mostrar un mensaje al usuario indicando que hubo un problema al obtener la ubicación.
      //print("Error al obtener la ubicación: $e");
      throw Exception('Error obtener direccion: $e');
    }
  }

  Future puntoEnPoligono(double? xA, double? yA) async {
    /*print('----------------------------------------');
    print('----------------------------------------');
    print('¡¡ENTRO A PUNTO EN POLIGONO!!');*/
    if (xA is double && yA is double) {
      //print('1) son double, se recorre las zonas');
      for (var i = 0; i < listZonas.length; i++) {
        var zonaID = listZonas[i].id;
        //print('zonaID = $zonaID');
        mapaLineasZonas[zonaID].forEach((value, mapaLinea) {
          //print('Ingreso a recorrer las lineas de la zona $zonaID');
          if (xA <= mapaLinea["maxX"] &&
              mapaLinea['minY'] <= yA &&
              yA <= mapaLinea['maxY']) {
            /*print('- Cumple todas estas');
            print('- $xA <= ${mapaLinea["maxX"]}');
            print('- ${mapaLinea['minY']} <= $yA');
            print('- $yA<= ${mapaLinea['maxY']}');
            print('');*/
            var xInterseccion =
                (yA - mapaLinea['constante']) / mapaLinea['pendiente'];
            /*print('Se calcula la xInterseccion');
            print(
                'xI = ($yA - ${mapaLinea['constante']})/${mapaLinea['pendiente']} = $xInterseccion');*/
            if (xA <= xInterseccion) {
              //EL PUNTO INTERSECTA A LA LINEA
              /*print('- el punto intersecta la linea hacia la deresha');
              print('- $xA <= $xInterseccion');
              print('');*/
              setState(() {
                mapaLinea['intersecciones'] = 1;
              });
            }
          }
        });
      }
      //SE CUENTA LA CANTIDAD DE INTERSECCIONES EN CADA ZONA
      for (var i = 0; i < listZonas.length; i++) {
        //se revisa para cada zona
        /*print('');
        print('');
        print('Ahora se cuenta la cantidad de intersecciones');*/
        var zonaID = listZonas[i].id;
        //print('Primero en la zona $zonaID');
        int intersecciones = 0;
        mapaLineasZonas[zonaID].forEach((key, mapaLinea) {
          if (mapaLinea['intersecciones'] == 1) {
            intersecciones += 1;
          }
        });
        if (intersecciones > 0) {
          //print('Nª intersecciones = $intersecciones en la Zona $zonaID');
          if (intersecciones % 2 == 0) {
            //print('- Es una cantidad PAR, ESTA AFUERA');
            setState(() {
              zonaIDUbicacion = null;
            });
          } else {
            setState(() {
              //print('- Es una cantidad IMPAR, ESTA DENTRO');
              zonaIDUbicacion = zonaID;
              //print(zonaIDUbicacion);
            });
            //es impar ESTA AFUERA
            break;
          }
        } else {
          //print('No tiene intersecciones');
          setState(() {
            zonaIDUbicacion = null;
          });
          //print('');
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getZonas();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    clienteID = userProvider.user?.id;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Definir los tamaños de fuente y espaciados según el ancho de la pantalla

            /* if (constraints.maxWidth <= Breakpoint.xsmall) {
                fontSizeTitle = 12;
                fontSizeSubtitle = 10;
                fontSizeButtons = 12;
              } else if (constraints.maxWidth <= Breakpoint.avgsmall) {
                fontSizeTitle = 12;
                fontSizeSubtitle = 12;
                fontSizeButtons = 16;
              } else if (constraints.maxWidth <= Breakpoint.small) {
                fontSizeTitle = 20;
                fontSizeSubtitle = 16;
                fontSizeButtons = 18;
              } else if (constraints.maxWidth <= Breakpoint.avgmedium) {
                fontSizeTitle = 22;
                fontSizeSubtitle = 18;
                fontSizeButtons = 20;
              } else if (constraints.maxWidth <= Breakpoint.medium) {
                fontSizeTitle = 24;
                fontSizeSubtitle = 20;
                fontSizeButtons = 22;
              } else {
                fontSizeTitle = 26;
                fontSizeSubtitle = 22;
                fontSizeButtons = 24;
              }*/

            return Container(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'lib/imagenes/aguamarina2.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 150),
                      Container(
                        width: 200,
                        height: 100,
                        child: Center(
                          child: Image.asset(
                            'lib/imagenes/nuevito.png',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Para asegurar entregas precisas, permita que AguaSol use tu ubicación todo el tiempo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width / 27,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'AguaSol recopila datos de ubicación para habilitar el reparto y programación de entregas de pedidos, incluso cuando la aplicación está cerrada o no se está utilizando.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width / 27,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage('lib/imagenes/pngegg.png'))),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        // color: Colors.green,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          //crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            TextButton(
                                onPressed: () async {
                                  await _showlocationpermissiondialogo();
                                },
                                child: Text("Denegar",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              20,
                                      fontWeight: FontWeight.bold,
                                    ))),
                            TextButton(
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return const AlertDialog(
                                        content: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            CircularProgressIndicator(
                                              backgroundColor: Color.fromARGB(
                                                  255, 118, 213, 80),
                                            ),
                                            SizedBox(
                                              width: 20,
                                            ),
                                            Text(
                                              "Cargando ...",
                                              style: TextStyle(fontSize: 15),
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                  try {
                                    await currentLocation();
                                  } catch (e) {
                                    throw Exception('Error $e');
                                  }
                                },
                                child: Text("Aceptar",
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              20,
                                      fontWeight: FontWeight.bold,
                                    ))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
