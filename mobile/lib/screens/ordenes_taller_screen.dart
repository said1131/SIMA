import 'package:flutter/material.dart';
import '../models/orden_model.dart';
import '../services/api_client.dart';
import '../services/datos.dart';
import 'cotizacion_detalle_screen.dart';
import 'servicios_citas_screen.dart';
import '../widgets/campana_notificaciones.dart';

class OrdenesTallerScreen extends StatefulWidget {
  final VoidCallback? irAServicios;
  final VoidCallback? irACotizaciones;

  const OrdenesTallerScreen({
    super.key,
    this.irAServicios,
    this.irACotizaciones,
  });

  @override
  State<OrdenesTallerScreen> createState() => _OrdenesTallerScreenState();
}

class _OrdenesTallerScreenState extends State<OrdenesTallerScreen> {
  final datos = DatosSima();
  int _ordenSeleccionadaIndex = 0;

  static const List<String> _etapas = [
    'Recibida',
    'En diagnóstico',
    'Cotizada',
    'Autorizada',
    'En reparación',
    'Lista',
    'Entregada',
  ];

  static const Map<String, String> _descripcionesEtapas = {
    'Recibida':
        'Tu vehículo fue recibido en el taller y se registró su inventario de ingreso.',
    'En diagnóstico':
        'El técnico especialista está revisando tu vehículo para detectar las fallas y necesidades.',
    'Cotizada':
        'El taller te envió la cotización detallada. Revísala y autorízala o recházala para continuar.',
    'Autorizada':
        'Autorizaste la cotización. El taller ya puede iniciar la reparación.',
    'En reparación':
        'Los técnicos están trabajando en tu vehículo con las refacciones y mano de obra autorizadas.',
    'Lista':
        'El servicio y control de calidad concluyeron. Tu vehículo está listo para pasar a recogerlo.',
    'Entregada':
        'El vehículo fue entregado satisfactoriamente. Puedes consultar el resumen en tu Historial.',
  };

  @override
  void initState() {
    super.initState();
    datos.addListener(_refrescar);
    datos.cargarOrdenes();
  }

  @override
  void dispose() {
    datos.removeListener(_refrescar);
    super.dispose();
  }

  void _refrescar() => setState(() {});

  int _indiceEtapa(String estado) {
    final limpio = estado.trim().toLowerCase();
    for (int i = 0; i < _etapas.length; i++) {
      if (_etapas[i].toLowerCase() == limpio) return i;
    }
    if (limpio.contains('diagn')) return 1;
    if (limpio.contains('cotiz')) return 2;
    if (limpio.contains('autoriz')) return 3;
    if (limpio.contains('reparac')) return 4;
    if (limpio.contains('list')) return 5;
    if (limpio.contains('entreg')) return 6;
    return 0;
  }

