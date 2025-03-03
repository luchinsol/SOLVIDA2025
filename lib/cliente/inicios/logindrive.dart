import 'package:app2025/cliente/models/ubicacion_model.dart';
import 'package:app2025/cliente/models/user_model.dart';
import 'package:app2025/cliente/provider/user_provider.dart';
import 'package:app2025/cliente/config/localization.dart';
import 'package:app2025/conductor/model/conductor_model.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import 'package:provider/provider.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';
//import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:intl/intl.dart';

class PreloginDriver extends StatefulWidget {
  const PreloginDriver({super.key});

  @override
  State<PreloginDriver> createState() => _PreloginDriverState();
}

class _PreloginDriverState extends State<PreloginDriver> {
  //FUNCION ORIGINAL LOGIN
  bool _obscureText1 = true;
  double opacity = 0.0;

  String apiUrl = dotenv.env['API_URL'] ?? '';
  String microUrl = dotenv.env['MICRO_URL'] ?? '';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usuario = TextEditingController();
  final TextEditingController _contrasena = TextEditingController();
  late int status = 0;
  late int rol = 0;
  late int id = 0;
  late String nivel = "NA";

  bool yaTieneUbicaciones = false;
  bool noTienePedidosEsNuevo = false;
  /*final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth __auth = FirebaseAuth.instance;*/
  String apiCreateUser = '/api/user_cliente';
  String rolIdKey = "rol_id";
  String nicknameKey = "nickname";
  String contrasenaKey = "contrasena";
  String emailKey = "email";
  String nombreKey = "nombre";
  String apellidosKey = "apellidos";
  String telefonoKey = "telefono";
  String rucKey = "ruc";
  String dniKey = "dni";
  String fechaNacimientoKey = "fecha_nacimiento";
  String fechaCreacionCuentaKey = "fecha_creacion_cuenta";
  String sexoKey = "sexo";
  String numrecargas = "";
  String microLogin = "/login";
  late ConductorModel conductor;

  @override
  void initState() {
    super.initState();
    //getUsers();
    // Iniciar la animación de la opacidad después de 500 milisegundos
    Timer(Duration(milliseconds: 900), () {
      setState(() {
        opacity = 1;
      });
    });
  }

