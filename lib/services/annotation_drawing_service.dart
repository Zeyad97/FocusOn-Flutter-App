import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/annotation.dart';

/// Annotation drawing service for vector graphics on PDF pages
class AnnotationDrawingService {
  /// Create annotation from touch/mouse input
  static Annotation createAnnotationFromInput({
    required List<Offset> points,
    required AnnotationTool tool,
    required Color color,
    required double strokeWidth,
    required int pageNumber,
    required Size pageSize,
    String? text,
    ColorTag? colorTag,
    String? layerId,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final timestamp = DateTime.now();
    
    // Normalize points to page coordinates (0.0 to 1.0)
    final normalizedPoints = points.map((point) => Offset(
      point.dx / pageSize.width,
      point.dy / pageSize.height,
    )).toList();
    
    // Create vector path based on tool type
    List<VectorPath> vectorPaths;
    
    switch (tool) {
      case AnnotationTool.pen:
        vectorPaths = [_createFreehandPath(normalizedPoints, strokeWidth)];
        break;
        
      case AnnotationTool.highlighter:
        vectorPaths = [_createHighlighterPath(normalizedPoints, strokeWidth)];
        break;
        
      case AnnotationTool.line:
        vectorPaths = [_createLinePath(normalizedPoints, strokeWidth)];
        break;
        
      case AnnotationTool.arrow:
        vectorPaths = _createArrowPaths(normalizedPoints, strokeWidth);
        break;
        
      case AnnotationTool.rectangle:
        vectorPaths = [_createRectanglePath(normalizedPoints, strokeWidth)];
        break;
        
      case AnnotationTool.circle:
        vectorPaths = [_createCirclePath(normalizedPoints, strokeWidth)];
        break;
        
      case AnnotationTool.text:
        vectorPaths = text != null ? [_createTextPath(normalizedPoints.first, text)] : [];
        break;
        
      case AnnotationTool.eraser:
        // Eraser is handled differently - it removes existing annotations
        vectorPaths = [];
        break;
    }
    
    return Annotation(
      id: id,
      pageNumber: pageNumber,
      tool: tool,
      vectorPaths: vectorPaths,
      color: color,
      strokeWidth: strokeWidth,
      text: text,
      colorTag: colorTag,
      layerId: layerId ?? 'default',
      timestamp: timestamp,
    );
  }
  
  /// Create freehand drawing path
  static VectorPath _createFreehandPath(List<Offset> points, double strokeWidth) {
    if (points.isEmpty) {
      return const VectorPath(
        type: VectorPathType.freehand,
        points: [],
        strokeWidth: 1.0,
      );
    }
    
    // Smooth the path using Catmull-Rom splines for better appearance
    final smoothedPoints = _smoothPath(points);
    
    return VectorPath(
      type: VectorPathType.freehand,
      points: smoothedPoints,
      strokeWidth: strokeWidth,
    );
  }
  
  /// Create highlighter path with transparency
  static VectorPath _createHighlighterPath(List<Offset> points, double strokeWidth) {
    final smoothedPoints = _smoothPath(points);
    
    return VectorPath(
      type: VectorPathType.highlighter,
      points: smoothedPoints,
      strokeWidth: strokeWidth * 3, // Highlighters are wider
    );
  }
  
  /// Create straight line path
  static VectorPath _createLinePath(List<Offset> points, double strokeWidth) {
    if (points.length < 2) {
      return VectorPath(
        type: VectorPathType.line,
        points: points,
        strokeWidth: strokeWidth,
      );
    }
    
    // Use first and last points for straight line
    return VectorPath(
      type: VectorPathType.line,
      points: [points.first, points.last],
      strokeWidth: strokeWidth,
    );
  }
  
  /// Create arrow paths (line + arrowhead)
  static List<VectorPath> _createArrowPaths(List<Offset> points, double strokeWidth) {
    if (points.length < 2) return [];
    
    final start = points.first;
    final end = points.last;
    
    // Main line
    final linePath = VectorPath(
      type: VectorPathType.line,
      points: [start, end],
      strokeWidth: strokeWidth,
    );
    
    // Arrowhead
    final arrowheadPath = _createArrowhead(start, end, strokeWidth);
    
    return [linePath, arrowheadPath];
  }
  
  /// Create arrowhead at the end of a line
  static VectorPath _createArrowhead(Offset start, Offset end, double strokeWidth) {
    final direction = (end - start);
    final length = direction.distance;
    
    if (length == 0) {
      return VectorPath(
        type: VectorPathType.polygon,
        points: [end],
        strokeWidth: strokeWidth,
      );
    }
    
    final unitDirection = direction / length;
    final perpendicular = Offset(-unitDirection.dy, unitDirection.dx);
    
    final arrowheadLength = math.min(length * 0.3, strokeWidth * 8);
    final arrowheadWidth = arrowheadLength * 0.5;
    
    final arrowBase = end - unitDirection * arrowheadLength;
    final leftPoint = arrowBase + perpendicular * arrowheadWidth;
    final rightPoint = arrowBase - perpendicular * arrowheadWidth;
    
    return VectorPath(
      type: VectorPathType.polygon,
      points: [end, leftPoint, rightPoint, end],
      strokeWidth: strokeWidth,
    );
  }
  
  /// Create rectangle path
  static VectorPath _createRectanglePath(List<Offset> points, double strokeWidth) {
    if (points.length < 2) {
      return VectorPath(
        type: VectorPathType.rectangle,
        points: points,
        strokeWidth: strokeWidth,
      );
    }
    
    final start = points.first;
    final end = points.last;
    
    // Create rectangle corners
    final topLeft = Offset(math.min(start.dx, end.dx), math.min(start.dy, end.dy));
    final topRight = Offset(math.max(start.dx, end.dx), math.min(start.dy, end.dy));
    final bottomRight = Offset(math.max(start.dx, end.dx), math.max(start.dy, end.dy));
    final bottomLeft = Offset(math.min(start.dx, end.dx), math.max(start.dy, end.dy));
    
    return VectorPath(
      type: VectorPathType.rectangle,
      points: [topLeft, topRight, bottomRight, bottomLeft, topLeft],
      strokeWidth: strokeWidth,
    );
  }
  
  /// Create circle/ellipse path
  static VectorPath _createCirclePath(List<Offset> points, double strokeWidth) {
    if (points.length < 2) {
      return VectorPath(
        type: VectorPathType.circle,
        points: points,
        strokeWidth: strokeWidth,
      );
    }
    
    final start = points.first;
    final end = points.last;
    final center = (start + end) / 2;
    final radius = (end - start).distance / 2;
    
    // Generate circle points for rendering
    final circlePoints = <Offset>[];
    const numPoints = 36; // 10-degree increments
    
    for (int i = 0; i <= numPoints; i++) {
      final angle = (i / numPoints) * 2 * math.pi;
      final point = center + Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      );
      circlePoints.add(point);
    }
    
    return VectorPath(
      type: VectorPathType.circle,
      points: circlePoints,
      strokeWidth: strokeWidth,
      metadata: {
        'center': {'x': center.dx, 'y': center.dy},
        'radius': radius,
      },
    );
  }
  
