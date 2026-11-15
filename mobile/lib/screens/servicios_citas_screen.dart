import 'package:flutter/material.dart';
import '../models/cita_model.dart';
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
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Text(
                'SIMA',
                style: TextStyle(color: rojoSima, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Servicios & Citas',
              style: TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Switch Catálogo / Mis citas
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
                          child: Text('Mis citas',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold, color: !verCatalogo ? azulSima : Colors.grey)),
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
                  children: ['Todos', 'Preventivo', 'Frenos & Suspensión', 'Electrónica'].map((cat) {
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
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8ECF7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.car_repair, color: azulSima, size: 34),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
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
                                    const SizedBox(height: 4),
                                    Text('🕒 ${s.duracion}   🛡️ Garantía 6m',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Precio estimado', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text('\$${s.precio.toStringAsFixed(0)} MXN',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900, fontSize: 16, color: azulSima)),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: rojoSima,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AgendarCitaScreen(servicioInicial: s)),
                                  );
                                },
                                child: const Text('Agendar →', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // Pestaña Mis Citas con colores según estado
              Expanded(
                child: ListView.builder(
                  itemCount: datos.citas.length,
                  itemBuilder: (_, i) => _tarjetaCita(datos.citas[i]),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _tarjetaCita(Cita c) {
    Color colorBorde;
    Color fondoBadge;
    Color textoBadge;

    if (c.estado == 'Confirmada') {
      colorBorde = const Color(0xFF1B8A4B);
      fondoBadge = const Color(0xFFD9F7E6);
      textoBadge = const Color(0xFF1B8A4B);
    } else if (c.estado == 'Rechazada') {
      colorBorde = const Color(0xFFD92323);
      fondoBadge = const Color(0xFFFDE8E8);
      textoBadge = const Color(0xFFD92323);
    } else {
      // Solicitada
      colorBorde = const Color(0xFFE5A100);
      fondoBadge = const Color(0xFFFEF3C7);
      textoBadge = const Color(0xFFB45309);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: colorBorde, width: 5)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      c.servicio,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1F36)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: fondoBadge, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      c.estado,
                      style: TextStyle(color: textoBadge, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${c.vehiculo} · ${c.placas}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[700]),
                  const SizedBox(width: 6),
                  Text(
                    '${c.fecha} · ${c.hora}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Contenido dinámico según estado
              if (c.estado == 'Confirmada')
                Text('Lleva tu vehículo al taller a esa hora.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),

              if (c.estado == 'Solicitada') ...[
                Text('Esperando respuesta del taller.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF102566),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    datos.eliminarCita(c.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitud cancelada')),
                    );
                  },
                  child: const Text('Cancelar solicitud', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],

              if (c.estado == 'Rechazada') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                      children: [
                        const TextSpan(text: 'Motivo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: c.motivoRechazo ?? 'No hay disponibilidad en ese horario.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD92323),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AgendarCitaScreen(servicioInicial: datos.catalogo.first),
                      ),
                    );
                  },
                  child: const Text('Volver a agendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}