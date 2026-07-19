import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';
import 'create_user_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestionar Usuarios',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF20303D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateUserScreen(),
                ),
              ).then((_) {
                userProvider.fetchUsers();
              });
            },
            tooltip: 'Agregar usuario',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: _buildBody(userProvider),
      ),
    );
  }

  Widget _buildBody(UserProvider userProvider) {
    if (userProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF20303D),
        ),
      );
    }

    if (userProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar usuarios',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userProvider.errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                userProvider.fetchUsers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20303D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (userProvider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay usuarios registrados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona el boton + para crear uno',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: userProvider.users.length,
      itemBuilder: (context, index) {
        final user = userProvider.users[index];
        return _buildUserCard(user, context);
      },
    );
  }

  Widget _buildUserCard(User user, BuildContext context) {
    final Color primaryColor = const Color(0xFF20303D);

    Color rolColor;
    String rolLabel;
    IconData rolIcon;

    switch (user.rol) {
      case 'admin':
        rolColor = const Color(0xFF6C63FF);
        rolLabel = 'Administrador';
        rolIcon = Icons.admin_panel_settings;
        break;
      case 'cocinero':
        rolColor = const Color(0xFFFF8A65);
        rolLabel = 'Cocinero';
        rolIcon = Icons.restaurant;
        break;
      case 'trabajador':
        rolColor = const Color(0xFF4FC3F7);
        rolLabel = 'Trabajador';
        rolIcon = Icons.engineering;
        break;
      case 'user':
        rolColor = const Color(0xFF81C784);
        rolLabel = 'Usuario';
        rolIcon = Icons.person;
        break;
      default:
        rolColor = Colors.grey;
        rolLabel = user.rol;
        rolIcon = Icons.person_outline;
    }

    Color estadoColor = user.estado == 'active'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE57373);
    String estadoLabel = user.estado == 'active' ? 'Activo' : 'Inactivo';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showUserDetails(context, user),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(
                  user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.nombre} ${user.apellido}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF20303D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'N° Empleado: ${user.numeroEmpleado}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: rolColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                rolIcon,
                                size: 14,
                                color: rolColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rolLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: rolColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: estadoColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: estadoColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                estadoLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: estadoColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (user.rol != 'admin')
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.person_remove,
                      color: Color(0xFFE53935),
                      size: 24,
                    ),
                    onPressed: () => _confirmDeactivate(context, user),
                    tooltip: 'Desactivar usuario',
                    splashRadius: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Desactivar usuario',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF20303D),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estas seguro de que quieres desactivar a ${user.nombre} ${user.apellido}?\n\nEl usuario no podra iniciar sesion hasta que sea reactivado.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${user.nombre} ${user.apellido} desactivado',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              Provider.of<UserProvider>(context, listen: false).fetchUsers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF20303D).withOpacity(0.1),
              radius: 20,
              child: Text(
                user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF20303D),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${user.nombre} ${user.apellido}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF20303D),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.badge, 'N° Empleado', user.numeroEmpleado),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.admin_panel_settings, 'Rol', user.rol),
            const SizedBox(height: 8),
            _buildDetailRow(
              user.estado == 'active' ? Icons.check_circle : Icons.cancel,
              'Estado',
              user.estado == 'active' ? 'Activo' : 'Inactivo',
              color: user.estado == 'active' ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.numbers, 'ID', user.id.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF20303D),
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color color = Colors.grey}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color == Colors.grey ? const Color(0xFF20303D) : color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}