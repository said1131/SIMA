import 'package:flutter/material.dart';
import 'screen/login_screen.dart';

void main() {
  runApp(const SimaApp());
}

class SimaApp extends StatelessWidget {
  const SimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIMA - Sistema Automotriz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8),
          primary: const Color(0xFF1D4ED8),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// Pantalla principal a la que direcciona el botón "Iniciar Sesión en SIMA"
class InicioAppScreen extends StatefulWidget {
  const InicioAppScreen({super.key});

  @override
  State<InicioAppScreen> createState() => _InicioAppScreenState();
}

class _InicioAppScreenState extends State<InicioAppScreen> {
  int _indiceActual = 0;

  @override
  Widget build(BuildContext context) {
    final titulos = [
      'Mi Garage y Vehículos',
      'Catálogo y Citas',
      'Seguimiento en Vivo',
      'Historial de Servicios',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Text(titulos[_indiceActual]),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Módulo activo: ${titulos[_indiceActual]}\n(Siguiente pantalla a construir)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (index) => setState(() => _indiceActual = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), label: 'Mi Garage'),
          NavigationDestination(icon: Icon(Icons.build_outlined), label: 'Catálogo'),
          NavigationDestination(icon: Icon(Icons.timeline), label: 'Seguimiento'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}