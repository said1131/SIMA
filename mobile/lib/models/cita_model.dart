class Cita {
  final String id;
  final String servicio;
  final String vehiculo;
  final String placas;
  final String fecha;
  final String hora;
  final String notas;
  final String estado;
  final String? motivoRechazo;
  final bool expres;

  Cita({
    required this.id,
    required this.servicio,
    required this.vehiculo,
    required this.placas,
    required this.fecha,
    required this.hora,
    this.notas = '',
    this.estado = 'Solicitada',
    this.motivoRechazo,
    this.expres = false,
  });

  int get idNumerico => int.tryParse(id) ?? 0;

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: (json['id'] ?? '').toString(),
      servicio: (json['servicio'] ?? '').toString(),
      vehiculo: (json['vehiculo'] ?? '').toString(),
      placas: (json['placas'] ?? '').toString(),
      fecha: (json['fecha'] ?? '').toString(),
      hora: (json['hora'] ?? '').toString(),
      notas: (json['notas'] ?? '').toString(),
      estado: (json['estado'] ?? 'Solicitada').toString(),
      motivoRechazo: json['motivoRechazo']?.toString(),
      expres: json['expres'] == true,
    );
  }
}
