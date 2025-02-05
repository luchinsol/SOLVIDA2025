import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sin conexión"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              "No tienes conexión a internet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Por favor verifica tu conexión y vuelve a intentar.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Verificar conexión de nuevo
                context.pop();
              },
              child: const Text("Reintentar"),
            ),
          ],
        ),
      ),
    );
  }
}
