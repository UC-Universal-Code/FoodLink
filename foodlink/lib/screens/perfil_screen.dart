// lib/screens/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoadingPerfil = true;

  final _formKey = GlobalKey<FormState>();
  final _contrasenaActualController = TextEditingController();
  final _nuevaContrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();

  bool _isLoading = false;
  bool _showChangePassword = false;
  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPerfil();
    });
  }

  Future<void> _cargarPerfil() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (userProvider.turnos.isEmpty || userProvider.departamentos.isEmpty) {
        await userProvider.loadCatalogos();
      }

      await authProvider.refreshUser();

      if (mounted) {
        setState(() {
          _isLoadingPerfil = false;
        });
      }
    } catch (e) {
      print('Error al cargar perfil: $e');
      if (mounted) {
        setState(() {
          _isLoadingPerfil = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _contrasenaActualController.dispose();
    _nuevaContrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  Future<void> _cambiarContrasena() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nuevaContrasenaController.text != _confirmarContrasenaController.text) {
      setState(() {
        _errorMessage = 'Las contrasenas no coinciden';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      final contrasenaActual = (user?.esTemporal == true)
          ? ''
          : _contrasenaActualController.text.trim();

      final response = await _apiService.cambiarContrasena(
        contrasenaActual: contrasenaActual,
        nuevaContrasena: _nuevaContrasenaController.text.trim(),
      );

      // Procesar la respuesta
      if (response != null && response is Map<String, dynamic>) {
        if (response.containsKey('usuario') && response['usuario'] != null) {
          final userData = response['usuario'] as Map<String, dynamic>;
          try {
            final updatedUser = User.fromJson(userData);
            authProvider.updateCurrentUser(updatedUser);
          } catch (e) {
            // Si falla al parsear el usuario, recargar desde el backend
            print('Error al parsear usuario: $e');
            await authProvider.refreshUser();
          }
        } else {
          await authProvider.refreshUser();
        }
      } else {
        await authProvider.refreshUser();
      }

      setState(() {
        _isLoading = false;
        _successMessage = 'Contrasena actualizada exitosamente';
        _errorMessage = null;
        _showChangePassword = false;
        _contrasenaActualController.clear();
        _nuevaContrasenaController.clear();
        _confirmarContrasenaController.clear();
      });

      authProvider.clearError();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contrasena actualizada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Capturar cualquier error y mostrar un mensaje amigable
      String errorMsg = 'Ocurrió un error al cambiar la contraseña. Intenta nuevamente.';
      if (e.toString().contains('incorrecta')) {
        errorMsg = 'Contraseña actual incorrecta.';
      } else if (e.toString().contains('caracteres')) {
        errorMsg = 'La nueva contraseña debe tener al menos 8 caracteres.';
      } else if (e.toString().contains('mayuscula')) {
        errorMsg = 'La nueva contraseña debe tener al menos una mayúscula.';
      } else if (e.toString().contains('minuscula')) {
        errorMsg = 'La nueva contraseña debe tener al menos una minúscula.';
      } else if (e.toString().contains('numero')) {
        errorMsg = 'La nueva contraseña debe tener al menos un número.';
      } else if (e.toString().contains('especial')) {
        errorMsg = 'La nueva contraseña debe tener al menos un carácter especial.';
      }
      setState(() {
        _errorMessage = errorMsg;
        _successMessage = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = authProvider.currentUser;

    if (_isLoadingPerfil) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil'),
          backgroundColor: const Color(0xFF20303D),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final String turnoNombre =
        userProvider.getTurnoNombre(user?.turnoId) ?? 'Sin asignar';
    final String departamentoNombre =
        userProvider.getDepartamentoNombre(user?.departamentoId) ?? 'Sin asignar';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF20303D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF20303D),
              child: Text(
                (user != null && user.nombre.isNotEmpty)
                    ? user.nombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              (user != null)
                  ? '${user.nombre} ${user.apellido}'
                  : 'Usuario FoodLink',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                'N° Empleado: ${user?.numeroEmpleado ?? 'N/A'}',
                style: const TextStyle(color: Color(0xFF20303D)),
              ),
              backgroundColor: const Color(0xFF20303D).withOpacity(0.1),
            ),
            const SizedBox(height: 8),
            if (user?.esTemporal == true)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Contrasena temporal - Debes cambiarla',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge, color: Color(0xFF20303D)),
                    title: const Text('Rol en el sistema'),
                    subtitle: Text(_getRolLabel(user?.rol ?? 'user')),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.business, color: Color(0xFF20303D)),
                    title: const Text('Departamento'),
                    subtitle: Text(
                      departamentoNombre,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule, color: Color(0xFF20303D)),
                    title: const Text('Turno'),
                    subtitle: Text(
                      turnoNombre,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showChangePassword = !_showChangePassword;
                  _errorMessage = null;
                  _successMessage = null;
                });
              },
              icon: Icon(
                _showChangePassword ? Icons.lock_open : Icons.lock,
                color: const Color(0xFF20303D),
              ),
              label: Text(
                _showChangePassword ? 'Cancelar cambio' : 'Cambiar contrasena',
                style: const TextStyle(color: Color(0xFF20303D)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF20303D)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (_showChangePassword)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (user?.esTemporal != true)
                        TextFormField(
                          controller: _contrasenaActualController,
                          obscureText: _obscureActual,
                          decoration: InputDecoration(
                            labelText: 'Contrasena Actual',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureActual
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureActual = !_obscureActual;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contrasena actual';
                            }
                            return null;
                          },
                        ),

                      if (user?.esTemporal == true)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Estas usando una contrasena temporal. '
                                  'No necesitas ingresar la actual.',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nuevaContrasenaController,
                        obscureText: _obscureNueva,
                        decoration: InputDecoration(
                          labelText: 'Nueva Contrasena',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNueva
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNueva = !_obscureNueva;
                              });
                            },
                          ),
                          helperText:
                              'Minimo 8 caracteres, mayuscula, minuscula, '
                              'numero y especial',
                          helperMaxLines: 2,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La contrasena es obligatoria';
                          }
                          if (value.length < 8) {
                            return 'Minimo 8 caracteres';
                          }
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return 'Debe tener al menos una mayuscula';
                          }
                          if (!value.contains(RegExp(r'[a-z]'))) {
                            return 'Debe tener al menos una minuscula';
                          }
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return 'Debe tener al menos un numero';
                          }
                          if (!value.contains(
                              RegExp(r'[!@#$%^&*(),.?":{}<>|]'))) {
                            return 'Debe tener al menos un caracter especial';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmarContrasenaController,
                        obscureText: _obscureConfirmar,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Contrasena',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmar
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmar = !_obscureConfirmar;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirma tu contrasena';
                          }
                          if (value != _nuevaContrasenaController.text) {
                            return 'Las contrasenas no coinciden';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      if (_successMessage != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _cambiarContrasena,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF20303D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Actualizar Contrasena',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                onPressed: () async {
                  await _apiService.logout();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cerrar Sesion',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRolLabel(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'cocinero':
        return 'Cocinero';
      case 'user':
        return 'Usuario';
      default:
        return rol;
    }
  }
}