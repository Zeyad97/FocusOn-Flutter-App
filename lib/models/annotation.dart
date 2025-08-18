import 'package:flutter/material.dart';

/// Annotation tool types as per ScoreRead Pro specification
enum AnnotationTool {
  pen,
  highlighter,
  eraser,
  text,
  stamp,
}

/// Color tags for organizing annotations
enum ColorTag {
  yellow,  // Dynamics
  blue,    // Fingering
  purple,  // Phrasing
  red,     // Critical areas
  green,   // Corrections
}

/// Vector annotation on a PDF page - ScoreRead Pro
class Annotation {
  final String id;
  final String pieceId;
  final int page;
  final String layerId;
  final ColorTag colorTag;
  final AnnotationTool tool;
  final DateTime createdAt;
  final List<Offset> path; // Vector path for pen/highlighter
  final String? text; // For text annotations
  final String? stampType; // For stamp annotations (fingering, pedal, etc.)
  final Rect? bounds; // Bounding rectangle
  final Map<String, dynamic>? metadata;

  const Annotation({
    required this.id,
    required this.pieceId,
    required this.page,
    required this.layerId,
    required this.colorTag,
    required this.tool,
    required this.createdAt,
    this.path = const [],
    this.text,
    this.stampType,
    this.bounds,
    this.metadata,
  });

  /// Get annotation color based on color tag
  Color get color {
    switch (colorTag) {
      case ColorTag.yellow:
        return Colors.yellow;
      case ColorTag.blue:
        return Colors.blue;
      case ColorTag.purple:
        return Colors.purple;
      case ColorTag.red:
        return Colors.red;
      case ColorTag.green:
        return Colors.green;
    }
  }

  /// Check if annotation matches filter criteria
  bool matchesFilter({
    Set<ColorTag>? colorTags,
    Set<AnnotationTool>? tools,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (colorTags != null && !colorTags.contains(colorTag)) {
      return false;
    }
    
    if (tools != null && !tools.contains(tool)) {
      return false;
    }
    
    if (startDate != null && createdAt.isBefore(startDate)) {
      return false;
    }
    
    if (endDate != null && createdAt.isAfter(endDate)) {
      return false;
    }
    
    return true;
  }

  /// Create copy with updated fields
  Annotation copyWith({
    String? layerId,
    ColorTag? colorTag,
    List<Offset>? path,
    String? text,
    String? stampType,
    Rect? bounds,
    Map<String, dynamic>? metadata,
  }) {
    return Annotation(
      id: id,
      pieceId: pieceId,
      page: page,
      layerId: layerId ?? this.layerId,
      colorTag: colorTag ?? this.colorTag,
      tool: tool,
      createdAt: createdAt,
      path: path ?? this.path,
      text: text ?? this.text,
      stampType: stampType ?? this.stampType,
      bounds: bounds ?? this.bounds,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'piece_id': pieceId,
      'page': page,
      'layer_id': layerId,
      'color_tag': colorTag.index,
      'tool': tool.index,
      'created_at': createdAt.millisecondsSinceEpoch,
      'path': path.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'text': text,
      'stamp_type': stampType,
      'bounds': bounds != null ? {
        'left': bounds!.left,
        'top': bounds!.top,
        'right': bounds!.right,
        'bottom': bounds!.bottom,
      } : null,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Annotation.fromJson(Map<String, dynamic> json) {
    return Annotation(
      id: json['id'],
      pieceId: json['piece_id'],
      page: json['page'],
      layerId: json['layer_id'],
      colorTag: ColorTag.values[json['color_tag']],
      tool: AnnotationTool.values[json['tool']],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      path: (json['path'] as List?)
          ?.map((p) => Offset(p['x'].toDouble(), p['y'].toDouble()))
          .toList() ?? [],
      text: json['text'],
      stampType: json['stamp_type'],
      bounds: json['bounds'] != null ? Rect.fromLTRB(
        json['bounds']['left'].toDouble(),
        json['bounds']['top'].toDouble(),
        json['bounds']['right'].toDouble(),
        json['bounds']['bottom'].toDouble(),
      ) : null,
      metadata: json['metadata']?.cast<String, dynamic>(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Annotation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Annotation(id: $id, page: $page, tool: $tool, colorTag: $colorTag)';
  }
}

/// Annotation layer for organizing annotations
class AnnotationLayer {
  final String id;
  final String name;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnnotationLayer({
    required this.id,
    required this.name,
    this.isVisible = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create copy with updated fields
  AnnotationLayer copyWith({
    String? name,
    bool? isVisible,
    DateTime? updatedAt,
  }) {
    return AnnotationLayer(
      id: id,
      name: name ?? this.name,
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
  String toString() {
    return 'AnnotationLayer(id: $id, name: $name, isVisible: $isVisible)';
  }
}
