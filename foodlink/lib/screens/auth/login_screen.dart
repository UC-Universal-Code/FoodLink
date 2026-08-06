import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _empleadoIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _empleadoIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      _empleadoIdController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _timer?.cancel();
      final user = authProvider.currentUser;
      if (user != null) {
        switch (user.rol) {
          case 'admin':
            Navigator.pushReplacementNamed(context, '/admin');
            break;
          case 'cocinero':
            Navigator.pushReplacementNamed(context, '/cocinero');
            break;
          case 'user':
            Navigator.pushReplacementNamed(context, '/trabajador');
            break;
          default:
            Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } else {
      final errorMsg = authProvider.errorMessage ?? 'Error al iniciar sesion';
      
      // Si está bloqueado, el temporizador ya se está actualizando
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: authProvider.isBloqueado ? Colors.orange : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    
    if (authProvider.isBloqueado && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Actualizar la UI cada segundo
        if (mounted) {
          // Forzar la actualización del provider
          final provider = Provider.of<AuthProvider>(context, listen: false);
          provider.notifyListeners();
        }
      });
    }

    
    if (!authProvider.isBloqueado && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant,
                  size: 80,
                  color: const Color(0xFF20303D),
                ),
                const SizedBox(height: 16),
                Text(
                  'FoodLink',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF20303D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestion de Cafeteria',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _empleadoIdController,
                  decoration: InputDecoration(
                    labelText: 'Numero de Empleado',
                    hintText: 'Ej: admin',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabled: !authProvider.isBloqueado,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El numero de empleado es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contrasena',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabled: !authProvider.isBloqueado,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contrasena es obligatoria';
                    }
                    if (value.length < 6) {
                      return 'La contrasena debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Mostrar intentos restantes
                if (authProvider.intentosFallidos > 0 && !authProvider.isBloqueado)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      'Intentos restantes: ${3 - authProvider.intentosFallidos}',
                      style: TextStyle(
                        color: (3 - authProvider.intentosFallidos) <= 1 
                            ? Colors.red 
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Mostrar bloqueo con temporizador
                if (authProvider.isBloqueado)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Cuenta bloqueada',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tiempo restante: ${authProvider.tiempoRestante}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _calcularProgreso(authProvider.tiempoRestante),
                          backgroundColor: Colors.grey.shade200,
                          color: Colors.red.shade700,
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading || authProvider.isBloqueado
                        ? null 
                        : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20303D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Iniciar Sesion',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Sistema exclusivo para personal autorizado',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _calcularProgreso(String tiempoRestante) {
    if (tiempoRestante.isEmpty) return 0;
    final partes = tiempoRestante.split(':');
    if (partes.length != 2) return 0;
    
    final minutos = int.tryParse(partes[0]) ?? 0;
    final segundos = int.tryParse(partes[1]) ?? 0;
    final totalSegundos = minutos * 60 + segundos;
    
    
    final maxSegundos = 60; // 1 minuto
    final progreso = 1 - (totalSegundos / maxSegundos);
    
    return progreso.clamp(0.0, 1.0);
  }
}