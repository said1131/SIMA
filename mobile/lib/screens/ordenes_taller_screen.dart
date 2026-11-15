import 'package:flutter/material.dart';
import '../models/orden_model.dart';
import '../services/datos.dart';

class OrdenesTallerScreen extends StatefulWidget {
  const OrdenesTallerScreen({super.key});

  @override
  State<OrdenesTallerScreen> createState() => _OrdenesTallerScreenState();
}

class _OrdenesTallerScreenState extends State<OrdenesTallerScreen> {
  final datos = DatosSima();

  @override
  void initState() {
    super.initState();
    datos.addListener(_refrescar);
  }

  @override
  void dispose() {
    datos.removeListener(_refrescar);
    super.dispose();
  }

  void _refrescar() => setState(() {});

  static const _pasos = ['Recibida', 'En diagnóstico', 'Cotizada', 'Autorizada', 'En reparación', 'Lista'];

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    final activas = datos.ordenes.where((o) => o.estado != 'Entregada').toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('En Taller', style: TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: datos.cargarOrdenes,
        child: activas.isEmpty
            ? ListView(children: const [SizedBox(height: 100), Center(child: Text('No tienes vehículos en taller actualmente.'))])
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activas.length,
                itemBuilder: (_, i) => _tarjetaOrden(activas[i]),
              ),
      ),
    );
  }

  Widget _tarjetaOrden(OrdenTrabajo o) {
    const azulSima = Color(0xFF102566);
    final pasoActual = _pasos.indexOf(o.estado);
    final progreso = pasoActual < 0 ? 0.15 : (pasoActual + 1) / _pasos.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.folio, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: azulSima)),
              Text(o.estado, style: const TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(o.servicio, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('${o.vehiculo} · ${o.placas}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          if (o.mecanico != null) Text('Mecánico: ${o.mecanico}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progreso, minHeight: 8, backgroundColor: const Color(0xFFE5E9F2), color: azulSima),
          if (o.diagnostico != null && o.diagnostico!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Diagnóstico: ${o.diagnostico}', style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
