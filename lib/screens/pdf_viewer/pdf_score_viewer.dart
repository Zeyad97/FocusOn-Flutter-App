import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/piece.dart';
import '../../models/spot.dart';
import '../../models/annotation.dart' as AppAnnotation;
import '../../theme/app_theme.dart';
import '../../services/spot_service.dart';
import '../../services/annotation_service.dart';
import '../../services/piece_service.dart';
import '../../providers/unified_library_provider.dart';
import 'widgets/pdf_toolbar.dart';
import 'widgets/spot_overlay.dart';
import 'widgets/annotation_toolbar.dart';
import 'widgets/metronome_widget.dart';
import 'widgets/pdf_zoom_controls.dart';

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
  final int? initialPage;

  const PDFScoreViewer({
    super.key,
    required this.piece,
    this.pdfPath,
    this.initialPage,
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
  int _spotRefreshCounter = 0; // Add counter to force SpotOverlay refresh
  
  // Spot movement state
  Spot? _selectedSpotForMoving;
  Offset? _spotDragStartPosition;
  
  // Annotation state
  AppAnnotation.AnnotationTool _currentTool = AppAnnotation.AnnotationTool.pen;
  AppAnnotation.ColorTag _currentColor = AppAnnotation.ColorTag.red;
  List<AppAnnotation.Annotation> _annotations = [];
  List<Offset> _currentDrawingPoints = [];
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _spots = widget.piece.spots;
    
    // Load spots and annotations from database
    _loadSpotsFromDatabase();
    _loadAnnotationsFromDatabase();
    
    // Navigate to initial page or last viewed page if available
    final targetPage = widget.initialPage ?? widget.piece.lastViewedPage;
    if (targetPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pdfController.jumpToPage(targetPage);
      });
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  // Annotation callback methods
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

  void _onAnnotationModeToggle() {
    setState(() {
      _isAnnotationMode = !_isAnnotationMode;
      _currentDrawingPoints.clear();
      _isDrawing = false;
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
    // TODO: Implement redo functionality
  }

  void _onClear() {
    setState(() {
      _annotations.clear();
      _currentDrawingPoints.clear();
      _isDrawing = false;
    });
    
    // Clear annotations from cache (database deletion not implemented yet)
    _clearAnnotationsFromCache();
  }

  void _clearAnnotationsFromCache() {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      annotationService.clearCacheForPiece(widget.piece.id);
      print('PDFScoreViewer: Cleared annotations cache for piece ${widget.piece.id}');
    } catch (e) {
      print('PDFScoreViewer: Error clearing annotations cache: $e');
    }
  }

  // Annotation gesture handling
  void _onPanStart(DragStartDetails details) {
    if (!_isAnnotationMode) return;
    
    if (_currentTool == AppAnnotation.AnnotationTool.eraser) {
      // Eraser mode - find and remove annotations at this position
      _eraseAnnotationsAt(details.localPosition);
    } else {
      // Drawing mode
      setState(() {
        _isDrawing = true;
        _currentDrawingPoints.clear();
        _currentDrawingPoints.add(details.localPosition);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isAnnotationMode) return;
    
    if (_currentTool == AppAnnotation.AnnotationTool.eraser) {
      // Continue erasing
      _eraseAnnotationsAt(details.localPosition);
    } else if (_isDrawing) {
      // Continue drawing
      setState(() {
        _currentDrawingPoints.add(details.localPosition);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isAnnotationMode) return;
    
    if (_currentTool == AppAnnotation.AnnotationTool.eraser) {
      // Eraser finished
      return;
    }
    
    if (!_isDrawing) return;
    
    if (_currentDrawingPoints.isNotEmpty) {
      final annotation = AppAnnotation.Annotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pieceId: widget.piece.id,
        page: _currentPage,
        layerId: 'default',
        tool: _currentTool,
        colorTag: _currentColor,
        data: AppAnnotation.VectorPath(
          points: List.from(_currentDrawingPoints),
          strokeWidth: _currentTool == AppAnnotation.AnnotationTool.highlighter ? 8.0 : 2.0,
          color: _getColorFromTag(_currentColor),
        ),
        createdAt: DateTime.now(),
      );
      
      setState(() {
        _annotations.add(annotation);
        _currentDrawingPoints.clear();
        _isDrawing = false;
      });
      
      // Save annotation to database
      _saveAnnotationToDatabase(annotation);
    }
  }

  void _eraseAnnotationsAt(Offset position) {
    const double eraserRadius = 20.0; // Eraser radius in pixels
    
    setState(() {
      _annotations.removeWhere((annotation) {
        if (annotation.page != _currentPage) return false;
        
        // Check if annotation intersects with eraser position
        if (annotation.vectorPath != null) {
          final path = annotation.vectorPath!;
          return path.points.any((point) {
            final distance = (point - position).distance;
            return distance <= eraserRadius;
          });
        }
        
        return false;
      });
    });
  }

  Future<void> _saveAnnotationToDatabase(AppAnnotation.Annotation annotation) async {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      await annotationService.saveAnnotation(annotation);
      print('PDFScoreViewer: Saved annotation ${annotation.id} to database');
    } catch (e) {
      print('PDFScoreViewer: Error saving annotation to database: $e');
    }
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

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
    });
    
    // Update piece with correct page count if it's different
    if (widget.piece.totalPages != _totalPages) {
      print('PDFScoreViewer: Updating piece page count from ${widget.piece.totalPages} to $_totalPages');
      _updatePiecePageCount(_totalPages);
    }
  }
  
  Future<void> _updatePiecePageCount(int actualPageCount) async {
    try {
      final updatedPiece = widget.piece.copyWith(
        totalPages: actualPageCount,
        updatedAt: DateTime.now(),
      );
      
      final pieceService = ref.read(pieceServiceProvider);
      await pieceService.savePiece(updatedPiece);
      
      print('PDFScoreViewer: Successfully updated piece page count to $actualPageCount');
    } catch (e) {
      print('PDFScoreViewer: Failed to update piece page count: $e');
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
    // TODO: Save page to database
  }

  void _onSpotTap(dynamic details, Size size) {
    print('PDFScoreViewer: Tap detected - isSpotMode: $_isSpotMode');
    if (!_isSpotMode) return;

    // Get local position from either TapUpDetails or TapDownDetails
    final Offset localPosition;
    if (details is TapUpDetails) {
      localPosition = details.localPosition;
    } else if (details is TapDownDetails) {
      localPosition = details.localPosition;
    } else {
      print('PDFScoreViewer: Unknown details type: ${details.runtimeType}');
      return;
    }
    
    print('PDFScoreViewer: Local position: $localPosition, Container size: $size');
    
    // Convert to relative coordinates (0.0 to 1.0) based on the actual container size
    final x = localPosition.dx / size.width;
    final y = localPosition.dy / size.height;

    print('PDFScoreViewer: Relative coordinates: ($x, $y)');

    // Ensure coordinates are within bounds and allow unlimited spot creation
    if (x >= 0 && x <= 1 && y >= 0 && y <= 1) {
      print('PDFScoreViewer: Creating spot at coordinates: ($x, $y) on page $_currentPage');
      _showSpotCreationDialog(x, y);
    } else {
      print('PDFScoreViewer: Coordinates out of bounds: ($x, $y)');
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
            // Don't exit spot mode - allow continuous spot creation
            // User can manually exit spot mode when done
          });
          
          // Save spot to database so it appears in practice dashboard
          _saveSpotToDatabase(updatedSpot);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Practice spot "${spot.title}" created!'),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showSpotEditor(Spot spot) {
    openSpotEditor(context, spot).then((result) async {
      if (result != null) {
        // Refresh spots after editing with a small delay to ensure database is updated
        await Future.delayed(const Duration(milliseconds: 100));
        await _loadSpotsFromDatabase();
        
        // Force a rebuild by incrementing refresh counter and calling setState
        setState(() {
          _spotRefreshCounter++;
        });
      }
    });
  }

  void _onSpotSelected(Spot spot) {
    // Navigate to spot's page
    if (spot.pageNumber != _currentPage) {
      _pdfController.jumpToPage(spot.pageNumber);
    }
    
    // Show spot editor dialog
    _showSpotEditor(spot);
  }

  Future<void> _saveSpotToDatabase(Spot spot) async {
    try {
      final spotService = ref.read(spotServiceProvider);
      await spotService.saveSpot(spot);
      print('PDFScoreViewer: Saved spot "${spot.title}" to database');
      
      // CRITICAL: Refresh unified library so the spot appears in practice dashboard
      await ref.read(unifiedLibraryProvider.notifier).refresh();
      print('PDFScoreViewer: Refreshed unified library after saving spot');
      
      // Refresh spots and force SpotOverlay rebuild
      await _loadSpotsFromDatabase();
    } catch (e) {
      print('PDFScoreViewer: Error saving spot to database: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving spot: $e'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Corner tap navigation for concerts
  void _handleCornerTap(TapUpDetails details) {
    // Only handle corner taps when not in spot or annotation mode
    if (_isSpotMode || _isAnnotationMode) return;
    
    final screenSize = MediaQuery.of(context).size;
    final tapPosition = details.globalPosition;
    
    // Define corner areas (20% of screen width from each edge)
    final cornerWidth = screenSize.width * 0.2;
    final isLeftCorner = tapPosition.dx < cornerWidth;
    final isRightCorner = tapPosition.dx > (screenSize.width - cornerWidth);
    
    if (isLeftCorner) {
      // Left corner - previous page
      _previousPage();
    } else if (isRightCorner) {
      // Right corner - next page
      _nextPage();
    }
    // Middle area does nothing (preserves existing behavior)
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfController.jumpToPage(_currentPage - 1);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfController.jumpToPage(_currentPage + 1);
    }
  }

  // Spot movement methods
  void _onSpotLongPress(LongPressStartDetails details) {
    if (!_isSpotMode) return;
    
    final localPosition = details.localPosition;
    print('PDFScoreViewer: Long press detected at $localPosition');
    
    // Find if there's a spot at this position
    final tappedSpot = _findSpotAtPosition(localPosition);
    if (tappedSpot != null) {
      setState(() {
        _selectedSpotForMoving = tappedSpot;
        _spotDragStartPosition = localPosition;
      });
      print('PDFScoreViewer: Selected spot "${tappedSpot.title}" for moving');
      
      // Show feedback
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected "${tappedSpot.title}" - drag to move'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSpotDragStart(DragStartDetails details) {
    if (_selectedSpotForMoving == null) return;
    _spotDragStartPosition = details.localPosition;
    print('PDFScoreViewer: Starting to drag spot "${_selectedSpotForMoving!.title}"');
  }

  void _onSpotDragUpdate(DragUpdateDetails details) {
    if (_selectedSpotForMoving == null) return;
    
    // Visual feedback could be added here (like updating spot position in real-time)
    print('PDFScoreViewer: Dragging spot to ${details.localPosition}');
  }

  void _onSpotDragEnd(DragEndDetails details) {
    if (_selectedSpotForMoving == null || _spotDragStartPosition == null) return;
    
    final size = context.size!;
    final newPosition = _spotDragStartPosition!; // Use the last known position
    
    // Convert to relative coordinates
    final x = newPosition.dx / size.width;
    final y = newPosition.dy / size.height;
    
    if (x >= 0 && x <= 1 && y >= 0 && y <= 1) {
      print('PDFScoreViewer: Moving spot "${_selectedSpotForMoving!.title}" to ($x, $y)');
      
      // Update the spot position
      final updatedSpot = _selectedSpotForMoving!.copyWith(
        x: x,
        y: y,
        updatedAt: DateTime.now(),
      );
      
      setState(() {
        final index = _spots.indexWhere((s) => s.id == _selectedSpotForMoving!.id);
        if (index != -1) {
          _spots[index] = updatedSpot;
        }
        _selectedSpotForMoving = null;
        _spotDragStartPosition = null;
      });
      
      // Save the updated spot to database
      _saveSpotToDatabase(updatedSpot);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved "${updatedSpot.title}" to new position'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Reset selection if moved out of bounds
      setState(() {
        _selectedSpotForMoving = null;
        _spotDragStartPosition = null;
      });
    }
  }

  Spot? _findSpotAtPosition(Offset position) {
    final size = context.size!;
    final relativeX = position.dx / size.width;
    final relativeY = position.dy / size.height;
    
    // Find spot that contains this position (with some tolerance)
    for (final spot in _spots.where((s) => s.pageNumber == _currentPage)) {
      final spotLeft = spot.x - spot.width / 2;
      final spotRight = spot.x + spot.width / 2;
      final spotTop = spot.y - spot.height / 2;
      final spotBottom = spot.y + spot.height / 2;
      
      if (relativeX >= spotLeft && relativeX <= spotRight &&
          relativeY >= spotTop && relativeY <= spotBottom) {
        return spot;
      }
    }
    return null;
  }

  Future<void> _loadSpotsFromDatabase() async {
    try {
      final spotService = ref.read(spotServiceProvider);
      final databaseSpots = await spotService.getSpotsForPiece(widget.piece.id);
      
      setState(() {
        // Use database spots as the source of truth since they have the latest data
        _spots = databaseSpots;
        _spotRefreshCounter++; // Increment counter to force SpotOverlay refresh
      });
      
      print('PDFScoreViewer: Loaded ${databaseSpots.length} spots from database for piece ${widget.piece.id}');
    } catch (e) {
      print('PDFScoreViewer: Error loading spots from database: $e');
    }
  }

  Future<void> _loadAnnotationsFromDatabase() async {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      final annotations = await annotationService.getAnnotationsForPiece(widget.piece.id);
      setState(() {
        _annotations = annotations;
      });
      print('PDFScoreViewer: Loaded ${annotations.length} annotations from database for piece ${widget.piece.id}');
    } catch (e) {
      print('PDFScoreViewer: Error loading annotations from database: $e');
    }
  }

  Widget _buildPDFViewer() {
    final pdfPath = widget.pdfPath ?? widget.piece.pdfFilePath;
    
    // Check if we have a valid file path
    if (pdfPath != null && pdfPath.isNotEmpty && !pdfPath.startsWith('assets/')) {
      // For actual file imports - optimized for performance
      return SfPdfViewer.file(
        File(pdfPath),
        controller: _pdfController,
        onDocumentLoaded: _onDocumentLoaded,
        onPageChanged: _onPageChanged,
        pageLayoutMode: _getPageLayoutMode(),
        scrollDirection: _viewMode == ViewMode.verticalScroll 
            ? PdfScrollDirection.vertical 
            : PdfScrollDirection.horizontal,
        enableDoubleTapZooming: !_isSpotMode, // Disable zoom in spot mode
        enableTextSelection: false,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        pageSpacing: 0, // No spacing for smooth scrolling
        enableDocumentLinkAnnotation: false,
        interactionMode: _isSpotMode ? PdfInteractionMode.selection : PdfInteractionMode.pan,
        // Performance optimizations
        canShowPaginationDialog: false,
        enableHyperlinkNavigation: false,
        canShowPasswordDialog: false,
        initialScrollOffset: Offset.zero,
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
        enableDoubleTapZooming: !_isSpotMode, // Disable zoom in spot mode
        enableTextSelection: false,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        pageSpacing: 0, // No spacing for smooth scrolling
        enableDocumentLinkAnnotation: false,
        interactionMode: _isSpotMode ? PdfInteractionMode.selection : PdfInteractionMode.pan,
        // Performance optimizations
        canShowPaginationDialog: false,
        enableHyperlinkNavigation: false,
        canShowPasswordDialog: false,
        initialScrollOffset: Offset.zero,
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
              }),
              onAnnotationModeToggle: () => setState(() {
                _isAnnotationMode = !_isAnnotationMode;
              }),
              onZoomIn: () => _pdfController.zoomLevel = _pdfController.zoomLevel * 1.25,
              onZoomOut: () => _pdfController.zoomLevel = _pdfController.zoomLevel * 0.8,
              onFitWidth: () => _pdfController.zoomLevel = 1.0,
              onMetronomeToggle: () => setState(() => _showMetronome = !_showMetronome),
              onClose: () => Navigator.pop(context),
            ),
            
            // Annotation toolbar (only show when annotation mode is active)
            if (_isAnnotationMode)
              AnnotationToolbar(
                currentTool: _currentTool,
                currentColorTag: _currentColor,
                isAnnotationMode: _isAnnotationMode,
                onToolChanged: _onToolChanged,
                onColorChanged: _onColorChanged,
                onAnnotationModeToggle: _onAnnotationModeToggle,
                onUndo: _onUndo,
                onRedo: _onRedo,
                onClear: _onClear,
              ),
            
            // Main content area
            Expanded(
              child: Stack(
                children: [
                  // PDF Viewer with gesture detection
                  GestureDetector(
                    onTapUp: (details) {
                      print('PDF Viewer: Single tap detected at ${details.localPosition}');
                      if (_isSpotMode) {
                        final size = context.size!;
                        _onSpotTap(details, size);
                      }
                    },
                    onDoubleTapDown: (details) {
                      print('PDF Viewer: Double tap detected at ${details.localPosition}');
                      if (_isSpotMode) {
                        final size = context.size!;
                        _onSpotTap(details, size);
                      } else {
                        // Enable spot mode and create spot on double tap
                        setState(() {
                          _isSpotMode = true;
                        });
                        final size = context.size!;
                        _onSpotTap(details, size);
                      }
                    },
                    onLongPressStart: (details) {
                      if (_isSpotMode) {
                        print('PDF Viewer: Long press detected for spot movement');
                        _onSpotLongPress(details);
                      }
                    },
                    onPanStart: (details) {
                      if (_isAnnotationMode) {
                        _onPanStart(details);
                      } else if (_isSpotMode && _selectedSpotForMoving != null) {
                        print('PDF Viewer: Starting spot drag');
                        _onSpotDragStart(details);
                      }
                    },
                    onPanUpdate: (details) {
                      if (_isAnnotationMode) {
                        _onPanUpdate(details);
                      } else if (_isSpotMode && _selectedSpotForMoving != null) {
                        _onSpotDragUpdate(details);
                      }
                    },
                    onPanEnd: (details) {
                      if (_isAnnotationMode) {
                        _onPanEnd(details);
                      } else if (_isSpotMode && _selectedSpotForMoving != null) {
                        _onSpotDragEnd(details);
                      }
                    },
                    // Force gesture detection in spot mode or annotation mode
                    behavior: (_isSpotMode || _isAnnotationMode) ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
                    child: Container(
                      decoration: _isSpotMode ? BoxDecoration(
                        border: Border.all(
                          color: AppColors.errorRed.withOpacity(0.5),
                          width: 3,
                        ),
                      ) : null,
                      child: Stack(
                        children: [
                          // PDF Viewer with corner tap navigation
                          GestureDetector(
                            onTapUp: (details) => _handleCornerTap(details),
                            child: _buildPDFViewer(),
                          ),
                          
                          // Annotation overlay
                          if (_isAnnotationMode)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: AnnotationOverlayPainter(
                                  annotations: _annotations.where((a) => a.page == _currentPage).toList(),
                                  currentDrawingPoints: _currentDrawingPoints,
                                  currentTool: _currentTool,
                                  currentColor: _currentColor,
                                  zoomLevel: _zoomLevel,
                                ),
                              ),
                            ),
                          
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
                                child: Text(
                                  '✏️ ${_currentTool.name.toUpperCase()} mode - Draw on the score',
                                  style: const TextStyle(
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
                        key: ValueKey('spots_${_currentPage}_$_spotRefreshCounter'),
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
                  
                  // Enhanced zoom controls
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: PDFZoomControls(
                      zoomLevel: _zoomLevel,
                      onZoomIn: () {
                        final newZoom = (_zoomLevel * 1.25).clamp(0.25, 5.0);
                        _pdfController.zoomLevel = newZoom;
                        setState(() => _zoomLevel = newZoom);
                      },
                      onZoomOut: () {
                        final newZoom = (_zoomLevel * 0.8).clamp(0.25, 5.0);
                        _pdfController.zoomLevel = newZoom;
                        setState(() => _zoomLevel = newZoom);
                      },
                      onFitWidth: () {
                        _pdfController.zoomLevel = 1.0;
                        setState(() => _zoomLevel = 1.0);
                      },
                      onFitHeight: () {
                        _pdfController.zoomLevel = 1.2;
                        setState(() => _zoomLevel = 1.2);
                      },
                      onActualSize: () {
                        _pdfController.zoomLevel = 1.0;
                        setState(() => _zoomLevel = 1.0);
                      },
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
