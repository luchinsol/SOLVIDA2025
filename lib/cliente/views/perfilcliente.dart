import 'package:app2025/cliente/models/user_model.dart';
import 'package:app2025/cliente/provider/user_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PerfilCliente extends StatefulWidget {
  const PerfilCliente({Key? key}) : super(key: key);
  @override
  State<PerfilCliente> createState() => _PerfilCliente();
}

class _PerfilCliente extends State<PerfilCliente> {
  late UserModel clienteUpdate;
  Color colorTitulos = const Color.fromARGB(255, 3, 34, 60);
  Color colorLetra = const Color.fromARGB(255, 1, 42, 76);
  Color colorInhabilitado = const Color.fromARGB(255, 130, 130, 130);
  bool estaHabilitado = false;
  String mensajeBanco = 'Numero de celular, cuenta o CCI';
  List<String> mediosString = ['Yape', 'Plin', 'Transferencia'];
  List<String> bancosString = ['BCP', 'BBVA', 'Caja Arequipa', 'Otros'];
  bool esYape = false;
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _cuenta = TextEditingController();
  String telefono_ = '';
  String cuenta_ = '';
  String apiUrl = dotenv.env['API_URL'] ?? '';
  String apiCliente = '/api/cliente/';
  DateTime fechaLimite = DateTime.now();
  TextEditingController numeroDeCuenta = TextEditingController();
  String numrecargas = '';
  DateTime mesyAnio(String? fecha) {
    if (fecha is String) {
      //print('es string');
      return DateTime.parse(fecha);
    } else {
      //print('no es string');
      return DateTime.now();
    }
  }

