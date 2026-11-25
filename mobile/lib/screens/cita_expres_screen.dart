import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/datos.dart';

class CitaExpresScreen extends StatefulWidget {
  const CitaExpresScreen({super.key});

  @override
  State<CitaExpresScreen> createState() => _CitaExpresScreenState();
}

class _CitaExpresScreenState extends State<CitaExpresScreen> {
  final _datos = DatosSima();
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _anioCtrl = TextEditingController(text: '2021');
  final _placasCtrl = TextEditingController();

  int? _servicioId;
  late final List<DateTime> _fechasHabiles;
  late DateTime _fechaElegida;
  String? _horaElegida;

  List<String> _horasOcupadas = [];
  bool _cargandoHoras = false;
  bool _enviada = false;
  bool _enviando = false;

  final List<String> _horarios = ['09:00', '10:00', '11:00', '14:00', '16:00'];

  @override
  void initState() {
    super.initState();
    _fechasHabiles = _generarProximosDiasHabiles(21);
    _fechaElegida = _fechasHabiles.first;
    _cargar();
    _cargarDisponibilidad();
  }

  List<DateTime> _generarProximosDiasHabiles(int cantidad) {
    final hoy = DateTime.now();
    final base = DateTime(hoy.year, hoy.month, hoy.day);
    final lista = <DateTime>[];
    int offset = 0;
    while (lista.length < cantidad) {
      final candidato = base.add(Duration(days: offset));
      if (candidato.weekday != DateTime.sunday) {
        lista.add(candidato);
      }
      offset++;
    }
    return lista;
  }

  String _toIso(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _etiquetaDia(DateTime d) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dias[d.weekday - 1]} ${d.day} ${meses[d.month - 1]}';
  }

  Future<void> _cargar() async {
    if (_datos.catalogo.isEmpty) await _datos.cargarCatalogoPublico();
    if (mounted && _datos.catalogo.isNotEmpty) {
      setState(() => _servicioId = _datos.catalogo.first.idNumerico);
    }
  }

  Future<void> _cargarDisponibilidad() async {
    setState(() => _cargandoHoras = true);
    final ocupadas = await _datos.obtenerHorasOcupadas(_toIso(_fechaElegida));
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

  Future<void> _enviar() async {
    if (_nombreCtrl.text.trim().isEmpty ||
        _apellidosCtrl.text.trim().isEmpty ||
        _telCtrl.text.trim().isEmpty ||
        _marcaCtrl.text.trim().isEmpty ||
        _modeloCtrl.text.trim().isEmpty ||
        _placasCtrl.text.trim().isEmpty ||
        _servicioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos (*).')),
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
      await _datos.crearCitaExpres(
        nombre: _nombreCtrl.text,
        apellidos: _apellidosCtrl.text,
        telefono: _telCtrl.text,
        marca: _marcaCtrl.text,
        modelo: _modeloCtrl.text,
        anio: int.tryParse(_anioCtrl.text.trim()) ?? 2021,
        placas: _placasCtrl.text,
        servicioId: _servicioId!,
        fechaIso: _toIso(_fechaElegida),
        hora: _horaElegida!,
      );
      if (mounted) setState(() => _enviada = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.mensajeError(e))),
        );
        _cargarDisponibilidad();
      }
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
        title: const Text('Cita exprés', style: TextStyle(color: azulSima, fontWeight: FontWeight.bold)),
      ),
      body: _enviada
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(radius: 36, backgroundColor: Color(0xFF1B8A4B), child: Icon(Icons.check, color: Colors.white, size: 42)),
                    const SizedBox(height: 16),
                    const Text('Solicitud enviada', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('El taller te contactará al ${_telCtrl.text} para confirmar.', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Volver al inicio')),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: _input('Nombre *', 'Oswaldo', _nombreCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _input('Apellidos *', 'Cruz', _apellidosCtrl)),
                  ]),
                  const SizedBox(height: 12),
                  _input('Teléfono *', '9985550142', _telCtrl),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _input('Marca *', 'Toyota', _marcaCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _input('Modelo *', 'Hilux', _modeloCtrl)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _input('Año *', '2021', _anioCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _input('Placas *', 'ABC-892', _placasCtrl)),
                  ]),
                  const SizedBox(height: 12),
                  const Text('Servicio *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  if (_datos.catalogo.isEmpty)
                    const LinearProgressIndicator()
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _servicioId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: _datos.catalogo.map((s) => DropdownMenuItem(value: s.idNumerico, child: Text(s.titulo))).toList(),
                      onChanged: (v) => setState(() => _servicioId = v),
                    ),
                  const SizedBox(height: 16),
                  const Text('Fecha disponible *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _fechasHabiles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final f = _fechasHabiles[i];
                        final sel = _toIso(f) == _toIso(_fechaElegida);
                        return ChoiceChip(
                          label: Text(
                            _etiquetaDia(f),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: sel ? Colors.white : azulSima,
                            ),
                          ),
                          selected: sel,
                          selectedColor: azulSima,
                          backgroundColor: Colors.white,
                          onSelected: (_) {
                            setState(() => _fechaElegida = f);
                            _cargarDisponibilidad();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hora disponible *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                      onPressed: (_enviando || _cargandoHoras || diaLleno) ? null : _enviar,
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

  Widget _input(String label, String hint, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}