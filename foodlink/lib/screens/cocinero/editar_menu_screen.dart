// lib/screens/cocinero/editar_menu_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/menu_model.dart';

class EditarMenuScreen extends StatefulWidget {
  final int menuId;
  const EditarMenuScreen({Key? key, required this.menuId}) : super(key: key);

  @override
  State<EditarMenuScreen> createState() => _EditarMenuScreenState();
}

class _EditarMenuScreenState extends State<EditarMenuScreen> {
  MenuSemanal? menu;
  bool isLoading = true;
  bool activo = true;

  @override
  void initState() {
    super.initState();
    cargarMenu();
  }

  Future<void> cargarMenu() async {
    try {
      final apiService = ApiService();
      final data = await apiService.obtenerMenuPorId(widget.menuId);
      setState(() {
        menu = MenuSemanal.fromJson(data);
        activo = menu?.activo ?? true;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Menú Semanal'),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : menu == null
              ? const Center(child: Text('Menú no encontrado'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Semana: ${menu!.semanaInicio.day}/${menu!.semanaInicio.month}/${menu!.semanaInicio.year} - ${menu!.semanaFin.day}/${menu!.semanaFin.month}/${menu!.semanaFin.year}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('Turno: ${menu!.turno}'),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: const Text('Menú Activo'),
                                value: activo,
                                onChanged: (value) {
                                  setState(() => activo = value);
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Platillos (Editables):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Mapeamos los platillos convirtiéndolos en formularios editables
                              ...menu!.items.map((item) {
                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  color: Colors.grey[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_capitalize(item.diaSemana)} - ${_capitalize(item.tipoComida)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Campo para editar el nombre del plato
                                        TextFormField(
                                          initialValue: item.nombre,
                                          decoration: const InputDecoration(
                                            labelText: 'Nombre del platillo',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (value) {
                                            item.nombre = value;
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            // Campo para editar el precio
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: item.precio.toString(),
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                  labelText: 'Precio (\$)',
                                                  border: OutlineInputBorder(),
                                                  isDense: true,
                                                ),
                                                onChanged: (value) {
                                                  item.precio = double.tryParse(value) ?? 0.0;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Switch para la disponibilidad individual
                                            Row(
                                              children: [
                                                const Text('Disponible'),
                                                Switch(
                                                  value: item.disponible,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      item.disponible = value;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _actualizarMenu,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Actualizar Menú',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _actualizarMenu() async {
    try {
      final List<Map<String, dynamic>> itemsPayload = menu!.items.map((item) {
        return {
          'dia_semana': item.diaSemana,
          'tipo_comida': item.tipoComida,
          'nombre_plato': item.nombre,
          'descripcion': item.descripcion,
          'ingredientes': item.ingredientes,
          'imagen_url': item.imagenUrl,
          'limite_porciones': item.limitePorciones,
          'precio': item.precio,
          'disponible': item.disponible,
        };
      }).toList();

      final Map<String, dynamic> body = {
        'activo': activo,
        'turno': menu!.turno,
        'semana_inicio': menu!.semanaInicio.toIso8601String().split('T')[0],
        'semana_fin': menu!.semanaFin.toIso8601String().split('T')[0],
        'items': itemsPayload,
      };

      final apiService = ApiService();
      await apiService.actualizarMenu(widget.menuId, body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menú actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}