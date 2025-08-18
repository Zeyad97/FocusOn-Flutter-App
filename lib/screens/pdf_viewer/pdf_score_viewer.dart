import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/piece.dart';
import '../../models/spot.dart';
import '../../theme/app_theme.dart';
import 'widgets/pdf_toolbar.dart';
import 'widgets/spot_overlay.dart';
import 'widgets/annotation_toolbar.dart' show AnnotationToolbar, AnnotationTool, PDFAnnotation, AnnotationPainter, CurrentDrawingPainter;
import 'widgets/metronome_widget.dart';

/// PDF viewing modes for different reading experiences
enum ViewMode {
  singlePage('Single Page'),
  twoPage('Two Page'),
  verticalScroll('Vertical Scroll'),
  grid('Grid'),
  list('List');

  const ViewMode(this.displayName);
  final String displayName;
}

/// Professional PDF score viewer with zero-lag reading experience
class PDFScoreViewer extends ConsumerStatefulWidget {
  final Piece piece;
  final String? pdfPath;

  const PDFScoreViewer({
    super.key,
    required this.piece,
    this.pdfPath,
  });

  @override
  ConsumerState<PDFScoreViewer> createState() => _PDFScoreViewerState();
}

class _PDFScoreViewerState extends ConsumerState<PDFScoreViewer> {
  late PdfViewerController _pdfController;
  ViewMode _viewMode = ViewMode.singlePage;
  bool _isSpotMode = false;
  bool _isAnnotationMode = false;
  bool _showMetronome = false;
  int _currentPage = 1;
  int _totalPages = 1;
  double _zoomLevel = 1.0;
  List<Spot> _spots = [];
  List<PDFAnnotation> _annotations = [];
  AnnotationTool _selectedTool = AnnotationTool.pen;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 2.0;
  List<Offset> _currentAnnotationPoints = [];
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _spots = widget.piece.spots;
    
