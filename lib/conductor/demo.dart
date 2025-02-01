import 'package:app2025/config/notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Demos extends StatefulWidget {
  const Demos({Key? key}) : super(key: key);

  @override
  State<Demos> createState() => _DemosState();
}

class _DemosState extends State<Demos> {
  String text = "Pedidos";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Acción cuando el usuario presiona la flecha "atrás" del AppBar
            //context.pop();
          },
        ),
      ),
      body: PopScope(
        canPop: true, // Permitir que se pueda retroceder
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          // Aquí simplemente se permite el retroceso sin ningún proceso adicional
          if (!didPop) {
            context.pop(); // Retroceder a la pantalla anterior
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
                    NotificationsService().showOrderNotification(
                      id: 29999,
                      title: 'Pedido #765433',
                      body: 'El pedido ha sido anulado.',
                      payload: 'order',

                      // payload: 'order_765433',
                    );
                    // NotificationsService().showGroupedNotifications();
                    //   NotificationsService().showNotificationsSequentially();
                  },
                  child: Text("Detalle pedido"))
            ],
          ),
        ),
      ),
    );
  }
}
