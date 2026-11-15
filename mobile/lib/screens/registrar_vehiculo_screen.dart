import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/vehiculo_model.dart';
import '../services/api_client.dart';
import '../services/datos.dart';

class RegistrarVehiculoScreen extends StatefulWidget {
  final Vehiculo? vehiculoEditar;
  final int? indexEditar;

  const RegistrarVehiculoScreen({super.key, this.vehiculoEditar, this.indexEditar});

  @override
  State<RegistrarVehiculoScreen> createState() => _RegistrarVehiculoScreenState();
}

class _RegistrarVehiculoScreenState extends State<RegistrarVehiculoScreen> {
  String _marca = 'Toyota';
  final _modeloCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  final _placasCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  Uint8List? _fotoBytes;
  bool _guardando = false;

  final List<String> _marcas = ['Toyota', 'Chevrolet', 'Nissan', 'Volkswagen', 'Honda', 'Ford', 'Kia', 'Mazda', 'Hyundai'];

  @override
  void initState() {
    super.initState();
    if (widget.vehiculoEditar != null) {
      final v = widget.vehiculoEditar!;
      if (_marcas.contains(v.marca)) _marca = v.marca;
      _modeloCtrl.text = v.modelo;
      _anioCtrl.text = v.anio;
      _placasCtrl.text = v.placas;
      _kmCtrl.text = v.kilometraje == 'Sin registro' ? '' : v.kilometraje;
      _fotoBytes = v.fotoBytes;
    }
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final XFile? archivo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (archivo != null) {
      final bytes = await archivo.readAsBytes();
      setState(() => _fotoBytes = bytes);
    }
  }

  Future<void> _guardar() async {
    final modelo = _modeloCtrl.text.trim();
    final placas = _placasCtrl.text.trim();
    final anio = int.tryParse(_anioCtrl.text.trim()) ?? 2024;

    if (modelo.isEmpty || placas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modelo y placas son obligatorios.')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final datos = DatosSima();
      if (widget.vehiculoEditar != null) {
        await datos.editarVehiculo(
          id: widget.vehiculoEditar!.id,
          marca: _marca,
          modelo: modelo,
          anio: anio,
          placas: placas,
          kilometraje: _kmCtrl.text,
          fotoBytes: _fotoBytes,
        );
      } else {
        await datos.crearVehiculo(
          marca: _marca,
          modelo: modelo,
          anio: anio,
          placas: placas,
          kilometraje: _kmCtrl.text,
          fotoBytes: _fotoBytes,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.mensajeError(e))));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);
    final esEdicion = widget.vehiculoEditar != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(esEdicion ? 'Editar vehículo' : 'Registrar vehículo',
            style: const TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _seleccionarFoto,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF102566), Color(0xFF2848A8)]),
                  borderRadius: BorderRadius.circular(14),
                  image: _fotoBytes != null ? DecorationImage(image: MemoryImage(_fotoBytes!), fit: BoxFit.cover) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_fotoBytes != null ? Icons.camera_alt : Icons.add_a_photo_outlined, color: Colors.white, size: 38),
                    const SizedBox(height: 6),
                    Text(
                      _fotoBytes != null ? 'Cambiar foto del vehículo' : 'Subir foto del vehículo (opcional)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Marca', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _marca,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              items: _marcas.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _marca = v!),
            ),
            const SizedBox(height: 12),
            _campo('Modelo *', 'Hilux', _modeloCtrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _campo('Año *', '2021', _anioCtrl, teclado: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _campo('Placas *', 'ABC-892', _placasCtrl)),
              ],
            ),
            const SizedBox(height: 12),
            _campo('Kilometraje actual', '45,210 km', _kmCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: rojoSima,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar vehículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, String hint, TextEditingController ctrl, {TextInputType teclado = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: teclado,
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
