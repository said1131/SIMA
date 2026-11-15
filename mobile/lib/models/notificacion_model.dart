class NotificacionItem {
  final int id;
  final String tipo;
  final String tono;
  final String titulo;
  final String detalle;
  final bool leida;
  final String fecha;
  final String? refTipo;
  final int? refId;

  NotificacionItem({
    required this.id,
    required this.tipo,
    required this.tono,
    required this.titulo,
    required this.detalle,
    required this.leida,
    required this.fecha,
    this.refTipo,
    this.refId,
  });

  factory NotificacionItem.fromJson(Map<String, dynamic> json) {
    return NotificacionItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tipo: (json['tipo'] ?? 'orden').toString(),
      tono: (json['tono'] ?? 'slate').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      detalle: (json['detalle'] ?? '').toString(),
      leida: json['leida'] == true,
      fecha: (json['fecha'] ?? '').toString(),
      refTipo: json['refTipo']?.toString(),
      refId: (json['refId'] as num?)?.toInt(),
    );
  }
}
