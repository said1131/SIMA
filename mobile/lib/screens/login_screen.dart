import 'package:flutter/material.dart';
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
              const SizedBox(height: 12),
              // Logo SIMA desde assets
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

              // Switch Iniciar Sesión / Crear Cuenta
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
                        onTap: () => setState(() => esLogin = false),
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
                _campo('Nombre', 'Ej. Juan', Icons.person_outline),
                const SizedBox(height: 12),
                _campo('Apellido', 'Ej. Pérez Mora', Icons.badge_outlined),
                const SizedBox(height: 12),
                _campo('Dirección', 'Calle, número, colonia, código postal', Icons.location_on_outlined),
                const SizedBox(height: 12),
              ],
              _campo('Correo Electrónico *', esLogin ? 'tu@correo.com' : 'ejemplo@correo.com', Icons.mail_outline),
              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contraseña *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
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
                  if (!esLogin) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Icon(Icons.radio_button_unchecked, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 8),
                          Text('Mínimo 8 caracteres', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
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
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                  child: Text(esLogin ? 'Iniciar Sesión en SIMA →' : 'Registrarme en SIMA →',
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
                        side: const BorderSide(color: rojoSima, width: 1.5)),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CitaExpresScreen())),
                    child: const Text('Agendar cita Exprés →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Ya tienes una cuenta?  ', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    GestureDetector(
                      onTap: () => setState(() => esLogin = true),
                      child: const Text(
                        'iniciar sesión',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: azulSima),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
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