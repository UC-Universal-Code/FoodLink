import 'package:flutter/material.dart';

class TrabajadorHome extends StatelessWidget {
  const TrabajadorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FoodLink - Trabajador'),
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
              'Menú del Día',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF20303D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Turno Matutino - Lunes 23 de Junio',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildPlatilloCard(
                    nombre: 'Tacos de Carnitas',
                    descripcion: 'Tortillas de maíz con carnitas, cebolla y cilantro',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Detalles del platillo'),
                        ),
                      );
                    },
                  ),
                  _buildPlatilloCard(
                    nombre: 'Sopa de Verduras',
                    descripcion: 'Caldo de verduras frescas con fideos',
                    onTap: () {},
                  ),
                  _buildPlatilloCard(
                    nombre: 'Ensalada César',
                    descripcion: 'Lechuga, pollo, crutones y aderezo César',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidad: Reportar incidencia (C7)'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20303D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Reportar Incidencia'),
              ),
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
        selectedItemColor: const Color(0xFF20303D),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Funcionalidad: Reportar incidencia (C7)'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPlatilloCard({
    required String nombre,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.fastfood, color: Color(0xFF20303D)),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(descripcion),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}