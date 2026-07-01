/// Modelo de Usuario para la app
/// casos de uso C1, C3 y C9 
class User {
  final int id;
  final String nombre;
  final String empleadoId; // ID de empleado 
  final String rol; // "admin", "cocinero", "trabajador"
  final String turno; // "Matutino", "Vespertino", "Nocturno"
  final bool activo;

  User({
    required this.id,
    required this.nombre,
    required this.empleadoId,
    required this.rol,
    required this.turno,
    required this.activo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      empleadoId: json['empleadoId'] as String,
      rol: json['rol'] as String,
      turno: json['turno'] as String,
      activo: json['activo'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'empleadoId': empleadoId,
      'rol': rol,
      'turno': turno,
      'activo': activo,
    };
  }
}