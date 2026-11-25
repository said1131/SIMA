import 'package:flutter/material.dart';

import '../models/notificacion_model.dart';
import '../services/api_client.dart';
import '../services/datos.dart';
import 'cotizacion_detalle_screen.dart';
import '../widgets/campana_notificaciones.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final datos = DatosSima();
  bool _soloSinLeer = false;

  @override
  void initState() {
    super.initState();
    datos.addListener(_refrescar);
    datos.cargarNotificaciones();
  }

  @override
  void dispose() {
    datos.removeListener(_refrescar);
    super.dispose();
  }

  void _refrescar() => setState(() {});

  Future<void> _marcarTodasLeidas() async {
    try {
      await datos.marcarNotificacionesLeidas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificaciones marcadas como leídas')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ApiClient.mensajeError(e))));
    }
  }

  Future<void> _abrirCotizacionDesdeNotificacion(NotificacionItem n) async {
    int? ordenId = n.refId;

    if (ordenId == null || ordenId == 0) {
      final coincidencias = datos.ordenes.where(
        (o) =>
            n.detalle.contains(o.folio) ||
            n.titulo.contains(o.folio) ||
            o.autorizacion == 'Pendiente',
      );
      if (coincidencias.isNotEmpty) {
        ordenId = coincidencias.first.id;
      }
    }

    if (ordenId == null || ordenId == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró el detalle de la cotización vinculada.',
          ),
        ),
      );
      return;
    }

    try {
      final detalle = await datos.obtenerDetalleOrden(ordenId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CotizacionDetalleScreen(ordenInicial: detalle),
        ),
      );
      await datos.cargarNotificaciones();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ApiClient.mensajeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);

    final int sinLeerCount = datos.notificaciones.where((n) => !n.leida).length;

    final List<NotificacionItem> listaMostrar = _soloSinLeer
        ? datos.notificaciones.where((n) => !n.leida).toList()
        : datos.notificaciones;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: azulSima, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: azulSima,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          CampanaNotificaciones(cantidadForzada: sinLeerCount),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(radius: 16, backgroundColor: Color(0xFFC5CEE0)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                _chipFiltro(
                  etiqueta: 'Todas',
                  activo: !_soloSinLeer,
                  onTap: () => setState(() => _soloSinLeer = false),
                ),
                const SizedBox(width: 8),
                _chipFiltro(
                  etiqueta: sinLeerCount > 0
                      ? 'Sin leer ($sinLeerCount)'
                      : 'Sin leer',
                  activo: _soloSinLeer,
                  onTap: () => setState(() => _soloSinLeer = true),
                ),
                const Spacer(),
                if (sinLeerCount > 0)
                  GestureDetector(
                    onTap: _marcarTodasLeidas,
                    child: const Text(
                      'Marcar leídas',
                      style: TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: datos.cargarNotificaciones,
              child: listaMostrar.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const SizedBox(height: 40),
                        _bannerSinNotificaciones(),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      itemCount: listaMostrar.length,
                      itemBuilder: (_, i) =>
                          _tarjetaNotificacion(listaMostrar[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipFiltro({
    required String etiqueta,
    required bool activo,
    required VoidCallback onTap,
  }) {
    const azulSima = Color(0xFF102566);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? azulSima : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? azulSima : const Color(0xFFD0D7E6),
          ),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: activo ? Colors.white : azulSima,
          ),
        ),
      ),
    );
  }

  Widget _bannerSinNotificaciones() {
    const azulSima = Color(0xFF102566);
    final texto = _soloSinLeer
        ? 'No tienes notificaciones pendientes por leer.'
        : 'Cuando el administrador del taller actualice tus citas, cotizaciones o el avance de tu vehículo desde el panel web, los avisos aparecerán aquí.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 30,
              color: azulSima,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sin notificaciones por ahora',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: azulSima,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7A99),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaNotificacion(NotificacionItem n) {
    const azulSima = Color(0xFF102566);

    final tipoLower = n.tipo.toLowerCase();
    final tonoLower = n.tono.toLowerCase();
    final tituloLower = n.titulo.toLowerCase();

    final bool esCotizacion =
        tipoLower.contains('cotiz') ||
        tonoLower.contains('amber') ||
        tonoLower.contains('yellow') ||
        tituloLower.contains('cotizaci');

    final bool esRechazada =
        tonoLower.contains('red') ||
        tonoLower.contains('rose') ||
        tituloLower.contains('rechaz');

    final bool esAceptada =
        tonoLower.contains('green') ||
        tonoLower.contains('emerald') ||
        tituloLower.contains('aceptad') ||
        tituloLower.contains('confirmad');

    final bool esCita = tipoLower.contains('cita') || esRechazada || esAceptada;

    late final Color colorCirculo;
    late final IconData iconoCirculo;

    if (esCotizacion) {
      colorCirculo = const Color(0xFFF59E0B);
      iconoCirculo = Icons.description_outlined;
    } else if (esRechazada) {
      colorCirculo = const Color(0xFFDC2626);
      iconoCirculo = Icons.event_busy_outlined;
    } else if (esAceptada) {
      colorCirculo = const Color(0xFF15803D);
      iconoCirculo = Icons.event_available_outlined;
    } else if (esCita) {
      colorCirculo = const Color(0xFF1D4ED8);
      iconoCirculo = Icons.calendar_today_outlined;
    } else {
      colorCirculo = const Color(0xFF1D4ED8);
      iconoCirculo = tituloLower.contains('diagn')
          ? Icons.assignment_outlined
          : Icons.build_outlined;
    }

return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: colorCirculo,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorCirculo,
                shape: BoxShape.circle,
              ),
              child: Icon(iconoCirculo, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: azulSima,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (n.fecha.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          n.fecha,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7A99),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (n.detalle.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      n.detalle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7A99),
                      ),
                    ),
                  ],
                  if (esCotizacion) ...[
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulSima,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _abrirCotizacionDesdeNotificacion(n),
                      child: const Text(
                        'Ver cotización',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}