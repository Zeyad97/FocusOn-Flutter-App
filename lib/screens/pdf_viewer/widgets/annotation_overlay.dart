import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../models/annotation.dart';

/// Widget that renders annotations on a PDF page
class AnnotationOverlay extends StatelessWidget {
  final List<Annotation> annotations;
  final Size pageSize;
  final double scale;
  final Offset offset;

  const AnnotationOverlay({
    super.key,
    required this.annotations,
    required this.pageSize,
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AnnotationPainter(
        annotations: annotations,
        pageSize: pageSize,
        scale: scale,
        offset: offset,
      ),
      size: pageSize * scale,
    );
  }
}

/// Custom painter for rendering annotations
class AnnotationPainter extends CustomPainter {
  final List<Annotation> annotations;
  final Size pageSize;
  final double scale;
  final Offset offset;

  AnnotationPainter({
    required this.annotations,
    required this.pageSize,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      _drawAnnotation(canvas, annotation);
    }
  }

  void _drawAnnotation(Canvas canvas, Annotation annotation) {
    switch (annotation.tool) {
      case AnnotationTool.pen:
        _drawPenPath(canvas, annotation);
        break;
      case AnnotationTool.highlighter:
        _drawHighlighter(canvas, annotation);
        break;
      case AnnotationTool.text:
        _drawText(canvas, annotation);
        break;
      case AnnotationTool.stamp:
        _drawStamp(canvas, annotation);
        break;
      case AnnotationTool.eraser:
        // Eraser removes annotations, doesn't draw anything
        break;
    }
  }

