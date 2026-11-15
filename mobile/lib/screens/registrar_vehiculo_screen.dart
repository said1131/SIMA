import 'package:flutter/material.dart';
import '../models/vehiculo_model.dart';
import '../services/datos.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

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

  final List<String> _marcas = ['Toyota', 'Chevrolet', 'Nissan', 'Volkswagen', 'Honda', 'Ford', 'Kia'];

  @override
  void initState() {
    super.initState();
    if (widget.vehiculoEditar != null) {
      final v = widget.vehiculoEditar!;
      if (_marcas.contains(v.marca)) _marca = v.marca;
      _modeloCtrl.text = v.modelo;
      _anioCtrl.text = v.anio;
      _placasCtrl.text = v.placas;
      _kmCtrl.text = v.kilometraje;
      _fotoBytes = v.fotoBytes;
    }
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final XFile? archivo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (archivo != null) {
      final bytes = await archivo.readAsBytes();
      setState(() {
        _fotoBytes = bytes;
      });
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
                  image: _fotoBytes != null
                    ? DecorationImage(image: MemoryImage(_fotoBytes!), fit: BoxFit.cover)
                    :null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _fotoBytes != null ? Colors.black.withValues(alpha: 0.25) : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _fotoBytes != null ? Icons.camera_alt : Icons.add_a_photo_outlined,
                        color: Colors.white,
                        size: 38,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _fotoBytes != null ? 'Cambiar foto del vehículo' : 'Subir foto del vehículo (opcional)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
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
            _campo('Modelo', 'Hilux', _modeloCtrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _campo('Año', '2021', _anioCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _campo('Placas', 'ABC-892', _placasCtrl)),
              ],
            ),
            const SizedBox(height: 12),
            _campo('Kilometraje actual', '45,210 km', _kmCtrl),
            const SizedBox(height: 12),
            Text('Podrás editar estos datos después desde Mi Garage.',
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
                onPressed: () {
                  final nuevo = Vehiculo(
                    id: esEdicion ? widget.vehiculoEditar!.id : DateTime.now().toString(),
                    marca: _marca,
                    modelo: _modeloCtrl.text.isEmpty ? 'Modelo' : _modeloCtrl.text,
                    anio: _anioCtrl.text.isEmpty ? '2024' : _anioCtrl.text,
                    placas: _placasCtrl.text.isEmpty ? 'SIN-000' : _placasCtrl.text,
                    kilometraje: _kmCtrl.text.isEmpty ? '0 km' : _kmCtrl.text,
                    ultimoServicio: esEdicion ? widget.vehiculoEditar!.ultimoServicio : 'Sin registro',
                    fotoBytes: _fotoBytes,
                  );
                  if (esEdicion && widget.indexEditar != null) {
                    DatosSima().actualizarVehiculo(widget.indexEditar!, nuevo);
                  } else {
                    DatosSima().agregarVehiculo(nuevo);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Guardar vehículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: azulSima, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, String hint, TextEditingController ctrl) {
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