import 'package:flutter/material.dart';
import 'garage_screen.dart';
import 'servicios_citas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      GarageScreen(irAServicios: () => setState(() => _indice = 1)),
      const ServiciosCitasScreen(),
      const Center(child: Text('En Taller')),
      const Center(child: Text('Cotizaciones')),
      const Center(child: Text('Historial')),
    ];

    return Scaffold(
      body: pantallas[_indice],
      bottomNavigationBar: Container(
        color: const Color(0xFF102566),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _itemNav(0, Icons.directions_car, 'Garage'),
              _itemNav(1, Icons.build_outlined, 'Servicios'),
              _itemNav(2, Icons.assignment_outlined, 'En Taller'),
              _itemNav(3, Icons.request_quote_outlined, 'Cotizaciones'),
              _itemNav(4, Icons.history, 'Historial'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemNav(int idx, IconData icon, String label) {
    final activo = _indice == idx;
    return GestureDetector(
      onTap: () => setState(() => _indice = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: activo ? const Color(0xFF102566) : Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: activo ? const Color(0xFF102566) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}