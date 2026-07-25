import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'cocinero/crear_menu_screen.dart';
import 'cocinero/mis_menus_screen.dart';

class CocineroHome extends StatelessWidget {
  const CocineroHome({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = authProvider.currentUser;
    
    String nombreCompleto = user != null 
        ? '${user.nombre} ${user.apellido}' 
        : 'Cocinero';
    
    // Obtener el nombre del turno desde UserProvider
    String turno = userProvider.getTurnoNombre(user?.turnoId) ?? 'Sin turno asignado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('FoodLink - Cocinero'),
        backgroundColor: const Color(0xFF20303D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del cocinero
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF20303D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido, $nombreCompleto',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF20303D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: Color(0xFF20303D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Turno asignado: $turno',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF20303D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Funcionalidades disponibles:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              context,
              icon: Icons.add,
              title: 'Crear Menú Semanal',
              subtitle: 'Registrar platillos para la semana',
              color: const Color(0xFF20303D),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CrearMenuScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.edit,
              title: 'Editar Menú',
              subtitle: 'Modificar platillos del menú',
              color: const Color(0xFF20303D),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MisMenusScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.visibility,
              title: 'Ver Mi Menú',
              subtitle: 'Consultar menú publicado',
              color: const Color(0xFF20303D),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MisMenusScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}