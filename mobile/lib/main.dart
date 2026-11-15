import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/datos.dart';

void main() {
  runApp(const SimaApp());
}

class SimaApp extends StatelessWidget {
  const SimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIMA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF102566),
          primary: const Color(0xFF102566),
          secondary: const Color(0xFFD92323),
        ),
      ),
      home: const _InicioSesionCheck(),
    );
  }
}

class _InicioSesionCheck extends StatefulWidget {
  const _InicioSesionCheck();

  @override
  State<_InicioSesionCheck> createState() => _InicioSesionCheckState();
}

class _InicioSesionCheckState extends State<_InicioSesionCheck> {
  late final Future<bool> _sesionFuture;

  @override
  void initState() {
    super.initState();
    _sesionFuture = DatosSima().restaurarSesion();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sesionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == true ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
