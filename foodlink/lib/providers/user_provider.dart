import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

// Clase simple para Turno (solo para el dropdown)
class Turno {
  final int id;
  final String nombre;

  Turno({required this.id, required this.nombre});

  factory Turno.fromJson(Map<String, dynamic> json) {
    return Turno(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
    );
  }

  @override
  String toString() => nombre;
}

// Clase simple para Departamento (solo para el dropdown)
class Departamento {
  final int id;
  final String nombre;

  Departamento({required this.id, required this.nombre});

  factory Departamento.fromJson(Map<String, dynamic> json) {
    return Departamento(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
    );
  }

  @override
  String toString() => nombre;
}

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  List<Turno> _turnos = [];
  List<Departamento> _departamentos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => _users;
  List<Turno> get turnos => _turnos;
  List<Departamento> get departamentos => _departamentos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Cargar turnos y departamentos desde el backend
  Future<void> loadCatalogos() async {
    try {
      final turnosData = await _apiService.getTurnos();
      _turnos = turnosData.map((json) => Turno.fromJson(json)).toList();

      final deptosData = await _apiService.getDepartamentos();
      _departamentos = deptosData.map((json) => Departamento.fromJson(json)).toList();

      print('Turnos cargados: ${_turnos.length}');
      print('Departamentos cargados: ${_departamentos.length}');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('Error al cargar catalogos: $_errorMessage');
      notifyListeners();
    }
  }

  /// Obtener la lista de todos los usuarios (solo admin)
  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _apiService.getAllUsers();
      print('Usuarios obtenidos: ${_users.length}');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('Error en fetchUsers: $_errorMessage');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crear un nuevo usuario en la base de datos (solo admin)
  Future<bool> createUser({
    required String numeroEmpleado,
    required String nombre,
    required String apellido,
    required String contrasena,
    String rol = 'user',
    String estado = 'active',
    int? departamentoId,
    int? turnoId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = await _apiService.createUser(
        numeroEmpleado: numeroEmpleado,
        nombre: nombre,
        apellido: apellido,
        contrasena: contrasena,
        rol: rol,
        estado: estado,
        departamentoId: departamentoId,
        turnoId: turnoId,
      );

      _users.add(newUser);
      print('Usuario creado: ${newUser.nombre} ${newUser.apellido}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('Error en createUser: $_errorMessage');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtener el nombre de un turno por su ID
  String getTurnoNombre(int? turnoId) {
    if (turnoId == null) return 'Sin asignar';
    try {
      return _turnos.firstWhere((t) => t.id == turnoId).nombre;
    } catch (e) {
      return 'Sin asignar';
    }
  }

  /// Obtener el nombre de un departamento por su ID
  String getDepartamentoNombre(int? departamentoId) {
    if (departamentoId == null) return 'Sin asignar';
    try {
      return _departamentos.firstWhere((d) => d.id == departamentoId).nombre;
    } catch (e) {
      return 'Sin asignar';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

    /// Actualizar un usuario existente (solo admin)
  Future<bool> updateUser({
    required String numeroEmpleado,
    required String nombre,
    required String apellido,
    String? contrasena,
    String? rol,
    String? estado,
    int? departamentoId,
    int? turnoId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _apiService.updateUser(
        numeroEmpleado: numeroEmpleado,
        nombre: nombre,
        apellido: apellido,
        contrasena: contrasena,
        rol: rol,
        estado: estado,
        departamentoId: departamentoId,
        turnoId: turnoId,
      );

      // Actualizar la lista local
      final index = _users.indexWhere((u) => u.numeroEmpleado == numeroEmpleado);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Eliminar un usuario (solo admin)
  Future<bool> deleteUser(String numeroEmpleado) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteUser(numeroEmpleado);

      // Eliminar de la lista local
      _users.removeWhere((u) => u.numeroEmpleado == numeroEmpleado);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}