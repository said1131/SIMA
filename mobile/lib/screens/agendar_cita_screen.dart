import 'package:flutter/material.dart';
import '../models/servicio_model.dart';
import '../models/cita_model.dart';
import '../services/datos.dart';

class AgendarCitaScreen extends StatefulWidget {
  final Servicio servicioInicial;
  const AgendarCitaScreen({super.key, required this.servicioInicial});

  @override
  State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
}

class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
  final datos = DatosSima();
  late int _vehiculoIndex;
  int _diaElegido = 12;
  String _horaElegida = '11:00';
  final _notasCtrl = TextEditingController(text: 'Ruido metálico al frenar.');

  final List<int> _diasDisponibles = [10, 11, 12, 13, 14, 16, 18, 19, 20, 21, 23, 24, 25, 26, 27, 28, 30];
  final List<String> _horarios = ['09:00', '10:00', '11:00', '14:00', '16:00'];

  @override
  void initState() {
    super.initState();
    _vehiculoIndex = datos.vehiculoActivoIndex;
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);
    final s = widget.servicioInicial;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Agendar cita', style: TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner del servicio
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFE8ECF7), borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                        child: Text(s.categoria.toUpperCase(),
                            style: const TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                      const SizedBox(height: 4),
                      Text(s.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('desde \$${s.precio.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: azulSima)),
                      Text('Duración ${s.duracion}', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Vehículo
            const Text('Vehículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
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

            // Calendario de cupos
            const Text('Fecha (solo días con cupo)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  const Text('Noviembre 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
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
                      final disp = _diasDisponibles.contains(dia);
                      final sel = dia == _diaElegido;
                      return GestureDetector(
                        onTap: disp ? () => setState(() => _diaElegido = dia) : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: sel ? azulSima : (disp ? Colors.white : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: disp ? Colors.grey.shade300 : Colors.transparent),
                          ),
                          child: Center(
                            child: Text(
                              '$dia',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: sel ? Colors.white : (disp ? Colors.black87 : Colors.grey[400]),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hora disponible
            const Text('Hora disponible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _horarios.map((h) {
                final sinCupo = h == '14:00';
                final elegida = h == _horaElegida;
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
                  selectedColor: azulSima,
                  onSelected: sinCupo ? null : (_) => setState(() => _horaElegida = h),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Notas
            const Text('Notas o síntomas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _notasCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: rojoSima,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final veh = datos.vehiculos[_vehiculoIndex];
                  datos.agregarCita(
                    Cita(
                      id: DateTime.now().toString(),
                      servicio: s.titulo,
                      vehiculo: veh.nombreCompleto,
                      placas: veh.placas,
                      fecha: '$_diaElegido nov',
                      hora: _horaElegida,
                      notas: _notasCtrl.text,
                      estado: 'Solicitada',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Cita agendada exitosamente!')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Confirmar cita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}