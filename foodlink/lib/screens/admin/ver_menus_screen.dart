import 'package:flutter/material.dart';
import 'package:foodlink/services/api_service.dart';

class VerMenusScreen extends StatefulWidget {
  const VerMenusScreen({super.key});

  @override
  State<VerMenusScreen> createState() => _VerMenusScreenState();
}

class _VerMenusScreenState extends State<VerMenusScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _menusFuture;

  @override
  void initState() {
    super.initState();
    _menusFuture = _apiService.obtenerTodosLosMenusAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menús Registrados'),
        backgroundColor: const Color(0xFF20303D),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _menusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error al cargar menús: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay menús registrados actualmente.'));
          }

          final menus = snapshot.data!;
          return ListView.builder(
            itemCount: menus.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final menu = menus[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.restaurant, color: Color(0xFF20303D), size: 32),
                  title: Text(
                    'Menú ID: ${menu['id'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Turno / Detalle: ${menu['turno_id'] ?? 'General'}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Detalles del Menú #${menu['id'] ?? 'N/A'}'),
                        content: SingleChildScrollView(
                          child: Text(
                            menu.toString(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
