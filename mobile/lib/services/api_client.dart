import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  static const _tokenKey = 'sima_jwt_token';
  static const _urlKey = 'sima_custom_api_url';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _urlPorDefecto(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final customUrl = await _storage.read(key: _urlKey);
          if (customUrl != null && customUrl.isNotEmpty) {
            options.baseUrl = customUrl;
          }
          final token = await _storage.read(key: _tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static String _urlPorDefecto() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    return 'http://localhost:3000/api/v1';
  }

  Future<String> obtenerBaseUrl() async {
    final guardada = await _storage.read(key: _urlKey);
    return (guardada != null && guardada.isNotEmpty) ? guardada : dio.options.baseUrl;
  }

  Future<void> guardarBaseUrl(String url) async {
    final limpia = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (limpia.isEmpty) {
      await _storage.delete(key: _urlKey);
      dio.options.baseUrl = _urlPorDefecto();
    } else {
      await _storage.write(key: _urlKey, value: limpia);
      dio.options.baseUrl = limpia;
    }
  }

  Future<void> guardarToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> leerToken() => _storage.read(key: _tokenKey);
  Future<void> borrarToken() => _storage.delete(key: _tokenKey);

  static String mensajeError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        final msg = err['message']?.toString() ?? 'Error en la solicitud';
        final details = err['details'];
        if (details is List && details.isNotEmpty && details.first is Map) {
          final detalle = (details.first as Map)['mensaje']?.toString();
          if (detalle != null && detalle.isNotEmpty) return '$msg:$detalle';
        }
        return msg;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'No se pudo conectar con el servidor SIMA. Verifica que el backend esté encendido en el puerto 3000.';
      }
    }
    return 'Ocurrió un error inesperado.';
  }
}
