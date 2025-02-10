import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:solvida/componentes/responsiveUI/breakpoint.dart';

class Bienvenida extends StatefulWidget {
  const Bienvenida({super.key});

  @override
  State<Bienvenida> createState() => _BienvenidaState();
}

class _BienvenidaState extends State<Bienvenida> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: true,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            return;
          }
        },
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(61, 85, 212, 1),
                /* gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Colors.blue,
                   // const Color(0xFF3179D2),
                  
                ),*/

                image: DecorationImage(
                  image: AssetImage('lib/imagenes/aguamarina2.png'),
                  fit: BoxFit
                      .cover, // Cambiado a BoxFit.cover para que cubra todo el Container
                ),
              ),
            ),
            Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 128.h,
                ),
                // IMAGENES
                Center(
                    child: Container(
                  width: 156.w,
                  height: 127.h, //MediaQuery.of(context).size.height/3,
                  decoration: const BoxDecoration(
                    //color: Colors.grey,
                    image: DecorationImage(
                      image: AssetImage('lib/imagenes/nuevito.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                )),
                SizedBox(
                  height: 84.h,
                ),
                Center(
                  child: Text('Bienvenido a la gran',
                      style: GoogleFonts.poppins(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                Center(
                  child: Text(
                    "familia SOL VIDA",
                    style: GoogleFonts.poppins(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                SizedBox(
                  height: 32.h,
                ),
                Container(
                  height: 63.h,
                  width: 330.w,
                  //color: Colors.grey,
                  child: Text(
                    "Descubre todas nuestras \nnovedades",
                    style: GoogleFonts.poppins(
                        fontSize: 19.sp,
                        letterSpacing: 0.05 * 20.sp,
                        fontWeight: FontWeight.w300,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 48.h,
                ),
                // BOTONES

                Container(
                  width: 331.w,
                  height: 39.h,
                  // color: Colors.grey,
                  child: ElevatedButton(
                      onPressed: () {
                        context.push('/login');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(0, 77, 255, 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r))),
                      child: Text(
                        "Iniciar sesión",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      )),
                ),
                SizedBox(
                  height: 26.h,
                ),
                Container(
                  width: 331.w,
                  height: 39.h,
                  child: ElevatedButton(
                      onPressed: () {
                        context.go('/register');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 255, 255, 255),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r))),
                      child: Text(
                        "Registrarse",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            color: const Color.fromRGBO(0, 77, 255, 1),
                            fontWeight: FontWeight.w600),
                      )),
                ),

                SizedBox(
                  height: 26.h,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                        thickness: 2,
                        indent: 40.sp,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal:
                              8.0), // Espacio entre las líneas y el texto
                      child: Text(
                        "o",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                        thickness: 2,
                        endIndent: 40.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 26.h,
                ),
                Container(
                  width: 331.w,
                  height: 39.h,
                  // color: Colors.grey,
                  child: ElevatedButton(
                      onPressed: () {
                        context.push('/repartidortemp');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(0, 77, 255, 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r))),
                      child: Text(
                        "Iniciar sesión conductor",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
