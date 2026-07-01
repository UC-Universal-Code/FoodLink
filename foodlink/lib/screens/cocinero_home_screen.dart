import 'package:flutter/material.dart';

class CocineroHome extends StatelessWidget {
  const CocineroHome({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Panel del Cocinero',
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
              icon: Icons.add,
              title: 'Crear Menú Semanal',
              subtitle: 'Registrar platillos para la semana (C4)',
              color: const Color(0xFF20303D),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad: Crear menú semanal (C4)'),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.edit,
              title: 'Editar Menú',
              subtitle: 'Modificar platillos del menú (C5)',
              color: const Color(0xFF20303D),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad: Editar menú (C5)'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad: Visualizar menú (C6)'),
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