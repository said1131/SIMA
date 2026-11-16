import 'package:flutter/material.dart';
import '../models/orden_model.dart';
import '../services/datos.dart';
import 'agendar_cita_screen.dart';
import 'servicios_citas_screen.dart';
import '../widgets/campana_notificaciones.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final datos = DatosSima();
  String _vehiculoFiltro = 'Todos';
  String _anioFiltro = 'Todos';

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

  String _monedaEntera(double valor) {
    final entero = valor.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '\$$entero';
  }

  String _extraerAnio(String fecha) {
    final match = RegExp(r'20\d{2}').firstMatch(fecha);
    return match?.group(0) ?? '';
  }

  int _mesesGarantia(OrdenTrabajo o) {
    final coincidencias = datos.catalogo.where(
      (s) => s.titulo.toLowerCase() == o.servicio.toLowerCase(),
    );
    return coincidencias.isNotEmpty ? coincidencias.first.garantia : 6;
  }

  void _reagendarServicio(OrdenTrabajo o) {
    final coincidencias = datos.catalogo.where(
      (s) => s.titulo.toLowerCase() == o.servicio.toLowerCase(),
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

    final entregadas = datos.ordenes
        .where((o) => o.estado.toLowerCase() == 'entregada')
        .toList();

    // Lista única de vehículos presentes en el historial
    final List<String> vehiculosDisponibles = ['Todos'];
    for (final o in entregadas) {
      if (o.vehiculo.trim().isNotEmpty &&
          !vehiculosDisponibles.contains(o.vehiculo)) {
        vehiculosDisponibles.add(o.vehiculo);
      }
    }
    if (!vehiculosDisponibles.contains(_vehiculoFiltro)) {
      _vehiculoFiltro = 'Todos';
    }

    // Lista única de años presentes en el historial
    final Set<String> aniosSet = {};
    for (final o in entregadas) {
      final anio = _extraerAnio(o.fechaIngreso);
      if (anio.isNotEmpty) aniosSet.add(anio);
    }
    final aniosOrdenados = aniosSet.toList()..sort((a, b) => b.compareTo(a));
    final List<String> aniosDisponibles = ['Todos', ...aniosOrdenados];
    if (!aniosDisponibles.contains(_anioFiltro)) {
      _anioFiltro = 'Todos';
    }

    // Aplicar filtros activos
    final List<OrdenTrabajo> filtradas = entregadas.where((o) {
      final okVehiculo =
          _vehiculoFiltro == 'Todos' || o.vehiculo == _vehiculoFiltro;
      final okAnio =
          _anioFiltro == 'Todos' || _extraerAnio(o.fechaIngreso) == _anioFiltro;
      return okVehiculo && okAnio;
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
                'HISTORIAL',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: azulSima,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.4,
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
      body: RefreshIndicator(
        onRefresh: datos.cargarOrdenes,
        child: entregadas.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 40),
                  _bannerHistorialVacio(),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _tarjetaMetricaMantenimiento(filtradas, aniosOrdenados),
                  const SizedBox(height: 16),
                  _seccionFiltros(
                    vehiculosDisponibles: vehiculosDisponibles,
                    aniosDisponibles: aniosDisponibles,
                    totalEntregadas: entregadas.length,
                  ),
                  const SizedBox(height: 14),
                  if (filtradas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay servicios con los filtros seleccionados.',
                          style: TextStyle(color: Color(0xFF6B7A99)),
                        ),
                      ),
                    )
                  else
                    ...filtradas.map(_tarjetaServicioCompletado),
                ],
              ),
      ),
    );
  }

  Widget _bannerHistorialVacio() {
    const azulSima = Color(0xFF102566);

    return Container(
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
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 32,
              color: azulSima,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no tienes servicios en tu historial',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: azulSima,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando el taller complete y entregue tus servicios desde el sistema web, aquí verás tu inversión acumulada, refacciones instaladas y garantías vigentes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7A99),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaMetricaMantenimiento(
    List<OrdenTrabajo> ordenes,
    List<String> aniosOrdenados,
  ) {
    const azulSima = Color(0xFF102566);

    final double totalInvertido =
        ordenes.fold(0, (suma, item) => suma + item.total);

    final String rangoAnios = _anioFiltro != 'Todos'
        ? _anioFiltro
        : (aniosOrdenados.length >= 2
            ? '${aniosOrdenados.last} - ${aniosOrdenados.first}'
            : (aniosOrdenados.isNotEmpty ? aniosOrdenados.first : 'Actual'));

    // Agrupar gastos por servicio para la barra de distribución
    final Map<String, double> porServicio = {};
    for (final o in ordenes) {
      final clave = o.servicio.trim().isNotEmpty ? o.servicio : 'Servicio';
      porServicio[clave] = (porServicio[clave] ?? 0) + o.total;
    }

    final entradas = porServicio.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = entradas.take(3).toList();

    final List<Color> coloresBarra = [
      const Color(0xFF102566),
      const Color(0xFF475589),
      const Color(0xFF8C9AE0),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E1FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E2FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: azulSima,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MÉTRICA DE MANTENIMIENTO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Costo Acumulado\nAnual',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: azulSima,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E2F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  rangoAnios,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: azulSima,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total invertido',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${_monedaEntera(totalInvertido)} ',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: azulSima,
                            ),
                          ),
                          const TextSpan(
                            text: 'MXN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${ordenes.length} ${ordenes.length == 1 ? "Garantía activa" : "Garantías activas"}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: azulSima,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '100% preventivo',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (top3.isNotEmpty && totalInvertido > 0) ...[
            const SizedBox(height: 14),
            const Text(
              'Distribución por Servicio',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: azulSima,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: List.generate(top3.length, (i) {
                    final peso = (top3[i].value * 100).round().clamp(1, 100);
                    return Expanded(
                      flex: peso,
                      child: Container(color: coloresBarra[i]),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(top3.length, (i) {
                final pct =
                    ((top3[i].value / totalInvertido) * 100).round();
                return Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3, right: 5),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: coloresBarra[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${top3[i].key}\n$pct%',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: azulSima,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _seccionFiltros({
    required List<String> vehiculosDisponibles,
    required List<String> aniosDisponibles,
    required int totalEntregadas,
  }) {
    const azulSima = Color(0xFF102566);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'VEHÍCULO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
              ),
            ),
            if (_vehiculoFiltro != 'Todos' || _anioFiltro != 'Todos')
              GestureDetector(
                onTap: () => setState(() {
                  _vehiculoFiltro = 'Todos';
                  _anioFiltro = 'Todos';
                }),
                child: const Text(
                  'Restablecer',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: vehiculosDisponibles.map((veh) {
              final sel = _vehiculoFiltro == veh;
              final etiqueta =
                  veh == 'Todos' ? 'Todos ($totalEntregadas)' : veh;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _vehiculoFiltro = veh),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? azulSima : const Color(0xFFE8EEF8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (veh == 'Todos') ...[
                          Icon(
                            Icons.directions_car_outlined,
                            size: 15,
                            color: sel ? Colors.white : azulSima,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          etiqueta,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sel ? Colors.white : azulSima,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (aniosDisponibles.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AÑO DE SERVICIO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: aniosDisponibles.map((anio) {
                    final sel = _anioFiltro == anio;
                    return GestureDetector(
                      onTap: () => setState(() => _anioFiltro = anio),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sel ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          anio,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sel ? azulSima : const Color(0xFF6B7A99),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _tarjetaServicioCompletado(OrdenTrabajo o) {
    const azulSima = Color(0xFF102566);
    const verdeSima = Color(0xFF1B8A4B);

    final folioFormateado =
        o.folio.startsWith('#') ? o.folio : '#${o.folio}';
    final meses = _mesesGarantia(o);

    // Lista de refacciones/componentes reales instalados en la orden
    final List<String> componentes = o.conceptos.isNotEmpty
        ? o.conceptos
            .map((c) => c.cantidad > 1
                ? '${c.cantidad.toInt()}x ${c.concepto}'
                : c.concepto)
            .toList()
        : (o.diagnostico != null && o.diagnostico!.trim().isNotEmpty
            ? [o.diagnostico!]
            : []);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: azulSima, width: 4),
        ),
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
              Expanded(
                child: Text(
                  '$folioFormateado · ${o.vehiculo} · ${o.placas}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF5E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 13,
                      color: verdeSima,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Completado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: verdeSima,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            o.servicio,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: azulSima,
              height: 1.2,
            ),
          ),
          if (o.fechaIngreso.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: azulSima,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7A99),
                        ),
                      ),
                      Text(
                        o.fechaIngreso,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: azulSima,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (componentes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'REFRACCIONES Y COMPONENTES INSTALADOS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            ...componentes.map(
              (comp) => Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comp,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: azulSima,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 16,
                color: azulSima,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Garantía $meses meses activa en servicio SIMA',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_monedaEntera(o.total)} MXN',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: azulSima,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulSima,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _reagendarServicio(o),
                    icon: const Icon(Icons.refresh, size: 17),
                    label: const Text(
                      'Re-agendar',
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
    );
  }
}