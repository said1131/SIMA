class ConceptoOrden {
  final int id;
  final String concepto;
  final String tipo;
  final double cantidad;
  final double precio;
  final double subtotal;

  ConceptoOrden({
    required this.id,
    required this.concepto,
    required this.tipo,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });

  factory ConceptoOrden.fromJson(Map<String, dynamic> json) {
    return ConceptoOrden(
      id: (json['id'] as num?)?.toInt() ?? 0,
      concepto: (json['concepto'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'Labor').toString(),
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 1,
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrdenTrabajo {
  final int id;
  final String folio;
  final String estado;
  final String? diagnostico;
  final String autorizacion;
  final bool cotizacionEnviada;
  final int? kilometraje;
  final String? notas;
  final String fechaIngreso;
  final String vehiculo;
  final String placas;
  final String servicio;
  final String? mecanico;
  final List<ConceptoOrden> conceptos;
  final double subtotal;
  final double iva;
  final double total;

  OrdenTrabajo({
    required this.id,
    required this.folio,
    required this.estado,
    this.diagnostico,
    required this.autorizacion,
    required this.cotizacionEnviada,
    this.kilometraje,
    this.notas,
    required this.fechaIngreso,
    required this.vehiculo,
    required this.placas,
    required this.servicio,
    this.mecanico,
    this.conceptos = const [],
    this.subtotal = 0,
    this.iva = 0,
    this.total = 0,
  });

  factory OrdenTrabajo.fromJson(Map<String, dynamic> json) {
    final listaConceptos = (json['conceptos'] as List?)
            ?.map((e) => ConceptoOrden.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    return OrdenTrabajo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      folio: (json['folio'] ?? 'OT-0000').toString(),
      estado: (json['estado'] ?? 'Recibida').toString(),
      diagnostico: json['diagnostico']?.toString(),
      autorizacion: (json['autorizacion'] ?? 'Pendiente').toString(),
      cotizacionEnviada: json['cotizacionEnviada'] == true,
      kilometraje: (json['kilometraje'] as num?)?.toInt(),
      notas: json['notas']?.toString(),
      fechaIngreso: (json['fechaIngreso'] ?? '').toString(),
      vehiculo: (json['vehiculo'] ?? '').toString(),
      placas: (json['placas'] ?? '').toString(),
      servicio: (json['servicio'] ?? 'Servicio general').toString(),
      mecanico: json['mecanico']?.toString(),
      conceptos: listaConceptos,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      iva: (json['iva'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}
