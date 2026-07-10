// lib/providers/auth_provider.dart

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

  /// Iniciar sesión
  Future<bool> login(String numeroEmpleado, String contrasena) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Iniciar sesión y obtener token
      await _apiService.login(numeroEmpleado, contrasena);

      // 2. Obtener datos del usuario actual
      _currentUser = await _apiService.getCurrentUser();

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

  /// Cerrar sesión
  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}