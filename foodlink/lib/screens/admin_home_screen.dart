import 'package:flutter/material.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FoodLink - Administrador'),
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
            const Text(
              'Panel de Administración',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF20303D),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Funcionalidades disponibles:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              context,
              icon: Icons.people,
              title: 'Gestionar Usuarios',
              subtitle: 'Alta, baja y modificación de usuarios',
              color: const Color(0xFF20303D),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad: Gestión de usuarios (C3, C9)'),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.report,
              title: 'Gestionar Incidencias',
              subtitle: 'Revisar y dar seguimiento a reportes',
              color: const Color(0xFF20303D),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad: Gestión de incidencias (C8)'),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.restaurant_menu,
              title: 'Ver Menús',
              subtitle: 'Consultar menús de todos los turnos',
              color: const Color(0xFF20303D),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad: Visualización de menús (C6)'),
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