import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio dio;

  ApiClient({String baseUrl = 'https://cyhh0y-ip-189-28-70-114.tunnelmole.net/api'})
    : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    
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
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] =
                'Bearer $token'; // Usable backend Dummy Auth
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Token expirado o invalido
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            // Implementar evento para desloguear usuario localmente
          }
          return handler.next(e);
        },
      ),
    );
  }
}
