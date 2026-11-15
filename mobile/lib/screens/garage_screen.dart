import 'package:flutter/material.dart';
import '../services/datos.dart';
import 'registrar_vehiculo_screen.dart';
import 'agendar_cita_screen.dart';

class GarageScreen extends StatefulWidget {
  final VoidCallback irAServicios;
  const GarageScreen({super.key, required this.irAServicios});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  final datos = DatosSima();

  @override
  void initState() {
    super.initState();
    datos.addListener(_refrescar);
  }

  @override
  void dispose() {
    datos.removeListener(_refrescar);
    super.dispose();
  }

  void _refrescar() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const azulSima = Color(0xFF102566);
    const rojoSima = Color(0xFFD92323);
    final vehiculoActivo = datos.vehiculos[datos.vehiculoActivoIndex];
    final proximaCita = datos.citas.isNotEmpty ? datos.citas.first : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Row(
          children: [
            Icon(Icons.settings, color: azulSima, size: 22),
            SizedBox(width: 6),
            Text('SIMA', style: TextStyle(color: rojoSima, fontWeight: FontWeight.w900, fontSize: 18)),
            SizedBox(width: 10),
            Text('Mi Garage', style: TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: azulSima),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(radius: 14, backgroundColor: Color(0xFFD0D7E8)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta Próxima Cita
            if (proximaCita != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECF7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: azulSima, borderRadius: BorderRadius.circular(6)),
                          child: const Text('PRÓXIMA CITA',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text('${proximaCita.estado} por el taller',
                            style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${proximaCita.servicio} · ${proximaCita.fecha},${proximaCita.hora}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: azulSima)),
                    Text('${proximaCita.vehiculo} (${proximaCita.placas}) · Taller SIMA',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulSima,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: widget.irAServicios,
                        child: const Text('Ver mis citas →', style: TextStyle(fontSize: 12)),
                      ),
                    )
                  ],
                ),
              ),
            const SizedBox(height: 18),

            // Chips Unidades Registradas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('UNIDADES REGISTRADAS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('${datos.vehiculos.length} vehículos',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(datos.vehiculos.length, (index) {
                  final v = datos.vehiculos[index];
                  final activo = index == datos.vehiculoActivoIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${v.marca} ${v.modelo}${activo ? " (Activo)" : ""}'),
                      selected: activo,
                      selectedColor: azulSima,
                      labelStyle: TextStyle(
                        color: activo ? Colors.white : azulSima,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => datos.seleccionarVehiculoActivo(index),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),

            // Tarjeta Vehículo Activo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFE8ECF7), borderRadius: BorderRadius.circular(6)),
                    child: Text(vehiculoActivo.placas,
                        style: const TextStyle(color: azulSima, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(height: 6),
                  Text(vehiculoActivo.nombreCompleto,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36))),
                  Text('Marca ${vehiculoActivo.marca} · Modelo ${vehiculoActivo.modelo} · Año ${vehiculoActivo.anio}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 12),
Container(
                    height: 140,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF102566), Color(0xFF2848A8)]),
                      borderRadius: BorderRadius.circular(12),
                      image: vehiculoActivo.fotoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(vehiculoActivo.fotoBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        if (vehiculoActivo.fotoBytes == null)
                          const Center(child: Icon(Icons.directions_car_filled, color: Colors.white54, size: 76)),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: _badgeInfo(vehiculoActivo.kilometraje),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: _badgeInfo('Último servicio: ${vehiculoActivo.ultimoServicio}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: azulSima, foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AgendarCitaScreen(servicioInicial: datos.catalogo.first),
                              ),
                            );
                          },
                          child: const Text('Agendar cita', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: azulSima, foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RegistrarVehiculoScreen(
                                  vehiculoEditar: vehiculoActivo,
                                  indexEditar: datos.vehiculoActivoIndex,
                                ),
                              ),
                            );
                          },
                          child: const Text('Editar vehículo', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Flota en Garage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Flota en Garage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Tus vehículos registrados', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: azulSima, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrarVehiculoScreen()));
                  },
                  child: const Text('+ Registrar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(datos.vehiculos.length, (i) {
              final v = datos.vehiculos[i];
              final esActivo = i == datos.vehiculoActivoIndex;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: azulSima, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.directions_car, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${v.placas} ·${v.kilometraje}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              SizedBox(
                                height: 28,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: rojoSima,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  onPressed: () {
                                    datos.seleccionarVehiculoActivo(i);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AgendarCitaScreen(servicioInicial: datos.catalogo.first),
                                      ),
                                    );
                                  },
                                  child: const Text('Agendar', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 28,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RegistrarVehiculoScreen(vehiculoEditar: v, indexEditar: i),
                                      ),
                                    );
                                  },
                                  child: const Text('Editar', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    if (esActivo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EDDA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Activo',
                            style: TextStyle(color: Color(0xFF155724), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _badgeInfo(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Text(texto, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF102566))),
    );
  }
}