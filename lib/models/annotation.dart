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

/// Stamp types for musical annotations
enum StampType {
  fingering1,
  fingering2,
  fingering3,
  fingering4,
  fingering5,
  pedal,
  bowingUp,
  bowingDown,
  accent,
  rehearsalLetter,
}

/// Vector path data for drawing annotations with advanced properties
class VectorPath {
  final List<Offset> points;
  final double strokeWidth;
  final Color color;
  final BlendMode blendMode;
  final bool isErasable;

  VectorPath({
    required this.points,
    required this.strokeWidth,
    required this.color,
    this.blendMode = BlendMode.srcOver,
    this.isErasable = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'stroke_width': strokeWidth,
      'color': color.value,
      'blend_mode': blendMode.index,
      'is_erasable': isErasable,
    };
  }

  factory VectorPath.fromJson(Map<String, dynamic> json) {
    final pointsList = json['points'] as List;
    final points = pointsList.map((p) => Offset(p['x'].toDouble(), p['y'].toDouble())).toList();
    
    return VectorPath(
      points: points,
      strokeWidth: json['stroke_width']?.toDouble() ?? 2.0,
      color: Color(json['color'] ?? 0xFF000000),
      blendMode: BlendMode.values[json['blend_mode'] ?? 0],
      isErasable: json['is_erasable'] ?? true,
    );
  }
}

/// Text annotation data with positioning and styling
class TextData {
  final String text;
  final Offset position;
  final double fontSize;
  final Color color;
  final String fontFamily;
  final bool isEditable;

  TextData({
    required this.text,
    required this.position,
    required this.fontSize,
    required this.color,
    this.fontFamily = 'Roboto',
    this.isEditable = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'position': {'x': position.dx, 'y': position.dy},
      'font_size': fontSize,
      'color': color.value,
      'font_family': fontFamily,
      'is_editable': isEditable,
    };
  }

  factory TextData.fromJson(Map<String, dynamic> json) {
    final pos = json['position'];
    return TextData(
      text: json['text'] ?? '',
      position: Offset(pos['x']?.toDouble() ?? 0.0, pos['y']?.toDouble() ?? 0.0),
      fontSize: json['font_size']?.toDouble() ?? 14.0,
      color: Color(json['color'] ?? 0xFF000000),
      fontFamily: json['font_family'] ?? 'Roboto',
      isEditable: json['is_editable'] ?? true,
    );
  }
}

/// Stamp annotation data with rotation and scaling
class StampData {
  final StampType type;
  final Offset position;
  final double size;
  final double rotation;
  final Color color;
  final Map<String, dynamic>? customData;

  StampData({
    required this.type,
    required this.position,
    required this.size,
    this.rotation = 0.0,
    required this.color,
    this.customData,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'position': {'x': position.dx, 'y': position.dy},
      'size': size,
      'rotation': rotation,
      'color': color.value,
      'custom_data': customData,
    };
  }

  factory StampData.fromJson(Map<String, dynamic> json) {
    final pos = json['position'];
    return StampData(
      type: StampType.values[json['type'] ?? 0],
      position: Offset(pos['x']?.toDouble() ?? 0.0, pos['y']?.toDouble() ?? 0.0),
      size: json['size']?.toDouble() ?? 24.0,
      rotation: json['rotation']?.toDouble() ?? 0.0,
      color: Color(json['color'] ?? 0xFF000000),
      customData: json['custom_data']?.cast<String, dynamic>(),
    );
  }
}

/// Vector annotation on a PDF page - ScoreRead Pro with Advanced Features
class Annotation {
  final String id;
  final String pieceId;
  final int page;
  final String layerId;
  final ColorTag colorTag;
  final AnnotationTool tool;
  final DateTime createdAt;
  final dynamic data; // VectorPath, TextData, or StampData
  final Rect? bounds; // Bounding rectangle for optimization
  final Map<String, dynamic>? metadata;

  const Annotation({
    required this.id,
    required this.pieceId,
    required this.page,
    required this.layerId,
    required this.colorTag,
    required this.tool,
    required this.createdAt,
    required this.data,
    this.bounds,
    this.metadata,
  });

