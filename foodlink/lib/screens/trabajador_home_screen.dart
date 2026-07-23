import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/menu_model.dart';
import '../../models/platillo.dart';
class TrabajadorHome extends StatefulWidget {
final String? turno;

  const TrabajadorHome({super.key, this.turno});

  @override
  State<TrabajadorHome> createState() => _TrabajadorHomeState();
}

class _TrabajadorHomeState extends State<TrabajadorHome> {
  MenuSemanal? menuSemanal;
  List<Platillo> platillosHoy = [];
  bool isLoading = true;
  String? errorMessage;
  String turnoUsuario = '';

  DateTime fechaSeleccionada = DateTime.now();

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
      final String turnoFinal = widget.turno ?? 'Matutino'; // Puedes cambiar 'Matutino' por el turno que prefieras por defecto

      setState(() {
        turnoUsuario = turnoFinal;
      });

      // Llama a la API con ese turno
      final data = await apiService.obtenerMenuActual(turnoFinal); 
      
      if (data == null) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'No hay menú disponible para el turno $turnoFinal.';
          isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        menuSemanal = MenuSemanal.fromJson(data);
        isLoading = false;
        errorMessage = null;
      });

      _filtrarPlatillosPorFecha();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error al obtener menú: $e';
        isLoading = false;
      });
    }
  }

  // Filtrado simple por día
  void _filtrarPlatillosPorFecha() {
    if (menuSemanal == null) return;

    final diaIndex = fechaSeleccionada.weekday - 1; // 0 = Lunes, 6 = Domingo
    final diaBuscado = diasSemana[diaIndex];

    final itemsFiltrados = menuSemanal!.items.where((item) {
      final diaItem = item.diaSemana.toLowerCase();
      return (diaItem == diaBuscado || diaItem.contains(diaBuscado)) && item.disponible;
    }).toList();

    setState(() {
      platillosHoy = itemsFiltrados;
    });
  }

  // Abrir ventana de Calendario
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'SELECCIONA UN DÍA PARA VER EL MENÚ',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF20303D),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != fechaSeleccionada) {
      setState(() {
        fechaSeleccionada = picked;
      });
      _filtrarPlatillosPorFecha();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos fechaSeleccionada para que el texto cambie en la pantalla
    final fechaTexto = '${_obtenerNombreDia(fechaSeleccionada.weekday)} ${fechaSeleccionada.day} de ${_obtenerNombreMes(fechaSeleccionada.month)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('FoodLink - Trabajador'),
        backgroundColor: const Color(0xFF20303D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Cambiar fecha',
            onPressed: () {
              _seleccionarFecha(context);
            },
          ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Turno ${_capitalize(turnoUsuario)} - $fechaTexto',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _seleccionarFecha(context);
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_calendar, size: 18, color: Color(0xFF20303D)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Cambiar',
                                    style: TextStyle(
                                      color: Color(0xFF20303D),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: platillosHoy.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay platillos disponibles para la fecha seleccionada.',
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