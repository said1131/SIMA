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
  int _dia = 18;
  String _hora = '11:00';
  bool _enviada = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (_datos.catalogo.isEmpty) await _datos.cargarCatalogoPublico();
    if (mounted && _datos.catalogo.isNotEmpty) {
      setState(() => _servicioId = _datos.catalogo.first.idNumerico);
    }
  }

  Future<void> _enviar() async {
    if (_nombreCtrl.text.trim().isEmpty ||
        _apellidosCtrl.text.trim().isEmpty ||
        _telCtrl.text.trim().isEmpty ||
        _marcaCtrl.text.trim().isEmpty ||
        _modeloCtrl.text.trim().isEmpty ||
        _placasCtrl.text.trim().isEmpty ||
        _servicioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos (*).')));
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
        fechaIso: '2026-11-${_dia.toString().padLeft(2, '0')}',
        hora: _hora,
      );
      if (mounted) setState(() => _enviada = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.mensajeError(e))));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Cita exprés', style: TextStyle(color: Color(0xFF102566), fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _dia,
                        decoration: InputDecoration(labelText: 'Día Nov 2026', filled: true, fillColor: Colors.white),
                        items: [16, 17, 18, 19, 20, 23, 24, 25].map((d) => DropdownMenuItem(value: d, child: Text('$d nov'))).toList(),
                        onChanged: (v) => setState(() => _dia = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _hora,
                        decoration: InputDecoration(labelText: 'Hora', filled: true, fillColor: Colors.white),
                        items: ['09:00', '10:00', '11:00', '16:00'].map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                        onChanged: (v) => setState(() => _hora = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD92323), foregroundColor: Colors.white),
                      onPressed: _enviando ? null : _enviar,
                      child: const Text('Confirmar cita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
