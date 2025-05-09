import 'dart:async';
import 'dart:convert';

import 'package:app2025/cliente/barracliente/barraclient.dart';
import 'package:app2025/cliente/inicios/logindrive.dart';
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
import 'package:app2025/conductor/barraconductor/barraconductoradmin.dart';
import 'package:app2025/conductor/providers/chipspedidos_provider.dart';
import 'package:app2025/conductor/providers/conexionstatus_provider.dart';
import 'package:app2025/conductor/providers/conexionswitch_provider.dart';
import 'package:app2025/conductor/providers/lastpedido_provider.dart';
import 'package:app2025/conductor/providers/notificacioncustom_provider.dart';
import 'package:app2025/conductor/providers/notificaciones_provider.dart';

import 'package:app2025/conductor/providers/pedidos_provider.dart';

import 'package:app2025/conductor/providers/almacen_provider.dart';
import 'package:app2025/conductor/providers/conductor_provider.dart';
import 'package:app2025/conductor/providers/pedidos_provider2.dart';
import 'package:app2025/conductor/views/admin.dart';

import 'package:app2025/conductor/views/calificacion.dart';

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
import 'package:app2025/conductor/views/pedidodemo.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await dotenv.load(fileName: ".env");
  // Crear instancia del provider
  //final pedidosProvider = PedidosProvider();
  //final notificationsService = NotificationsService();
  //await notificationsService.initNotification();
  //await notificationsService.requestNotificationPermission();

  //notificationsService.silenceNotifications(true);
  await initializeDateFormatting('es_ES', null);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userJson = prefs.getString('user');
  bool estalogeado = userJson != null;
  int rol = 0;

  print("----/////// $userJson");

  if (estalogeado) {
    rol = jsonDecode(userJson)['rolid'];
    print("ROLLLLLLL----->>>");
    print(rol);
  }

  UserProvider userProvider = UserProvider();
  await userProvider.initUser();

  ConductorProvider conductorProvider = ConductorProvider();
  await conductorProvider.initConductor();
  //SocketService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider(create: (context) => PedidoProvider()),
        ChangeNotifierProvider(create: (context) => UbicacionProvider()),
        ChangeNotifierProvider(create: (context) => UbicacionListProvider()),
        //ChangeNotifierProvider<PedidosProvider>.value(value: pedidosProvider),
        ChangeNotifierProvider<ConductorProvider>.value(
            value: conductorProvider),
        ChangeNotifierProvider(create: (context) => AlmacenProvider()),
        ChangeNotifierProvider(create: (context) => PedidosProvider2()),
        ChangeNotifierProvider(create: (context) => LastpedidoProvider()),
        ChangeNotifierProvider(
            create: (context) => ConductorConnectionProvider()),
        ChangeNotifierProvider(
            create: (context) => NotificationProvider(context)),
        ChangeNotifierProvider(
            create: (context) => NotificacionesInicioProvider()),
        ChangeNotifierProvider(create: (context) => ConexionStatusProvider()),
        ChangeNotifierProvider(
            create: (context) => ChipspedidosProvider(context))
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
        //NotificationsService().silenceNotifications(true);
        //return const AdminDriver();
        // return const PedidoWidget();
        UserProvider userProvider = Provider.of<UserProvider>(context);
        ConductorProvider conductorProvider =
            Provider.of<ConductorProvider>(context);
        if (userProvider.user != null) {
          return UpgradeAlert(
              upgrader: Upgrader(
                languageCode: "es",
                //debugLogging: true,
                minAppVersion: "3.4.0",
                //debugDisplayAlways: true,
              ),
              showIgnore: false,
              showLater: false,
              child: const BarraNavegacion());
        } else if (conductorProvider.conductor != null) {
          return UpgradeAlert(
              upgrader: Upgrader(
                languageCode: "es",
                minAppVersion: "3.4.0",
              ),
              showIgnore: false,
              showLater: false,
              child: const BarraConductorAdmin());
        } else {
          return UpgradeAlert(
              upgrader: Upgrader(
                languageCode: "es",
                //debugLogging: true,
                minAppVersion: "3.4.0",
                //debugDisplayAlways: true,
              ),
              showIgnore: false,
              showLater: false,
              child: const Bienvenida());
          //return const Demos();
          //return const NavegacionPedido2(); // Pantalla principal con navegación curva
        }
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (BuildContext context, GoRouterState state) {
        return const BarraConductorAdmin();
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
      path: '/repartidortemp',
      builder: (BuildContext context, GoRouterState state) {
        return const PreloginDriver();
        // return const Login(); // Pantalla principal con navegación curva
      },
    ),
    GoRoute(
        path: '/localizacion',
        builder: (BuildContext context, GoRouterState state) {
          return const LocationPermissionScreen();
        }),
    GoRoute(
        path: '/drive',
        builder: (BuildContext context, GoRouterState state) {
          //NotificationsService().silenceNotifications(false);
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
              //NotificationsService().silenceNotifications(false);
              return PopScope(
                  canPop: true,
                  onPopInvoked: (bool didPop) {
                    if (didPop) {
                      //NotificationsService().silenceNotifications(false);
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
    saveStartTime();
  }

  Future<void> saveStartTime() async {
    final tiempoCond = await SharedPreferences.getInstance();
    // Verificar si ya existe una hora guardada
    if (!tiempoCond.containsKey('startTime')) {
      final startTime = DateTime.now().millisecondsSinceEpoch;
      await tiempoCond.setInt('startTime', startTime);
    }
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
          debugShowCheckedModeBanner: false,
          title: 'Sol vida',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
        );
      },
    );
  }
}
