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
  });
}