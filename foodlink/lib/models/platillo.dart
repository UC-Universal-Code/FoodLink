/// Modelo de Platillo para FoodLink
/// Basado en los casos de uso C4, C5, C6 del documento S-SDLC
class Platillo {
  final int id;
  final String nombre;
  final String descripcion;
  final String? imagenUrl; 
  final String diaSemana;      // "lunes", "martes", etc.
  final String tipoComida;     // "desayuno", "almuerzo", "cena"
  final String? ingredientes;
  final int? limitePorciones;
  final double precio;
  final bool disponible;

  Platillo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.imagenUrl,
    required this.diaSemana,
    required this.tipoComida,
    this.ingredientes,
    this.limitePorciones,
    required this.precio,
    this.disponible = true,
  });

  factory Platillo.fromJson(Map<String, dynamic> json) {
    return Platillo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      imagenUrl: json['imagenUrl'] as String?,
      diaSemana: json['diaSemana'] as String? ?? '',
      tipoComida: json['tipoComida'] as String? ?? '',
      ingredientes: json['ingredientes'] as String?,
      limitePorciones: json['limitePorciones'] as int?,
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      disponible: json['disponible'] as bool? ?? true,
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
  factory Platillo.fromMenuJson(Map<String, dynamic> json) {
    return Platillo(
      id: json['id'] ?? 0,
      nombre: json['nombre_plato'] ?? '',
      descripcion: json['descripcion'] ?? '',
      imagenUrl: json['imagen_url'],
      diaSemana: json['dia_semana'] ?? '',
      tipoComida: json['tipo_comida'] ?? '',
      ingredientes: json['ingredientes'],
      limitePorciones: json['limite_porciones'],
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      disponible: json['disponible'] ?? true,
    );
  }
  Map<String, dynamic> toMenuJson() {
  return {
    'id': id,
    'nombre_plato': nombre,
    'descripcion': descripcion,
    'imagen_url': imagenUrl,
    'dia_semana': diaSemana,
    'tipo_comida': tipoComida,
    'ingredientes': ingredientes,
    'limite_porciones': limitePorciones,
    'precio': precio,
    'disponible': disponible,
  };
  }
}