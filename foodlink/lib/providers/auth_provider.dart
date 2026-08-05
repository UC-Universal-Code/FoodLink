// lib/providers/auth_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  int _intentosFallidos = 0;
  bool _bloqueado = false;
  String _tiempoRestante = '';
  Timer? _timer;
  DateTime? _bloqueoHasta;
  bool? get esTemporal => _currentUser?.esTemporal;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isBloqueado => _bloqueado;
  String get tiempoRestante => _tiempoRestante;
  int get intentosFallidos => _intentosFallidos;

  /// Recargar los datos del usuario actual
  Future<void> refreshUser() async {
    try {
      _currentUser = await _apiService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('Error al refrescar usuario: $e');
    }
  }

  /// Actualizar el usuario actual con nuevos datos
  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> login(String numeroEmpleado, String contrasena) async {
    _isLoading = true;
    _errorMessage = null;
    _bloqueado = false;
    _tiempoRestante = '';
    _bloqueoHasta = null;
    _timer?.cancel();
    notifyListeners();

    try {
      await _apiService.login(numeroEmpleado, contrasena);
      _currentUser = await _apiService.getCurrentUser();
      _intentosFallidos = 0;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error capturado: $errorMessage');
      
      if (errorMessage.contains('bloqueada') || 
          errorMessage.contains('bloqueado') ||
          errorMessage.contains('Tiempo restante')) {
        _bloqueado = true;
        
        final match = RegExp(r'Tiempo restante: (\d+):(\d+)').firstMatch(errorMessage);
        if (match != null) {
          final minutos = int.parse(match.group(1)!);
          final segundos = int.parse(match.group(2)!);
          final totalSegundos = minutos * 60 + segundos;
          _bloqueoHasta = DateTime.now().add(Duration(seconds: totalSegundos));
          _tiempoRestante = '$minutos:${segundos.toString().padLeft(2, '0')}';
          _errorMessage = 'Cuenta bloqueada. Tiempo restante: $_tiempoRestante';
        } else {
          _bloqueoHasta = DateTime.now().add(const Duration(minutes: 1));
          _tiempoRestante = '1:00';
          _errorMessage = 'Cuenta bloqueada por 15 minutos';
        }
        
        _iniciarTemporizador();
        _intentosFallidos = 0;
      } else if (errorMessage.contains('Cuenta desactivada') || errorMessage.contains('desactivada')) {
        _errorMessage = 'Cuenta desactivada. Contacta al administrador.';
      } else if (errorMessage.contains('incorrectos') || errorMessage.contains('Incorrectos')) {
        _intentosFallidos++;
        print('Intentos fallidos: $_intentosFallidos');

        if (_intentosFallidos >= 3) {
          _bloqueado = true;
          _bloqueoHasta = DateTime.now().add(const Duration(minutes: 1));
          _tiempoRestante = '1:00';
          _errorMessage = 'Cuenta bloqueada temporalmente por exceso de intentos.';
          _iniciarTemporizador();
        } else {
          final restantes = 3 - _intentosFallidos;
          _errorMessage = 'Numero de empleado o contrasena incorrectos. Te quedan $restantes intentos.';
        }
      } else {
        _errorMessage = errorMessage;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _iniciarTemporizador() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_bloqueoHasta == null) {
        timer.cancel();
        return;
      }

      final ahora = DateTime.now();
      final diferencia = _bloqueoHasta!.difference(ahora);

      if (diferencia.isNegative || diferencia.inSeconds <= 0) {
        _bloqueado = false;
        _tiempoRestante = '';
        _bloqueoHasta = null;
        _timer?.cancel();
        _timer = null;
        _intentosFallidos = 0;
        _errorMessage = null;
        notifyListeners();
        return;
      }

      final minutos = diferencia.inMinutes;
      final segundos = diferencia.inSeconds % 60;
      _tiempoRestante = '$minutos:${segundos.toString().padLeft(2, '0')}';
      notifyListeners();
    });
  }

  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    _intentosFallidos = 0;
    _bloqueado = false;
    _tiempoRestante = '';
    _bloqueoHasta = null;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}