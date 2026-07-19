// lib/models/menu_model.dart
import 'platillo.dart';

class MenuSemanal {
  final int? id;
  final DateTime semanaInicio;
  final DateTime semanaFin;
  final String turno;
  final bool activo;
  final String? creadoPor;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final List<Platillo> items;

  MenuSemanal({
    this.id,
    required this.semanaInicio,
    required this.semanaFin,
    required this.turno,
    this.activo = true,
    this.creadoPor,
    this.creadoEn,
    this.actualizadoEn,
    this.items = const [],
  });

  MenuSemanal copyWith({
    int? id,
    DateTime? semanaInicio,
    DateTime? semanaFin,
    String? turno,
    bool? activo,
    String? creadoPor,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
    List<Platillo>? items,
  }) {
    return MenuSemanal(
      id: id ?? this.id,
      semanaInicio: semanaInicio ?? this.semanaInicio,
      semanaFin: semanaFin ?? this.semanaFin,
      turno: turno ?? this.turno,
      activo: activo ?? this.activo,
      creadoPor: creadoPor ?? this.creadoPor,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
    'semana_inicio': semanaInicio.toIso8601String().split('T')[0],
    'semana_fin': semanaFin.toIso8601String().split('T')[0],
    'turno': turno,
    'activo': activo,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory MenuSemanal.fromJson(Map<String, dynamic> json) => MenuSemanal(
    id: json['id'],
    semanaInicio: DateTime.parse(json['semana_inicio']),
    semanaFin: DateTime.parse(json['semana_fin']),
    turno: json['turno'] ?? '',
    activo: json['activo'] ?? true,
    creadoPor: json['creado_por'],
    creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en']) : null,
    actualizadoEn: json['actualizado_en'] != null ? DateTime.parse(json['actualizado_en']) : null,
    items: (json['items'] as List)
        .map((e) => Platillo.fromMenuJson(e))
        .toList(),
  );
}