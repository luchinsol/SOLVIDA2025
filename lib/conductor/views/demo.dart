import 'package:app2025/conductor/config/notifications.dart';
import 'package:app2025/conductor/providers/pedidos_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Demos extends StatefulWidget {
  const Demos({Key? key}) : super(key: key);

  @override
  State<Demos> createState() => _DemosState();
}

class _DemosState extends State<Demos> {
  late PedidosProvider _pedidosProvider;
  final NotificationsService _notificationsService = NotificationsService();
  String text = "Pedidos";
  bool _shouldShowNotifications = false;

  @override
  void initState() {
    super.initState();
    _pedidosProvider = Provider.of<PedidosProvider>(context, listen: false);
    _setupNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCurrentRoute();
    });
  }

  void _checkCurrentRoute() {
    final String currentPath = GoRouterState.of(context).uri.path;
    setState(() {
      _shouldShowNotifications = currentPath == '/drive/navegar';
    });

    // Observar cambios de ruta
    GoRouter.of(context).routerDelegate.addListener(() {
      if (!mounted) return;
      final String newPath = GoRouterState.of(context).uri.path;
      setState(() {
        _shouldShowNotifications = newPath == '/drive/navegar';
      });

      // Si entramos a la ruta correcta, verificamos pedidos pendientes
      if (_shouldShowNotifications) {
        _handlePedidosChange();
      }
    });
  }

  void _setupNotifications() {
    _notificationsService.initNotification();
    _notificationsService.requestNotificationPermission();
    _pedidosProvider.addListener(() {
      if (_shouldShowNotifications) {
        _handlePedidosChange();
      }
    });
  }

  void _handlePedidosChange() {
    if (!_shouldShowNotifications) return;

    final activePedidos = _pedidosProvider.getActivePedidos();
    for (var pedido in activePedidos) {
      _notificationsService.showOrderNotification(
        id: int.parse(pedido.id),
        title: 'Nuevo Pedido #${pedido.id}',
        body:
            'Cliente: ${pedido.clienteName}\nDirección: ${pedido.ubicacion['direccion']}',
        payload: 'order_${pedido.id}',
      );
    }
  }

  @override
  void dispose() {
    _pedidosProvider.removeListener(_handlePedidosChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            //context.pop();
          },
        ),
      ),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (!didPop) {
            context.pop();
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(fontSize: 24),
              ),
              ElevatedButton(
                  onPressed: () {
                    //0. crear un metodo en la clase socket central clase notificaciones showordernotificacion
                    //1. LLENAR ESTA NOTIFICACION CON LA INFORMACION DE PROVIDER
                    //2. ME DIRIJO A LA CLASE DE NOTIFICACIONES
                    //3. CAMBIO DENEGAR A VER
                    //4. MODIFICAR LAS ACCIONES DE LA FUNCION ONNOTIFICATIONRESPONSE
                    //5. CAMBIAR LOS NOMBRES Y LAS ACCIONES TIENEN QUE COINCIDIR
                    //6. PASARLE LA INFORMACION DEL PROVIDER PARA LA LOGICA DEL ACEPTADO
                    //7. EL SOCKET REEMPLAZA AL BOTON
                    NotificationsService().showOrderNotification(
                      id: 29999,
                      title: 'Pedido #765433',
                      body: 'El pedido ha sido anulado.',
                      payload: 'order',
                    );
                  },
                  child: Text("Detalle pedido"))
            ],
          ),
        ),
      ),
    );
  }
}
