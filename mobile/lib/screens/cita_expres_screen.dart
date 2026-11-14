import 'package:flutter/material.dart';
import '../models/cita_model.dart';
import '../services/datos.dart';

class CitaExpresScreen extends StatefulWidget {
  const CitaExpresScreen({super.key});

  @override
  State<CitaExpresScreen> createState() => _CitaExpresScreenState();
}

class _CitaExpresScreenState extends State<CitaExpresScreen> {
  final _nombreCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _vehiculoCtrl = TextEditingController();
  final _placasCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  String _servicioSeleccionado = 'Frenos delanteros';
  int _diaSeleccionado = 12;
  String _horaSeleccionada = '11:00';
  String _fechaTexto = '';
  bool _enviada = false;

  final List<int> _diasDisponibles = [10, 11, 12, 13, 14, 16, 18, 19, 20, 21, 23, 24, 25, 26, 27, 28, 30];
  final List<String> _horarios = ['09:00', '10:00', '11:00', '14:00', '16:00'];

  void _abrirSelectorFecha() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Elige fecha y hora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Center(child: Text('Noviembre 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 30,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemBuilder: (_, index) {
                      final dia = index + 1;
                      final disponible = _diasDisponibles.contains(dia);
                      final elegido = dia == _diaSeleccionado;
                      return GestureDetector(
                        onTap: disponible ? () => setModalState(() => _diaSeleccionado = dia) : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: elegido ? const Color(0xFF102566) : (disponible ? Colors.white : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: disponible ? Colors.grey.shade300 : Colors.transparent),
                          ),
                          child: Center(
                            child: Text(
                              '$dia',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: elegido ? Colors.white : (disponible ? Colors.black87 : Colors.grey[400]),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Hora disponible · $_diaSeleccionado de noviembre',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _horarios.map((h) {
                      final sinCupo = h == '14:00';
                      final elegida = h == _horaSeleccionada;
                      return ChoiceChip(
                        label: Text(
                          h,
                          style: TextStyle(
                            decoration: sinCupo ? TextDecoration.lineThrough : null,
                            color: elegida ? Colors.white : (sinCupo ? Colors.grey : Colors.black87),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: elegida,
                        selectedColor: const Color(0xFF102566),
                        onSelected: sinCupo ? null : (_) => setModalState(() => _horaSeleccionada = h),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD92323),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        setState(() => _fechaTexto = '$_diaSeleccionado nov · $_horaSeleccionada');
                        Navigator.pop(ctx);
                      },
                      child: const Text('Elegir esta fecha', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Cita exprés',
          style: TextStyle(color: Color(0xFF102566), fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text(
                  'SIMA',
                  style: TextStyle(
                    color: Color(0xFFD92323),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: _enviada ? _vistaConfirmacion() : _vistaFormulario(),
    );
  }

  Widget _vistaFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFE8ECF7), borderRadius: BorderRadius.circular(10)),
            child: const Text(
              'Sin cuenta. El taller te contactará por teléfono o WhatsApp para confirmar tu cita.',
              style: TextStyle(fontSize: 12, color: Color(0xFF102566)),
            ),
          ),
          const SizedBox(height: 16),
          _input('Nombre completo *', 'Ej. Oswaldo Cruz', _nombreCtrl),
          const SizedBox(height: 12),
          _input('Teléfono o WhatsApp *', '998 555 0142', _telCtrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 2, child: _input('Vehículo (marca, modelo, año) *', 'Toyota Hilux 2021', _vehiculoCtrl)),
              const SizedBox(width: 10),
              Expanded(child: _input('Placas', 'ABC-892', _placasCtrl)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Servicio *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _servicioSeleccionado,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            items: ['Frenos delanteros', 'Afinación Mayor Completa', 'Escaneo OBD-II & Sensores']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _servicioSeleccionado = v!),
          ),
          const SizedBox(height: 12),
          const Text('Fecha y hora *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _abrirSelectorFecha,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fechaTexto.isEmpty ? 'Selecciona fecha y hora' : _fechaTexto,
                    style: TextStyle(color: _fechaTexto.isEmpty ? Colors.grey : Colors.black87),
                  ),
                  const Icon(Icons.calendar_today, size: 18, color: Color(0xFF102566)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _input('Descripción del problema', 'Escribe aquí...', _notasCtrl, maxLines: 3),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD92323),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                DatosSima().agregarCita(
                  Cita(
                    id: DateTime.now().toString(),
                    servicio: _servicioSeleccionado,
                    vehiculo: _vehiculoCtrl.text.isEmpty ? 'Vehículo Exprés' : _vehiculoCtrl.text,
                    placas: _placasCtrl.text.isEmpty ? 'S/P' : _placasCtrl.text,
                    fecha: '$_diaSeleccionado nov',
                    hora: _horaSeleccionada,
                    notas: _notasCtrl.text,
                  ),
                );
                setState(() => _enviada = true);
              },
              child: const Text('Confirmar cita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vistaConfirmacion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFF1B8A4B),
            child: Icon(Icons.check, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 16),
          const Text('Solicitud enviada', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Recibimos tu cita exprés. El taller te contactará al ${_telCtrl.text.isEmpty ? '998 555 0142' : _telCtrl.text} por teléfono o WhatsApp para confirmarla.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Resumen', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Solicitada',
                          style: TextStyle(color: Color(0xFF856404), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(),
                const Text('Servicio', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(_servicioSeleccionado, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Vehículo', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                    '${_vehiculoCtrl.text.isEmpty ? 'Toyota Hilux 2021' : _vehiculoCtrl.text} · ${_placasCtrl.text.isEmpty ? 'ABC-892' : _placasCtrl.text}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Fecha y hora', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(_fechaTexto.isEmpty ? 'Jue 12 nov · 11:00' : _fechaTexto, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD92323), foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text('Crear cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Volver al inicio')),
          ),
        ],
      ),
    );
  }

  Widget _input(String label, String hint, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
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