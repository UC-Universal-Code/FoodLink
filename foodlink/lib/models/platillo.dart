/// Modelo de Platillo para FoodLink
/// Basado en los casos de uso C4, C5, C6 del documento S-SDLC
class Platillo {
  final int? id;
  String nombre;         // <-- Sin 'final' para poder editarlo
  String descripcion;    // <-- Sin 'final'
  String? imagenUrl; 
  String diaSemana;      // "lunes", "martes", etc.
  String tipoComida;     // "desayuno", "almuerzo", "cena"
  String? ingredientes;
  int? limitePorciones;
  double precio;         // <-- Sin 'final' para poder editarlo
  bool disponible;       // <-- Sin 'final' para poder cambiar el interruptor

  Platillo({
    this.id,
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
      id: json['id'] as int?,
      nombre: (json['nombre_plato'] ?? json['nombre']) as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      imagenUrl: json['imagen_url'] ?? json['imagenUrl'],
      diaSemana: (json['dia_semana'] ?? json['diaSemana']) as String? ?? '',
      tipoComida: (json['tipo_comida'] ?? json['tipoComida']) as String? ?? '',
      ingredientes: json['ingredientes'] as String?,
      limitePorciones: json['limite_porciones'] ?? json['limitePorciones'],
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      disponible: json['disponible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre_plato': nombre,
      'descripcion': descripcion,
      'imagen_url': imagenUrl,
      'dia_semana': diaSemana.toLowerCase(),
      'tipo_comida': tipoComida.toLowerCase(),
      'ingredientes': ingredientes,
      'limite_porciones': limitePorciones,
      'precio': precio,
      'disponible': disponible,
    };
  }

  factory Platillo.fromMenuJson(Map<String, dynamic> json) => Platillo.fromJson(json);
  
  Map<String, dynamic> toMenuJson() => toJson();
}