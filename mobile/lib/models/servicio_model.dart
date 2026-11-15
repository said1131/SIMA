class Servicio {
  final String id;
  final String categoria;
  final String titulo;
  final String descripcion;
  final String duracion;
  final int garantia;
  final double precio;
  final String etiqueta;

  Servicio({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.descripcion,
    required this.duracion,
    this.garantia = 6,
    required this.precio,
    this.etiqueta = '',
  });

  int get idNumerico => int.tryParse(id) ?? 0;

  factory Servicio.fromJson(Map<String, dynamic> json) {
    final dur = json['duracion'] ?? 1;
    return Servicio(
      id: (json['id'] ?? '').toString(),
      categoria: (json['categoria'] ?? 'Preventivo').toString(),
      titulo: (json['nombre'] ?? json['titulo'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      duracion: '$dur hrs',
      garantia: (json['garantia'] as num?)?.toInt() ?? 6,
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
    );
  }
}