  void _drawPenPath(Canvas canvas, Annotation annotation) {
    if (annotation.path.isEmpty) return;

    final paint = Paint()
      ..color = annotation.color
      ..strokeWidth = 2.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final scaledPath = annotation.path.map((point) => 
      Offset(point.dx * pageSize.width, point.dy * pageSize.height) * scale + offset
    ).toList();

    if (scaledPath.isNotEmpty) {
      path.moveTo(scaledPath.first.dx, scaledPath.first.dy);
      for (int i = 1; i < scaledPath.length; i++) {
        path.lineTo(scaledPath[i].dx, scaledPath[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawHighlighter(Canvas canvas, Annotation annotation) {
    if (annotation.path.isEmpty) return;

    final paint = Paint()
      ..color = annotation.color.withOpacity(0.3)
      ..strokeWidth = 8.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final scaledPath = annotation.path.map((point) => 
      Offset(point.dx * pageSize.width, point.dy * pageSize.height) * scale + offset
    ).toList();

    if (scaledPath.isNotEmpty) {
      path.moveTo(scaledPath.first.dx, scaledPath.first.dy);
      for (int i = 1; i < scaledPath.length; i++) {
        path.lineTo(scaledPath[i].dx, scaledPath[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawText(Canvas canvas, Annotation annotation) {
    if (annotation.text == null || annotation.bounds == null) return;

    final bounds = Rect.fromLTRB(
      annotation.bounds!.left * pageSize.width * scale + offset.dx,
      annotation.bounds!.top * pageSize.height * scale + offset.dy,
      annotation.bounds!.right * pageSize.width * scale + offset.dx,
      annotation.bounds!.bottom * pageSize.height * scale + offset.dy,
    );

    // Draw background
    final backgroundPaint = Paint()
      ..color = annotation.color.withOpacity(0.8);
    canvas.drawRect(bounds, backgroundPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = annotation.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(bounds, borderPaint);

    // Draw text
    final textStyle = TextStyle(
      color: _getContrastingTextColor(annotation.color),
      fontSize: 12.0 * scale,
      fontWeight: FontWeight.w500,
    );

    final textSpan = TextSpan(
      text: annotation.text,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(maxWidth: bounds.width - 8);
    
    final textOffset = Offset(
      bounds.left + 4,
      bounds.top + (bounds.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  void _drawStamp(Canvas canvas, Annotation annotation) {
    if (annotation.stampType == null || annotation.bounds == null) return;

    final bounds = Rect.fromLTRB(
      annotation.bounds!.left * pageSize.width * scale + offset.dx,
      annotation.bounds!.top * pageSize.height * scale + offset.dy,
      annotation.bounds!.right * pageSize.width * scale + offset.dx,
      annotation.bounds!.bottom * pageSize.height * scale + offset.dy,
    );

    // Draw stamp background
    final backgroundPaint = Paint()
      ..color = annotation.color.withOpacity(0.2);
    canvas.drawOval(bounds, backgroundPaint);

    // Draw stamp border
    final borderPaint = Paint()
      ..color = annotation.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawOval(bounds, borderPaint);

    // Draw stamp text/symbol
    final textStyle = TextStyle(
      color: annotation.color,
      fontSize: bounds.height * 0.4,
      fontWeight: FontWeight.bold,
    );

    final text = _getStampText(annotation.stampType!);
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    final textOffset = Offset(
      bounds.center.dx - textPainter.width / 2,
      bounds.center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  String _getStampText(String stampType) {
    switch (stampType.toLowerCase()) {
      case 'fingering':
        return '1';
      case 'pedal':
        return '♩';
      case 'crescendo':
        return '<';
      case 'diminuendo':
        return '>';
      case 'accent':
        return '>';
      case 'staccato':
        return '.';
      case 'legato':
        return '⌐';
      default:
        return '✓';
    }
  }

  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate luminance to determine if text should be light or dark
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return annotations != oldDelegate.annotations ||
           pageSize != oldDelegate.pageSize ||
           scale != oldDelegate.scale ||
           offset != oldDelegate.offset;
  }
}

/// Interactive annotation editor widget
class AnnotationEditor extends StatefulWidget {
  final Size pageSize;
  final double scale;
  final Offset offset;
  final AnnotationTool currentTool;
  final ColorTag currentColorTag;
  final Function(Annotation) onAnnotationCreated;
  final List<Annotation> existingAnnotations;

  const AnnotationEditor({
    super.key,
    required this.pageSize,
    required this.currentTool,
    required this.currentColorTag,
    required this.onAnnotationCreated,
    this.scale = 1.0,
    this.offset = Offset.zero,
    this.existingAnnotations = const [],
  });

  @override
  State<AnnotationEditor> createState() => _AnnotationEditorState();
}

class _AnnotationEditorState extends State<AnnotationEditor> {
  List<Offset> _currentPath = [];
  bool _isDrawing = false;
  Offset? _startPoint;
  Offset? _endPoint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: _onTap,
      child: Container(
        width: widget.pageSize.width * widget.scale,
        height: widget.pageSize.height * widget.scale,
        color: Colors.transparent,
        child: CustomPaint(
          painter: _DrawingPainter(
            currentPath: _currentPath,
            currentTool: widget.currentTool,
            currentColorTag: widget.currentColorTag,
            scale: widget.scale,
            offset: widget.offset,
            pageSize: widget.pageSize,
            startPoint: _startPoint,
            endPoint: _endPoint,
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.currentTool == AnnotationTool.pen || 
        widget.currentTool == AnnotationTool.highlighter) {
      setState(() {
        _isDrawing = true;
        _currentPath = [_normalizePoint(details.localPosition)];
      });
    } else if (widget.currentTool == AnnotationTool.text ||
               widget.currentTool == AnnotationTool.stamp) {
      setState(() {
        _startPoint = _normalizePoint(details.localPosition);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDrawing && (widget.currentTool == AnnotationTool.pen || 
                       widget.currentTool == AnnotationTool.highlighter)) {
      setState(() {
        _currentPath.add(_normalizePoint(details.localPosition));
      });
    } else if (widget.currentTool == AnnotationTool.text ||
               widget.currentTool == AnnotationTool.stamp) {
      setState(() {
        _endPoint = _normalizePoint(details.localPosition);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDrawing && _currentPath.isNotEmpty) {
      _createPathAnnotation();
      setState(() {
        _isDrawing = false;
        _currentPath = [];
      });
    } else if (_startPoint != null && _endPoint != null) {
      _createBoundedAnnotation();
      setState(() {
        _startPoint = null;
        _endPoint = null;
      });
    }
  }

  void _onTap() {
    if (widget.currentTool == AnnotationTool.stamp && _startPoint != null) {
      // Create stamp at tap location
      _createBoundedAnnotation();
      setState(() {
        _startPoint = null;
        _endPoint = null;
      });
    }
  }

  Offset _normalizePoint(Offset point) {
    // Convert screen coordinates to normalized page coordinates (0.0 to 1.0)
    final adjustedPoint = (point - widget.offset) / widget.scale;
    return Offset(
      adjustedPoint.dx / widget.pageSize.width,
      adjustedPoint.dy / widget.pageSize.height,
    );
  }

  void _createPathAnnotation() {
    final annotation = Annotation(
      id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
      pieceId: '', // Will be set by parent
      page: 1, // Will be set by parent
      layerId: 'default',
      colorTag: widget.currentColorTag,
      tool: widget.currentTool,
      createdAt: DateTime.now(),
      path: _currentPath,
    );

    widget.onAnnotationCreated(annotation);
  }

  void _createBoundedAnnotation() {
    if (_startPoint == null) return;

    final endPoint = _endPoint ?? _startPoint!;
    final bounds = Rect.fromPoints(_startPoint!, endPoint);

    if (widget.currentTool == AnnotationTool.text) {
      _showTextDialog(bounds);
    } else if (widget.currentTool == AnnotationTool.stamp) {
      _showStampDialog(bounds);
    }
  }

  void _showTextDialog(Rect bounds) {
    showDialog(
      context: context,
      builder: (context) => _TextAnnotationDialog(
        onSave: (text) {
          final annotation = Annotation(
            id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
            pieceId: '', // Will be set by parent
            page: 1, // Will be set by parent
            layerId: 'default',
            colorTag: widget.currentColorTag,
            tool: widget.currentTool,
            createdAt: DateTime.now(),
            text: text,
            bounds: bounds,
          );

          widget.onAnnotationCreated(annotation);
        },
      ),
    );
  }

  void _showStampDialog(Rect bounds) {
    showDialog(
      context: context,
      builder: (context) => _StampAnnotationDialog(
        onSave: (stampType) {
          final annotation = Annotation(
            id: 'annotation_${DateTime.now().millisecondsSinceEpoch}',
            pieceId: '', // Will be set by parent
            page: 1, // Will be set by parent
            layerId: 'default',
            colorTag: widget.currentColorTag,
            tool: widget.currentTool,
            createdAt: DateTime.now(),
            stampType: stampType,
            bounds: bounds,
          );

          widget.onAnnotationCreated(annotation);
        },
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset> currentPath;
  final AnnotationTool currentTool;
  final ColorTag currentColorTag;
  final double scale;
  final Offset offset;
  final Size pageSize;
  final Offset? startPoint;
  final Offset? endPoint;

  _DrawingPainter({
    required this.currentPath,
    required this.currentTool,
    required this.currentColorTag,
    required this.scale,
    required this.offset,
    required this.pageSize,
    this.startPoint,
    this.endPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentPath.isNotEmpty && (currentTool == AnnotationTool.pen || 
                                   currentTool == AnnotationTool.highlighter)) {
      _drawCurrentPath(canvas);
    }

    if (startPoint != null && endPoint != null) {
      _drawSelectionRect(canvas);
    }
  }

  void _drawCurrentPath(Canvas canvas) {
    final color = _getColorForTag(currentColorTag);
    final paint = Paint()
      ..color = currentTool == AnnotationTool.highlighter 
          ? color.withOpacity(0.3) 
          : color
      ..strokeWidth = currentTool == AnnotationTool.highlighter ? 8.0 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final scaledPath = currentPath.map((point) => 
      Offset(point.dx * pageSize.width, point.dy * pageSize.height) * scale + offset
    ).toList();

    if (scaledPath.isNotEmpty) {
      path.moveTo(scaledPath.first.dx, scaledPath.first.dy);
      for (int i = 1; i < scaledPath.length; i++) {
        path.lineTo(scaledPath[i].dx, scaledPath[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawSelectionRect(Canvas canvas) {
    final color = _getColorForTag(currentColorTag);
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeDashArray = [5.0, 5.0]; // Dashed line

    final rect = Rect.fromPoints(
      Offset(startPoint!.dx * pageSize.width, startPoint!.dy * pageSize.height) * scale + offset,
      Offset(endPoint!.dx * pageSize.width, endPoint!.dy * pageSize.height) * scale + offset,
    );

    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }

  Color _getColorForTag(ColorTag tag) {
    switch (tag) {
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

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return currentPath != oldDelegate.currentPath ||
           startPoint != oldDelegate.startPoint ||
           endPoint != oldDelegate.endPoint;
  }
}

class _TextAnnotationDialog extends StatefulWidget {
  final Function(String) onSave;

  const _TextAnnotationDialog({required this.onSave});

  @override
  State<_TextAnnotationDialog> createState() => _TextAnnotationDialogState();
}

class _TextAnnotationDialogState extends State<_TextAnnotationDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Text Annotation'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Enter your annotation text...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onSave(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _StampAnnotationDialog extends StatelessWidget {
  final Function(String) onSave;

  const _StampAnnotationDialog({required this.onSave});

  @override
  Widget build(BuildContext context) {
    final stamps = [
      'fingering',
      'pedal',
      'crescendo',
      'diminuendo',
      'accent',
      'staccato',
      'legato',
    ];

    return AlertDialog(
      title: const Text('Select Stamp'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: stamps.map((stamp) => ListTile(
          title: Text(stamp.substring(0, 1).toUpperCase() + stamp.substring(1)),
          onTap: () {
            widget.onSave(stamp);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }
}
