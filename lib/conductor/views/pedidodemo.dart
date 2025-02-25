import 'package:app2025/conductor/model/pedido_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PedidoWidget extends StatefulWidget {
  const PedidoWidget({Key? key}) : super(key: key);

  @override
  _PedidoWidgetState createState() => _PedidoWidgetState();
}

class _PedidoWidgetState extends State<PedidoWidget> {
  bool isExpanded = false;
  late GoogleMapController _mapController;

  void _toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 📍 Google Map - NO se redibuja al expandir
        Positioned.fill(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(15), // Opcional, para bordes redondeados
            child: GoogleMap(
              // key: ValueKey(index), // 🔑 Clave única para evitar recreaciones
              initialCameraPosition: CameraPosition(
                target: LatLng(-16.404875716889595, -71.51875540815976),
                zoom: 14,
              ),
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
        ),

        /// 🔻 Contenedor animado (solo la tarjeta de información)
        Positioned(
          bottom: 20,
          left: 10,
          right: 10,
          child: GestureDetector(
            onTap: _toggleExpanded,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              height: isExpanded ? 200 : 80, // 📌 Solo la info se expande
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26, blurRadius: 10, spreadRadius: 1),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Cliente",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  if (isExpanded) ...[
                    Text("Dirección: widget.pedido.direccion}"),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {}, // Acción al aceptar el pedido
                      child: const Text("Aceptar Pedido"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