  Future<dynamic> recargas(clienteID) async {
    try {
      var res = await http.get(
        Uri.parse(apiUrl + '/api/cliente/recargas/' + clienteID.toString()),
        headers: {"Content-type": "application/json"},
      );
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        if (data != null) {
          if (mounted) {
            setState(() {
              numrecargas = data['recargas'];
            });
          }
        } else {
          if (mounted) {
            setState(() {
              numrecargas = '0';
            });
          }
        }
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  Future<dynamic> updateCliente(saldoBeneficios, suscripcion, frecuencia,
      quiereretirar, clienteID, medioretiro, bancoretiro, numerocuenta) async {
    /* print("2.- UPDAE CLEINTE---");

    print("cliente----------------------------------------------");
    print(clienteID);
    print("end point URI------------------------------------------------");
    print(apiUrl + apiCliente + clienteID.toString());
    print("quiereretirar");
    print(quiereretirar);
    print("saldo bene");
    print(saldoBeneficios);
    print("frencua............");
    print(frecuencia);*/
    await http.put(Uri.parse(apiUrl + apiCliente + clienteID.toString()),
        headers: {"Content-type": "application/json"},
        body: jsonEncode({
          "saldo_beneficios": saldoBeneficios,
          "suscripcion": suscripcion,
          "frecuencia": frecuencia,
          "quiereretirar": quiereretirar,
          "medio_retiro": medioretiro,
          "banco_retiro": bancoretiro,
          "numero_cuenta": numerocuenta
        }));
  }

  void _showTransferDialog(BuildContext context, String type) {
    final TextEditingController numberController = TextEditingController();
    final TextEditingController bankController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            type == 'Otros'
                ? 'Ingrese datos de transferencia'
                : 'Ingrese número de $type',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: type == 'Otros'
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Número de cuenta',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bankController,
                      decoration: const InputDecoration(
                        labelText: 'Banco de procedencia',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                )
              : TextField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Número de destino',
                    //border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Obtener los datos actuales del usuario desde el Provider
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                final currentUser = userProvider.user;

                if (currentUser != null) {
                  try {
                    // Actualizar los datos en la base de datos
                    await updateCliente(
                      currentUser.saldoBeneficio,
                      currentUser.suscripcion,
                      'NA',
                      true, // quiereretirar
                      currentUser.id,
                      type, // medioretiro
                      type == 'Otros'
                          ? bankController.text
                          : type, // bancoretiro
                      numberController.text, // numerocuenta
                    );

                    // Luego actualizar el Provider
                    actualizarProviderCliente(
                      currentUser.id,
                      currentUser.nombre,
                      currentUser.apellidos,
                      currentUser.saldoBeneficio,
                      currentUser.codigocliente,
                      currentUser.fechaCreacionCuenta,
                      currentUser.sexo,
                      'NA',
                      currentUser.suscripcion,
                      type, // medio_retiro
                      type == 'Otros'
                          ? bankController.text
                          : type, // banco_retiro
                      numberController.text, // numero_cuenta
                    );

                    context.pop();

                    // Mostrar mensaje de éxito
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Información de transferencia actualizada correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    // Mostrar mensaje de error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Error al actualizar la información: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Confirmar',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required double width,
    required double height,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: width * 0.25,
      height: height * 0.05,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: width * 0.02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: height * 0.016,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void actualizarProviderCliente(
      clienteid,
      name,
      lastname,
      saldo,
      codigo,
      fechaCreacion,
      sexo,
      frecuencia,
      suscrip,
      medioretiro,
      bancoretiro,
      numerocuenta) async {
    //  print("1 .- ---actualizar Provider");

    clienteUpdate = UserModel(
        id: clienteid,
        nombre: name,
        apellidos: lastname,
        saldoBeneficio: saldo,
        codigocliente: codigo,
        fechaCreacionCuenta: fechaCreacion,
        sexo: sexo,
        frecuencia: frecuencia,
        quiereRetirar: true,
        suscripcion: suscrip,
        rolid: 4);
    // print("${clienteUpdate}");

    Provider.of<UserProvider>(context, listen: false).updateUser(clienteUpdate);

    await updateCliente(saldo, suscrip, frecuencia, true, clienteid,
        medioretiro, bancoretiro, numerocuenta);
  }

  String capitalizarPrimeraLetra(String texto) {
    if (texto.isEmpty) return texto;
    return '${texto[0].toUpperCase()}${texto.substring(1).toLowerCase()}';
  }

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    final idcliente = userProvider.user?.id;
    recargas(idcliente);
  }

  @override
  Widget build(BuildContext context) {
    final anchoActual = MediaQuery.of(context).size.width;
    final largoActual = MediaQuery.of(context).size.height;
    final userProvider = context.watch<UserProvider>();
    fechaLimite = mesyAnio(userProvider.user?.fechaCreacionCuenta)
        .add(const Duration(days: (30 * 3)));
    //TYJYUJY
    return Scaffold(
        backgroundColor: Colors.white,
        body: PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) {
            if (didPop) {
              return;
            }
          },
          /*appBar: AppBar(
        backgroundColor: Colors.white,
      ),*/
          child: SafeArea(
              child: Padding(
            padding: EdgeInsets.all(anchoActual * 0.04),
            child: ListView(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: largoActual * 0.02,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //FOTO DEL CLIENTE
                          Container(
                            margin: EdgeInsets.only(left: anchoActual * 0.035),
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 220, 220, 220),
                                borderRadius: BorderRadius.circular(50)),
                            height: largoActual * 0.085,
                            width: anchoActual * 0.18,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              //poner un if por aqui por si es hombre o mujer
                              child: userProvider.user?.sexo == 'Femenino'
                                  ? Icon(
                                      Icons.face_3_rounded,
                                      color: colorTitulos,
                                      size: anchoActual * 0.14,
                                    )
                                  : Icon(
                                      Icons.face_6_rounded,
                                      color: colorTitulos,
                                      size: anchoActual * 0.14,
                                    ),
                            ),
                          ),

                          SizedBox(
                            width: anchoActual * 0.03,
                          ),
                          Container(
                            width: anchoActual * 0.45,
                            child: Column(
                              //   mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //Nombre
                                Text(
                                  capitalizarPrimeraLetra(
                                      userProvider.user?.nombre ?? ''),
                                  textAlign: TextAlign.left,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.normal,
                                    fontSize: largoActual * 0.023,
                                    color: colorTitulos,
                                  ),
                                ),

                                SizedBox(height: largoActual * 0.005),
                                // Ícono de estrella
                              ],
                            ),
                          ),
                          //SizedBox(width: anchoActual * 0.02),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.015,
                  ),

                  // SizedBox(height: largoActual * 0.03),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(anchoActual * 0.03),
                    /*
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    */

                    child: /*Row(
                      mainAxisAlignment: MainAxisAlignment
                          .start, // Cambiado para alinear al inicio
                      children: [
                        Column(
                          children: [*/
                        Text(
                      'Resumen',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    //  ],
                    // ),
                    //  ],
                    //   ),
                  ),

                  // Resumen Section
                  Container(
                    width: double.infinity,
                    /*
                    padding: EdgeInsets.symmetric(
                      horizontal: anchoActual * 0.04,
                      vertical: anchoActual * 0.03,
                    ),
              */

                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.4),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: anchoActual * 0.35,
                          child: Card(
                            elevation: 0,
                            color: Colors.grey.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: largoActual * 0.02,
                                vertical: largoActual * 0.015,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.monetization_on,
                                    color: Colors.blue.shade700,
                                    size: largoActual * 0.03,
                                  ),
                                  SizedBox(height: largoActual * 0.01),
                                  Text(
                                    'S/. ${userProvider.user?.saldoBeneficio}0',
                                    style: GoogleFonts.poppins(
                                      fontSize: largoActual * 0.025,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Soles',
                                    style: GoogleFonts.poppins(
                                      fontSize: largoActual * 0.016,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Retiralo hasta: ${fechaLimite.day}/${fechaLimite.month}/${fechaLimite.year}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w400,
                                        fontSize: largoActual * 0.016),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: largoActual * 0.06,
                          width: 1.5,
                          color: Colors.grey.shade200,
                        ),
                        SizedBox(
                          width: anchoActual * 0.35,
                          child: Card(
                            elevation: 0,
                            color: Colors.grey.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: largoActual * 0.02,
                                vertical: largoActual * 0.015,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.work,
                                    color: Colors.blue.shade700,
                                    size: largoActual * 0.03,
                                  ),
                                  SizedBox(height: largoActual * 0.01),
                                  Text(
                                    '${numrecargas}',
                                    style: GoogleFonts.poppins(
                                      fontSize: largoActual * 0.025,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Recargas',
                                    style: GoogleFonts.poppins(
                                      fontSize: largoActual * 0.016,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  //SizedBox(height: largoActual * 0.03),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(anchoActual * 0.03),
                    /*
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    */
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment
                          .start, // Cambiado para alinear al inicio
                      children: [
                        Column(
                          children: [
                            Text(
                              'Código',
                              style: GoogleFonts.poppins(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Código Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 100.h,
                        padding: EdgeInsets.symmetric(
                          horizontal: anchoActual * 0.04,
                          vertical: largoActual * 0.015,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            // <- Aquí se añade la sombra
                            BoxShadow(
                              color: Colors.grey
                                  .withOpacity(0.3), // Color de la sombra
                              spreadRadius: 1, // Qué tanto se expande
                              blurRadius: 5, // Qué tan borrosa es
                              offset: const Offset(
                                  0, 2), // Posición (horizontal, vertical)
                            ),
                          ],
                          color:
                              Colors.white, // Importante añadir color de fondo
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${userProvider.user?.codigocliente}',
                              style: GoogleFonts.poppins(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Válido por 3 meses',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w400,
                              ),
                            )

                            /*
                            IconButton(
                              icon: Icon(
                                Icons.share,
                                size: largoActual * 0.025,
                                color: Colors.grey,
                              ),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),*/
                          ],
                        ),
                      ),
                    ],
                  ),

                  //SizedBox(height: largoActual * 0.03),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(anchoActual * 0.03),
                    /*
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    */
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment
                          .start, // Cambiado para alinear al inicio
                      children: [
                        Column(
                          children: [
                            Text(
                              'Escoge el tipo de retiro',
                              style: GoogleFonts.poppins(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildButton(
                        context: context,
                        text: 'Yape',
                        width: anchoActual,
                        height: largoActual,
                        onPressed: () => _showTransferDialog(context, 'Yape'),
                      ),
                      _buildButton(
                        context: context,
                        text: 'Plin',
                        width: anchoActual,
                        height: largoActual,
                        onPressed: () => _showTransferDialog(context, 'Plin'),
                      ),
                      _buildButton(
                        context: context,
                        text: 'Otros',
                        width: anchoActual,
                        height: largoActual,
                        onPressed: () => _showTransferDialog(context, 'Otros'),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.085,
              ),
              Container(
                  child: ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.remove('user');
                  if (context.mounted) {
                    context.go('/');
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10), // Borde recto (sin radio)
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15), // Ajuste del tamaño del botón
                  backgroundColor: Colors.blue, // Color de fondo del botón
                ),
                child: Text(
                  'Cerrar sesión',
                  style: GoogleFonts.poppins(
                      fontSize: largoActual * 0.018,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              )),
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.085,
              ),
            ]),
          )),
        ));
  }

  void _showThankYouDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gracias'),
          content: const Text(
              'Se realizará el depósito mediante el método de pago que eligió dentro del plazo de una semana'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                context.pop();
              },
            ),
          ],
        );
      },
    );
  }
}
