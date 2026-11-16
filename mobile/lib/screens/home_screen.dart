import 'package:flutter/material.dart';
import '../services/datos.dart';
import 'cotizaciones_screen.dart';
import 'garage_screen.dart';
import 'historial_screen.dart';
import 'ordenes_taller_screen.dart';
import 'servicios_citas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final datos = DatosSima();
  int _indice = 0;

  @override
  void initState() {
    super.initState();
    datos.addListener(_refrescar);
  }

  @override
  void dispose() {
    datos.removeListener(_refrescar);
    super.dispose();
  }

  void _refrescar() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cotizacionesPendientes = datos.ordenes
        .where((o) =>
            (o.cotizacionEnviada || o.estado == 'Cotizada') &&
            o.autorizacion == 'Pendiente')
        .length;

    final pantallas = [
      GarageScreen(irAServicios: () => setState(() => _indice = 1)),
      const ServiciosCitasScreen(),
      OrdenesTallerScreen(
        irAServicios: () => setState(() => _indice = 1),
        irACotizaciones: () => setState(() => _indice = 3),
      ),
      const CotizacionesScreen(),
      const HistorialScreen(),
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
              _itemNav(
                3,
                Icons.request_quote_outlined,
                'Cotizaciones',
                badge: cotizacionesPendientes,
              ),
              _itemNav(4, Icons.history, 'Historial'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemNav(int idx, IconData icon, String label, {int badge = 0}) {
    final activo = _indice == idx;
    return GestureDetector(
      onTap: () => setState(() => _indice = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: activo ? const Color(0xFF102566) : Colors.white,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: activo ? const Color(0xFF102566) : Colors.white,
                  ),
                ),
              ],
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD92323),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}