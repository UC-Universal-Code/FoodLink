import 'package:flutter/material.dart';

/// Pantalla principal de FoodLink
/// Muestra el menú del día según el rol del usuario
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FoodLink'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Cerrar sesión (futura funcionalidad)
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
            // Saludo
            Text(
              '¡Bienvenido!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Menú del día - Turno Matutino',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Tarjetas de platillos (Mock)
            _buildPlatilloCard(
              'Tacos de Carnitas',
              'Tortillas de maíz con carnitas, cebolla y cilantro',
            ),
            const SizedBox(height: 12),
            _buildPlatilloCard(
              'Sopa de Verduras',
              'Caldo de verduras frescas con fideos',
            ),
            const SizedBox(height: 12),
            _buildPlatilloCard(
              'Ensalada César',
              'Lechuga, pollo, crutones y aderezo César',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menú',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Reportar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        selectedItemColor: Colors.orange[700],
        unselectedItemColor: Colors.grey[600],
      ),
    );
  }

  Widget _buildPlatilloCard(String nombre, String descripcion) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.fastfood,
          color: Colors.orange,
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(descripcion),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Detalle del platillo (futura funcionalidad)
        },
      ),
    );
  }
}