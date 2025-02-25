import 'package:app2025/conductor/views/admin.dart';
import 'package:app2025/conductor/views/historial.dart';
import 'package:app2025/conductor/views/inicio.dart';
import 'package:app2025/conductor/views/pedido.dart';
import 'package:app2025/conductor/views/perfil.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BarraConductorAdmin extends StatefulWidget {
  const BarraConductorAdmin({Key? key}) : super(key: key);

  @override
  State<BarraConductorAdmin> createState() => _BarraConductorAdminState();
}

class _BarraConductorAdminState extends State<BarraConductorAdmin> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = const [
    AdminDriver(),
    Perfil(),
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
        color: const Color.fromARGB(255, 43, 40, 195),
        buttonBackgroundColor: const Color.fromARGB(255, 43, 40, 195),
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.home_filled, size: 30, color: Colors.white),
          Icon(Icons.more_vert_outlined, size: 30, color: Colors.white),
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
