import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _numeroEmpleadoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  String? _rolSeleccionado;
  String? _turnoSeleccionadoId;
  String? _departamentoSeleccionadoId;

  // Roles del backend: admin, cocinero, user
  final List<Map<String, dynamic>> _roles = [
    {'value': 'admin', 'label': 'Administrador'},
    {'value': 'cocinero', 'label': 'Cocinero'},
    {'value': 'user', 'label': 'Usuario'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadCatalogos();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _numeroEmpleadoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rolSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un rol'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_turnoSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un turno'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_departamentoSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un departamento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await userProvider.createUser(
      numeroEmpleado: _numeroEmpleadoController.text.trim(),
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      contrasena: _contrasenaController.text.trim(),
      rol: _rolSeleccionado!,
      estado: 'active',
      turnoId: int.tryParse(_turnoSeleccionadoId!),
      departamentoId: int.tryParse(_departamentoSeleccionadoId!),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.errorMessage ?? 'Error al crear usuario'),
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
        title: const Text('Crear Usuario'),
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
                // Numero de empleado
                TextFormField(
                  controller: _numeroEmpleadoController,
                  decoration: const InputDecoration(
                    labelText: 'Numero de Empleado',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El numero de empleado es obligatorio';
                    }
                    if (value.length < 3) {
                      return 'Minimo 3 caracteres';
                    }
                    return null;
                  },
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

                // Contrasena
                TextFormField(
                  controller: _contrasenaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contrasena',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contrasena es obligatoria';
                    }
                    if (value.length < 6) {
                      return 'Minimo 6 caracteres';
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
                  hint: const Text('Selecciona un rol'),
                  items: _roles.map((rol) {
                    return DropdownMenuItem(
                      value: rol['value'] as String,
                      child: Text(rol['label'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _rolSeleccionado = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecciona un rol';
                    }
                    return null;
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecciona un turno';
                    }
                    return null;
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecciona un departamento';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Boton guardar
                ElevatedButton(
                  onPressed: userProvider.isLoading ? null : _createUser,
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
                          'Guardar Usuario',
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