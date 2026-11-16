import 'package:flutter/material.dart';
import '../models/cita_model.dart';
import '../services/api_client.dart';
import '../services/datos.dart';
import 'agendar_cita_screen.dart';
import '../widgets/campana_notificaciones.dart';

class ServiciosCitasScreen extends StatefulWidget {
  final bool iniciarEnMisCitas;

  const ServiciosCitasScreen({
    super.key,
    this.iniciarEnMisCitas = false,
  });

  @override
  State<ServiciosCitasScreen> createState() => _ServiciosCitasScreenState();
}

class _ServiciosCitasScreenState extends State<ServiciosCitasScreen> {
  final datos = DatosSima();
  late bool verCatalogo;
  String filtroCategoria = 'Todos';
  String textoBusqueda = '';

  @override
  void initState() {
    super.initState();
    verCatalogo = !widget.iniciarEnMisCitas;
    datos.addListener(_refrescar);
    if (widget.iniciarEnMisCitas) {
      datos.cargarCitas();
    }
  }

  @override
  void dispose() {
    datos.removeListener(_refrescar);
    super.dispose();
  }

  void _refrescar() => setState(() {});

  void _cambiarPestana(bool mostrarCatalogo) {
    setState(() => verCatalogo = mostrarCatalogo);
    if (mostrarCatalogo) {
      datos.cargarCatalogoPublico();
    } else {
      // Consulta al servidor lo que el sitio web del taller haya actualizado
      datos.cargarCitas();
    }
  }

  Future<void> _cancelarCita(Cita c) async {
    try {
      await datos.cancelarCita(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud de cita cancelada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.mensajeError(e))),
      );
    }
  }

  void _volverAAgendar(Cita c) {
    final coincidencias = datos.catalogo.where(
      (s) => s.titulo.toLowerCase() == c.servicio.toLowerCase(),
    );

    if (coincidencias.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AgendarCitaScreen(servicioInicial: coincidencias.first),
        ),
      );
    } else if (datos.catalogo.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AgendarCitaScreen(servicioInicial: datos.catalogo.first),
        ),
      );
    } else {
      _cambiarPestana(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);

    final serviciosFiltrados = datos.catalogo.where((s) {
      final coincideCat =
          filtroCategoria == 'Todos' || s.categoria == filtroCategoria;
      final coincideBusq =
          s.titulo.toLowerCase().contains(textoBusqueda.toLowerCase());
      return coincideCat && coincideBusq;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Text(
                'SIMA',
                style: TextStyle(
                  color: rojoSima,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Servicios & Citas',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: azulSima,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          const CampanaNotificaciones(),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFC5CEE0),
            ),
          ),
        ],
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E9F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _cambiarPestana(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color:
                              verCatalogo ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text(
                            'Catálogo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: verCatalogo
                                  ? azulSima
                                  : const Color(0xFF5A6B8C),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _cambiarPestana(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color:
                              !verCatalogo ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text(
                            'Mis citas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: !verCatalogo
                                  ? azulSima
                                  : const Color(0xFF5A6B8C),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (verCatalogo) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Todos',
                    'Preventivo',
                    'Frenos',
                    'Eléctrico',
                    'Suspensión',
                    'Motor',
                  ].map((cat) {
                    final sel = filtroCategoria == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: sel,
                        selectedColor: azulSima,
                        labelStyle: TextStyle(
                          color: sel ? Colors.white : azulSima,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) =>
                            setState(() => filtroCategoria = cat),
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.categoria.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: azulSima,
                              ),
                            ),
                            Text(
                              s.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              s.descripcion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${s.precio.toStringAsFixed(0)} MXN',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: azulSima,
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: rojoSima,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AgendarCitaScreen(servicioInicial: s),
                                    ),
                                  ),
                                  child: const Text(
                                    'Agendar →',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('No tienes citas aún.')),
                          ],
                        )
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
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);

    final esConfirmada = c.estado == 'Confirmada';
    final esRechazada = c.estado == 'Rechazada' || c.estado == 'Cancelada';
    final esSolicitada = c.estado == 'Solicitada';

    final Color colorBorde = esConfirmada
        ? const Color(0xFF1B8A4B)
        : (esRechazada ? rojoSima : const Color(0xFFF59E0B));

    final Color colorFondoBadge = esConfirmada
        ? const Color(0xFFDDF5E6)
        : (esRechazada ? const Color(0xFFFDE8E8) : const Color(0xFFFEF3C7));

    final Color colorTextoBadge = esConfirmada
        ? const Color(0xFF1B8A4B)
        : (esRechazada ? rojoSima : const Color(0xFFB45309));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: colorBorde, width: 5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  c.servicio,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: azulSima,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorFondoBadge,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  c.estado,
                  style: TextStyle(
                    color: colorTextoBadge,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${c.vehiculo} · ${c.placas}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7A99),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: azulSima,
              ),
              const SizedBox(width: 6),
              Text(
                '${c.fecha} · ${c.hora}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: azulSima,
                ),
              ),
            ],
          ),
          // 1. Mensaje cuando el sitio web del taller confirma la cita
          if (esConfirmada) ...[
            const SizedBox(height: 6),
            const Text(
              'Lleva tu vehículo al taller a esa hora.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7A99),
              ),
            ),
          ],
          // 2. Mensaje y acción cuando la cita está solicitada esperando al taller
          if (esSolicitada) ...[
            const SizedBox(height: 6),
            const Text(
              'Esperando respuesta del taller.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7A99),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: azulSima,
                side: const BorderSide(color: Color(0xFFD0D7E6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => _cancelarCita(c),
              child: const Text(
                'Cancelar solicitud',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          // 3. Banner de motivo y botón cuando el sitio web del taller rechaza la cita
          if (esRechazada) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB91C1C),
                  ),
                  children: [
                    const TextSpan(
                      text: 'Motivo: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: (c.motivoRechazo != null &&
                              c.motivoRechazo!.trim().isNotEmpty)
                          ? c.motivoRechazo!
                          : 'No hay disponibilidad en ese horario.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: rojoSima,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => _volverAAgendar(c),
              child: const Text(
                'Volver a agendar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}