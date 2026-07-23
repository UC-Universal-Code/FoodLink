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
                  subtitle: Text('Turno: ${menu['turno'] ?? 'General'} | Del ${menu['seman_inicio'] ?? ''} al ${menu['semana_fin'] ?? ''}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    final items = menu['items'] as List<dynamic>? ?? [];
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          children: [
                            const Icon(Icons.restaurant_menu, color: Color(0xFF20303D)),
                            const SizedBox(width: 8),
                            Text('Menú #${menu['id']}'),
                          ],
                        ),
                        content: SizedBox(
                          width: 400,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildInfoRow('Turno:', menu['turno'] ?? 'N/A'),
                                _buildInfoRow('Semana:', '${menu['semana_inicio']} al ${menu['semana_fin']}'),
                                _buildInfoRow('Creado por:', menu['creado_por'] ?? 'N/A'),
                                _buildInfoRow('Estado:', (menu['activo'] == true) ? 'Activo' : 'Inactivo'),
                                const Divider(height: 24),
                                const Text(
                                  'Platillos / Items:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF20303D)),
                                ),
                                const SizedBox(height: 8),
                                if (items.isEmpty)
                                  const Text('No hay platillos registrados para este menú.')
                                else
                                  ...items.map((item) => Card(
                                        color: Colors.grey[100],
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${item['dia_semana']?.toUpperCase()} - ${item['tipo_comida']}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF20303D)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text('Plato: ${item['nombre_plato']}'),
                                              Text('Descripción: ${item['descripcion']}'),
                                              Text('Ingredientes: ${item['ingredientes']}'),
                                            ],
                                          ),
                                        ),
                                      )),
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF20303D),
                              foregroundColor: Colors.white,
                            ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey[700]))),
        ],
      ),
    );
  }
}