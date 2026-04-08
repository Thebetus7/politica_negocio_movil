import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio dio;

  ApiClient({String baseUrl = 'http://10.0.2.2:8080/api'})
      : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token'; // Usable backend Dummy Auth
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
    ));
  }
}
