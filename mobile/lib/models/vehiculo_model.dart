import 'dart:typed_data';

class Vehiculo {
  String id;
  String marca;
  String modelo;
  String anio;
  String placas;
  String kilometraje;
  String ultimoServicio;
  Uint8List? fotoBytes;

  Vehiculo({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.placas,
    this.kilometraje = 'Sin registro',
    this.ultimoServicio = 'Sin registro',
    this.fotoBytes,
  });

  int get idNumerico => int.tryParse(id) ?? 0;
  String get nombreCompleto => '$marca $modelo$anio';

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: (json['id'] ?? '').toString(),
      marca: (json['marca'] ?? '').toString(),
      modelo: (json['modelo'] ?? '').toString(),
      anio: (json['anio'] ?? '').toString(),
      placas: (json['placas'] ?? '').toString(),
      kilometraje: json['kilometraje'] != null ? '${json['kilometraje']} km' : 'Sin registro',
      ultimoServicio: (json['ultimoServicio'] ?? 'Sin registro').toString(),
    );
  }
}
