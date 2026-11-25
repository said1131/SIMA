import 'package:flutter/material.dart';

class CalendarioCitas extends StatelessWidget {
  final DateTime mesVisible;
  final DateTime fechaSeleccionada;
  final Set<String> diasLlenosIso;
  final bool cargando;
  final ValueChanged<DateTime> onCambiarMes;
  final ValueChanged<DateTime> onSeleccionarFecha;

  const CalendarioCitas({
    super.key,
    required this.mesVisible,
    required this.fechaSeleccionada,
    required this.diasLlenosIso,
    required this.cargando,
    required this.onCambiarMes,
    required this.onSeleccionarFecha,
  });

  static String toIso(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    const diasSemana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final primerDiaMes = DateTime(mesVisible.year, mesVisible.month, 1);
    final diasEnMes = DateTime(mesVisible.year, mesVisible.month + 1, 0).day;
    final offsetInicio = primerDiaMes.weekday - 1; // Lunes = 0 ... Domingo = 6

    final puedeRetroceder =
        mesVisible.year > hoy.year || (mesVisible.year == hoy.year && mesVisible.month > hoy.month);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: puedeRetroceder ? azulSima : Colors.grey[300],
                onPressed: puedeRetroceder
                    ? () => onCambiarMes(DateTime(mesVisible.year, mesVisible.month - 1, 1))
                    : null,
              ),
              Row(
                children: [
                  Text(
                    '${meses[mesVisible.month - 1]} ${mesVisible.year}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: azulSima,
                    ),
                  ),
                  if (cargando) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: azulSima,
                onPressed: () => onCambiarMes(DateTime(mesVisible.year, mesVisible.month + 1, 1)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: diasSemana
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offsetInicio + diasEnMes,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (_, index) {
              if (index < offsetInicio) {
                return const SizedBox.shrink();
              }
              final dia = index - offsetInicio + 1;
              final fecha = DateTime(mesVisible.year, mesVisible.month, dia);
              final iso = toIso(fecha);

              final esPasado = fecha.isBefore(hoy);
              final esDomingo = fecha.weekday == DateTime.sunday;
              final estaLleno = diasLlenosIso.contains(iso);
              final disponible = !esPasado && !esDomingo && !estaLleno;
              final seleccionado = iso == toIso(fechaSeleccionada);

              return GestureDetector(
                onTap: disponible ? () => onSeleccionarFecha(fecha) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? azulSima
                        : (disponible ? Colors.white : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: seleccionado
                          ? azulSima
                          : (disponible ? Colors.grey.shade300 : Colors.transparent),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dia',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: estaLleno ? TextDecoration.lineThrough : null,
                        color: seleccionado
                            ? Colors.white
                            : (disponible ? Colors.black87 : Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}