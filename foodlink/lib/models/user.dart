// lib/models/user.dart

/// Modelo de Usuario para FoodLink
/// Basado en los casos de uso C1, C3 y C9 del documento S-SDLC
class User {
  final int id;
  final String numeroEmpleado;
  final String nombre;
  final String apellido;
  final int? departamentoId;
  final int? turnoId;
  final String rol; // "admin", "cocinero", "trabajador"
  final String estado;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final bool? esTemporal; 

  User({
    required this.id,
    required this.numeroEmpleado,
    required this.nombre,
    required this.apellido,
    this.departamentoId,
    this.turnoId,
    required this.rol,
    required this.estado,
    required this.creadoEn,
    required this.actualizadoEn,
    this.esTemporal,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      numeroEmpleado: json['numero_empleado'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      departamentoId: json['departamento_id'] as int?,
      turnoId: json['turno_id'] as int?,
      rol: json['rol'] as String,
      estado: json['estado'] as String,
      creadoEn: DateTime.parse(json['creado_en'] as String),
      actualizadoEn: DateTime.parse(json['actualizado_en'] as String),
      esTemporal: json['es_temporal'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_empleado': numeroEmpleado,
      'nombre': nombre,
      'apellido': apellido,
      'departamento_id': departamentoId,
      'turno_id': turnoId,
      'rol': rol,
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
      'es_temporal': esTemporal,
    };
  }
}