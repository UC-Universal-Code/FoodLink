import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('Token enviado: ${token.substring(0, 20)}...');
          } else {
            print('No hay token guardado');
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'access_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Iniciar sesion con numero de empleado y contrasena
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

        await _storage.write(key: 'access_token', value: accessToken);
        print('Token guardado correctamente');

        return {
          'access_token': accessToken,
          'token_type': tokenType,
        };
      } else {
        throw Exception('Error al iniciar sesion: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Numero de empleado o contrasena incorrectos');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Error de conexion. Verifica que el backend este corriendo.');
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

  /// Obtener la lista de todos los usuarios (solo admin)
  Future<List<User>> getAllUsers() async {
    try {
      final response = await _dio.get('$baseUrl/usuarios/');

      print('Respuesta de /usuarios/: ${response.statusCode}');
      print('Datos recibidos: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Error en getAllUsers: ${e.message}');
      if (e.response?.statusCode == 403) {
        throw Exception('Se requiere rol de administrador');
      } else if (e.response?.statusCode == 401) {
        throw Exception('No autenticado. Inicia sesion nuevamente.');
      } else {
        throw Exception('Error al obtener usuarios: ${e.message}');
      }
    }
  }

  /// Crear un nuevo usuario (solo admin)
  Future<User> createUser({
    required String numeroEmpleado,
    required String nombre,
    required String apellido,
    required String contrasena,
    String rol = 'user',
    String estado = 'active',
    int? departamentoId,
    int? turnoId,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/usuarios/',
        data: {
          'numero_empleado': numeroEmpleado,
          'nombre': nombre,
          'apellido': apellido,
          'contrasena': contrasena,
          'rol': rol,
          'estado': estado,
          'departamento_id': departamentoId,
          'turno_id': turnoId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return User.fromJson(response.data);
      } else {
        throw Exception('Error al crear usuario: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('El numero de empleado ya existe');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Se requiere rol de administrador');
      } else {
        throw Exception('Error al crear usuario: ${e.message}');
      }
    }
  }

  /// Obtener la lista de todos los turnos
  Future<List<Map<String, dynamic>>> getTurnos() async {
    try {
      final response = await _dio.get('$baseUrl/usuarios/turnos');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => json as Map<String, dynamic>).toList();
      } else {
        throw Exception('Error al obtener turnos: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error al obtener turnos: ${e.message}');
    }
  }

  /// Obtener la lista de todos los departamentos
  Future<List<Map<String, dynamic>>> getDepartamentos() async {
    try {
      final response = await _dio.get('$baseUrl/usuarios/departamentos');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => json as Map<String, dynamic>).toList();
      } else {
        throw Exception('Error al obtener departamentos: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error al obtener departamentos: ${e.message}');
    }
  }

  /// Cerrar sesion - eliminar token
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    print('Sesion cerrada');
  }
   // ========== MENÚ SEMANAL ==========

  /// Crear un menú semanal (solo cocinero/admin)
  Future<Map<String, dynamic>> crearMenuSemanal(Map<String, dynamic> menuData) async {
    try {
      final response = await _dio.post(
        '${ApiService.baseUrl}/menu/semanal',
        data: menuData,
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Error al crear menú: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No tienes permiso para crear menús');
      } else if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? 'Datos inválidos');
      } else if (e.response?.statusCode == 401) {
        throw Exception('No autenticado. Inicia sesión nuevamente.');
      } else {
        throw Exception('Error al crear menú: ${e.message}');
      }
    }
  }

  /// Obtener el menú actual (para el turno del usuario)
  /// Obtener el menú actual (para el turno del usuario autenticado)
  Future<Map<String, dynamic>?> obtenerMenuActual() async {
    try {
      // 1. Usamos la ruta exacta con barra diagonal final tal cual está en tu FastAPI
      // 2. Eliminamos el parámetro 'turno', ya que tu backend lo obtiene solo del token
      final response = await _dio.get(
        '$baseUrl/menu/semanal/actual/',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener menú: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      } else if (e.response?.statusCode == 401) {
        throw Exception('No autenticado. Inicia sesión nuevamente.');
      } else {
        throw Exception('Error al conectar con el servidor: ${e.message}');
      }
    }
  }

  /// Obtener todos los menús creados por el cocinero actual
  Future<List<dynamic>> obtenerMisMenus() async {
    try {
      final response = await _dio.get(
        '${ApiService.baseUrl}/menu/semanal/mis-menus', 
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al obtener menús: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Solo los cocineros pueden ver sus menús');
      } else if (e.response?.statusCode == 401) {
        throw Exception('No autenticado. Inicia sesión nuevamente.');
      } else {
        throw Exception('Error al obtener menús: ${e.message}');
      }
    }
  }

  /// Obtener un menú por ID
  Future<Map<String, dynamic>> obtenerMenuPorId(int id) async {
    try {
      final response = await _dio.get(
        '${ApiService.baseUrl}/menu/semanal/$id',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else if (response.statusCode == 404) {
        throw Exception('Menú no encontrado');
      } else {
        throw Exception('Error al obtener menú: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Menú no encontrado');
      } else if (e.response?.statusCode == 403) {
        throw Exception('No tienes permiso para ver este menú');
      } else {
        throw Exception('Error al obtener menú: ${e.message}');
      }
    }
  }

  /// Actualizar un menú semanal (solo cocinero que lo creó o admin)
  Future<Map<String, dynamic>> actualizarMenu(int id, Map<String, dynamic> menuData) async {
    try {
      final response = await _dio.put(
        '${ApiService.baseUrl}/menu/semanal/$id',
        data: menuData,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al actualizar menú: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No tienes permiso para editar este menú');
      } else if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? 'Datos inválidos');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Menú no encontrado');
      } else {
        throw Exception('Error al actualizar menú: ${e.message}');
      }
    }
  }

  /// Eliminar un menú semanal (solo cocinero que lo creó o admin)
  Future<void> eliminarMenu(int id) async {
    try {
      final response = await _dio.delete(
        '${ApiService.baseUrl}/menu/semanal/$id',
      );

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar menú: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No tienes permiso para eliminar este menú');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Menú no encontrado');
      } else {
        throw Exception('Error al eliminar menú: ${e.message}');
      }
    }
  }
  // ==========================================
  // PEGA EL MÉTODO DE REPORTES AQUÍ ABAJO:
  // ==========================================
  Future<Map<String, dynamic>> crearReporte(String titulo, String descripcion) async {
    try {
      final response = await _dio.post(
        '$baseUrl/', 
        data: {
          'titulo': titulo,
          'descripcion': descripcion,
          'estado': 'Pendiente',
        },
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Error al crear reporte: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('No autenticado. Inicia sesión nuevamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('No tienes permisos para realizar esta acción.');
      } else {
        throw Exception('Error al conectar con el servidor: ${e.message}');
      }
    }
  }
}