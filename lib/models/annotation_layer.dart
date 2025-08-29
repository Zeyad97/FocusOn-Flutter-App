import 'package:flutter/material.dart';

/// Represents an annotation layer with color tagging
class AnnotationLayer {
  final String id;
  final String name;
  final String colorTag; // Yellow, Blue, Purple, Red
  final Color color;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnotationLayer({
    required this.id,
    required this.name,
    required this.colorTag,
    required this.color,
    this.isVisible = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Predefined color tags with their corresponding colors
  static const Map<String, Color> colorTagMap = {
    'Yellow': Color(0xFFFFEB3B),
    'Blue': Color(0xFF2196F3),
    'Purple': Color(0xFF9C27B0),
    'Red': Color(0xFFF44336),
    'Green': Color(0xFF4CAF50),
    'Orange': Color(0xFFFF9800),
  };

  /// Get color from color tag
  static Color getColorFromTag(String colorTag) {
    return colorTagMap[colorTag] ?? Colors.grey;
  }

  /// Create copy with updated fields
  AnnotationLayer copyWith({
    String? name,
    String? colorTag,
    Color? color,
    bool? isVisible,
    DateTime? updatedAt,
  }) {
    return AnnotationLayer(
      id: id,
      name: name ?? this.name,
      colorTag: colorTag ?? this.colorTag,
      color: color ?? this.color,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color_tag': colorTag,
      'color': color.value,
      'is_visible': isVisible,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory AnnotationLayer.fromJson(Map<String, dynamic> json) {
    return AnnotationLayer(
      id: json['id'],
      name: json['name'],
      colorTag: json['color_tag'],
      color: Color(json['color']),
      isVisible: json['is_visible'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnotationLayer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AnnotationLayer(id: $id, name: $name, colorTag: $colorTag)';
}
