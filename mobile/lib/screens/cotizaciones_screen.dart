import 'package:flutter/material.dart';
import '../models/orden_model.dart';
import '../services/api_client.dart';
import '../services/datos.dart';

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
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

  Future<void> _abrirDetalle(int ordenId) async {
    try {
      final detalle = await datos.obtenerDetalleOrden(ordenId);
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (ctx) => _DetalleSheet(
          orden: detalle,
          onDecidir: (decision) async {
            Navigator.pop(ctx);
            await datos.responderCotizacion(detalle.id, decision);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cotización $decision')));
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.mensajeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    final cotizadas = datos.ordenes.where((o) => o.cotizacionEnviada || o.estado == 'Cotizada').toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Cotizaciones', style: TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: datos.cargarOrdenes,
        child: cotizadas.isEmpty
            ? ListView(children: const [SizedBox(height: 100), Center(child: Text('No tienes cotizaciones enviadas.'))])
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cotizadas.length,
                itemBuilder: (_, i) {
                  final o = cotizadas[i];
                  final pendiente = o.autorizacion == 'Pendiente';
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
                            Text('${o.folio} · ${o.vehiculo}', style: const TextStyle(fontWeight: FontWeight.bold, color: azulSima)),
                            Text(o.autorizacion,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: pendiente ? const Color(0xFFB45309) : const Color(0xFF1B8A4B))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(o.servicio, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total: \$${o.total.toStringAsFixed(2)} MXN',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: azulSima)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pendiente ? const Color(0xFFD92323) : azulSima,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _abrirDetalle(o.id),
                              child: Text(pendiente ? 'Revisar' : 'Ver desglose'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _DetalleSheet extends StatelessWidget {
  final OrdenTrabajo orden;
  final Future<void> Function(String decision) onDecidir;

  const _DetalleSheet({required this.orden, required this.onDecidir});

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    final pendiente = orden.autorizacion == 'Pendiente';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cotización ${orden.folio}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: azulSima)),
          Text('${orden.vehiculo} (${orden.placas})', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const Divider(height: 22),
          ...orden.conceptos.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${c.concepto} (x${c.cantidad.toStringAsFixed(0)})')),
                  Text('\$${c.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total (IVA incluido)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('\$${orden.total.toStringAsFixed(2)} MXN',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: azulSima)),
            ],
          ),
          if (pendiente) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFD92323)),
                    onPressed: () => onDecidir('Rechazada'),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B8A4B), foregroundColor: Colors.white),
                    onPressed: () => onDecidir('Autorizada'),
                    child: const Text('Autorizar trabajo'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
