import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';

/// Annotation toolbar for PDF viewer with drawing tools
class AnnotationToolbar extends StatelessWidget {
  final AnnotationTool selectedTool;
  final Color selectedColor;
  final double strokeWidth;
  final Function(AnnotationTool) onToolChanged;
  final Function(Color) onColorChanged;
  final Function(double) onStrokeWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final bool canUndo;

  const AnnotationToolbar({
    super.key,
    required this.selectedTool,
    required this.selectedColor,
    required this.strokeWidth,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onUndo,
    required this.onClear,
    required this.canUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tools row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolButton(
                icon: Icons.gesture,
                tool: AnnotationTool.pen,
                isSelected: selectedTool == AnnotationTool.pen,
                onPressed: () => onToolChanged(AnnotationTool.pen),
              ),
              _ToolButton(
                icon: Icons.highlight,
                tool: AnnotationTool.highlighter,
                isSelected: selectedTool == AnnotationTool.highlighter,
                onPressed: () => onToolChanged(AnnotationTool.highlighter),
              ),
              _ToolButton(
                icon: Icons.text_fields,
                tool: AnnotationTool.text,
                isSelected: selectedTool == AnnotationTool.text,
                onPressed: () => onToolChanged(AnnotationTool.text),
              ),
              _ToolButton(
                icon: Icons.crop_free,
                tool: AnnotationTool.rectangle,
                isSelected: selectedTool == AnnotationTool.rectangle,
                onPressed: () => onToolChanged(AnnotationTool.rectangle),
              ),
              _ToolButton(
                icon: Icons.circle_outlined,
                tool: AnnotationTool.circle,
                isSelected: selectedTool == AnnotationTool.circle,
                onPressed: () => onToolChanged(AnnotationTool.circle),
              ),
              _ToolButton(
                icon: Icons.arrow_forward,
                tool: AnnotationTool.arrow,
                isSelected: selectedTool == AnnotationTool.arrow,
                onPressed: () => onToolChanged(AnnotationTool.arrow),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Colors and controls row
          Row(
            children: [
              // Color picker
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _annotationColors.map((color) {
                    return GestureDetector(
                      onTap: () => onColorChanged(color),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Stroke width
              if (selectedTool == AnnotationTool.pen ||
                  selectedTool == AnnotationTool.highlighter) ...[
                const Icon(Icons.line_weight, size: 16),
                const SizedBox(width: 4),
                SizedBox(
                  width: 60,
                  child: Slider(
                    value: strokeWidth,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    onChanged: onStrokeWidthChanged,
                  ),
                ),
                Text('${strokeWidth.round()}'),
              ],
              
              const SizedBox(width: 16),
              
              // Action buttons
              IconButton(
                onPressed: canUndo ? onUndo : null,
                icon: Icon(
                  Icons.undo,
                  color: canUndo ? AppColors.primaryBlue : Colors.grey,
                ),
                iconSize: 20,
              ),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.clear, color: AppColors.errorRed),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<Color> _annotationColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.pink,
    Colors.black,
  ];
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final AnnotationTool tool;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.tool,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[700],
          size: 20,
        ),
      ),
    );
  }
}

/// Enum for annotation tools
enum AnnotationTool {
  pen,
  highlighter,
  text,
  rectangle,
  circle,
  arrow,
}

/// Data class for PDF annotations
class PDFAnnotation {
  final String id;
  final int pageNumber;
  final AnnotationTool tool;
  final Color color;
  final double strokeWidth;
  final List<Offset> points;
  final String? text;
  final Rect? bounds;
  final DateTime createdAt;

  const PDFAnnotation({
    required this.id,
    required this.pageNumber,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.points,
    this.text,
    this.bounds,
    required this.createdAt,
  });

  PDFAnnotation copyWith({
    String? id,
    int? pageNumber,
    AnnotationTool? tool,
    Color? color,
    double? strokeWidth,
    List<Offset>? points,
    String? text,
    Rect? bounds,
    DateTime? createdAt,
  }) {
    return PDFAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      tool: tool ?? this.tool,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      points: points ?? this.points,
      text: text ?? this.text,
      bounds: bounds ?? this.bounds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Custom painter for rendering annotations
class AnnotationPainter extends CustomPainter {
  final List<PDFAnnotation> annotations;
  final double zoomLevel;

  AnnotationPainter({
    required this.annotations,
    required this.zoomLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      final paint = Paint()
        ..color = annotation.color
        ..strokeWidth = annotation.strokeWidth * zoomLevel
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      switch (annotation.tool) {
        case AnnotationTool.pen:
          _drawPath(canvas, annotation, paint);
          break;
        case AnnotationTool.highlighter:
          paint.color = annotation.color.withOpacity(0.3);
          paint.strokeWidth = annotation.strokeWidth * 2 * zoomLevel;
          _drawPath(canvas, annotation, paint);
          break;
        case AnnotationTool.rectangle:
          _drawRectangle(canvas, annotation, paint);
          break;
        case AnnotationTool.circle:
          _drawCircle(canvas, annotation, paint);
          break;
        case AnnotationTool.arrow:
          _drawArrow(canvas, annotation, paint);
          break;
        case AnnotationTool.text:
          _drawText(canvas, annotation);
          break;
      }
    }
  }

  void _drawPath(Canvas canvas, PDFAnnotation annotation, Paint paint) {
    if (annotation.points.length < 2) return;

    final path = Path();
    final scaledPoints = annotation.points
        .map((point) => Offset(point.dx * zoomLevel, point.dy * zoomLevel))
        .toList();

    path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
    for (int i = 1; i < scaledPoints.length; i++) {
      path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawRectangle(Canvas canvas, PDFAnnotation annotation, Paint paint) {
    if (annotation.bounds == null) return;

    final rect = Rect.fromLTRB(
      annotation.bounds!.left * zoomLevel,
      annotation.bounds!.top * zoomLevel,
      annotation.bounds!.right * zoomLevel,
      annotation.bounds!.bottom * zoomLevel,
    );

    canvas.drawRect(rect, paint);
  }

  void _drawCircle(Canvas canvas, PDFAnnotation annotation, Paint paint) {
    if (annotation.bounds == null) return;

    final center = Offset(
      annotation.bounds!.center.dx * zoomLevel,
      annotation.bounds!.center.dy * zoomLevel,
    );
    final radius = (annotation.bounds!.width / 2) * zoomLevel;

    canvas.drawCircle(center, radius, paint);
  }

  void _drawArrow(Canvas canvas, PDFAnnotation annotation, Paint paint) {
    if (annotation.points.length < 2) return;

    final start = Offset(
      annotation.points.first.dx * zoomLevel,
      annotation.points.first.dy * zoomLevel,
    );
    final end = Offset(
      annotation.points.last.dx * zoomLevel,
      annotation.points.last.dy * zoomLevel,
    );

    // Draw line
    canvas.drawLine(start, end, paint);

    // Draw arrowhead
    final angle = (end - start).direction;
    final arrowLength = 10 * zoomLevel;
    final arrowAngle = 0.5;

    final arrowPoint1 = end +
        Offset(
          arrowLength * math.cos(angle + arrowAngle),
          arrowLength * math.sin(angle + arrowAngle),
        );
    final arrowPoint2 = end +
        Offset(
          arrowLength * math.cos(angle - arrowAngle),
          arrowLength * math.sin(angle - arrowAngle),
        );

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);

    canvas.drawPath(arrowPath, paint);
  }

  void _drawText(Canvas canvas, PDFAnnotation annotation) {
    if (annotation.text == null || annotation.points.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: annotation.text,
        style: TextStyle(
          color: annotation.color,
          fontSize: 16 * zoomLevel,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        annotation.points.first.dx * zoomLevel,
        annotation.points.first.dy * zoomLevel,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return annotations != oldDelegate.annotations ||
           zoomLevel != oldDelegate.zoomLevel;
  }
}

/// Painter for current drawing stroke
class CurrentDrawingPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  CurrentDrawingPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CurrentDrawingPainter oldDelegate) {
    return points != oldDelegate.points ||
           color != oldDelegate.color ||
           strokeWidth != oldDelegate.strokeWidth;
  }
}
