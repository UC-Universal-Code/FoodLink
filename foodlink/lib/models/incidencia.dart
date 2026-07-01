/// Modelo de Incidencia para FoodLink
/// Basado en los casos de uso C7, C8 
class Incidencia {
  final int id;
  final String idEmpleado; // ID del empleado que reporta
  final int platilloId;
  final String descripcion;
  final String estado; // "Pendiente", "En revisión", "Resuelto"
  final DateTime fecha;

  Incidencia({
    required this.id,
    required this.idEmpleado,
    required this.platilloId,
    required this.descripcion,
    required this.estado,
    required this.fecha,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    return Incidencia(
      id: json['id'] as int,
      idEmpleado: json['idEmpleado'] as String,
      platilloId: json['platilloId'] as int,
      descripcion: json['descripcion'] as String,
      estado: json['estado'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idEmpleado': idEmpleado,
      'platilloId': platilloId,
      'descripcion': descripcion,
      'estado': estado,
      'fecha': fecha.toIso8601String(),
    };
  }
}