import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio dio;

  ApiClient({
    String? baseUrl,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl ?? _resolveBaseUrl(),
           connectTimeout: const Duration(seconds: 8),
           receiveTimeout: const Duration(seconds: 12),
           sendTimeout: const Duration(seconds: 12),
           headers: const {'Content-Type': 'application/json'},
         ),
       ) {
    // Configuración para ignorar errores de certificado SSL (necesario para túneles de desarrollo)
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept'] = 'application/json';
          if (options.path == 'health') {
            return handler.next(options);
          }
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 &&
              !e.requestOptions.path.contains('/auth/login')) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
          }
          return handler.next(e);
        },
      ),
    );
  }

  static bool isConnectionFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return true;
      default:
        return e.response == null &&
            e.type != DioExceptionType.cancel &&
            e.type != DioExceptionType.badResponse;
    }
  }

  static String? parseApiErrorCode(dynamic body) {
    final map = _asJsonMap(body);
    if (map == null) return null;
    final code = map['code'];
    return code == null ? null : code.toString();
  }

  static Map<String, dynamic>? _asJsonMap(dynamic body) {
    if (body is Map) {
      return body.map((key, value) => MapEntry(key.toString(), value));
    }
    if (body is String && body.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {}
    }
    return null;
  }

  /// Verificación general de salud del backend.
  /// Devuelve un resultado descriptivo para poder mostrar el motivo exacto
  /// (servidor caído, túnel privado, etc.) en la UI.
  Future<HealthCheckResult> checkHealth() async {
    try {
      final response = await dio.get(
        'health',
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          followRedirects: false,
          validateStatus: (status) => status != null,
        ),
      );

      final status = response.statusCode ?? 0;

      // El backend responde 200 con {"status":"UP"}.
      if (status == 200) {
        final map = _asJsonMap(response.data);
        if (map != null && map['status'] == 'UP') {
          return HealthCheckResult.connected();
        }
        // 200 pero contenido inesperado (ej. página HTML de un proxy/túnel).
        return HealthCheckResult.failed(
          'Respuesta inesperada del servidor (¿proxy o túnel?).',
        );
      }

      // 3xx => el dev tunnel exige autenticación (redirige a login de GitHub).
      if (status >= 300 && status < 400) {
        return HealthCheckResult.failed(
          'El túnel exige autenticación (hazlo público/anónimo).',
        );
      }

      if (status >= 500) {
        return HealthCheckResult.failed('Servidor con error interno ($status).');
      }

      return HealthCheckResult.failed('Servidor respondió con código $status.');
    } on DioException catch (e) {
      if (isConnectionFailure(e)) {
        return HealthCheckResult.failed(
          'No se pudo conectar. Verifica que el backend esté encendido y la URL.',
        );
      }
      final status = e.response?.statusCode;
      if (status != null && status >= 300 && status < 400) {
        return HealthCheckResult.failed(
          'El túnel exige autenticación (hazlo público/anónimo).',
        );
      }
      return HealthCheckResult.failed(
        'Error de conexión (${e.type.name}).',
      );
    } catch (_) {
      return HealthCheckResult.failed('Error inesperado al verificar el servidor.');
    }
  }

  Future<bool> isServerReachable() async {
    final result = await checkHealth();
    return result.connected;
  }

  Future<bool?> checkEmailExists(String correo) async {
    try {
      final response = await dio.get(
        'auth/exists',
        queryParameters: {'correo': correo},
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode != 200) return null;
      final map = _asJsonMap(response.data);
      if (map == null) return null;
      return map['exists'] == true;
    } on DioException catch (e) {
      if (isConnectionFailure(e)) return null;
      return null;
    } catch (_) {
      return null;
    }
  }
}

class HealthCheckResult {
  final bool connected;
  final String message;

  const HealthCheckResult._(this.connected, this.message);

  factory HealthCheckResult.connected() =>
      const HealthCheckResult._(true, 'Conectado al servidor');

  factory HealthCheckResult.failed(String message) =>
      HealthCheckResult._(false, message);
}

String _resolveBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  final envUrl = fromEnv.trim();
  if (envUrl.isNotEmpty && _isValidHttpUrl(envUrl)) {
    return _normalizeBaseUrl(envUrl);
  }
  // Safe defaults:
  // - localhost works on desktop/web
  // - 10.0.2.2 works on Android emulator
  // - Móvil físico (misma WiFi): Reemplazar por la IP LAN local de tu PC (ej: http://192.168.1.50:8081/api)
  // return _normalizeBaseUrl('http://192.168.1.100:8081/api');
  // return _normalizeBaseUrl('http://10.0.2.2:8081/api');
  return _normalizeBaseUrl('http://18.118.29.153:8081/api');
}

bool _isValidHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) return false;
  return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}

String _normalizeBaseUrl(String value) {
  final noTrailingSlash = value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  final withApi = noTrailingSlash.endsWith('/api') ? noTrailingSlash : '$noTrailingSlash/api';
  return '$withApi/';
}
