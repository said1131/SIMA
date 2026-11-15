import 'package:flutter/material.dart';
import '../models/cita_model.dart';
import '../services/api_client.dart';
import '../services/datos.dart';
import 'agendar_cita_screen.dart';

class ServiciosCitasScreen extends StatefulWidget {
  const ServiciosCitasScreen({super.key});

  @override
  State<ServiciosCitasScreen> createState() => _ServiciosCitasScreenState();
}

class _ServiciosCitasScreenState extends State<ServiciosCitasScreen> {
  final datos = DatosSima();
  bool verCatalogo = true;
  String filtroCategoria = 'Todos';
  String textoBusqueda = '';

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

  Future<void> _cancelarCita(Cita c) async {
    try {
      await datos.cancelarCita(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cita cancelada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.mensajeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);

    final serviciosFiltrados = datos.catalogo.where((s) {
      final coincideCat = filtroCategoria == 'Todos' || s.categoria == filtroCategoria;
      final coincideBusq = s.titulo.toLowerCase().contains(textoBusqueda.toLowerCase());
      return coincideCat && coincideBusq;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Servicios & Citas',
            style: TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (verCatalogo) ...[
              TextField(
                onChanged: (v) => setState(() => textoBusqueda = v),
                decoration: InputDecoration(
                  hintText: 'Buscar frenos, afinación, escáner...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFE5E9F2), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => verCatalogo = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: verCatalogo ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('Catálogo',
                              style: TextStyle(fontWeight: FontWeight.bold, color: verCatalogo ? azulSima : Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => verCatalogo = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !verCatalogo ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('Mis citas (${datos.citas.length})',
                              style: TextStyle(fontWeight: FontWeight.bold, color: !verCatalogo ? azulSima : Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (verCatalogo) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Todos', 'Preventivo', 'Frenos', 'Eléctrico', 'Suspensión', 'Motor'].map((cat) {
                    final sel = filtroCategoria == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: sel,
                        selectedColor: azulSima,
                        labelStyle: TextStyle(color: sel ? Colors.white : azulSima, fontWeight: FontWeight.bold, fontSize: 12),
                        onSelected: (_) => setState(() => filtroCategoria = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: datos.cargarCatalogoPublico,
                  child: ListView.builder(
                    itemCount: serviciosFiltrados.length,
                    itemBuilder: (_, i) {
                      final s = serviciosFiltrados[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.categoria.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: azulSima)),
                            Text(s.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(s.descripcion,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('\$${s.precio.toStringAsFixed(0)} MXN',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: azulSima)),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: rojoSima, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AgendarCitaScreen(servicioInicial: s)),
                                  ),
                                  child: const Text('Agendar →', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: datos.cargarCitas,
                  child: datos.citas.isEmpty
                      ? ListView(children: const [SizedBox(height: 80), Center(child: Text('No tienes citas aún.'))])
                      : ListView.builder(
                          itemCount: datos.citas.length,
                          itemBuilder: (_, i) => _tarjetaCita(datos.citas[i]),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaCita(Cita c) {
    final esConfirmada = c.estado == 'Confirmada';
    final esCancelada = c.estado == 'Rechazada' || c.estado == 'Cancelada';
    final colorBorde = esConfirmada
        ? const Color(0xFF1B8A4B)
        : (esCancelada ? const Color(0xFFD92323) : const Color(0xFFE5A100));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: colorBorde, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(c.servicio, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              Text(c.estado, style: TextStyle(color: colorBorde, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${c.vehiculo} (${c.placas}) · ${c.fecha} ${c.hora} hrs',
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          if (c.motivoRechazo != null && c.motivoRechazo!.isNotEmpty)
            Text('Motivo: ${c.motivoRechazo}', style: const TextStyle(fontSize: 12, color: Color(0xFFD92323))),
          if (c.estado == 'Solicitada')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _cancelarCita(c),
                child: const Text('Cancelar cita', style: TextStyle(color: Color(0xFFD92323))),
              ),
            ),
        ],
      ),
    );
  }
}
