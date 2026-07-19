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
                                'Platillos:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...menu!.items.map((item) => ListTile(
                                dense: true,
                                leading: Icon(
                                  item.disponible ? Icons.check_circle : Icons.cancel,
                                  color: item.disponible ? Colors.green : Colors.red,
                                ),
                                title: Text(item.nombre),
                                subtitle: Text('${_capitalize(item.diaSemana)} - ${_capitalize(item.tipoComida)}'),
                                trailing: Text('\$${item.precio.toStringAsFixed(2)}'),
                              )),
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
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _actualizarMenu() async {
    try {
      final menuActualizado = MenuSemanal(
        id: menu!.id,
        semanaInicio: menu!.semanaInicio,
        semanaFin: menu!.semanaFin,
        turno: menu!.turno,
        activo: activo,
        creadoPor: menu!.creadoPor,
        creadoEn: menu!.creadoEn,
        actualizadoEn: menu!.actualizadoEn,
        items: menu!.items,
      );
      
      final apiService = ApiService();
      await apiService.actualizarMenu(widget.menuId, menuActualizado.toJson());
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menú actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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