  /// Legacy constructor for backward compatibility
  factory Annotation.legacy({
    required String id,
    required String pieceId,
    required int page,
    required String layerId,
    required ColorTag colorTag,
    required AnnotationTool tool,
    required DateTime createdAt,
    List<Offset> path = const [],
    String? text,
    String? stampType,
    Rect? bounds,
    Map<String, dynamic>? metadata,
  }) {
    dynamic data;
    switch (tool) {
      case AnnotationTool.pen:
      case AnnotationTool.highlighter:
        data = VectorPath(
          points: path,
          strokeWidth: 2.0,
          color: _getColorFromTag(colorTag),
          blendMode: tool == AnnotationTool.highlighter ? BlendMode.multiply : BlendMode.srcOver,
        );
        break;
      case AnnotationTool.text:
        data = TextData(
          text: text ?? '',
          position: path.isNotEmpty ? path.first : Offset.zero,
          fontSize: 14.0,
          color: _getColorFromTag(colorTag),
        );
        break;
      case AnnotationTool.stamp:
        data = StampData(
          type: _getStampTypeFromString(stampType ?? 'fingering1'),
          position: path.isNotEmpty ? path.first : Offset.zero,
          size: 24.0,
          color: _getColorFromTag(colorTag),
        );
        break;
      case AnnotationTool.eraser:
        data = VectorPath(
          points: path,
          strokeWidth: 10.0,
          color: Colors.transparent,
        );
        break;
    }

    return Annotation(
      id: id,
      pieceId: pieceId,
      page: page,
      layerId: layerId,
      colorTag: colorTag,
      tool: tool,
      createdAt: createdAt,
      data: data,
      bounds: bounds,
      metadata: metadata,
    );
  }

  static Color _getColorFromTag(ColorTag tag) {
    switch (tag) {
      case ColorTag.yellow: return Colors.yellow;
      case ColorTag.blue: return Colors.blue;
      case ColorTag.purple: return Colors.purple;
      case ColorTag.red: return Colors.red;
      case ColorTag.green: return Colors.green;
    }
  }

  static StampType _getStampTypeFromString(String stamp) {
    switch (stamp) {
      case 'fingering1': return StampType.fingering1;
      case 'fingering2': return StampType.fingering2;
      case 'fingering3': return StampType.fingering3;
      case 'fingering4': return StampType.fingering4;
      case 'fingering5': return StampType.fingering5;
      case 'pedal': return StampType.pedal;
      case 'bowingUp': return StampType.bowingUp;
      case 'bowingDown': return StampType.bowingDown;
      case 'accent': return StampType.accent;
      case 'rehearsalLetter': return StampType.rehearsalLetter;
      default: return StampType.fingering1;
    }
  }

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

  /// Get vector path for pen/highlighter/eraser tools
  VectorPath? get vectorPath => data is VectorPath ? data as VectorPath : null;

  /// Get text data for text tool
  TextData? get textData => data is TextData ? data as TextData : null;

  /// Get stamp data for stamp tool
  StampData? get stampData => data is StampData ? data as StampData : null;

  /// Legacy path getter for backward compatibility
  List<Offset> get path {
    if (data is VectorPath) {
      return (data as VectorPath).points;
    }
    if (data is TextData) {
      return [(data as TextData).position];
    }
    if (data is StampData) {
      return [(data as StampData).position];
    }
    return [];
  }

  /// Legacy text getter
  String? get text => data is TextData ? (data as TextData).text : null;

  /// Legacy stamp type getter
  String? get stampType {
    if (data is StampData) {
      return (data as StampData).type.toString().split('.').last;
    }
    return null;
  }

