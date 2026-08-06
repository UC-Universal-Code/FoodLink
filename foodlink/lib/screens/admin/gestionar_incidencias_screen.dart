import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class GestionarIncidenciasScreen extends StatefulWidget {
  const GestionarIncidenciasScreen({super.key});

  @override
  State<GestionarIncidenciasScreen> createState() => _GestionarIncidenciasScreenState();
}

class _GestionarIncidenciasScreenState extends State<GestionarIncidenciasScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _futureReportes;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  void _cargarReportes() {
    setState(() {
      _futureReportes = _apiService.obtenerReportes();
    });
  }

  void _mostrarOpciones(Map<String, dynamic> reporte) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestionar: ${reporte['titulo']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Cambiar estado:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade100),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _apiService.actualizarEstadoReporte(reporte['id'], 'Pendiente');
                      _cargarReportes();
                    },
                    child: const Text('Pendiente'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _apiService.actualizarEstadoReporte(reporte['id'], 'Cumplido');
                      _cargarReportes();
                    },
                    child: const Text('Cumplido'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _apiService.actualizarEstadoReporte(reporte['id'], 'Rechazado');
                      _cargarReportes();
                    },
                    child: const Text('Rechazado'),
                  ),
                ],
              ),
              const Divider(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar Reporte'),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _apiService.eliminarReporte(reporte['id']);
                    _cargarReportes();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Incidencias'),
        backgroundColor: const Color(0xFF20303D),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureReportes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay incidencias registradas.'));
          }

          final reportes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final reporte = reportes[index];
              
              Color chipColor = Colors.orange.shade100;
              if (reporte['estado'] == 'Cumplido') chipColor = Colors.green.shade100;
              if (reporte['estado'] == 'Rechazado') chipColor = Colors.red.shade100;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(reporte['titulo'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(reporte['descripcion'] ?? ''),
                      const SizedBox(height: 8),
                      Text('Empleado: ${reporte['numero_empleado']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(reporte['estado'] ?? 'Pendiente'),
                    backgroundColor: chipColor,
                  ),
                  onTap: () => _mostrarOpciones(reporte),
                ),
              );
            },
          );
        },
      ),
    );
  }
}