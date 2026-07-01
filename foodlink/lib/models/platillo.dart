/// Modelo de Platillo para FoodLink
/// Basado en los casos de uso C4, C5, C6 del documento S-SDLC
class Platillo {
  final int id;
  final String nombre;
  final String descripcion;
  final String? imagenUrl; 

  Platillo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.imagenUrl,
  });

  factory Platillo.fromJson(Map<String, dynamic> json) {
    return Platillo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      imagenUrl: json['imagenUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      if (imagenUrl != null) 'imagenUrl': imagenUrl,
    };
  }
}