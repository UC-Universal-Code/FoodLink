import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/menu_model.dart';
import '../../models/platillo.dart';

class CrearMenuScreen extends StatefulWidget {
  const CrearMenuScreen({Key? key}) : super(key: key);

  @override
  State<CrearMenuScreen> createState() => _CrearMenuScreenState();
}

class _CrearMenuScreenState extends State<CrearMenuScreen> {
  DateTime semanaInicio = DateTime.now();
  DateTime semanaFin = DateTime.now().add(const Duration(days: 6));
  String turno = 'Matutino';
  bool activo = true;

  List<Platillo> items = [];
  String? diaSeleccionado;
  String? tipoComidaSeleccionado;
  
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController ingredientesController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  bool disponible = true;

  final List<String> diasSemana = [
    'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'
  ];
  final List<String> tiposComida = ['desayuno', 'almuerzo', 'cena'];
  final List<String> turnos = ['Matutino', 'Vespertino', 'Nocturno'];

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    ingredientesController.dispose();
    precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Menú Semanal'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Configuración del menú
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Inicio de semana (Lunes)'),
                      subtitle: Text(
                        '${semanaInicio.day}/${semanaInicio.month}/${semanaInicio.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _seleccionarFechaInicio(context),
                    ),
                    ListTile(
                      title: const Text('Fin de semana (Domingo)'),
                      subtitle: Text(
                        '${semanaFin.day}/${semanaFin.month}/${semanaFin.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _seleccionarFechaFin(context),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Turno',
                        border: OutlineInputBorder(),
                      ),
                      value: turno,
                      items: turnos.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => turno = value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Menú activo'),
                      value: activo,
                      onChanged: (value) {
                        setState(() => activo = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Formulario para agregar platillos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agregar Platillos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Día de la semana',
                        border: OutlineInputBorder(),
                      ),
                      value: diaSeleccionado,
                      items: diasSemana.map((dia) {
                        return DropdownMenuItem(
                          value: dia,
                          child: Text(_capitalize(dia)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => diaSeleccionado = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Tipo de comida',
                        border: OutlineInputBorder(),
                      ),
                      value: tipoComidaSeleccionado,
                      items: tiposComida.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(_capitalize(tipo)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => tipoComidaSeleccionado = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del platillo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ingredientesController,
                      decoration: const InputDecoration(
                        labelText: 'Ingredientes (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: precioController,
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Disponible'),
                      value: disponible,
                      onChanged: (value) {
                        setState(() => disponible = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _agregarItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar al Menú'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de platillos agregados
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platillos (${items.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No hay platillos agregados'),
                        ),
                      )
                    else
                      ...items.map((item) => ListTile(
                            dense: true,
                            leading: Icon(
                              item.disponible ? Icons.check_circle : Icons.cancel,
                              color: item.disponible ? Colors.green : Colors.red,
                            ),
                            title: Text('${_capitalize(item.diaSemana)} - ${_capitalize(item.tipoComida)}'),
                            subtitle: Text(item.nombre),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('\$${item.precio.toStringAsFixed(2)}'),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      items.remove(item);
                                    });
                                  },
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardarMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Guardar Menú Semanal',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _agregarItem() {
    if (diaSeleccionado == null || tipoComidaSeleccionado == null) {
      _mostrarSnackBar('Selecciona el día y el tipo de comida');
      return;
    }

    if (nombreController.text.trim().isEmpty) {
      _mostrarSnackBar('Ingresa el nombre del platillo');
      return;
    }

    final precio = double.tryParse(precioController.text);
    if (precio == null || precio <= 0) {
      _mostrarSnackBar('Ingresa un precio válido');
      return;
    }

    setState(() {
      items.add(Platillo(
        id: DateTime.now().millisecondsSinceEpoch,
        nombre: nombreController.text.trim(),
        descripcion: descripcionController.text.trim(),
        diaSemana: diaSeleccionado!,
        tipoComida: tipoComidaSeleccionado!,
        ingredientes: ingredientesController.text.trim().isNotEmpty 
            ? ingredientesController.text.trim() 
            : null,
        precio: precio,
        disponible: disponible,
      ));

      // Limpiar campos de entrada
      diaSeleccionado = null;
      tipoComidaSeleccionado = null;
      nombreController.clear();
      descripcionController.clear();
      ingredientesController.clear();
      precioController.clear();
      disponible = true;
    });
  }

  void _guardarMenu() async {
    if (items.isEmpty) {
      _mostrarSnackBar('Agrega al menos un platillo al menú');
      return;
    }

    final menu = MenuSemanal(
      semanaInicio: semanaInicio,
      semanaFin: semanaFin,
      turno: turno,
      activo: activo,
      items: items,
    );

    try {
      final apiService = ApiService();
      await apiService.crearMenuSemanal(menu.toJson());
      if (!mounted) return;
      _mostrarSnackBar('Menú creado exitosamente', esError: false);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _mostrarSnackBar('Error al guardar: $e');
    }
  }

  void _seleccionarFechaInicio(BuildContext context) async {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);

    final fecha = await showDatePicker(
      context: context,
      initialDate: semanaInicio.isBefore(hoy) ? hoy : semanaInicio,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (fecha != null) {
      setState(() {
        semanaInicio = fecha;
        semanaFin = fecha.add(const Duration(days: 6));
      });
    }
  }

  void _seleccionarFechaFin(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: semanaFin,
      firstDate: semanaInicio,
      lastDate: semanaInicio.add(const Duration(days: 30)),
    );
    if (fecha != null) {
      setState(() {
        semanaFin = fecha;
      });
    }
  }

  void _mostrarSnackBar(String mensaje, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}