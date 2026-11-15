import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/datos.dart';
import 'cita_expres_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool esLogin = true;
  bool ocultarPass = true;
  bool cargando = false;

  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController(text: 'cliente@sima.mx');
  final _passCtrl = TextEditingController(text: 'sima1234');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_correoCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _mostrarMensaje('Ingresa tu correo y contraseña.');
      return;
    }
    if (!esLogin &&
        (_nombreCtrl.text.trim().isEmpty ||
            _apellidosCtrl.text.trim().isEmpty ||
            _telefonoCtrl.text.trim().isEmpty)) {
      _mostrarMensaje('Completa nombre, apellidos y teléfono.');
      return;
    }

    setState(() => cargando = true);
    try {
      final datos = DatosSima();
      if (esLogin) {
        await datos.iniciarSesion(_correoCtrl.text, _passCtrl.text);
      } else {
        await datos.registrarCuenta(
          nombre: _nombreCtrl.text,
          apellidos: _apellidosCtrl.text,
          telefono: _telefonoCtrl.text,
          correo: _correoCtrl.text,
          contrasena: _passCtrl.text,
        );
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      _mostrarMensaje(ApiClient.mensajeError(e));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _configurarServidor() async {
    final actual = await ApiClient().obtenerBaseUrl();
    final ctrl = TextEditingController(text: actual);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servidor API SIMA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emulador Android: http://10.0.2.2:3000/api/v1\nCelular físico: http://<IP-DE-TU-PC>:3000/api/v1',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await ApiClient().guardarBaseUrl(ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              _mostrarMensaje('Servidor actualizado');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Configurar IP del servidor',
                  icon: const Icon(Icons.dns_outlined, color: azulSima, size: 20),
                  onPressed: _configurarServidor,
                ),
              ),
              Image.asset(
                'assets/images/logo.png',
                height: 62,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text(
                  'SIMA',
                  style: TextStyle(color: rojoSima, fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                esLogin ? 'Tu taller mecánico de confianza\nen la palma de tu mano' : 'Crea tu Cuenta en SIMA',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
              ),
              const SizedBox(height: 6),
              Text(
                esLogin
                    ? 'Diagnósticos en tiempo real, citas garantizadas y trazabilidad completa.'
                    : 'Gestiona el mantenimiento y seguimiento en tiempo real de tus vehículos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFE5E9F2), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => esLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: esLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('Iniciar Sesión',
                                style: TextStyle(fontWeight: FontWeight.bold, color: esLogin ? azulSima : Colors.grey[700])),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          esLogin = false;
                          _correoCtrl.clear();
                          _passCtrl.clear();
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !esLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('Crear Cuenta',
                                style: TextStyle(fontWeight: FontWeight.bold, color: !esLogin ? azulSima : Colors.grey[700])),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!esLogin) ...[
                _campo('Nombre *', 'Ej. Ana', Icons.person_outline, _nombreCtrl),
                const SizedBox(height: 12),
                _campo('Apellidos *', 'Ej. Ruiz Pérez', Icons.badge_outlined, _apellidosCtrl),
                const SizedBox(height: 12),
                _campo('Teléfono / WhatsApp *', 'Ej. 9981234567', Icons.phone_outlined, _telefonoCtrl,
                    teclado: TextInputType.phone),
                const SizedBox(height: 12),
              ],
              _campo('Correo Electrónico *', 'cliente@sima.mx', Icons.mail_outline, _correoCtrl,
                  teclado: TextInputType.emailAddress),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contraseña *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passCtrl,
                    obscureText: ocultarPass,
                    decoration: InputDecoration(
                      hintText: '••••••••••••',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(ocultarPass ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => ocultarPass = !ocultarPass),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rojoSima,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: cargando ? null : _enviar,
                  child: cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(esLogin ? 'Iniciar Sesión en SIMA →' : 'Registrarme en SIMA →',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              if (esLogin) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('o Agenda cita Exprés', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: rojoSima,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: rojoSima, width: 1.5),
                      ),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CitaExpresScreen())),
                    child: const Text('Agendar cita Exprés →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, String hint, IconData icon, TextEditingController ctrl,
      {TextInputType teclado = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: teclado,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
