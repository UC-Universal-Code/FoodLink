import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String numeroEmpleado, String contrasena) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.login(numeroEmpleado, contrasena);
      _currentUser = await _apiService.getCurrentUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMessage = e.toString();
      
      // Mensajes limpios según el tipo de error
      if (errorMessage.contains('Cuenta desactivada')) {
        _errorMessage = 'Cuenta desactivada. Contacta al administrador.';
      } else if (errorMessage.contains('incorrectos')) {
        _errorMessage = 'Numero de empleado o contrasena incorrectos';
      } else if (errorMessage.contains('conexion') || 
                 errorMessage.contains('timeout') ||
                 errorMessage.contains('connection')) {
        _errorMessage = 'Error de conexion. Verifica el servidor.';
      } else {
        _errorMessage = 'Error al iniciar sesion. Intenta mas tarde.';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}