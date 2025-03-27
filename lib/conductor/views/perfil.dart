import 'package:app2025/conductor/config/notifications.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Perfil extends StatefulWidget {
  const Perfil({Key? key}) : super(key: key);
  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  @override
  Widget build(BuildContext context) {
    final conductorProvider = context.watch<ConductorProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        //crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 319.h,
            width: 1.sw,
            color: const Color.fromARGB(255, 185, 185, 185),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 26.h,
                ),
                Container(
                  height: 142.w,
                  width: 142.w,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(75.r)),
                ),
                SizedBox(
                  height: 26.h,
                ),
                Text(
                  "${conductorProvider.conductor?.nombres} ${conductorProvider.conductor?.apellidos}",
                  style: GoogleFonts.manrope(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
                SizedBox(
                  height: 26.h,
                ),
                Text(
                  "Conductor",
                  style: GoogleFonts.manrope(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                )
              ],
            ),
          ),
          SizedBox(
            height: 30.h,
          ),
          Padding(
            padding: EdgeInsets.only(left: 20.r, right: 20.r),
            child: Column(
              children: [
                Container(
                  height: 55.0.h,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 168, 168, 168),
                      borderRadius: BorderRadius.circular(15.r)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_outlined,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          SizedBox(
                            width: 15.0.w,
                          ),
                          Text(
                            "Editar perfil",
                            style: GoogleFonts.manrope(
                                fontSize: 12.sp, color: Colors.white),
                          )
                        ],
                      ),
                      Container(
                        height: 30.w,
                        width: 30.w,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50.r)),
                        child: IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.arrow_forward_ios_outlined,
                              size: 12.sp,
                            )),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 16.0.h,
                ),
                Container(
                  height: 55.0.h,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 168, 168, 168),
                      borderRadius: BorderRadius.circular(15.r)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          SizedBox(
                            width: 15.0.w,
                          ),
                          Text(
                            "Ajustes",
                            style: GoogleFonts.manrope(
                                fontSize: 12.sp, color: Colors.white),
                          )
                        ],
                      ),
                      Container(
                        height: 30.w,
                        width: 30.w,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50.r)),
                        child: IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.arrow_forward_ios_outlined,
                              size: 12.sp,
                            )),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 16.0.h,
                ),
                Material(
                  elevation: 15.0.r,
                  borderRadius: BorderRadius.circular(15.r),
                  child: Container(
                      height: 55.0.h,
                      width: 1.sw,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 62, 65, 220),
                          borderRadius: BorderRadius.circular(15.r)),
                      child: ElevatedButton(
                          onPressed: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            prefs.remove('conductor');
                            Provider.of<ConductorProvider>(context,
                                    listen: false)
                                .logout();
                            context.go('/');
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.exit_to_app),
                              SizedBox(
                                width: 12.w,
                              ),
                              Text(
                                "Cerrar sesión",
                                style: GoogleFonts.manrope(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ))),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
