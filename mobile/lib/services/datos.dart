import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/vehiculo_model.dart';
import '../models/servicio_model.dart';
import '../models/cita_model.dart';
import '../models/orden_model.dart';
import '../models/notificacion_model.dart';
import 'api_client.dart';

class DatosSima extends ChangeNotifier {
  static final DatosSima _instance = DatosSima._internal();
  factory DatosSima() => _instance;
  DatosSima._internal();

  final ApiClient _api = ApiClient();

  int vehiculoActivoIndex = 0;
  bool cargando = false;
  Map<String, dynamic>? usuario;

  final List<Vehiculo> vehiculos = [];
  final List<Servicio> catalogo = [];
  final List<Cita> citas = [];
  final List<OrdenTrabajo> ordenes = [];
  final List<NotificacionItem> notificaciones = [];
  int notificacionesNoLeidas = 0;

  final Map<String, Uint8List> _fotosLocales = {};
  final Map<String, String> _kmLocales = {};

  void seleccionarVehiculoActivo(int index) {
    if (index >= 0 && index < vehiculos.length) {
      vehiculoActivoIndex = index;
      notifyListeners();
    }
  }

  Future<bool> restaurarSesion() async {
    final token = await _api.leerToken();
    if (token == null || token.isEmpty) return false;
    try {
      final res = await _api.dio.get('/auth/me');
      usuario = Map<String, dynamic>.from(res.data['data']);
      await cargarTodo();
      return true;
    } catch (_) {
      await _api.borrarToken();
      return false;
    }
  }

  Future<void> iniciarSesion(String correo, String contrasena) async {
    final res = await _api.dio.post('/auth/login', data: {
      'correo': correo.trim(),
      'contrasena': contrasena,
    });
    final data = Map<String, dynamic>.from(res.data['data']);
    await _api.guardarToken(data['token'].toString());
    usuario = Map<String, dynamic>.from(data['usuario']);
    await cargarTodo();
  }

  Future<void> registrarCuenta({
    required String nombre,
    required String apellidos,
    required String telefono,
    required String correo,
    required String contrasena,
  }) async {
    final res = await _api.dio.post('/auth/register', data: {
      'nombre': nombre.trim(),
      'apellidos': apellidos.trim(),
      'telefono': telefono.trim(),
      'correo': correo.trim(),
      'contrasena': contrasena,
    });
    final data = res.data['data'];
    if (data is Map && data['token'] != null) {
      await _api.guardarToken(data['token'].toString());
      if (data['usuario'] is Map) {
        usuario = Map<String, dynamic>.from(data['usuario']);
      }
      await cargarTodo();
    } else {
      await iniciarSesion(correo, contrasena);
    }
  }

  Future<void> cerrarSesion() async {
    await _api.borrarToken();
    usuario = null;
    vehiculos.clear();
    citas.clear();
    ordenes.clear();
    notificaciones.clear();
    notificacionesNoLeidas = 0;
    vehiculoActivoIndex = 0;
    notifyListeners();
  }

