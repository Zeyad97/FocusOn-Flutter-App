import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/piece.dart';
import '../models/spot.dart';
import '../models/annotation.dart' as AppAnnotation;
import 'pdf_viewer/widgets/annotation_toolbar.dart';

class PDFViewerScreen extends ConsumerStatefulWidget {
  final Piece piece;
  final bool isAnnotationMode;

  const PDFViewerScreen({
    Key? key,
    required this.piece,
    this.isAnnotationMode = false,
  }) : super(key: key);

  @override
  ConsumerState<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends ConsumerState<PDFViewerScreen> {
  late PdfViewerController _pdfViewerController;
  int currentPage = 1;
  double _zoomLevel = 1.0;
  
  // Annotation state
  bool _isAnnotationMode = false;
  AppAnnotation.AnnotationTool _currentTool = AppAnnotation.AnnotationTool.pen;
  AppAnnotation.ColorTag _currentColor = AppAnnotation.ColorTag.red;
  List<AppAnnotation.Annotation> _annotations = [];
  List<Offset> _currentDrawingPoints = [];
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _isAnnotationMode = widget.isAnnotationMode;
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _toggleAnnotationMode() {
    setState(() {
      _isAnnotationMode = !_isAnnotationMode;
      if (!_isAnnotationMode) {
        _currentDrawingPoints.clear();
        _isDrawing = false;
      }
    });
  }

  void _onToolChanged(AppAnnotation.AnnotationTool tool) {
    setState(() {
      _currentTool = tool;
      _currentDrawingPoints.clear();
      _isDrawing = false;
    });
  }

  void _onColorChanged(AppAnnotation.ColorTag color) {
    setState(() {
      _currentColor = color;
    });
  }

  void _onUndo() {
    if (_annotations.isNotEmpty) {
      setState(() {
        _annotations.removeLast();
      });
    }
  }

  void _onRedo() {
    // Implement redo functionality if needed
  }

  void _onClearAll() {
    setState(() {
      _annotations.clear();
      _currentDrawingPoints.clear();
      _isDrawing = false;
    });
  }

  void _handlePanStart(DragStartDetails details) {
    if (!_isAnnotationMode || _currentTool == AppAnnotation.AnnotationTool.eraser) return;
    
    setState(() {
      _isDrawing = true;
      _currentDrawingPoints = [details.localPosition];
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isAnnotationMode || !_isDrawing) return;
    
    setState(() {
      _currentDrawingPoints.add(details.localPosition);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isAnnotationMode || !_isDrawing || _currentDrawingPoints.isEmpty) return;
    
    // Create annotation from current drawing
    final annotation = AppAnnotation.Annotation.legacy(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pieceId: widget.piece.id,
      page: currentPage,
      layerId: 'default',
      tool: _currentTool,
      colorTag: _currentColor,
      createdAt: DateTime.now(),
      path: List.from(_currentDrawingPoints),
    );
    
    setState(() {
      _annotations.add(annotation);
      _currentDrawingPoints.clear();
      _isDrawing = false;
    });
  }

  void _handleTap(TapUpDetails details) {
    if (!_isAnnotationMode) return;
    
    if (_currentTool == AppAnnotation.AnnotationTool.eraser) {
      // Find annotation to erase at tap position
      final tapPosition = details.localPosition;
      _annotations.removeWhere((annotation) {
        // Simple bounds check for erasing
        return annotation.data is AppAnnotation.VectorPath &&
               (annotation.data as AppAnnotation.VectorPath).points.any((point) =>
                 (point - tapPosition).distance < 20.0);
      });
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.piece.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Annotation mode toggle
          IconButton(
            icon: Icon(
              _isAnnotationMode ? Icons.edit : Icons.edit_outlined,
              color: _isAnnotationMode ? Colors.blue : null,
            ),
            onPressed: _toggleAnnotationMode,
            tooltip: 'Toggle Annotation Mode',
          ),
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                _zoomLevel = (_zoomLevel * 1.2).clamp(0.5, 3.0);
              });
              _pdfViewerController.zoomLevel = _zoomLevel;
            },
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                _zoomLevel = (_zoomLevel / 1.2).clamp(0.5, 3.0);
              });
              _pdfViewerController.zoomLevel = _zoomLevel;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Page indicator
          Container(
            padding: EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Page $currentPage'),
                Text('Zoom: ${(_zoomLevel * 100).toInt()}%'),
              ],
            ),
          ),
          
          // Annotation toolbar (when in annotation mode)
          if (_isAnnotationMode)
            AnnotationToolbar(
              currentTool: _currentTool,
              currentColorTag: _currentColor,
              isAnnotationMode: _isAnnotationMode,
              onToolChanged: _onToolChanged,
              onColorChanged: _onColorChanged,
              onAnnotationModeToggle: _toggleAnnotationMode,
              onUndo: _onUndo,
              onRedo: _onRedo,
              onClear: _onClearAll,
            ),
          
          // PDF Viewer with annotation overlay
          Expanded(
            child: Stack(
              children: [
                // PDF Viewer
                SfPdfViewer.asset(
                  widget.piece.pdfFilePath,
                  controller: _pdfViewerController,
                  onPageChanged: (PdfPageChangedDetails details) {
                    setState(() {
                      currentPage = details.newPageNumber;
                    });
                  },
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    print('PDF loaded with ${details.document.pages.count} pages');
                  },
                  onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to load PDF: ${details.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
                
                // Annotation interaction layer
                if (_isAnnotationMode)
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: _handlePanStart,
                      onPanUpdate: _handlePanUpdate,
                      onPanEnd: _handlePanEnd,
                      onTapUp: _handleTap,
                      child: CustomPaint(
                        painter: AnnotationOverlayPainter(
                          annotations: _annotations.where((a) => a.page == currentPage).toList(),
                          currentDrawingPoints: _currentDrawingPoints,
                          currentTool: _currentTool,
                          currentColor: _currentColor,
                          zoomLevel: _zoomLevel,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Simple spot dialog for future implementation
class _EditSpotDialog extends StatefulWidget {
  final Piece piece;
  final int pageNumber;
  final Offset position;
  final Spot? spot;

  const _EditSpotDialog({
    Key? key,
    required this.piece,
    required this.pageNumber,
    required this.position,
    this.spot,
  }) : super(key: key);

  @override
  State<_EditSpotDialog> createState() => _EditSpotDialogState();
}

class _EditSpotDialogState extends State<_EditSpotDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.spot?.title ?? '');
    _descriptionController = TextEditingController(text: widget.spot?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.spot == null ? 'Create Practice Spot' : 'Edit Practice Spot'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Text('Page: ${widget.pageNumber}'),
            Text('Position: (${widget.position.dx.toStringAsFixed(2)}, ${widget.position.dy.toStringAsFixed(2)})'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isNotEmpty) {
              Navigator.of(context).pop({
                'title': title,
                'description': _descriptionController.text.trim(),
                'page': widget.pageNumber,
                'position': widget.position,
              });
            }
          },
          child: Text(widget.spot == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}

/// Custom painter for rendering annotations and current drawing
class AnnotationOverlayPainter extends CustomPainter {
  final List<AppAnnotation.Annotation> annotations;
  final List<Offset> currentDrawingPoints;
  final AppAnnotation.AnnotationTool currentTool;
  final AppAnnotation.ColorTag currentColor;
  final double zoomLevel;

  AnnotationOverlayPainter({
    required this.annotations,
    required this.currentDrawingPoints,
    required this.currentTool,
    required this.currentColor,
    required this.zoomLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw existing annotations
    for (final annotation in annotations) {
      _drawAnnotation(canvas, annotation, size);
    }

    // Draw current drawing stroke
    if (currentDrawingPoints.isNotEmpty) {
      _drawCurrentStroke(canvas, size);
    }
  }

  void _drawAnnotation(Canvas canvas, AppAnnotation.Annotation annotation, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (annotation.tool) {
      case AppAnnotation.AnnotationTool.pen:
        paint
          ..color = _getColorFromTag(annotation.colorTag)
          ..strokeWidth = 2.0 * zoomLevel
          ..style = PaintingStyle.stroke;
        break;
      case AppAnnotation.AnnotationTool.highlighter:
        paint
          ..color = _getColorFromTag(annotation.colorTag).withOpacity(0.3)
          ..strokeWidth = 8.0 * zoomLevel
          ..style = PaintingStyle.stroke;
        break;
      default:
        paint
          ..color = _getColorFromTag(annotation.colorTag)
          ..strokeWidth = 2.0 * zoomLevel
          ..style = PaintingStyle.stroke;
        break;
    }

    if (annotation.data is AppAnnotation.VectorPath) {
      final vectorPath = annotation.data as AppAnnotation.VectorPath;
      _drawPath(canvas, vectorPath.points, paint, size);
    }
  }

  void _drawCurrentStroke(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (currentTool) {
      case AppAnnotation.AnnotationTool.pen:
        paint
          ..color = _getColorFromTag(currentColor)
          ..strokeWidth = 2.0 * zoomLevel
          ..style = PaintingStyle.stroke;
        break;
      case AppAnnotation.AnnotationTool.highlighter:
        paint
          ..color = _getColorFromTag(currentColor).withOpacity(0.3)
          ..strokeWidth = 8.0 * zoomLevel
          ..style = PaintingStyle.stroke;
        break;
      default:
        paint
          ..color = _getColorFromTag(currentColor)
          ..strokeWidth = 2.0 * zoomLevel
          ..style = PaintingStyle.stroke;
        break;
    }

    _drawPath(canvas, currentDrawingPoints, paint, size);
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint, Size size) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  Color _getColorFromTag(AppAnnotation.ColorTag tag) {
    switch (tag) {
      case AppAnnotation.ColorTag.red:
        return Colors.red;
      case AppAnnotation.ColorTag.blue:
        return Colors.blue;
      case AppAnnotation.ColorTag.yellow:
        return Colors.yellow.shade700;
      case AppAnnotation.ColorTag.green:
        return Colors.green;
      case AppAnnotation.ColorTag.purple:
        return Colors.purple;
    }
  }

  @override
  bool shouldRepaint(AnnotationOverlayPainter oldDelegate) {
    return annotations != oldDelegate.annotations ||
           currentDrawingPoints != oldDelegate.currentDrawingPoints ||
           currentTool != oldDelegate.currentTool ||
           currentColor != oldDelegate.currentColor ||
           zoomLevel != oldDelegate.zoomLevel;
  }
}
