// lib/screens/cocinero/crear_menu_screen.dart
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
  final _formKey = GlobalKey<FormState>();
  
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Menú Semanal'),
        backgroundColor: Colors.orange,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                          setState(() => turno = value!);
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
              
              // Agregar platillos
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecciona un día';
                          }
                          return null;
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecciona un tipo de comida';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del platillo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa el nombre del platillo';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: ingredientesController,
                        decoration: const InputDecoration(
                          labelText: 'Ingredientes (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: precioController,
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa el precio';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
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
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _agregarItem() {
    if (!_formKey.currentState!.validate()) return;

    if (diaSeleccionado == null || tipoComidaSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona día y tipo de comida')),
      );
      return;
    }

    final precio = double.tryParse(precioController.text);
    if (precio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precio inválido')),
      );
      return;
    }

    setState(() {
      items.add(Platillo(
        id: DateTime.now().millisecondsSinceEpoch, // ID temporal
        nombre: nombreController.text,
        descripcion: descripcionController.text.isNotEmpty ? descripcionController.text : '',
        diaSemana: diaSeleccionado!,
        tipoComida: tipoComidaSeleccionado!,
        ingredientes: ingredientesController.text.isNotEmpty ? ingredientesController.text : null,
        precio: precio,
        disponible: disponible,
      ));
      
      // Limpiar campos
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un platillo')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menú creado exitosamente'),
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

  void _seleccionarFechaInicio(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: semanaInicio,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}