  Future<void> cargarCatalogoPublico() async {
    try {
      final res = await _api.dio.get('/servicios');
      final lista = (res.data['data'] as List)
          .map((e) => Servicio.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      catalogo
        ..clear()
        ..addAll(lista);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cargarTodo() async {
    cargando = true;
    notifyListeners();
    try {
      await Future.wait([
        cargarVehiculos(),
        cargarCatalogoPublico(),
        cargarCitas(),
        cargarOrdenes(),
        cargarContadorNotificaciones(),
      ]);
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarVehiculos() async {
    final res = await _api.dio.get('/vehiculos');
    final lista = (res.data['data'] as List).map((e) {
      final v = Vehiculo.fromJson(Map<String, dynamic>.from(e));
      if (_fotosLocales.containsKey(v.id)) v.fotoBytes = _fotosLocales[v.id];
      if (_kmLocales.containsKey(v.id)) v.kilometraje = _kmLocales[v.id]!;
      return v;
    }).toList();

    vehiculos
      ..clear()
      ..addAll(lista);
    if (vehiculoActivoIndex >= vehiculos.length) {
      vehiculoActivoIndex = 0;
    }
    notifyListeners();
  }

  Future<void> crearVehiculo({
    required String marca,
    required String modelo,
    required int anio,
    required String placas,
    String? kilometraje,
    Uint8List? fotoBytes,
  }) async {
    final res = await _api.dio.post('/vehiculos', data: {
      'marca': marca,
      'modelo': modelo.trim(),
      'anio': anio,
      'placas': placas.trim().toUpperCase(),
    });
    final creado = Vehiculo.fromJson(Map<String, dynamic>.from(res.data['data']));
    if (fotoBytes != null) _fotosLocales[creado.id] = fotoBytes;
    if (kilometraje != null && kilometraje.trim().isNotEmpty) {
      _kmLocales[creado.id] = kilometraje.trim();
    }
    await cargarVehiculos();
  }

  Future<void> editarVehiculo({
    required String id,
    required String marca,
    required String modelo,
    required int anio,
    required String placas,
    String? kilometraje,
    Uint8List? fotoBytes,
  }) async {
    await _api.dio.put('/vehiculos/$id', data: {
      'marca': marca,
      'modelo': modelo.trim(),
      'anio': anio,
      'placas': placas.trim().toUpperCase(),
    });
    if (fotoBytes != null) _fotosLocales[id] = fotoBytes;
    if (kilometraje != null && kilometraje.trim().isNotEmpty) {
      _kmLocales[id] = kilometraje.trim();
    }
    await cargarVehiculos();
  }

  Future<List<String>> obtenerHorasOcupadas(String fechaIso) async {
    try {
      final res = await _api.dio.get(
        '/citas/disponibilidad',
        queryParameters: {'fecha': fechaIso},
      );
      final data = res.data['data'];
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<String>> obtenerDiasLlenosMes(int anio, int mes) async {
    try {
      final res = await _api.dio.get(
        '/citas/dias-llenos',
        queryParameters: {'anio': anio, 'mes': mes},
      );
      final data = res.data['data'];
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> cargarCitas() async {
    final res = await _api.dio.get('/citas');
    final lista = (res.data['data'] as List)
        .map((e) => Cita.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    citas
      ..clear()
      ..addAll(lista);
    notifyListeners();
  }

  Future<void> crearCita({
    required int vehiculoId,
    required int servicioId,
    required String fechaIso,
    required String hora,
  }) async {
    await _api.dio.post('/citas', data: {
      'vehiculoId': vehiculoId,
      'servicioId': servicioId,
      'fecha': fechaIso,
      'hora': hora,
    });
    await cargarCitas();
  }

  Future<void> crearCitaExpres({
    required String nombre,
    required String apellidos,
    required String telefono,
    required String marca,
    required String modelo,
    required int anio,
    required String placas,
    required int servicioId,
    required String fechaIso,
    required String hora,
  }) async {
    await _api.dio.post('/citas/express', data: {
      'nombre': nombre.trim(),
      'apellidos': apellidos.trim(),
      'telefono': telefono.trim(),
      'marca': marca.trim(),
      'modelo': modelo.trim(),
      'anio': anio,
      'placas': placas.trim().toUpperCase(),
      'servicioId': servicioId,
      'fecha': fechaIso,
      'hora': hora,
    });
  }

  Future<void> cancelarCita(String id) async {
    await _api.dio.patch('/citas/$id/cancelar');
    await cargarCitas();
  }

  Future<void> cargarOrdenes() async {
    final res = await _api.dio.get('/ordenes');
    final lista = (res.data['data'] as List)
        .map((e) => OrdenTrabajo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    ordenes
      ..clear()
      ..addAll(lista);
    notifyListeners();
  }

  Future<OrdenTrabajo> obtenerDetalleOrden(int id) async {
    final res = await _api.dio.get('/ordenes/$id');
    return OrdenTrabajo.fromJson(Map<String, dynamic>.from(res.data['data']));
  }

  Future<void> responderCotizacion(int ordenId, String decision) async {
    await _api.dio.patch('/ordenes/$ordenId/autorizacion', data: {
      'decision': decision,
    });
    await Future.wait([cargarOrdenes(), cargarContadorNotificaciones()]);
  }

  Future<void> cargarContadorNotificaciones() async {
    try {
      final res = await _api.dio.get('/notificaciones/contador');
      notificacionesNoLeidas = (res.data['data']['noLeidas'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cargarNotificaciones() async {
    final res = await _api.dio.get('/notificaciones');
    final lista = (res.data['data'] as List)
        .map((e) => NotificacionItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    notificaciones
      ..clear()
      ..addAll(lista);
    notificacionesNoLeidas = notificaciones.where((n) => !n.leida).length;
    notifyListeners();
  }

  Future<void> marcarNotificacionesLeidas() async {
    await _api.dio.patch('/notificaciones/leidas');
    await cargarNotificaciones();
  }
}
