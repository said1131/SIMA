import 'package:flutter/material.dart';
import '../models/servicio_model.dart';
import '../services/api_client.dart';
import '../services/datos.dart';
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
  int _diaElegido = 18;
  String _horaElegida = '10:00';
  bool _enviando = false;

  final List<int> _diasDisponibles = [16, 17, 18, 19, 20, 21, 23, 24, 25, 26, 27, 28, 30];
  final List<String> _horarios = ['09:00', '10:00', '11:00', '14:00', '16:00'];

  @override
  void initState() {
    super.initState();
    _servicioElegido = widget.servicioInicial;
    _vehiculoIndex = datos.vehiculoActivoIndex;
  }

  Future<void> _confirmar() async {
    if (datos.vehiculos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero registra un vehículo.')));
      return;
    }
    setState(() => _enviando = true);
    try {
      final veh = datos.vehiculos[_vehiculoIndex];
      final d = _diaElegido.toString().padLeft(2, '0');
      await datos.crearCita(
        vehiculoId: veh.idNumerico,
        servicioId: _servicioElegido.idNumerico,
        fechaIso: '2026-11-$d',
        hora: _horaElegida,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Cita agendada!')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.mensajeError(e))));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);

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
            const Text('Fecha (Noviembre 2026)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: GridView.builder(
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
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: rojoSima, foregroundColor: Colors.white),
                onPressed: _enviando ? null : _confirmar,
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
