class Servicio {
  final String id;
  final String categoria;
  final String titulo;
  final String descripcion;
  final String duracion;
  final double precio;
  final String etiqueta;

  Servicio({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.descripcion,
    required this.duracion,
    required this.precio,
    this.etiqueta = '',
  });
}