  /// Create text annotation path
  static VectorPath _createTextPath(Offset position, String text) {
    return VectorPath(
      type: VectorPathType.text,
      points: [position],
      strokeWidth: 1.0,
      metadata: {
        'text': text,
        'fontSize': 14.0,
        'fontFamily': 'Arial',
      },
    );
  }
  
  /// Smooth path using Catmull-Rom splines
  static List<Offset> _smoothPath(List<Offset> points) {
    if (points.length < 3) return points;
    
    final smoothed = <Offset>[];
    smoothed.add(points.first);
    
    for (int i = 1; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];
      
      // Add intermediate points using Catmull-Rom spline
      const segments = 4;
      for (int j = 0; j < segments; j++) {
        final t = j / segments;
        final smoothPoint = _catmullRomPoint(p0, p1, p2, p3, t);
        smoothed.add(smoothPoint);
      }
    }
    
    smoothed.add(points.last);
    return smoothed;
  }
  
  /// Calculate point on Catmull-Rom spline
  static Offset _catmullRomPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    
    final x = 0.5 * (
      (2 * p1.dx) +
      (-p0.dx + p2.dx) * t +
      (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
      (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3
    );
    
    final y = 0.5 * (
      (2 * p1.dy) +
      (-p0.dy + p2.dy) * t +
      (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
      (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3
    );
    
    return Offset(x, y);
  }
  
  /// Check if point is near annotation (for selection/editing)
  static bool isPointNearAnnotation(
    Annotation annotation,
    Offset point,
    Size pageSize,
    double threshold,
  ) {
    // Convert normalized annotation points to screen coordinates
    for (final path in annotation.vectorPaths) {
      for (int i = 0; i < path.points.length; i++) {
        final annotationPoint = Offset(
          path.points[i].dx * pageSize.width,
          path.points[i].dy * pageSize.height,
        );
        
        final distance = (point - annotationPoint).distance;
        if (distance <= threshold) return true;
        
        // For lines, also check distance to line segments
        if (i > 0 && path.type == VectorPathType.line) {
          final prevPoint = Offset(
            path.points[i - 1].dx * pageSize.width,
            path.points[i - 1].dy * pageSize.height,
          );
          
          final distanceToLine = _distanceToLineSegment(point, prevPoint, annotationPoint);
          if (distanceToLine <= threshold) return true;
        }
      }
    }
    
    return false;
  }
  
  /// Calculate distance from point to line segment
  static double _distanceToLineSegment(Offset point, Offset lineStart, Offset lineEnd) {
    final lineLength = (lineEnd - lineStart).distance;
    if (lineLength == 0) return (point - lineStart).distance;
    
    final t = math.max(0, math.min(1, 
        (point - lineStart).dx * (lineEnd - lineStart).dx +
        (point - lineStart).dy * (lineEnd - lineStart).dy)) / (lineLength * lineLength);
    
    final projection = lineStart + (lineEnd - lineStart) * t;
    return (point - projection).distance;
  }
  
  /// Filter annotations by color tag
  static List<Annotation> filterByColorTag(
    List<Annotation> annotations,
    ColorTag? colorTag,
  ) {
    if (colorTag == null) return annotations;
    return annotations.where((annotation) => annotation.colorTag == colorTag).toList();
  }
  
  /// Filter annotations by layer
  static List<Annotation> filterByLayer(
    List<Annotation> annotations,
    String? layerId,
  ) {
    if (layerId == null) return annotations;
    return annotations.where((annotation) => annotation.layerId == layerId).toList();
  }
  
  /// Get bounding box for annotation
  static Rect getAnnotationBounds(Annotation annotation, Size pageSize) {
    if (annotation.vectorPaths.isEmpty) return Rect.zero;
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final path in annotation.vectorPaths) {
      for (final point in path.points) {
        final screenPoint = Offset(
          point.dx * pageSize.width,
          point.dy * pageSize.height,
        );
        
        minX = math.min(minX, screenPoint.dx);
        minY = math.min(minY, screenPoint.dy);
        maxX = math.max(maxX, screenPoint.dx);
        maxY = math.max(maxY, screenPoint.dy);
      }
    }
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
  
  /// Scale annotation for different zoom levels
  static Annotation scaleAnnotation(Annotation annotation, double scaleFactor) {
    final scaledPaths = annotation.vectorPaths.map((path) => 
        path.copyWith(strokeWidth: path.strokeWidth * scaleFactor)).toList();
    
    return annotation.copyWith(vectorPaths: scaledPaths);
  }
  
  /// Merge nearby annotations of the same type
  static List<Annotation> mergeNearbyAnnotations(
    List<Annotation> annotations,
    double mergeThreshold,
    Size pageSize,
  ) {
    final merged = <Annotation>[];
    final processed = <bool>[];
    
    for (int i = 0; i < annotations.length; i++) {
      processed.add(false);
    }
    
    for (int i = 0; i < annotations.length; i++) {
      if (processed[i]) continue;
      
      final currentAnnotation = annotations[i];
      final toMerge = <Annotation>[currentAnnotation];
      processed[i] = true;
      
      // Find nearby annotations of the same type
      for (int j = i + 1; j < annotations.length; j++) {
        if (processed[j]) continue;
        
        final otherAnnotation = annotations[j];
        if (currentAnnotation.tool != otherAnnotation.tool ||
            currentAnnotation.color != otherAnnotation.color) continue;
        
        final currentBounds = getAnnotationBounds(currentAnnotation, pageSize);
        final otherBounds = getAnnotationBounds(otherAnnotation, pageSize);
        
        // Check if annotations are close enough to merge
        final distance = (currentBounds.center - otherBounds.center).distance;
        if (distance <= mergeThreshold) {
          toMerge.add(otherAnnotation);
          processed[j] = true;
        }
      }
      
      if (toMerge.length > 1) {
        // Merge annotations by combining their paths
        final mergedPaths = toMerge.expand((a) => a.vectorPaths).toList();
        final mergedAnnotation = currentAnnotation.copyWith(
          vectorPaths: mergedPaths,
          id: '${currentAnnotation.id}_merged',
        );
        merged.add(mergedAnnotation);
      } else {
        merged.add(currentAnnotation);
      }
    }
    
    return merged;
  }
}
