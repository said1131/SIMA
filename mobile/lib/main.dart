import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

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
      home: const LoginScreen(),
    );
  }
}