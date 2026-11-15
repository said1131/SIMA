import 'package:flutter/material.dart';
import '../models/vehiculo_model.dart';
import '../models/servicio_model.dart';
import '../models/cita_model.dart';

class DatosSima extends ChangeNotifier {
  static final DatosSima _instance = DatosSima._internal();
  factory DatosSima() => _instance;
  DatosSima._internal();

  int vehiculoActivoIndex = 0;

  final List<Vehiculo> vehiculos = [
    Vehiculo(
      id: '1',
      marca: 'Toyota',
      modelo: 'Hilux',
      anio: '2021',
      placas: 'ABC-892',
      kilometraje: '45,210 km',
      ultimoServicio: '20 jun 2026',
    ),
    Vehiculo(
      id: '2',
      marca: 'Chevrolet',
      modelo: 'Aveo',
      anio: '2016',
      placas: 'QWE-123',
      kilometraje: '88,400 km',
      ultimoServicio: '12 mar 2026',
    ),
  ];

  final List<Servicio> catalogo = [
    Servicio(
      id: 's1',
      categoria: 'Preventivo',
      titulo: 'Afinación Mayor Completa',
      descripcion: 'Aceite sintético, cambio de 4 bujías iridium, filtros de aire y gasolina.',
      duracion: '2.5 hrs',
      precio: 1850,
      etiqueta: 'Popular',
    ),
    Servicio(
      id: 's2',
      categoria: 'Frenos & Suspensión',
      titulo: 'Frenos delanteros',
      descripcion: 'Reemplazo de pastillas cerámicas delanteras y rectificado de discos.',
      duracion: '2.0 hrs',
      precio: 1950,
    ),
    Servicio(
      id: 's3',
      categoria: 'Electrónica',
      titulo: 'Escaneo OBD-II & Sensores',
      descripcion: 'Lectura y borrado de códigos de falla Check Engine y prueba de alternador.',
      duracion: '1.0 hr',
      precio: 650,
      etiqueta: 'Rápido',
    ),
  ];

  final List<Cita> citas = [
    Cita(
      id: 'c1',
      servicio: 'Frenos delanteros',
      vehiculo: 'Toyota Hilux 2021',
      placas: 'ABC-892',
      fecha: '24 oct',
      hora: '09:30',
      estado: 'Confirmada',
    ),

    Cita(
      id: 'c2',
      servicio: 'Cambio de aceite y filtro',
      vehiculo: 'Chevrolet Aveo 2016',
      placas: 'QWE-123',
      fecha: '28 oct',
      hora: '11:00',
      estado: 'Solicitada',
    ),
    Cita(
      id: 'c3',
      servicio: 'Alineación y balanceo',
      vehiculo: 'Toyota Hilux 2021',
      placas: 'ABC-892',
      fecha: '15 oct',
      hora: '10:00',
      estado: 'Rechazada',
      motivoRechazo: 'No hay disponibilidad en ese horario.',
    ),
  ];

void eliminarCita(String id) {
    citas.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void seleccionarVehiculoActivo(int index) {
    vehiculoActivoIndex = index;
    notifyListeners();
  }

  void agregarVehiculo(Vehiculo v) {
    vehiculos.add(v);
    notifyListeners();
  }

  void actualizarVehiculo(int index, Vehiculo v) {
    vehiculos[index] = v;
    notifyListeners();
  }

  void agregarCita(Cita c) {
    citas.insert(0, c);
    notifyListeners();
  }
}