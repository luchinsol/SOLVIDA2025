/*import 'package:app2025/cliente/vista1.dart';
import 'package:app2025/cliente/vista2.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BarraCliente extends StatefulWidget {
  const BarraCliente({Key? key}) : super(key: key);

  @override
  State<BarraCliente> createState() => _CurvedNavigationState();
}

class _CurvedNavigationState extends State<BarraCliente> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = const [
    Vista1(),
    Vista2(),
    //Historial(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: const Color.fromARGB(255, 226, 226, 226),
        buttonBackgroundColor: const Color.fromRGBO(42, 75, 160, 1),
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.home_filled, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
          // Icon(Icons.assignment_outlined, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
    );
  }
}
*/

import 'package:app2025/cliente/views/estadopedido.dart';
import 'package:app2025/cliente/views/hola.dart';
import 'package:app2025/cliente/views/perfilcliente.dart';
import 'package:app2025/cliente/views/promos.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class BarraNavegacion extends StatefulWidget {
  const BarraNavegacion({Key? key}) : super(key: key);

  @override
  State<BarraNavegacion> createState() => _BarraNavegacionState();
}

class _BarraNavegacionState extends State<BarraNavegacion> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = const [
    Hola2(clienteId: 1, esNuevo: true), // Simulación de datos
    PerfilCliente(),
    EstadoPedido()
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: const Color.fromRGBO(0, 106, 252, 1.0),
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.home_rounded, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
          Icon(Icons.assignment_rounded, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
    );
  }
}
