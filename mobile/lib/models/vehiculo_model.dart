class Vehiculo {
  String id;
  String marca;
  String modelo;
  String anio;
  String placas;
  String kilometraje;
  String ultimoServicio;

  Vehiculo({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.placas,
    required this.kilometraje,
    this.ultimoServicio = 'Sin registro',
  });

  String get nombreCompleto => '$marca $modelo $anio';
}