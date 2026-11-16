import 'package:flutter/material.dart';
import '../models/orden_model.dart';
import '../services/api_client.dart';
import '../services/datos.dart';
import 'cotizacion_detalle_screen.dart';
import '../widgets/campana_notificaciones.dart';

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  final datos = DatosSima();
  String _filtroActual = 'Todas';

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

  String _formatearMoneda(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final entero = partes[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '\$$entero.${partes[1]}';
  }

  Future<void> _abrirDetalle(int ordenId) async {
    try {
      final detalle = await datos.obtenerDetalleOrden(ordenId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CotizacionDetalleScreen(ordenInicial: detalle),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.mensajeError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);

    final todasCotizaciones = datos.ordenes
        .where((o) =>
            o.cotizacionEnviada ||
            o.estado == 'Cotizada' ||
            o.autorizacion == 'Autorizada' ||
            o.autorizacion == 'Rechazada' ||
            o.total > 0)
        .toList();

    final int pendientesCount = todasCotizaciones
        .where((o) => o.autorizacion == 'Pendiente')
        .length;

    final List<OrdenTrabajo> listaFiltrada = todasCotizaciones.where((o) {
      if (_filtroActual == 'Pendientes') return o.autorizacion == 'Pendiente';
      if (_filtroActual == 'Autorizadas') return o.autorizacion == 'Autorizada';
      if (_filtroActual == 'Rechazadas') return o.autorizacion == 'Rechazada';
      return true;
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
                'Cotizaciones',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipFiltro('Todas', 'Todas'),
                  const SizedBox(width: 8),
                  _chipFiltro(
                    'Pendientes',
                    pendientesCount > 0
                        ? 'Pendientes ($pendientesCount)'
                        : 'Pendientes',
                  ),
                  const SizedBox(width: 8),
                  _chipFiltro('Autorizadas', 'Autorizadas'),
                  const SizedBox(width: 8),
                  _chipFiltro('Rechazadas', 'Rechazadas'),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: datos.cargarOrdenes,
              child: listaFiltrada.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const SizedBox(height: 40),
                        _bannerSinCotizaciones(),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: listaFiltrada.length,
                      itemBuilder: (_, i) =>
                          _tarjetaCotizacion(listaFiltrada[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipFiltro(String clave, String etiqueta) {
    const azulSima = Color(0xFF102566);
    final seleccionado = _filtroActual == clave;

    return GestureDetector(
      onTap: () => setState(() => _filtroActual = clave),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? azulSima : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? azulSima : const Color(0xFFD0D7E6),
          ),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: seleccionado ? Colors.white : azulSima,
          ),
        ),
      ),
    );
  }

  Widget _bannerSinCotizaciones() {
    const azulSima = Color(0xFF102566);
    final String mensaje = _filtroActual == 'Todas'
        ? 'Cuando el taller diagnostique tu vehículo y envíe una cotización desde el sistema web, aparecerá aquí para que puedas revisarla y autorizarla.'
        : 'No tienes cotizaciones en la categoría "$_filtroActual" en este momento.';

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
              Icons.request_quote_outlined,
              size: 30,
              color: azulSima,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Esperando cotización del taller',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: azulSima,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
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

  Widget _tarjetaCotizacion(OrdenTrabajo o) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);

    final esPendiente = o.autorizacion == 'Pendiente';
    final esRechazada = o.autorizacion == 'Rechazada';

    final Color colorTextoBadge = esPendiente
        ? const Color(0xFFB45309)
        : (esRechazada ? rojoSima : const Color(0xFF1B8A4B));

    final Color colorFondoBadge = esPendiente
        ? const Color(0xFFFEF3C7)
        : (esRechazada
            ? const Color(0xFFFDE8E8)
            : const Color(0xFFDDF5E6));

    final String folioFormateado =
        o.folio.startsWith('#') ? o.folio : '#${o.folio}';

    final String subtituloServicio =
        (!esPendiente && o.fechaIngreso.trim().isNotEmpty)
            ? '${o.servicio} · ${o.fechaIngreso}'
            : o.servicio;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  folioFormateado,
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorFondoBadge,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  o.autorizacion,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: colorTextoBadge,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            o.vehiculo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: azulSima,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtituloServicio,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7A99),
            ),
          ),
          if (o.diagnostico != null && o.diagnostico!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Diagnóstico: ${o.diagnostico}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${_formatearMoneda(o.total)} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: azulSima,
                      ),
                    ),
                    const TextSpan(
                      text: 'MXN',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color(0xFF6B7A99),
                      ),
                    ),
                  ],
                ),
              ),
              if (esPendiente)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulSima,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _abrirDetalle(o.id),
                  child: const Text(
                    'Revisar y autorizar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: azulSima,
                    side: const BorderSide(color: Color(0xFFD0D7E6)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _abrirDetalle(o.id),
                  child: const Text(
                    'Ver detalle',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}