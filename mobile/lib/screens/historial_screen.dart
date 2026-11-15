import 'package:flutter/material.dart';
import '../services/datos.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    final datos = DatosSima();
    final entregadas = datos.ordenes.where((o) => o.estado == 'Entregada').toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Historial de Servicios',
            style: TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: datos.cargarOrdenes,
        child: entregadas.isEmpty
            ? ListView(children: const [SizedBox(height: 100), Center(child: Text('Aún no tienes servicios entregados.'))])
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entregadas.length,
                itemBuilder: (_, i) {
                  final o = entregadas[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(o.folio, style: const TextStyle(fontWeight: FontWeight.bold, color: azulSima)),
                            const Text('Entregada', style: TextStyle(color: Color(0xFF1B8A4B), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(o.servicio, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('${o.vehiculo} · ${o.placas}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        const SizedBox(height: 6),
                        Text('Total pagado: \$${o.total.toStringAsFixed(2)} MXN',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