  void _mostrarInfoEtapa(String etapa) {
    const azulSima = Color(0xFF102566);
    final descripcion = _descripcionesEtapas[etapa] ??
        'Etapa del proceso de servicio en el taller SIMA.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D7E6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1D4ED8),
                      width: 1.8,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    etapa,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: azulSima,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              descripcion,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5568),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulSima,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirCotizacionVinculada(OrdenTrabajo orden) async {
    try {
      final detalle = await datos.obtenerDetalleOrden(orden.id);
      if (!mounted) return;
      final decision = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => CotizacionDetalleScreen(ordenInicial: detalle),
        ),
      );
      if (decision == 'Autorizada' && mounted) {
        _mostrarInfoEtapa('Autorizada');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.mensajeError(e))),
      );
    }
  }

  void _irAAgendarCita() {
    if (widget.irAServicios != null) {
      widget.irAServicios!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ServiciosCitasScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);

    final activas =
        datos.ordenes.where((o) => o.estado != 'Entregada').toList();
    if (_ordenSeleccionadaIndex >= activas.length) {
      _ordenSeleccionadaIndex = 0;
    }

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
                'En Taller',
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
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: datos.cargarOrdenes,
        child: activas.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 40),
                  _bannerEsperandoCita(),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (activas.length > 1) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(activas.length, (i) {
                          final ord = activas[i];
                          final sel = i == _ordenSeleccionadaIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('${ord.folio} · ${ord.vehiculo}'),
                              selected: sel,
                              selectedColor: azulSima,
                              labelStyle: TextStyle(
                                color: sel ? Colors.white : azulSima,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              onSelected: (_) => setState(
                                () => _ordenSeleccionadaIndex = i,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _vistaDetalleOrden(activas[_ordenSeleccionadaIndex]),
                ],
              ),
      ),
    );
  }

  Widget _bannerEsperandoCita() {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              size: 34,
              color: azulSima,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Esperando tu cita',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: azulSima,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aún no tienes ningún vehículo en el taller. Agenda una cita para dar seguimiento en tiempo real a cada etapa de tu servicio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7A99),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: rojoSima,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _irAAgendarCita,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: const Text(
                'Agenda una cita',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vistaDetalleOrden(OrdenTrabajo o) {
    const azulSima = Color(0xFF102566);
    final pasoActual = _indiceEtapa(o.estado);
    final esCotizada = pasoActual == 2;
    final folioFormateado =
        o.folio.startsWith('#') ? o.folio : '#${o.folio}';
    final textoKm =
        o.kilometraje != null ? '${o.kilometraje} km' : o.servicio;

    String duracionAprox = '2.0 h';
    final servCoincidente = datos.catalogo.where(
      (s) => s.titulo.toLowerCase() == o.servicio.toLowerCase(),
    );
    if (servCoincidente.isNotEmpty) {
      duracionAprox = servCoincidente.first.duracion;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: azulSima,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      folioFormateado,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    esCotizada ? 'COTIZADA' : 'EN BAHÍA',
                    style: TextStyle(
                      color: esCotizada
                          ? const Color(0xFFB45309)
                          : const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.vehiculo,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: azulSima,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PLACA: ${o.placas} • $textoKm',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7A99),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car_outlined,
                      color: azulSima,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FLUJO DE TALLER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Etapas del servicio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: azulSima,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Duración aprox.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7A99),
                        ),
                      ),
                      Text(
                        duracionAprox,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(_etapas.length, (index) {
                final nombreEtapa = _etapas[index];
                final completada = index < pasoActual;
                final esActual = index == pasoActual;
                return _itemEtapa(
                  nombre: nombreEtapa,
                  completada: completada,
                  esActual: esActual,
                  orden: o,
                );
              }),
            ],
          ),
        ),
        if ((o.diagnostico != null && o.diagnostico!.trim().isNotEmpty) ||
            (o.notas != null && o.notas!.trim().isNotEmpty)) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 18,
                      color: azulSima,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Reporte técnico del taller',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: azulSima,
                      ),
                    ),
                  ],
                ),
                if (o.diagnostico != null &&
                    o.diagnostico!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Diagnóstico: ${o.diagnostico}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ],
                if (o.notas != null && o.notas!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Notas: ${o.notas}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7A99),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (o.cotizacionEnviada ||
            o.estado == 'Cotizada' ||
            o.total > 0) ...[
          const SizedBox(height: 14),
          _tarjetaCotizacionVinculada(o),
        ],
      ],
    );
  }

  Widget _itemEtapa({
    required String nombre,
    required bool completada,
    required bool esActual,
    required OrdenTrabajo orden,
  }) {
    const azulSima = Color(0xFF102566);
    const verdeSima = Color(0xFF0D7A5F);

    if (esActual) {
      final esCotizada = nombre == 'Cotizada';
      final textoDetalle = esCotizada
          ? 'El taller te envió la cotización. Revísala y autorízala o recházala.'
          : (orden.diagnostico != null && orden.diagnostico!.trim().isNotEmpty
              ? orden.diagnostico!
              : (_descripcionesEtapas[nombre] ?? ''));

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2848A8), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D3B8B),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    esCotizada ? Icons.access_time : Icons.sync,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: azulSima,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _botonAyudaEtapa(nombre),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: esCotizada
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    esCotizada ? 'Ahora' : 'En Ejecución',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: esCotizada
                          ? const Color(0xFFB45309)
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
            if (textoDetalle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                textoDetalle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A5568),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const LinearProgressIndicator(
                value: 0.55,
                minHeight: 7,
                backgroundColor: Color(0xFFDCE4F5),
                color: Color(0xFF1D3B8B),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: completada ? verdeSima : const Color(0xFFDCE4F5),
              shape: BoxShape.circle,
            ),
            child: completada
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: completada
                          ? azulSima
                          : const Color(0xFF7B8AA8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _botonAyudaEtapa(nombre),
              ],
            ),
          ),
          Text(
            completada ? 'Listo' : 'Pendiente',
            style: TextStyle(
              fontSize: 12,
              fontWeight: completada ? FontWeight.bold : FontWeight.normal,
              color: completada ? verdeSima : const Color(0xFF7B8AA8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonAyudaEtapa(String etapa) {
    return GestureDetector(
      onTap: () => _mostrarInfoEtapa(etapa),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF94A3B8)),
        ),
        child: const Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjetaCotizacionVinculada(OrdenTrabajo o) {
    const azulSima = Color(0xFF102566);
    final esAutorizada = o.autorizacion == 'Autorizada';
    final esRechazada = o.autorizacion == 'Rechazada';

    final String tituloCotizacion = esAutorizada
        ? 'Presupuesto aprobado'
        : (esRechazada ? 'Cotización rechazada' : 'Cotización pendiente');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tituloCotizacion,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: azulSima,
                ),
              ),
              if (esAutorizada)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF5E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Autorizada',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B8A4B),
                    ),
                  ),
                )
              else
                Text(
                  '\$${o.total.toStringAsFixed(2)} MXN',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: azulSima,
                  ),
                ),
            ],
          ),
          if (esAutorizada) ...[
            const SizedBox(height: 4),
            Text(
              '\$${o.total.toStringAsFixed(2)} MXN',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: azulSima,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: azulSima,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _abrirCotizacionVinculada(o),
              icon: const Icon(Icons.request_quote_outlined, size: 18),
              label: const Text(
                'Ver cotización vinculada',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
