import 'package:flutter/material.dart';
import '../main.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _ocultarPassword = true;

  static const Color rojoSima = Color(0xFFF00707);
  static const Color azulSima = Color(0xFF1D4ED8);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color fondoCampo = Color(0xFFEEF2F8);

  void _irAlInicioApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const InicioAppScreen()),
    );
  }

  void _irAlRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(
              children: [
                // 1. LOGO SIMA (Engrane azul + texto rojo SIMA)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0026FF), width: 3),
                            ),
                            child: const Icon(Icons.build_rounded, color: Color(0xFF0026FF), size: 30),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'SIMA',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: rojoSima,
                              letterSpacing: 1.2,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'SERVICIOS INTEGRALES DE MANTENIMIENTO AUTOMOTRIZ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. BADGE "SERVICIO TÉCNICO OFICIAL"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Color(0xFF0026FF)),
                      SizedBox(width: 6),
                      Text(
                        'SERVICIO TÉCNICO OFICIAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0026FF),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. TÍTULO Y SUBTÍTULO
                const Text(
                  'Tu taller mecánico de confianza\nen la palma de tu mano',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: textoOscuro,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Diagnósticos en tiempo real, citas garantizadas y\ntrazabilidad completa de tu vehículo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),

                // 4. BARRA DE BOTONES: INICIAR SESIÓN / CREAR CUENTA
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EFF8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // Botón Activo: Iniciar Sesión
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline, size: 16, color: azulSima),
                              SizedBox(width: 6),
                              Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: azulSima,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Botón que direcciona a Crear Cuenta (RegistroScreen)
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _irAlRegistro,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add_alt_1_outlined, size: 16, color: Color(0xFF475569)),
                                SizedBox(width: 6),
                                Text(
                                  'Crear Cuenta',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 5. TARJETA DEL FORMULARIO DE ACCESO
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Etiqueta Correo Electrónico *
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textoOscuro),
                          children: [
                            TextSpan(text: 'Correo Electrónico '),
                            TextSpan(text: '*', style: TextStyle(color: rojoSima)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'tu@correo.com',
                          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                          filled: true,
                          fillColor: fondoCampo,
                          prefixIcon: const Icon(Icons.email_outlined, size: 19, color: Color(0xFF64748B)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Etiqueta Contraseña * + ¿Olvidaste tu contraseña?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textoOscuro),
                              children: [
                                TextSpan(text: 'Contraseña '),
                                TextSpan(text: '*', style: TextStyle(color: rojoSima)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: azulSima,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _ocultarPassword,
                        decoration: InputDecoration(
                          hintText: '••••••••••••',
                          filled: true,
                          fillColor: fondoCampo,
                          prefixIcon: const Icon(Icons.vpn_key_outlined, size: 19, color: Color(0xFF64748B)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 19,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // BOTÓN ROJO: INICIAR SESIÓN EN SIMA ->
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rojoSima,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: _irAlInicioApp,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Iniciar Sesión en SIMA',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // DIVISOR "o accede rápidamente"
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'o accede rápidamente',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // BOTONES GOOGLE Y APPLE
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: fondoCampo,
                                foregroundColor: textoOscuro,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _irAlInicioApp,
                              icon: const Icon(Icons.g_mobiledata, size: 26, color: Colors.red),
                              label: const Text('Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: fondoCampo,
                                foregroundColor: textoOscuro,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _irAlInicioApp,
                              icon: const Icon(Icons.apple, size: 20, color: Colors.black),
                              label: const Text('Apple', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. TEXTO INFERIOR DE TÉRMINOS Y PRIVACIDAD
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
                    children: [
                      TextSpan(text: 'Al continuar, aceptas nuestros '),
                      TextSpan(
                        text: 'Términos de Servicio',
                        style: TextStyle(
                          color: azulSima,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ' y\n'),
                      TextSpan(
                        text: 'Privacidad',
                        style: TextStyle(
                          color: azulSima,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}