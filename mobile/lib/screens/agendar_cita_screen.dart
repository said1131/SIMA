import 'package:flutter/material.dart';
import '../models/servicio_model.dart';
import '../services/api_client.dart';
import '../services/datos.dart';
import '../widgets/calendario_citas.dart';
import 'registrar_vehiculo_screen.dart';

class AgendarCitaScreen extends StatefulWidget {
  final Servicio servicioInicial;
  const AgendarCitaScreen({super.key, required this.servicioInicial});

  @override
  State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
}

class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
  final datos = DatosSima();
  late Servicio _servicioElegido;
  int _vehiculoIndex = 0;

  late DateTime _mesVisible;
  late DateTime _fechaElegida;
  String? _horaElegida;

  Set<String> _diasLlenos = {};
  List<String> _horasOcupadas = [];
  bool _cargandoMes = false;
  bool _cargandoHoras = false;
  bool _enviando = false;

  final List<String> _horarios = ['09:00', '10:00', '11:00', '14:00', '16:00'];

  @override
  void initState() {
    super.initState();
    _servicioElegido = widget.servicioInicial;
    _vehiculoIndex = datos.vehiculoActivoIndex;

    final ahora = DateTime.now();
    var inicial = DateTime(ahora.year, ahora.month, ahora.day);
    if (inicial.weekday == DateTime.sunday) {
      inicial = inicial.add(const Duration(days: 1));
    }
    _fechaElegida = inicial;
    _mesVisible = DateTime(inicial.year, inicial.month, 1);

    _cargarMesYHoras();
  }

  Future<void> _cargarMesYHoras() async {
    await Future.wait([
      _cargarDiasLlenos(),
      _cargarDisponibilidad(),
    ]);
  }

  Future<void> _cargarDiasLlenos() async {
    setState(() => _cargandoMes = true);
    final llenos = await datos.obtenerDiasLlenosMes(_mesVisible.year, _mesVisible.month);
    if (!mounted) return;
    setState(() {
      _diasLlenos = llenos.toSet();
      _cargandoMes = false;
    });
  }

  Future<void> _cargarDisponibilidad() async {
    setState(() => _cargandoHoras = true);
    final ocupadas = await datos.obtenerHorasOcupadas(CalendarioCitas.toIso(_fechaElegida));
    if (!mounted) return;

    final disponibles = _horarios.where((h) => !ocupadas.contains(h)).toList();
    setState(() {
      _horasOcupadas = ocupadas;
      if (_horaElegida == null || !disponibles.contains(_horaElegida)) {
        _horaElegida = disponibles.isNotEmpty ? disponibles.first : null;
      }
      _cargandoHoras = false;
    });
  }

  Future<void> _confirmar() async {
    if (datos.vehiculos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero registra un vehículo.')),
      );
      return;
    }
    if (_horaElegida == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay horarios disponibles en esa fecha. Elige otro día.')),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      final veh = datos.vehiculos[_vehiculoIndex];
      await datos.crearCita(
        vehiculoId: veh.idNumerico,
        servicioId: _servicioElegido.idNumerico,
        fechaIso: CalendarioCitas.toIso(_fechaElegida),
        hora: _horaElegida!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cita agendada!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.mensajeError(e))),
      );
      _cargarMesYHoras();
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);

    final diaLleno = !_cargandoHoras && _horasOcupadas.length >= _horarios.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Agendar cita', style: TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(_servicioElegido.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Text('\$${_servicioElegido.precio.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: azulSima)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Vehículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            if (datos.vehiculos.isEmpty)
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrarVehiculoScreen()));
                  setState(() {});
                },
                icon: const Icon(Icons.add),
                label: const Text('Registrar vehículo primero'),
              )
            else
              DropdownButtonFormField<int>(
                initialValue: _vehiculoIndex,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                items: List.generate(datos.vehiculos.length, (i) {
                  final v = datos.vehiculos[i];
                  return DropdownMenuItem(value: i, child: Text('${v.nombreCompleto} · ${v.placas}'));
                }),
                onChanged: (v) => setState(() => _vehiculoIndex = v!),
              ),
            const SizedBox(height: 16),
            const Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            CalendarioCitas(
              mesVisible: _mesVisible,
              fechaSeleccionada: _fechaElegida,
              diasLlenosIso: _diasLlenos,
              cargando: _cargandoMes,
              onCambiarMes: (nuevoMes) {
                setState(() => _mesVisible = nuevoMes);
                _cargarDiasLlenos();
              },
              onSeleccionarFecha: (nuevaFecha) {
                setState(() => _fechaElegida = nuevaFecha);
                _cargarDisponibilidad();
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hora disponible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (_cargandoHoras)
                  const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            if (diaLleno)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Todos los horarios de este día están ocupados. Selecciona otra fecha.',
                  style: TextStyle(color: rojoSima, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _horarios.map((h) {
                  final sinCupo = _horasOcupadas.contains(h);
                  final elegida = h == _horaElegida;
                  return ChoiceChip(
                    label: Text(
                      sinCupo ? '$h (Ocupado)' : h,
                      style: TextStyle(
                        decoration: sinCupo ? TextDecoration.lineThrough : null,
                        color: elegida ? Colors.white : (sinCupo ? Colors.grey : Colors.black87),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: elegida,
                    selectedColor: azulSima,
                    onSelected: sinCupo ? null : (_) => setState(() => _horaElegida = h),
                  );
                }).toList(),
              ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: rojoSima, foregroundColor: Colors.white),
                onPressed: (_enviando || _cargandoHoras || diaLleno) ? null : _confirmar,
                child: _enviando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmar cita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}