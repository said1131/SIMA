import 'package:flutter/material.dart';
import '../main.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _ocultarPass = true;
  bool _aceptaTerminos = false;

  static const Color rojoSima = Color(0xFFF00707);
  static const Color azulSima = Color(0xFF1D4ED8);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color fondoCampo = Color(0xFFEEF2F8);

  void _completarRegistroEIrAlInicio() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const InicioAppScreen()),
      (route) => false,
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
                const Text(
                  'Crear Cuenta en SIMA',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textoOscuro),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Registra tus datos para gestionar tus vehículos y citas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),

                // Selector superior para volver a Iniciar Sesión
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EFF8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_outline, size: 16, color: Color(0xFF475569)),
                                SizedBox(width: 6),
                                Text(
                                  'Iniciar Sesión',
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
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_alt_1_outlined, size: 16, color: azulSima),
                              SizedBox(width: 6),
                              Text(
                                'Crear Cuenta',
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
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Tarjeta del Formulario de Registro
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _campoFormulario('Nombre *', 'Tu nombre', Icons.person_outline, _nombreCtrl),
                      const SizedBox(height: 14),
                      _campoFormulario('Apellido *', 'Tus apellidos', Icons.badge_outlined, _apellidoCtrl),
                      const SizedBox(height: 14),
                      _campoFormulario('Dirección *', 'Calle, número y colonia', Icons.location_on_outlined, _direccionCtrl),
                      const SizedBox(height: 14),
                      _campoFormulario('Correo Electrónico *', 'tu@correo.com', Icons.email_outlined, _correoCtrl),
                      const SizedBox(height: 14),
                      const Text('Contraseña *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _ocultarPass,
                        decoration: InputDecoration(
                          hintText: '••••••••••••',
                          filled: true,
                          fillColor: fondoCampo,
                          prefixIcon: const Icon(Icons.vpn_key_outlined, size: 19, color: Color(0xFF64748B)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 19,
                            ),
                            onPressed: () => setState(() => _ocultarPass = !_ocultarPass),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _aceptaTerminos,
                        onChanged: (v) => setState(() => _aceptaTerminos = v ?? false),
                        title: const Text('Acepto términos y condiciones', style: TextStyle(fontSize: 12.5)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rojoSima,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _completarRegistroEIrAlInicio,
                          child: const Text(
                            'Registrarme en SIMA',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(backgroundColor: fondoCampo, foregroundColor: textoOscuro),
                              onPressed: _completarRegistroEIrAlInicio,
                              icon: const Icon(Icons.g_mobiledata, size: 26, color: Colors.red),
                              label: const Text('Google'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(backgroundColor: fondoCampo, foregroundColor: textoOscuro),
                              onPressed: _completarRegistroEIrAlInicio,
                              icon: const Icon(Icons.apple, size: 20, color: Colors.black),
                              label: const Text('Apple'),
                            ),
                          ),
                        ],
                      ),
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

  Widget _campoFormulario(String label, String hint, IconData icono, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textoOscuro)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: fondoCampo,
            prefixIcon: Icon(icono, size: 19, color: const Color(0xFF64748B)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}