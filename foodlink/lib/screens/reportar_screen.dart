import 'package:flutter/material.dart';

class ReportarScreen extends StatefulWidget {
  final String token;
  const ReportarScreen({Key? key, required this.token}) : super(key: key);

  @override
  _ReportarScreenState createState() => _ReportarScreenState();
}

class _ReportarScreenState extends State<ReportarScreen> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  bool _cargando = false;

  void _enviarReporte() async {
    if (_tituloController.text.isEmpty || _descripcionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _cargando = true);

    // Llamas a tu función de API aquí
    // bool exito = await apiService.crearReporte(_tituloController.text, _descripcionController.text, widget.token);

    setState(() => _cargando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte enviado con éxito')),
    );
    _tituloController.clear();
    _descripcionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Incidencia')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título del reporte'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descripción detallada'),
            ),
            const SizedBox(height: 24),
            _cargando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _enviarReporte,
                    child: const Text('Enviar Reporte'),
                  ),
          ],
        ),
      ),
    );
  }
}