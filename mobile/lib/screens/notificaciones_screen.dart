import 'package:flutter/material.dart';
import '../services/datos.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final datos = DatosSima();

  @override
  void initState() {
    super.initState();
    datos.cargarNotificaciones();
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Notificaciones', style: TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () async {
              await datos.marcarNotificacionesLeidas();
              if (mounted) setState(() {});
            },
            child: const Text('Marcar leídas'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: datos,
        builder: (_, _) {
          if (datos.notificaciones.isEmpty) {
            return const Center(child: Text('No tienes notificaciones por ahora.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: datos.notificaciones.length,
            itemBuilder: (_, i) {
              final n = datos.notificaciones[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: n.leida ? Colors.white : const Color(0xFFE8ECF7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(n.detalle, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