  /// Check if annotation matches filter criteria - Enhanced with performance optimization
  bool matchesFilter({
    Set<ColorTag>? colorTags,
    Set<AnnotationTool>? tools,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Early exit for performance
    if (colorTags != null && colorTags.isNotEmpty && !colorTags.contains(colorTag)) {
      return false;
    }
    
    if (tools != null && tools.isNotEmpty && !tools.contains(tool)) {
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

  /// Advanced filtering with date presets
  bool matchesAdvancedFilter({
    Set<ColorTag>? colorTags,
    Set<AnnotationTool>? tools,
    bool? showToday,
    bool? showLast7Days,
    bool? showAll,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    // Filter by color tags
    if (colorTags != null && colorTags.isNotEmpty && !colorTags.contains(colorTag)) {
      return false;
    }
    
    // Filter by tools
    if (tools != null && tools.isNotEmpty && !tools.contains(tool)) {
      return false;
    }

    // Date filtering with presets
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7Days = today.subtract(const Duration(days: 7));

    if (showToday == true) {
      if (createdAt.isBefore(today)) return false;
    } else if (showLast7Days == true) {
      if (createdAt.isBefore(last7Days)) return false;
    } else if (showAll != true) {
      // Custom date range
      if (customStart != null && createdAt.isBefore(customStart)) return false;
      if (customEnd != null && createdAt.isAfter(customEnd)) return false;
    }

    return true;
  }

  /// Create copy with updated fields
  Annotation copyWith({
    String? layerId,
    ColorTag? colorTag,
    dynamic data,
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
      data: data ?? this.data,
      bounds: bounds ?? this.bounds,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for storage - Enhanced with new data types
  Map<String, dynamic> toJson() {
    Map<String, dynamic> dataJson;
    
    switch (tool) {
      case AnnotationTool.pen:
      case AnnotationTool.highlighter:
      case AnnotationTool.eraser:
        dataJson = (data as VectorPath).toJson();
        break;
      case AnnotationTool.text:
        dataJson = (data as TextData).toJson();
        break;
      case AnnotationTool.stamp:
        dataJson = (data as StampData).toJson();
        break;
    }

    return {
      'id': id,
      'piece_id': pieceId,
      'page': page,
      'layer_id': layerId,
      'color_tag': colorTag.index,
      'tool': tool.index,
      'created_at': createdAt.millisecondsSinceEpoch,
      'data': dataJson,
      'bounds': bounds != null ? {
        'left': bounds!.left,
        'top': bounds!.top,
        'right': bounds!.right,
        'bottom': bounds!.bottom,
      } : null,
      'metadata': metadata,
    };
  }

  /// Create from JSON - Enhanced with new data types
  factory Annotation.fromJson(Map<String, dynamic> json) {
    final tool = AnnotationTool.values[json['tool']];
    dynamic data;

    switch (tool) {
      case AnnotationTool.pen:
      case AnnotationTool.highlighter:
      case AnnotationTool.eraser:
        data = VectorPath.fromJson(json['data']);
        break;
      case AnnotationTool.text:
        data = TextData.fromJson(json['data']);
        break;
      case AnnotationTool.stamp:
        data = StampData.fromJson(json['data']);
        break;
    }

    return Annotation(
      id: json['id'],
      pieceId: json['piece_id'],
      page: json['page'],
      layerId: json['layer_id'],
      colorTag: ColorTag.values[json['color_tag']],
      tool: tool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      data: data,
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

/// Annotation layer for organizing annotations - Enhanced with Color Tags
class AnnotationLayer {
  final String id;
  final String name;
  final ColorTag colorTag;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnnotationLayer({
    required this.id,
    required this.name,
    required this.colorTag,
    this.isVisible = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get layer color based on color tag
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

  /// Create copy with updated fields
  AnnotationLayer copyWith({
    String? name,
    ColorTag? colorTag,
    bool? isVisible,
    DateTime? updatedAt,
  }) {
    return AnnotationLayer(
      id: id,
      name: name ?? this.name,
      colorTag: colorTag ?? this.colorTag,
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
      'color_tag': colorTag.index,
      'is_visible': isVisible,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory AnnotationLayer.fromJson(Map<String, dynamic> json) {
    // Handle boolean conversion from SQLite INTEGER (0/1) to bool
    bool isVisible = true;
    final visibleValue = json['is_visible'];
    if (visibleValue is bool) {
      isVisible = visibleValue;
    } else if (visibleValue is int) {
      isVisible = visibleValue == 1;
    } else if (visibleValue == null) {
      isVisible = true;
    }
    
    return AnnotationLayer(
      id: json['id'],
      name: json['name'],
      colorTag: ColorTag.values[json['color_tag'] ?? 0],
      isVisible: isVisible,
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
    return 'AnnotationLayer(id: $id, name: $name, colorTag: $colorTag, isVisible: $isVisible)';
  }
}

/// Advanced filter for annotations with preset date ranges and visual modes
class AnnotationFilter {
  final Set<ColorTag>? colorTags;
  final Set<AnnotationTool>? tools;
  final bool showToday;
  final bool showLast7Days;
  final bool showAll;
  final DateTime? customStart;
  final DateTime? customEnd;
  final bool fadeNonMatching; // true = fade to 20%, false = hide completely

  const AnnotationFilter({
    this.colorTags,
    this.tools,
    this.showToday = false,
    this.showLast7Days = false,
    this.showAll = true,
    this.customStart,
    this.customEnd,
    this.fadeNonMatching = false, // Default to hiding
  });

  /// Apply filter to list of annotations with performance optimization
  List<Annotation> apply(List<Annotation> annotations) {
    // Check if no filters are active at all
    bool hasColorFilter = colorTags != null && colorTags!.isNotEmpty;
    bool hasToolFilter = tools != null && tools!.isNotEmpty;
    bool hasDateFilter = showToday || showLast7Days || (!showAll && (customStart != null || customEnd != null));
    
    if (!hasColorFilter && !hasToolFilter && !hasDateFilter) {
      return annotations; // No filtering needed
    }

    return annotations.where((annotation) {
      return annotation.matchesAdvancedFilter(
        colorTags: colorTags,
        tools: tools,
        showToday: showToday,
        showLast7Days: showLast7Days,
        showAll: showAll,
        customStart: customStart,
        customEnd: customEnd,
      );
    }).toList();
  }

  /// Get annotations that should be faded (non-matching when fadeNonMatching is true)
  List<Annotation> getFadedAnnotations(List<Annotation> allAnnotations) {
    if (!fadeNonMatching) {
      return []; // No fading needed
    }
    
    // Check if no filters are active at all
    bool hasColorFilter = colorTags != null && colorTags!.isNotEmpty;
    bool hasToolFilter = tools != null && tools!.isNotEmpty;
    bool hasDateFilter = showToday || showLast7Days || (!showAll && (customStart != null || customEnd != null));
    
    if (!hasColorFilter && !hasToolFilter && !hasDateFilter) {
      return []; // No fading needed when no filters are active
    }

    return allAnnotations.where((annotation) {
      return !annotation.matchesAdvancedFilter(
        colorTags: colorTags,
        tools: tools,
        showToday: showToday,
        showLast7Days: showLast7Days,
        showAll: showAll,
        customStart: customStart,
        customEnd: customEnd,
      );
    }).toList();
  }

  /// Check if any color filters are active
  bool get hasColorFilter => colorTags != null && colorTags!.isNotEmpty;

  /// Check if any tool filters are active
  bool get hasToolFilter => tools != null && tools!.isNotEmpty;

  /// Check if any date filters are active
  bool get hasDateFilter => showToday || showLast7Days || customStart != null || customEnd != null;

  /// Create copy with updated filters
  AnnotationFilter copyWith({
    Set<ColorTag>? colorTags,
    Set<AnnotationTool>? tools,
    bool? showToday,
    bool? showLast7Days,
    bool? showAll,
    DateTime? customStart,
    DateTime? customEnd,
    bool? fadeNonMatching,
  }) {
    return AnnotationFilter(
      colorTags: colorTags ?? this.colorTags,
      tools: tools ?? this.tools,
      showToday: showToday ?? this.showToday,
      showLast7Days: showLast7Days ?? this.showLast7Days,
      showAll: showAll ?? this.showAll,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      fadeNonMatching: fadeNonMatching ?? this.fadeNonMatching,
    );
  }

  /// Check if filter is active (has any criteria set)
  bool get isActive {
    return !showAll || 
           (colorTags != null && colorTags!.isNotEmpty) ||
           (tools != null && tools!.isNotEmpty) ||
           showToday ||
           showLast7Days ||
           customStart != null ||
           customEnd != null;
  }

  /// Get filter summary for UI display
  String get filterSummary {
    List<String> parts = [];
    
    if (hasColorFilter) {
      parts.add('${colorTags!.length} color${colorTags!.length == 1 ? '' : 's'}');
    }
    
    if (hasToolFilter) {
      parts.add('${tools!.length} tool${tools!.length == 1 ? '' : 's'}');
    }
    
    if (showToday) {
      parts.add('today');
    } else if (showLast7Days) {
      parts.add('last 7 days');
    } else if (customStart != null || customEnd != null) {
      parts.add('custom date');
    }
    
    if (parts.isEmpty) return 'All annotations';
    return parts.join(', ');
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'color_tags': colorTags?.map((e) => e.index).toList(),
      'tools': tools?.map((e) => e.index).toList(),
      'show_today': showToday,
      'show_last_7_days': showLast7Days,
      'show_all': showAll,
      'custom_start': customStart?.millisecondsSinceEpoch,
      'custom_end': customEnd?.millisecondsSinceEpoch,
      'fade_non_matching': fadeNonMatching,
    };
  }

  /// Create from JSON
  factory AnnotationFilter.fromJson(Map<String, dynamic> json) {
    return AnnotationFilter(
      colorTags: json['color_tags'] != null 
          ? (json['color_tags'] as List).map((e) => ColorTag.values[e]).toSet()
          : null,
      tools: json['tools'] != null 
          ? (json['tools'] as List).map((e) => AnnotationTool.values[e]).toSet()
          : null,
      showToday: json['show_today'] ?? false,
      showLast7Days: json['show_last_7_days'] ?? false,
      showAll: json['show_all'] ?? true,
      customStart: json['custom_start'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['custom_start'])
          : null,
      customEnd: json['custom_end'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['custom_end'])
          : null,
      fadeNonMatching: json['fade_non_matching'] ?? false,
    );
  }
}
