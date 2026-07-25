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
  bool _catalogosCargados = false;
  String? _errorMessage;
  String? _contrasenaGenerada;

  List<User> get users => _users;
  List<Turno> get turnos => _turnos;
  List<Departamento> get departamentos => _departamentos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get contrasenaGenerada => _contrasenaGenerada;

  /// Cargar turnos y departamentos desde el backend (solo una vez)
  Future<void> loadCatalogos({bool force = false}) async {
    if (_catalogosCargados && !force) {
      print('Catalogos ya cargados, omitiendo...');
      return;
    }

    try {
      print('Cargando catalogos...');
      final turnosData = await _apiService.getTurnos();
      _turnos = turnosData.map((json) => Turno.fromJson(json)).toList();

      final deptosData = await _apiService.getDepartamentos();
      _departamentos = deptosData.map((json) => Departamento.fromJson(json)).toList();

      _catalogosCargados = true;
      print('Turnos cargados: ${_turnos.length}');
      print('Departamentos cargados: ${_departamentos.length}');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('Error al cargar catalogos: $_errorMessage');
      notifyListeners();
    }
  }

  /// Obtener el nombre de un turno por su ID
  /// Si los catalogos no están cargados, los carga automáticamente
  String getTurnoNombre(int? turnoId) {
    if (turnoId == null) return 'Sin asignar';
    
    if (_turnos.isEmpty && !_catalogosCargados) {
      loadCatalogos();
      return 'Cargando...';
    }
    
    try {
      final turno = _turnos.firstWhere((t) => t.id == turnoId);
      return turno.nombre;
    } catch (e) {
      return 'Sin asignar';
    }
  }

  /// Obtener el nombre de un departamento por su ID
  String getDepartamentoNombre(int? departamentoId) {
    if (departamentoId == null) return 'Sin asignar';
    
    if (_departamentos.isEmpty && !_catalogosCargados) {
      loadCatalogos();
      return 'Cargando...';
    }
    
    try {
      final depto = _departamentos.firstWhere((d) => d.id == departamentoId);
      return depto.nombre;
    } catch (e) {
      return 'Sin asignar';
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
  required String contrasena,  // Puede ser vacía
  String rol = 'user',
  String estado = 'active',
  int? departamentoId,
  int? turnoId,
}) async {
  _isLoading = true;
  _errorMessage = null;
  _contrasenaGenerada = null;
  notifyListeners();

  try {
    // Si la contraseña está vacía, enviar null para que el backend la genere
    final contrasenaFinal = contrasena.isEmpty ? null : contrasena;

    final result = await _apiService.createUser(
      numeroEmpleado: numeroEmpleado,
      nombre: nombre,
      apellido: apellido,
      contrasena: contrasenaFinal,  // Puede ser null
      rol: rol,
      estado: estado,
      departamentoId: departamentoId,
      turnoId: turnoId,
    );

    // Extraer la contraseña generada si existe
    if (result.containsKey('contrasena_generada')) {
      _contrasenaGenerada = result['contrasena_generada'] as String?;
    }

    // Convertir el mapa a User
    final newUser = User.fromJson(result);
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}