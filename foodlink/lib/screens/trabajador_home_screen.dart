import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/menu_model.dart';
import '../../models/platillo.dart';

class TrabajadorHome extends StatefulWidget {
  const TrabajadorHome({super.key});

  @override
  State<TrabajadorHome> createState() => _TrabajadorHomeState();
}

class _TrabajadorHomeState extends State<TrabajadorHome> {
  MenuSemanal? menuSemanal;
  List<Platillo> platillosHoy = [];
  bool isLoading = true;
  String? errorMessage;
  String turnoUsuario = '';

  final List<String> diasSemana = [
    'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'
  ];

  @override
  void initState() {
    super.initState();
    _cargarMenuActual();
  }

  Future<void> _cargarMenuActual() async {
    try {
      final apiService = ApiService();
      // Usamos obtenerMenuActual() que ya existe en tu ApiService con Dio
      final data = await apiService.obtenerMenuActual();
      
      if (data == null) {
        setState(() {
          errorMessage = 'No hay un menú activo para tu turno actualmente.';
          isLoading = false;
        });
        return;
      }

      final menu = MenuSemanal.fromJson(data);
      
      // Día de la semana actual (1 = Lunes, 7 = Domingo)
      final hoyIndex = DateTime.now().weekday - 1;
      final diaHoyTexto = diasSemana[hoyIndex];

      // Filtrar ítems del día que estén disponibles
      final itemsHoy = menu.items.where((item) {
        final diaItem = item.diaSemana.toLowerCase();
        return (diaItem == diaHoyTexto || diaItem.contains(diaHoyTexto)) && item.disponible;
      }).toList();

      setState(() {
        menuSemanal = menu;
        platillosHoy = itemsHoy;
        turnoUsuario = menu.turno;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final fechaTexto = '${_obtenerNombreDia(hoy.weekday)} ${hoy.day} de ${_obtenerNombreMes(hoy.month)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('FoodLink - Trabajador'),
        backgroundColor: const Color(0xFF20303D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final apiService = ApiService();
              await apiService.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => isLoading = true);
                            _cargarMenuActual();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF20303D),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reintentar'),
                        )
                      ],
                    ),
                  ),
                )
              : Padding(
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
                      Text(
                        'Turno ${_capitalize(turnoUsuario)} - $fechaTexto',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: platillosHoy.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay platillos disponibles para hoy.',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                itemCount: platillosHoy.length,
                                itemBuilder: (context, index) {
                                  final item = platillosHoy[index];
                                  return _buildPlatilloCard(
                                    nombre: item.nombre,
                                    descripcion: item.descripcion,
                                    precio: item.precio,
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Platillo: ${item.nombre}'),
                                        ),
                                      );
                                    },
                                  );
                                },
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
    required double precio,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (precio > 0)
              Text(
                '\$${precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF20303D),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _obtenerNombreDia(int weekday) {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[weekday - 1];
  }

  String _obtenerNombreMes(int month) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[month - 1];
  }
}