// lib/screens/cocinero/mis_menus_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/menu_model.dart';
import 'crear_menu_screen.dart';
import 'editar_menu_screen.dart';

class MisMenusScreen extends StatefulWidget {
  const MisMenusScreen({Key? key}) : super(key: key);

  @override
  State<MisMenusScreen> createState() => _MisMenusScreenState();
}

class _MisMenusScreenState extends State<MisMenusScreen> {
  List<MenuSemanal> menus = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarMenus();
  }

  Future<void> cargarMenus() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    
    try {
      final apiService = ApiService();
      final data = await apiService.obtenerMisMenus();
      setState(() {
        menus = data.map((e) => MenuSemanal.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Menús Semanales'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarMenus,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: cargarMenus,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : menus.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No has creado menús aún',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Crea tu primer menú semanal',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CrearMenuScreen(),
                                ),
                              ).then((_) => cargarMenus());
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Crear Menú'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: menus.length,
                      itemBuilder: (context, index) {
                        final menu = menus[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          child: ListTile(
                            title: Text(
                              '${_formatDate(menu.semanaInicio)} - ${_formatDate(menu.semanaFin)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Turno: ${menu.turno}'),
                                Text('Platillos: ${menu.items.length}'),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: menu.activo ? Colors.green : Colors.grey,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    menu.activo ? 'Activo' : 'Inactivo',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Colors.blue),
                                  onPressed: () {
                                    _mostrarDetalleMenu(context, menu);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditarMenuScreen(menuId: menu.id!),
                                      ),
                                    ).then((_) => cargarMenus());
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmarEliminar(menu.id!),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CrearMenuScreen(),
            ),
          ).then((_) => cargarMenus());
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _mostrarDetalleMenu(BuildContext context, MenuSemanal menu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Menú ${_formatDate(menu.semanaInicio)} - ${_formatDate(menu.semanaFin)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Turno: ${menu.turno}'),
              Text('Estado: ${menu.activo ? "Activo" : "Inactivo"}'),
              const Divider(),
              const Text(
                'Platillos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: menu.items.length,
                  itemBuilder: (context, index) {
                    final item = menu.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              item.disponible ? Icons.check_circle : Icons.cancel,
                              color: item.disponible ? Colors.green : Colors.red,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_capitalize(item.diaSemana)} - ${_capitalize(item.tipoComida)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  item.nombre,
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                                // Validación corregida (sin chequeo de nulos innecesario)
                                if (item.descripcion.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.descripcion,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                  ),
                                ],
                                // Validación para ingredientes (mantenemos si es String? o también solo isNotEmpty si es String estricto)
                                if (item.ingredientes != null && item.ingredientes!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ingredientes: ${item.ingredientes}',
                                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${item.precio.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
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
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _confirmarEliminar(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Menú'),
        content: const Text('¿Estás seguro de eliminar este menú? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final apiService = ApiService();
                await apiService.eliminarMenu(id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Menú eliminado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                cargarMenus();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}