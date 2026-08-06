import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';

class EditUserScreen extends StatefulWidget {
  final User user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  String? _rolSeleccionado;
  String? _turnoSeleccionadoId;
  String? _departamentoSeleccionadoId;
  String? _estadoSeleccionado;

  final List<String> _roles = ['admin', 'cocinero', 'user'];
  final List<String> _estados = ['active', 'inactive'];

  @override
  void initState() {
    super.initState();
    // Cargar datos del usuario
    _nombreController.text = widget.user.nombre;
    _apellidoController.text = widget.user.apellido;
    _rolSeleccionado = widget.user.rol;
    _estadoSeleccionado = widget.user.estado;
    _turnoSeleccionadoId = widget.user.turnoId?.toString();
    _departamentoSeleccionadoId = widget.user.departamentoId?.toString();

    // Cargar catálogos si no están cargados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      if (provider.turnos.isEmpty) {
        provider.loadCatalogos();
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await userProvider.updateUser(
      numeroEmpleado: widget.user.numeroEmpleado,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      contrasena: _contrasenaController.text.isNotEmpty
          ? _contrasenaController.text.trim()
          : null,
      rol: _rolSeleccionado,
      estado: _estadoSeleccionado,
      turnoId: _turnoSeleccionadoId != null
          ? int.tryParse(_turnoSeleccionadoId!)
          : null,
      departamentoId: _departamentoSeleccionadoId != null
          ? int.tryParse(_departamentoSeleccionadoId!)
          : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.errorMessage ?? 'Error al actualizar usuario'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuario'),
        backgroundColor: const Color(0xFF20303D),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Número de empleado (solo lectura)
                TextFormField(
                  initialValue: widget.user.numeroEmpleado,
                  decoration: const InputDecoration(
                    labelText: 'Número de Empleado',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),

                // Nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Apellido
                TextFormField(
                  controller: _apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El apellido es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contraseña (opcional)
                TextFormField(
                  controller: _contrasenaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña (opcional)',
                    hintText: 'Dejar vacío para no cambiar',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Rol
                DropdownButtonFormField<String>(
                  value: _rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment_ind),
                  ),
                  items: _roles.map((rol) {
                    return DropdownMenuItem(
                      value: rol,
                      child: Text(rol),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _rolSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Estado
                DropdownButtonFormField<String>(
                  value: _estadoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.circle),
                  ),
                  items: _estados.map((estado) {
                    return DropdownMenuItem(
                      value: estado,
                      child: Text(estado == 'active' ? 'Activo' : 'Inactivo'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _estadoSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Turno
                DropdownButtonFormField<String>(
                  value: _turnoSeleccionadoId,
                  decoration: const InputDecoration(
                    labelText: 'Turno',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  hint: const Text('Selecciona un turno'),
                  items: userProvider.turnos.map((turno) {
                    return DropdownMenuItem(
                      value: turno.id.toString(),
                      child: Text(turno.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _turnoSeleccionadoId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Departamento
                DropdownButtonFormField<String>(
                  value: _departamentoSeleccionadoId,
                  decoration: const InputDecoration(
                    labelText: 'Departamento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  hint: const Text('Selecciona un departamento'),
                  items: userProvider.departamentos.map((depto) {
                    return DropdownMenuItem(
                      value: depto.id.toString(),
                      child: Text(depto.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _departamentoSeleccionadoId = value;
                    });
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: userProvider.isLoading ? null : _updateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20303D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: userProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Actualizar Usuario',
                          style: TextStyle(fontSize: 16),
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