    // Navigate to last viewed page if available
    if (widget.piece.lastViewedPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pdfController.jumpToPage(widget.piece.lastViewedPage!);
      });
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
    });
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
    // TODO: Save page to database
  }

  void _onSpotTap(TapUpDetails details, Size size) {
    if (!_isSpotMode) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Convert to relative coordinates (0.0 to 1.0)
    final x = localPosition.dx / size.width;
    final y = localPosition.dy / size.height;

    // Ensure coordinates are within bounds
    if (x >= 0 && x <= 1 && y >= 0 && y <= 1) {
      _showSpotCreationDialog(x, y);
    }
  }

  void _showSpotCreationDialog(double x, double y) {
    showDialog(
      context: context,
      builder: (context) => SpotCreationDialog(
        position: Offset(x, y),
        page: _currentPage,
        onSpotCreated: (spot) {
          // Set the piece ID and add to spots list
          final updatedSpot = Spot(
            id: spot.id,
            pieceId: widget.piece.id,
            title: spot.title,
            description: spot.description,
            pageNumber: spot.pageNumber,
            x: spot.x,
            y: spot.y,
            width: spot.width,
            height: spot.height,
            priority: spot.priority,
            readinessLevel: spot.readinessLevel,
            color: spot.color,
            createdAt: spot.createdAt,
            updatedAt: spot.updatedAt,
            nextDue: spot.nextDue,
            practiceCount: spot.practiceCount,
          );
          
          setState(() {
            _spots.add(updatedSpot);
            _isSpotMode = false; // Exit spot mode after creation
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Practice spot "${spot.title}" created!'),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // TODO: Save to database
        },
      ),
    );
  }

  // Annotation drawing methods
  void _onAnnotationPanStart(DragStartDetails details) {
    if (!_isAnnotationMode) return;
    
    setState(() {
      _isDrawing = true;
      _currentAnnotationPoints = [details.localPosition];
    });
  }

  void _onAnnotationPanUpdate(DragUpdateDetails details) {
    if (!_isAnnotationMode || !_isDrawing) return;
    
    setState(() {
      _currentAnnotationPoints.add(details.localPosition);
    });
  }

  void _onAnnotationPanEnd(DragEndDetails details) {
    if (!_isAnnotationMode || !_isDrawing) return;
    
    if (_currentAnnotationPoints.length > 1) {
      // Create annotation from current drawing
      final annotation = PDFAnnotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pageNumber: _currentPage,
        tool: _selectedTool,
        color: _selectedColor,
        strokeWidth: _strokeWidth,
        points: List.from(_currentAnnotationPoints),
        createdAt: DateTime.now(),
      );
      
      setState(() {
        _annotations.add(annotation);
        _currentAnnotationPoints.clear();
        _isDrawing = false;
      });
      
      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedTool.name.toUpperCase()} annotation added!'),
          backgroundColor: _selectedColor,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      setState(() {
        _currentAnnotationPoints.clear();
        _isDrawing = false;
      });
    }
  }

  void _onSpotSelected(Spot spot) {
    // Navigate to spot's page
    if (spot.pageNumber != _currentPage) {
      _pdfController.jumpToPage(spot.pageNumber);
    }
    
    // TODO: Show spot details or practice session
  }

  Widget _buildPDFViewer() {
    final pdfPath = widget.pdfPath ?? widget.piece.pdfFilePath;
    
    // Check if we have a valid file path
    if (pdfPath != null && pdfPath.isNotEmpty && !pdfPath.startsWith('assets/')) {
      // For actual file imports
      return SfPdfViewer.file(
        File(pdfPath),
        controller: _pdfController,
        onDocumentLoaded: _onDocumentLoaded,
        onPageChanged: _onPageChanged,
        pageLayoutMode: _getPageLayoutMode(),
        scrollDirection: _viewMode == ViewMode.verticalScroll 
            ? PdfScrollDirection.vertical 
            : PdfScrollDirection.horizontal,
        enableDoubleTapZooming: true,
        enableTextSelection: false,
        canShowScrollHead: false,
        canShowScrollStatus: false,
      );
    } else {
      // For demo/asset files
      return SfPdfViewer.asset(
        'assets/demo_score.pdf',
        controller: _pdfController,
        onDocumentLoaded: _onDocumentLoaded,
        onPageChanged: _onPageChanged,
        pageLayoutMode: _getPageLayoutMode(),
        scrollDirection: _viewMode == ViewMode.verticalScroll 
            ? PdfScrollDirection.vertical 
            : PdfScrollDirection.horizontal,
        enableDoubleTapZooming: true,
        enableTextSelection: false,
        canShowScrollHead: false,
        canShowScrollStatus: false,
      );
    }
  }

  PdfPageLayoutMode _getPageLayoutMode() {
    return switch (_viewMode) {
      ViewMode.singlePage => PdfPageLayoutMode.single,
      ViewMode.twoPage => PdfPageLayoutMode.continuous,
      ViewMode.verticalScroll => PdfPageLayoutMode.continuous,
      _ => PdfPageLayoutMode.single,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top toolbar
            PDFToolbar(
              piece: widget.piece,
              currentPage: _currentPage,
              totalPages: _totalPages,
              zoomLevel: _zoomLevel,
              viewMode: _viewMode,
              isSpotMode: _isSpotMode,
              isAnnotationMode: _isAnnotationMode,
              onPageChanged: (page) => _pdfController.jumpToPage(page),
              onViewModeChanged: (mode) => setState(() => _viewMode = mode),
              onSpotModeToggle: () => setState(() {
                _isSpotMode = !_isSpotMode;
                if (_isSpotMode) _isAnnotationMode = false;
              }),
              onAnnotationModeToggle: () => setState(() {
                _isAnnotationMode = !_isAnnotationMode;
                if (_isAnnotationMode) _isSpotMode = false;
              }),
              onZoomIn: () => _pdfController.zoomLevel = _pdfController.zoomLevel * 1.25,
              onZoomOut: () => _pdfController.zoomLevel = _pdfController.zoomLevel * 0.8,
              onFitWidth: () => _pdfController.zoomLevel = 1.0,
              onMetronomeToggle: () => setState(() => _showMetronome = !_showMetronome),
              onClose: () => Navigator.pop(context),
            ),
            
            // Main content area
            Expanded(
              child: Stack(
                children: [
                  // PDF Viewer with gesture detection
                  GestureDetector(
                    onTapUp: (details) {
                      if (_isSpotMode) {
                        final size = context.size!;
                        _onSpotTap(details, size);
                      }
                    },
                    onPanStart: _isAnnotationMode ? _onAnnotationPanStart : null,
                    onPanUpdate: _isAnnotationMode ? _onAnnotationPanUpdate : null,
                    onPanEnd: _isAnnotationMode ? _onAnnotationPanEnd : null,
                    child: Container(
                      decoration: _isSpotMode ? BoxDecoration(
                        border: Border.all(
                          color: AppColors.errorRed.withOpacity(0.5),
                          width: 3,
                        ),
                      ) : _isAnnotationMode ? BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.5),
                          width: 3,
                        ),
                      ) : null,
                      child: Stack(
                        children: [
                          _buildPDFViewer(),
                          
                          // Spot mode overlay instruction
                          if (_isSpotMode)
                            Positioned(
                              top: 20,
                              left: 20,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '🎯 Tap anywhere to create a practice spot',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                          // Annotation mode overlay instruction  
                          if (_isAnnotationMode)
                            Positioned(
                              top: 20,
                              left: 20,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '✏️ Draw on the PDF with your finger',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Spot overlay - show spots with better visibility
                  if (_spots.isNotEmpty)
                    Positioned.fill(
                      child: SpotOverlay(
                        spots: _spots.where((s) => s.pageNumber == _currentPage).toList(),
                        pageWidth: MediaQuery.of(context).size.width,
                        pageHeight: MediaQuery.of(context).size.height,
                        zoomLevel: _zoomLevel,
                        onSpotTapped: _onSpotSelected,
                        onSpotLongPressed: _onSpotSelected,
                      ),
                    ),
                  
                  // Debug overlay to show spot count
                  if (_spots.isNotEmpty)
                    Positioned(
                      top: 60,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Spots: ${_spots.where((s) => s.pageNumber == _currentPage).length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Annotation canvas overlay
                  if (_isAnnotationMode)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: AnnotationPainter(
                          annotations: _annotations.where((a) => a.pageNumber == _currentPage).toList(),
                          zoomLevel: _zoomLevel,
                        ),
                      ),
                    ),
                  
                  // Current drawing overlay
                  if (_isAnnotationMode && _isDrawing && _currentAnnotationPoints.isNotEmpty)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CurrentDrawingPainter(
                          points: _currentAnnotationPoints,
                          color: _selectedColor,
                          strokeWidth: _strokeWidth,
                        ),
                      ),
                    ),
                  
                  // Annotation toolbar
                  if (_isAnnotationMode)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: AnnotationToolbar(
                        selectedTool: _selectedTool,
                        selectedColor: _selectedColor,
                        strokeWidth: _strokeWidth,
                        canUndo: _annotations.isNotEmpty,
                        onToolChanged: (tool) {
                          setState(() {
                            _selectedTool = tool;
                          });
                        },
                        onColorChanged: (color) {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        onStrokeWidthChanged: (width) {
                          setState(() {
                            _strokeWidth = width;
                          });
                        },
                        onUndo: () {
                          setState(() {
                            if (_annotations.isNotEmpty) {
                              _annotations.removeLast();
                            }
                          });
                        },
                        onClear: () {
                          setState(() {
                            _annotations.removeWhere((a) => a.pageNumber == _currentPage);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Annotations cleared for this page'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Metronome widget
                  if (_showMetronome)
                    Positioned(
                      top: 80,
                      right: 16,
                      child: MetronomeWidget(
                        isVisible: _showMetronome,
                        onClose: () => setState(() => _showMetronome = false),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo viewer for testing without actual PDF files
class DemoScoreViewer extends StatelessWidget {
  final Piece piece;

  const DemoScoreViewer({
    super.key,
    required this.piece,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(piece.title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 120,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Demo Score Viewer',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Viewing: ${piece.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'by ${piece.composer}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.text.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Spots: ${piece.spots.length}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (piece.spots.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Next practice spots:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...piece.spots.take(3).map((spot) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: spot.displayColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: spot.displayColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: spot.displayColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        spot.title,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${spot.priority.displayName})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.text.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
