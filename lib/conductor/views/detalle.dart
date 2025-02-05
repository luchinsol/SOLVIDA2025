import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Detalle extends StatefulWidget {
  const Detalle({Key? key}) : super(key: key);

  @override
  State<Detalle> createState() => _DetalleState();
}

class _DetalleState extends State<Detalle> {
  String text = "Detalle";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Acción cuando el usuario presiona la flecha "atrás" del AppBar
            context.pop();
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
                    context.go('/drive');
                  },
                  child: Text("FIN"))
            ],
          ),
        ),
      ),
    );
  }
}
