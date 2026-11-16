import 'package:flutter/material.dart';
import '../screens/notificaciones_screen.dart';
import '../services/datos.dart';

class CampanaNotificaciones extends StatelessWidget {
  final int? cantidadForzada;

  const CampanaNotificaciones({
    super.key,
    this.cantidadForzada,
  });

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const verdeAviso = Color(0xFF1B8A4B);
    final datos = DatosSima();

    return AnimatedBuilder(
      animation: datos,
      builder: (context, _) {
        final int noLeidas = cantidadForzada ?? datos.notificacionesNoLeidas;
        final bool hayNuevas = noLeidas > 0;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hayNuevas
                      ? const Color(0xFFE6F7EE)
                      : const Color(0xFFEEF2F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hayNuevas
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none,
                  color: hayNuevas ? verdeAviso : azulSima,
                  size: 20,
                ),
              ),
              if (hayNuevas)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: verdeAviso,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$noLeidas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}