  Future<void> loginsol(username, password, BuildContext context) async {
    try {
      print("credenciales - $username $password");

      print("Enviando solicitud de login...");
      print("URL: ${microUrl + microLogin}");

      var res = await http.post(
        Uri.parse(microUrl + microLogin),
        headers: {"Content-type": "application/json"},
        body: jsonEncode({"nickname": username, "contrasena": password}),
      );

      print("Código de respuesta: ${res.statusCode}");
      print("Cuerpo de respuesta: ${res.body}");

      if (res.statusCode == 201) {
        var data = json.decode(res.body);
        setState(() {
          rol = data['user']['rol_id'];
          status = res.statusCode;
        });
        if (data['driver']['nivel'] != null) {
          setState(() {
            nivel = data['driver']['nivel'];
          });
        } else {
          setState(() {
            nivel = "NA";
          });
        }

        // Guardar token de la respuesta
        SharedPreferences tokenUser = await SharedPreferences.getInstance();
        tokenUser.setString('token', data['token']);
        print("ENTRANDO AL MODEL ----------------------------");

        conductor = ConductorModel(
            id: data['driver']['id'],
            nombres: data['driver']['nombres'],
            apellidos: data['driver']['apellidos'],
            fecha_nacimiento:
                DateTime.parse(data['driver']['fecha_nacimiento']),
            licencia: data['driver']['n_licencia'],
            soat: data['driver']['n_soat'],
            valoracion: data['driver']['valoración'],
            latitud: data['driver']['latitud'],
            longitud: data['driver']['longitud'],
            estado_registro: data['driver']['estado_regitro'],
            estado_trabajo: data['driver']['estado_trabajo'],
            departamento: data['driver']['departamento'],
            provincia: data['driver']['provincia'],
            evento_id: data['driver']['evento_id'],
            foto_perfil: data['driver']['foto_perfil'],
            nombre: 'almacen_${data['driver']['evento_id']}',
            nivel: nivel);

        print("Login exitoso:");
        //print(data);
        print(conductor.nombre);

        Provider.of<ConductorProvider>(context, listen: false)
            .updateConductor(conductor);
      } else {
        print("Error en login: ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      print("Excepción en login: $e");
    }
  }

  // VISTA DEL WIDGET

  //ESTA ES LA VISTA PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 41, 35, 103),
        body: Padding(
          padding: const EdgeInsets.all(0.0),
          child: SingleChildScrollView(
            // reverse: true,
            physics: const BouncingScrollPhysics(),
            child: Stack(
              children: [
                /* Positioned.fill(
                  child: Image.asset(
                    'lib/imagenes/aguamarina2.png',
                    fit: BoxFit.cover,
                  ),
                ),*/
                Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: Column(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      //crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 77.sp),
                        Container(
                          width: 156.w,
                          height: 127.h,
                          decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image:
                                      AssetImage('lib/imagenes/nuevito.png'))),
                        ),
                        SizedBox(height: 43.h),
                        Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Inicia sesión",
                                style: GoogleFonts.poppins(
                                    fontSize: 24.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 19.h),
                              Text(
                                "Repartidor",
                                style: GoogleFonts.poppins(
                                    fontSize: 24.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(
                                height: 0,
                              ),
                              Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 34.h,
                                    ),
                                    Container(
                                      height: 48.h,
                                      width: 332.w,
                                      padding:
                                          EdgeInsets.only(left: 20, right: 20),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(30.r)),
                                      child: TextFormField(
                                        controller: _usuario,
                                        keyboardType:
                                            TextInputType.visiblePassword,
                                        decoration: InputDecoration(
                                          //necesario para login

                                          labelText: 'Usuario',
                                          hintText: 'Usuario',
                                          border: InputBorder.none,
                                          isDense: true,
                                          labelStyle: GoogleFonts.poppins(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.grey),
                                          hintStyle: GoogleFonts.poppins(
                                              fontSize: 16.sp,
                                              color: Colors.grey),
                                          /*prefixIcon: Icon(
                                              Icons.person_outline_outlined,
                                              color: Colors.grey,
                                              size: 16.sp,
                                            )*/
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Por favor, ingrese su usuario';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      height: 34.h,
                                    ),
                                    Container(
                                      height: 48.h,
                                      width: 332.w,
                                      padding:
                                          EdgeInsets.only(left: 20, right: 20),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(30.r)),
                                      child: TextFormField(
                                        controller: _contrasena,
                                        keyboardType:
                                            TextInputType.visiblePassword,
                                        obscureText: _obscureText1,
                                        decoration: InputDecoration(
                                          labelText: 'Contraseña',
                                          hintText: 'Contraseña',
                                          isDense: true,
                                          border: InputBorder.none,
                                          labelStyle: GoogleFonts.poppins(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.grey),
                                          hintStyle: GoogleFonts.poppins(
                                              fontSize: 16.sp,
                                              color: Colors.grey),
                                          suffixIcon: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _obscureText1 = !_obscureText1;
                                              });
                                            },
                                            child: Icon(
                                              _obscureText1
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off,
                                              color: Colors.grey,
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  18.5,
                                            ),
                                          ),
                                          /* prefixIcon: Icon(
                                            Icons.lock_outline,
                                            size: 16.sp, //30,
                                            color: Colors.grey,
                                          ),*/
                                        ),
                                        //VALIDACION DE CONTRASEÑA ORIGINAL
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Por favor, ingrese una contraseña';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 19.h,
                        ),
                        Container(
                          decoration: BoxDecoration(
                              //color: Colors.blue,
                              borderRadius: BorderRadius.circular(10)),
                          margin: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width /
                                  3), //MediaQuery.of(context).size.width / 3),
                          child: TextButton(
                              onPressed: () {
                                context.push('/recovery');
                              },

                              //RECUPERACION DE CONTRASEÑA DEL ARCHIVO ORIGINAL
                              child: Text(
                                "¿Olvidaste contraseña?",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15.sp,
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255)),
                              )),
                        ),
                        SizedBox(
                          height: 19.h,
                        ),
                        Center(
                          child: Container(
                            width: 331.w, //MediaQuery.of(context).size.width,
                            height: 48.h, //50,
                            child: ElevatedButton(
                                onPressed: () async {
                                  //INICIAR SESIÓN DEL ARCHIVO ORIGINAL

                                  if (_formKey.currentState!.validate()) {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          );
                                        });
                                    try {
                                      await loginsol(_usuario.text,
                                          _contrasena.text, context);

                                      if (status == 201) {
                                        context
                                            .pop(); // Cerrar el primer AlertDialog

                                        print("q pasa=");
                                        //SI ES CLIENTE
                                        if (rol == 4) {
                                          //SI ES CONDUCTOR
                                        } else if (rol == 5) {
                                          print("...ROL: $rol");
                                          if (nivel == 'admin') {
                                            context.go('/admin');
                                          } else {
                                            context.go('/drive');
                                          }

                                          //SI ES GERENTE
                                        } else if (rol == 3) {
                                          //por cmabiar
                                        }

                                        //SI NO ESTA REGISTRADO
                                      } else if (status == 401) {
                                        context
                                            .pop(); // Cerrar el primer AlertDialog

                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Dialog(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    5,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: const BoxDecoration(
                                                          image: DecorationImage(
                                                              image: AssetImage(
                                                                  'lib/imagenes/nuevecito.png'))),
                                                    ),
                                                    const SizedBox(
                                                      height: 19,
                                                    ),
                                                    Text(
                                                      "Credenciales inválidas.",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              25,
                                                          color: const Color
                                                              .fromARGB(255, 2,
                                                              100, 181)),
                                                    ),
                                                    const SizedBox(
                                                      height: 19,
                                                    ),
                                                    TextButton(
                                                        onPressed: () {
                                                          context.pop();
                                                        },
                                                        child: const Text(
                                                          "OK",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 24,
                                                              color: const Color
                                                                  .fromARGB(255,
                                                                  4, 93, 167)),
                                                        ))
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      } else if (status == 404) {
                                        context.pop();
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Dialog(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    5,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: const BoxDecoration(
                                                          image: DecorationImage(
                                                              image: AssetImage(
                                                                  'lib/imagenes/nuevecito.png'))),
                                                    ),
                                                    const SizedBox(
                                                      height: 19,
                                                    ),
                                                    Text(
                                                      "Usuario no existente. Intente de nuevo.",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              25,
                                                          color: const Color
                                                              .fromARGB(255, 2,
                                                              100, 181)),
                                                    ),
                                                    const SizedBox(
                                                      height: 19,
                                                    ),
                                                    TextButton(
                                                        onPressed: () {
                                                          context.pop();
                                                        },
                                                        child: const Text(
                                                          "OK",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 24,
                                                              color: const Color
                                                                  .fromARGB(255,
                                                                  4, 93, 167)),
                                                        ))
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    } catch (e) {
                                      /*print(
                                          "Excepción durante el inicio de sesión: $e");*/
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30.r))),
                                child: Text(
                                  "Iniciar sesión",
                                  style: GoogleFonts.poppins(
                                      color:
                                          const Color.fromRGBO(0, 77, 225, 1),
                                      fontSize: 17.sp, //30,
                                      fontWeight: FontWeight.bold),
                                )),
                          ),
                        ),
                        SizedBox(
                          height: 43.h,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
