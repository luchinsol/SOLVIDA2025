import 'dart:async';
import 'dart:convert';

import 'package:app2025/cliente/barracliente/barraclient.dart';
import 'package:app2025/cliente/views/confirmarubi.dart';
import 'package:app2025/cliente/views/formubi.dart';
import 'package:app2025/cliente/views/pedido.dart';
import 'package:app2025/cliente/views/prefinal.dart';
import 'package:app2025/cliente/views/productos.dart';
import 'package:app2025/cliente/views/promos.dart';
import 'package:app2025/cliente/provider/pedido_provider.dart';
import 'package:app2025/cliente/provider/ubicacion_list_provider.dart';
import 'package:app2025/cliente/provider/ubicacion_provider.dart';
import 'package:app2025/cliente/provider/user_provider.dart';
import 'package:app2025/conductor/barraconductor/barraconductor.dart';
import 'package:app2025/conductor/providers/pedidos_provider.dart';
import 'package:app2025/conductor/views/calificacion.dart';
import 'package:app2025/conductor/views/cargaproductos.dart';
import 'package:app2025/conductor/views/demodrive.dart';
import 'package:app2025/conductor/views/detalle.dart';
import 'package:app2025/conductor/views/navegacion.dart';
import 'package:app2025/conductor/views/notificaciones.dart';
import 'package:app2025/conductor/views/demo.dart';
import 'package:app2025/cliente/config/localization.dart';
import 'package:app2025/conductor/config/notifications.dart';
import 'package:app2025/conductor/config/socketcentral.dart';
import 'package:app2025/cliente/inicios/bienvenida.dart';
import 'package:app2025/cliente/inicios/login.dart';
import 'package:app2025/cliente/inicios/nowifi.dart';
import 'package:app2025/cliente/inicios/recoverypass.dart';
import 'package:app2025/cliente/inicios/tiporegister.dart';
import 'package:app2025/cliente/inicios/register2.dart';
import 'package:app2025/cliente/inicios/updatepass.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationsService = NotificationsService();
  NotificationsService().initNotification();
  NotificationsService().requestNotificationPermission();

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('es_ES', null);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userJson = prefs.getString('user');
  bool estalogeado = userJson != null;
  int rol = 0;

  if (estalogeado) {
    rol = jsonDecode(userJson)['rolid'];
  }

  UserProvider userProvider = UserProvider();
  await userProvider.initUser();
  SocketService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider(create: (context) => PedidoProvider()),
        ChangeNotifierProvider(create: (context) => UbicacionProvider()),
        ChangeNotifierProvider(create: (context) => UbicacionListProvider()),
        ChangeNotifierProvider(create: (context) {
          final pedidosProvider = PedidosProvider();
          // Setup notification handling when orders are received
          return pedidosProvider;
        }),
      ],
      child: const MyApp(),
    ),
  );
}

// RUTAS PARA NAVEGACIÓN
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const Bienvenida();
        //return const NavegacionPedido2(); // Pantalla principal con navegación curva
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const Prelogin();
        // return const Login(); // Pantalla principal con navegación curva
      },
    ),
    GoRoute(
        path: '/drive',
        builder: (BuildContext context, GoRouterState state) {
          NotificationsService().silenceNotifications(false);
          return const BarraConductor(); // Pantalla principal con navegación curva
        },
        routes: [
          GoRoute(
            path: 'notificacion',
            builder: (BuildContext context, GoRouterState state) {
              // final orderId = state.params['id'];
              return const Notificaciones(); //OrderDetailScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: 'navegar',
            builder: (BuildContext context, GoRouterState state) {
              // final orderId = state.params['id'];
              return const NavegacionPedido(); //OrderDetailScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: 'calificar',
            builder: (BuildContext context, GoRouterState state) {
              // final orderId = state.params['id'];
              return const Calificacion(); //OrderDetailScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: 'cargar',
            builder: (BuildContext context, GoRouterState state) {
              // final orderId = state.params['id'];
              return const Almacenes(); //OrderDetailScreen(orderId: orderId);
            },
          )
        ]),
    GoRoute(
        path: '/client',
        builder: (BuildContext context, GoRouterState state) {
          return const BarraNavegacion();
          //return const BarraCliente(); // Pantalla principal con navegación curva
        },
        routes: [
          GoRoute(
              path: 'promos',
              builder: (BuildContext context, GoRouterState state) {
                return const Promos();
              }),
          GoRoute(
              path: 'productos',
              builder: (BuildContext context, GoRouterState state) {
                return const Productos();
              }),
          GoRoute(
            path: 'pedido',
            builder: (BuildContext context, GoRouterState state) {
              NotificationsService().silenceNotifications(true);
              return PopScope(
                  canPop: true,
                  onPopInvoked: (bool didPop) {
                    if (didPop) {
                      NotificationsService().silenceNotifications(false);
                      return;
                    }
                  },
                  child: const Pedido());
            },
          ),
          GoRoute(
              path: 'ubicacion',
              builder: (BuildContext context, GoRouterState state) {
                return const FormUbi();
              }),
          GoRoute(
              path: 'localizacion',
              builder: (BuildContext context, GoRouterState state) {
                return const LocationPermissionScreen();
              }),
          GoRoute(
            path: 'confirmarubicacion/:direccion',
            name: 'confirmarubicacion',
            builder: (BuildContext context, GoRouterState state) {
              final direccion = state.pathParameters['direccion'] ?? '';
              return Confirmarubi(
                direccion: direccion,
              );
            },
          ),
          GoRoute(
              path: 'ventafin',
              builder: (BuildContext context, GoRouterState state) {
                return const Prefinal();
              })
        ]),
    GoRoute(
        path: '/update',
        builder: (BuildContext context, GoRouterState state) {
          return const Newpass();
        }),
    GoRoute(
        path: '/recovery',
        builder: (BuildContext context, GoRouterState state) {
          return const Recuperacion();
        }),
    GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          return const Registroelegir();
        },
        routes: [
          GoRoute(
              path: 'modeclient',
              builder: (BuildContext context, GoRouterState state) {
                return const Formucli();
              }),
        ]),
    GoRoute(
        path: '/wifi',
        builder: (BuildContext context, GoRouterState state) {
          return const NoInternetScreen();
        }),
  ],
);

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = true; // Estado de carga inicial
  bool estalogeado = false;
  int rol = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user');

    setState(() {
      estalogeado = userJson != null;
      if (estalogeado) {
        rol = jsonDecode(userJson!)['rolid'];
      }
      isLoading = false; // Cambia el estado de carga
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(412, 917),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: _router,
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
        );
      },
    );
  }
}
