import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _futurePerfil;

  @override
  void initState() {
    super.initState();
    _futurePerfil = _apiService.obtenerPerfil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF20303D),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futurePerfil,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar perfil: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No se encontraron datos del usuario.'));
          }

          final perfil = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF20303D),
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  perfil['nombre'] ?? 'Usuario FoodLink',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text('Nº Empleado: ${perfil['numero_empleado'] ?? 'N/A'}'),
                  backgroundColor: Colors.blue.shade100,
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.badge, color: Color(0xFF20303D)),
                    title: const Text('Rol en el sistema'),
                    subtitle: Text(perfil['rol'] ?? 'Trabajador'),
                  ),
                ),
                // Aquí puedes agregar más opciones si deseas (ej. cambiar contraseña)
              ],
            ),
          );
        },
      ),
    );
  }
}