import 'dart:typed_data';
class Vehiculo {
  String id;
  String marca;
  String modelo;
  String anio;
  String placas;
  String kilometraje;
  String ultimoServicio;
  Uint8List? fotoBytes; // Foto opcional del auto

  Vehiculo({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.placas,
    required this.kilometraje,
    this.ultimoServicio = 'Sin registro',
    this.fotoBytes,
  });

  String get nombreCompleto => '$marca $modelo $anio';
}