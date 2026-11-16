import 'package:flutter/material.dart';
import '../models/orden_model.dart';
import '../services/api_client.dart';
import '../services/datos.dart';
import 'notificaciones_screen.dart';

class CotizacionDetalleScreen extends StatefulWidget {
  final OrdenTrabajo ordenInicial;

  const CotizacionDetalleScreen({
    super.key,
    required this.ordenInicial,
  });

  @override
  State<CotizacionDetalleScreen> createState() =>
      _CotizacionDetalleScreenState();
}

class _CotizacionDetalleScreenState extends State<CotizacionDetalleScreen> {
  final datos = DatosSima();
  late OrdenTrabajo _orden;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _orden = widget.ordenInicial;
    datos.addListener(_refrescar);
  }

  @override
  void dispose() {
    datos.removeListener(_refrescar);
    super.dispose();
  }

  void _refrescar() {
    final actualizada = datos.ordenes.where((o) => o.id == _orden.id);
    if (actualizada.isNotEmpty && mounted) {
      setState(() => _orden = actualizada.first);
    } else if (mounted) {
      setState(() {});
    }
  }

  String _moneda(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final entero = partes[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '\$$entero.${partes[1]}';
  }

  String _formatoCantidad(double cant) {
    if (cant % 1 == 0) return cant.toInt().toString();
    return cant.toStringAsFixed(1);
  }

  Future<void> _responder(String decision) async {
    setState(() => _procesando = true);
    try {
      await datos.responderCotizacion(_orden.id, decision);
      final detalleActualizado = await datos.obtenerDetalleOrden(_orden.id);
      if (!mounted) return;
      setState(() => _orden = detalleActualizado);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cotización $decision correctamente')),
      );
      Navigator.pop(context, decision);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.mensajeError(e))),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);

    final esPendiente = _orden.autorizacion == 'Pendiente';
    final esRechazada = _orden.autorizacion == 'Rechazada';

    final String textoEstado = esPendiente
        ? 'Pendiente de autorización'
        : (_orden.autorizacion == 'Autorizada'
            ? 'Autorizada'
            : _orden.autorizacion);

    final Color colorTextoEstado = esPendiente
        ? const Color(0xFFB45309)
        : (esRechazada ? rojoSima : const Color(0xFF1B8A4B));

    final Color colorFondoEstado = esPendiente
        ? const Color(0xFFFEF3C7)
        : (esRechazada
            ? const Color(0xFFFDE8E8)
            : const Color(0xFFDDF5E6));

    // Clasificar partidas reales enviadas por el taller según su tipo
    final refacciones = _orden.conceptos.where((c) {
      final t = c.tipo.toLowerCase();
      return t.contains('refac') ||
          t.contains('repuest') ||
          t.contains('pieza') ||
          t.contains('insumo');
    }).toList();

    final manoObra =
        _orden.conceptos.where((c) => !refacciones.contains(c)).toList();

    final double totalRefacciones =
        refacciones.fold(0, (sum, item) => sum + item.subtotal);
    final double totalManoObra =
        manoObra.fold(0, (sum, item) => sum + item.subtotal);

    final double subtotalMostrar = _orden.subtotal > 0
        ? _orden.subtotal
        : (_orden.total > 0 ? _orden.total / 1.16 : 0);
    final double ivaMostrar =
        _orden.iva > 0 ? _orden.iva : (_orden.total - subtotalMostrar);

    final folioLimpio =
        _orden.folio.startsWith('#') ? _orden.folio : '#${_orden.folio}';

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
          'Cotización',
          style: TextStyle(
            color: azulSima,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    color: azulSima,
                    size: 20,
                  ),
                ),
                if (datos.notificacionesNoLeidas > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: rojoSima,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${datos.notificacionesNoLeidas}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFC5CEE0),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tarjeta de Orden y Vehículo
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
                      Text(
                        'ORDEN $folioLimpio',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7A99),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorFondoEstado,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          textoEstado,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorTextoEstado,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _orden.vehiculo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: azulSima,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'PLACA: ${_orden.placas} · ${_orden.servicio}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7A99),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_car_outlined,
                          color: Color(0xFF1D4ED8),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Tarjeta azul de Total a Autorizar + Subtotal + IVA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD5E2FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL A AUTORIZAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'IVA incluido (16%)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${_moneda(_orden.total)} ',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        const TextSpan(
                          text: 'MXN',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal neto',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${_moneda(subtotalMostrar)} MXN',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: azulSima,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'IVA trasladado (16%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${_moneda(ivaMostrar)} MXN',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: azulSima,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Encabezado Desglose de conceptos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Desglose de conceptos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: azulSima,
                  ),
                ),
                Text(
                  '${_orden.conceptos.length} ${_orden.conceptos.length == 1 ? "partida" : "partidas"}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7A99),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_orden.conceptos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'El taller aún no ha cargado partidas individuales en esta cotización.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7A99)),
                ),
              ),

            // Bloque A: Refacciones y repuestos
            if (refacciones.isNotEmpty) ...[
              _bloquePartidas(
                titulo: 'Refacciones y repuestos',
                totalGrupo: totalRefacciones,
                items: refacciones,
                esRefaccion: true,
              ),
              const SizedBox(height: 12),
            ],

            // Bloque B: Mano de obra y servicios
            if (manoObra.isNotEmpty) ...[
              _bloquePartidas(
                titulo: 'Mano de obra y servicios',
                totalGrupo: totalManoObra,
                items: manoObra,
                esRefaccion: false,
              ),
              const SizedBox(height: 12),
            ],

            // 4. Tarjeta Diagnóstico del especialista
            if (_orden.diagnostico != null &&
                _orden.diagnostico!.trim().isNotEmpty)
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Diagnóstico del especialista',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: azulSima,
                          ),
                        ),
                        if (_orden.fechaIngreso.trim().isNotEmpty)
                          Text(
                            _orden.fechaIngreso,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7A99),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _orden.diagnostico!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A5568),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // 5. Barra inferior fija para Rechazar o Autorizar cotización
      bottomNavigationBar: esPendiente
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total a autorizar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7A99),
                          ),
                        ),
                        Text(
                          '${_moneda(_orden.total)} MXN',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: azulSima,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: rojoSima,
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _procesando
                                  ? null
                                  : () => _responder('Rechazada'),
                              child: const Text(
                                'Rechazar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: azulSima,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _procesando
                                  ? null
                                  : () => _responder('Autorizada'),
                              child: _procesando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Autorizar cotización',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _bloquePartidas({
    required String titulo,
    required double totalGrupo,
    required List<ConceptoOrden> items,
    required bool esRefaccion,
  }) {
    const azulSima = Color(0xFF102566);

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
                titulo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: azulSima,
                ),
              ),
              Text(
                _moneda(totalGrupo),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: azulSima,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(items.length, (i) {
            final c = items[i];
            final cantTexto = _formatoCantidad(c.cantidad);
            final unidad = esRefaccion
                ? (c.cantidad == 1 ? 'pieza' : 'piezas')
                : (c.tipo.toLowerCase().contains('hora') ? 'h' : 'servicio');

            return Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.concepto,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: azulSima,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$cantTexto $unidad × ${_moneda(c.precio)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7A99),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _moneda(c.subtotal),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: azulSima,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
