import 'package:flutter/material.dart';
import '../../data/mock_users.dart';
import '../../models/user.dart';

//// Pantalla de inicio de sesión de FoodLink
/// 
/// Caso de uso: C1 - Iniciar sesión
/// 
/// Esta pantalla implementa validaciones de seguridad:
/// - validación de ID de empleado con formato y obligatoriedad
/// - validación de contraseña con mínimo 8 caracteres
/// - manejo de errores con mensajes genéricos
/// - protección contra ataques de fuerza bruta con bloqueo temporal
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
  bool _isLoading = false;
  int _intentosFallidos = 0;
  bool _bloqueado = false;

  @override
  void dispose() {
    _empleadoIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_bloqueado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta bloqueada temporalmente. Espera 30 segundos.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      final empleadoId = _empleadoIdController.text.trim();
      final password = _passwordController.text.trim();

      final User? usuario = MockUsers.authenticate(empleadoId, password);

      if (usuario != null) {
        if (!usuario.activo) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(' Cuenta desactivada. Contacta al administrador.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bienvenido ${usuario.nombre}'),
              backgroundColor: Colors.green,
            ),
          );

          switch (usuario.rol) {
            case 'admin':
              Navigator.pushReplacementNamed(context, '/admin');
              break;
            case 'cocinero':
              Navigator.pushReplacementNamed(context, '/cocinero');
              break;
            case 'trabajador':
              Navigator.pushReplacementNamed(context, '/trabajador');
              break;
            default:
              Navigator.pushReplacementNamed(context, '/login');
          }
        }
        return;
      }

      setState(() {
        _intentosFallidos++;
        if (_intentosFallidos >= 3) {
          _bloqueado = true;
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) {
              setState(() {
                _bloqueado = false;
                _intentosFallidos = 0;
              });
            }
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _intentosFallidos >= 3
                  ? ' Demasiados intentos. Cuenta bloqueada 30 segundos.'
                  : ' ID de empleado o contraseña incorrectos',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al iniciar sesión. Intenta más tarde.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      print('Error en login: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Gestión de Cafetería',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _empleadoIdController,
                  decoration: InputDecoration(
                    labelText: 'ID de Empleado',
                    hintText: 'Ej: ADMIN-001',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabled: !_bloqueado && !_isLoading,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El ID de empleado es obligatorio';
                    }
                    if (value.length < 4) {
                      return 'El ID debe tener al menos 4 caracteres';
                    }
                    final RegExp regex = RegExp(r'^[a-zA-Z0-9\-_]+$');
                    if (!regex.hasMatch(value)) {
                      return 'El ID solo puede contener letras, números, - y _';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabled: !_bloqueado && !_isLoading,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es obligatoria';
                    }
                    if (value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'La contraseña debe tener al menos un número';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'La contraseña debe tener al menos una mayúscula';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading || _bloqueado
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Contacta al administrador para restablecer tu contraseña',
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _bloqueado) ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20303D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_intentosFallidos > 0 && !_bloqueado)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Intentos restantes: ${3 - _intentosFallidos}',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ),

                if (_bloqueado)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: Colors.red, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Cuenta bloqueada por 30 segundos',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

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
}