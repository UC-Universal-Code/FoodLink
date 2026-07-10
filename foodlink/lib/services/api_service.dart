// lib/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8000"; // Cambia a la IP real del backend
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    // Configurar timeout
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Interceptor para agregar el token automáticamente
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expirado o inválido - limpiar y redirigir al login
            await _storage.delete(key: 'access_token');
            // Aquí puedes emitir un evento para redirigir al login
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Iniciar sesión con número de empleado y contraseña
  Future<Map<String, String>> login(String numeroEmpleado, String contrasena) async {
    try {
      final response = await _dio.post(
        '$baseUrl/usuarios/login',
        data: {
          'username': numeroEmpleado,
          'password': contrasena,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access_token'] as String;
        final tokenType = response.data['token_type'] as String;

        // Guardar token en almacenamiento seguro
        await _storage.write(key: 'access_token', value: accessToken);

        return {
          'access_token': accessToken,
          'token_type': tokenType,
        };
      } else {
        throw Exception('Error al iniciar sesión: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Número de empleado o contraseña incorrectos');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Error de conexión. Verifica que el backend esté corriendo.');
      } else {
        throw Exception('Error al conectar con el servidor: ${e.message}');
      }
    }
  }

  /// Obtener los datos del usuario actual
  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('$baseUrl/usuarios/me');

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        throw Exception('Error al obtener usuario: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error al obtener usuario: ${e.message}');
    }
  }

  /// Cerrar sesión - eliminar token
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }
}