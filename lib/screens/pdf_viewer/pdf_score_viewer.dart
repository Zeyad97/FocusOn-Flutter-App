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
import '../../services/bluetooth_pedal_service.dart';
import '../../providers/unified_library_provider.dart';
import 'widgets/pdf_toolbar.dart';
import 'widgets/spot_overlay.dart';
import 'widgets/annotation_toolbar.dart';
import 'widgets/annotation_toolbar_new.dart' as NewToolbar;
import 'widgets/metronome_widget.dart';
import 'widgets/pdf_zoom_controls.dart';
import '../../../widgets/layer_panel.dart';
import '../../../widgets/annotation_filter_panel.dart';

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
  
  // Annotation state - Enhanced with layers and filtering
  AppAnnotation.AnnotationTool _currentTool = AppAnnotation.AnnotationTool.pen;
  AppAnnotation.ColorTag _currentColor = AppAnnotation.ColorTag.red;
  List<AppAnnotation.Annotation> _annotations = [];
  List<AppAnnotation.AnnotationLayer> _layers = [];
  AppAnnotation.AnnotationLayer? _selectedLayer;
  String _selectedLayerId = 'default';
  AppAnnotation.AnnotationFilter _currentFilter = const AppAnnotation.AnnotationFilter();
  List<Offset> _currentDrawingPoints = [];
  bool _isDrawing = false;
  AppAnnotation.StampType? _selectedStamp;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _spots = widget.piece.spots;
    
    // Load spots and annotations from database
    _loadSpotsFromDatabase();
    _loadAnnotationsFromDatabase();
    _loadAnnotationLayersFromDatabase();
    
    // Initialize Bluetooth pedal support
    _initializeBluetoothPedal();
    
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
    // Stop Bluetooth pedal listening
    _stopBluetoothPedal();
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

  void _onStampSelected(AppAnnotation.StampType stamp) {
    setState(() {
      _selectedStamp = stamp;
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

  /// Transform screen coordinates to PDF document coordinates
  Offset _transformScreenToPdfCoordinates(Offset screenPosition) {
    // Store screen coordinates directly - let the rendering handle zoom transformation
    // This approach stores the raw touch position for better accuracy
    return screenPosition;
  }

  void _onTextInput(String text, Offset position) {
    if (text.isEmpty) return;
    
    final layerId = _selectedLayer?.id ?? 'default';
    
    // Transform screen coordinates to PDF coordinates
    final pdfPosition = _transformScreenToPdfCoordinates(position);
    
    final annotationData = AppAnnotation.TextData(
      text: text,
      position: pdfPosition,
      fontSize: 14.0,
      color: _getColorFromTag(_currentColor),
    );
    
    final annotation = AppAnnotation.Annotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pieceId: widget.piece.id,
      page: _currentPage,
      layerId: layerId,
      tool: AppAnnotation.AnnotationTool.text,
      colorTag: _currentColor,
      data: annotationData,
      createdAt: DateTime.now(),
    );
    
    setState(() {
      _annotations.add(annotation);
    });
    
    // Save annotation to database
    _saveAnnotationToDatabase(annotation);
  }

  void _showLayerPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.4,
          maxChildSize: 0.8,
          minChildSize: 0.2,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.layers, color: Theme.of(context).iconTheme.color),
                    const SizedBox(width: 8),
                    Text(
                      'Annotation Layers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _createNewLayer(),
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Layer',
                    ),
                  ],
                ),
              ),
              
              // Layer list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _layers.length,
                  itemBuilder: (context, index) {
                    final layer = _layers[index];
                    final isSelected = layer.id == _selectedLayerId;
                    
                    return ListTile(
                      leading: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: layer.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      title: Text(
                        layer.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  color: layer.isVisible ? null : Colors.grey,
                                ),
                                if (!layer.isVisible)
                                  Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                              ],
                            ),
                            onPressed: () {
                              _toggleLayerVisibility(layer.id);
                              setModalState(() {}); // Update the modal's UI
                            },
                            tooltip: layer.isVisible ? 'Hide Layer' : 'Show Layer',
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Rename'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'rename':
                                  _renameLayer(layer);
                                  break;
                                case 'delete':
                                  _deleteLayer(layer.id);
                                  break;
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () => _onLayerChanged(layer.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Theme.of(context).iconTheme.color),
                    const SizedBox(width: 8),
                    Text(
                      'Filter Annotations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentFilter = const AppAnnotation.AnnotationFilter();
                        });
                        setModalState(() {}); // Update modal UI
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              
              // Filter options
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Color filters
                      Text(
                        'Filter by Color:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: AppAnnotation.ColorTag.values.map((colorTag) {
                          final color = _getColorFromTag(colorTag);
                          final isSelected = _currentFilter.colorTags?.contains(colorTag) ?? false;
                          
                          return FilterChip(
                            label: Text(colorTag.name.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              _toggleColorFilter(colorTag);
                              setModalState(() {}); // Update modal UI
                            },
                            backgroundColor: color.withOpacity(0.1),
                            selectedColor: color.withOpacity(0.3),
                            avatar: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Tool filters
                      Text(
                        'Filter by Tool:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: AppAnnotation.AnnotationTool.values.map((tool) {
                          final isSelected = _currentFilter.tools?.contains(tool) ?? false;
                          
                          return FilterChip(
                            label: Text(_getToolName(tool)),
                            selected: isSelected,
                            onSelected: (selected) {
                              _toggleToolFilter(tool);
                              setModalState(() {}); // Update modal UI
                            },
                            avatar: Icon(
                              _getToolIcon(tool),
                              size: 16,
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Quick filters
                      Text(
                        'Quick Filters:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      CheckboxListTile(
                        title: const Text('Show Today'),
                        value: _currentFilter.showToday,
                        onChanged: (value) {
                          setState(() {
                            _currentFilter = _currentFilter.copyWith(
                              showToday: value ?? false,
                              showLast7Days: false,
                              showAll: false,
                            );
                          });
                          setModalState(() {}); // Update modal UI
                        },
                      ),
                      
                      CheckboxListTile(
                        title: const Text('Show Last 7 Days'),
                        value: _currentFilter.showLast7Days,
                        onChanged: (value) {
                          setState(() {
                            _currentFilter = _currentFilter.copyWith(
                              showLast7Days: value ?? false,
                              showToday: false,
                              showAll: false,
                            );
                          });
                          setModalState(() {}); // Update modal UI
                        },
                      ),
                      
                      CheckboxListTile(
                        title: const Text('Show All'),
                        value: _currentFilter.showAll,
                        onChanged: (value) {
                          setState(() {
                            _currentFilter = _currentFilter.copyWith(
                              showAll: value ?? false,
                              showToday: false,
                              showLast7Days: false,
                            );
                          });
                          setModalState(() {}); // Update modal UI
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  void _toggleColorFilter(AppAnnotation.ColorTag colorTag) {
    final currentColors = _currentFilter.colorTags?.toSet() ?? <AppAnnotation.ColorTag>{};
    
    if (currentColors.contains(colorTag)) {
      currentColors.remove(colorTag);
    } else {
      currentColors.add(colorTag);
    }
    
    setState(() {
      _currentFilter = _currentFilter.copyWith(
        colorTags: currentColors.isEmpty ? null : currentColors,
      );
    });
  }

  void _toggleToolFilter(AppAnnotation.AnnotationTool tool) {
    final currentTools = _currentFilter.tools?.toSet() ?? <AppAnnotation.AnnotationTool>{};
    
    if (currentTools.contains(tool)) {
      currentTools.remove(tool);
    } else {
      currentTools.add(tool);
    }
    
    setState(() {
      _currentFilter = _currentFilter.copyWith(
        tools: currentTools.isEmpty ? null : currentTools,
      );
    });
  }

  void _createNewLayer() {
    String name = '';
    AppAnnotation.ColorTag colorTag = AppAnnotation.ColorTag.blue;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Layer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Layer Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Color: '),
                  ...AppAnnotation.ColorTag.values.map((tag) {
                    final tagColor = _getColorFromTag(tag);
                    return GestureDetector(
                      onTap: () => setState(() => colorTag = tag),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: tagColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorTag == tag ? Colors.black : Colors.grey,
                            width: colorTag == tag ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the layer panel too
                if (name.isNotEmpty) {
                  final layer = AppAnnotation.AnnotationLayer(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    colorTag: colorTag,
                    isVisible: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  setState(() {
                    _layers.add(layer);
                    _selectedLayerId = layer.id;
                    _selectedLayer = layer;
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLayerVisibility(String layerId) async {
    // First update the local state
    final layerIndex = _layers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex == -1) return;

    final oldVisibility = _layers[layerIndex].isVisible;
    
    setState(() {
      _layers[layerIndex] = _layers[layerIndex].copyWith(
        isVisible: !_layers[layerIndex].isVisible,
      );
    });

    debugPrint('PDFScoreViewer: Layer ${layerId} visibility changed from $oldVisibility to ${_layers[layerIndex].isVisible}');

    // Save to database
    try {
      final annotationService = ref.read(annotationServiceProvider);
      await annotationService.updateLayer(widget.piece.id, _layers[layerIndex]);
      debugPrint('PDFScoreViewer: Layer visibility updated in database');
      
    } catch (e) {
      debugPrint('PDFScoreViewer: Error updating layer visibility: $e');
      // Revert the change if database update fails
      setState(() {
        _layers[layerIndex] = _layers[layerIndex].copyWith(isVisible: oldVisibility);
      });
    }
  }

  void _renameLayer(AppAnnotation.AnnotationLayer layer) {
    String name = layer.name;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Layer'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Layer Name',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: layer.name),
          onChanged: (value) => name = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (name.isNotEmpty && name != layer.name) {
                setState(() {
                  final layerIndex = _layers.indexWhere((l) => l.id == layer.id);
                  if (layerIndex != -1) {
                    _layers[layerIndex] = _layers[layerIndex].copyWith(name: name);
                  }
                });
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _deleteLayer(String layerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Layer'),
        content: const Text('Are you sure you want to delete this layer? All annotations in this layer will be moved to the default layer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                // Delete from database (moves annotations to default layer)
                final annotationService = ref.read(annotationServiceProvider);
                await annotationService.deleteLayer(widget.piece.id, layerId, deleteAnnotations: false);
                debugPrint('PDFScoreViewer: Layer deleted from database');
                
                // Update local state
                setState(() {
                  _layers.removeWhere((layer) => layer.id == layerId);
                  if (_selectedLayerId == layerId) {
                    _selectedLayerId = _layers.isNotEmpty ? _layers.first.id : 'default';
                    _selectedLayer = _layers.isNotEmpty ? _layers.first : null;
                  }
                });
                
                // Reload annotations to reflect the layer change
                await _loadAnnotationsFromDatabase();
                debugPrint('PDFScoreViewer: Annotations reloaded after layer deletion');
                
              } catch (e) {
                debugPrint('PDFScoreViewer: Error deleting layer: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting layer: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _refreshAnnotationDisplay() {
    setState(() {
      // Force rebuild of the entire widget tree to update the Consumer
      // This ensures the annotation overlay gets rebuilt with new layer visibility
    });
  }

  String _getToolName(AppAnnotation.AnnotationTool tool) {
    switch (tool) {
      case AppAnnotation.AnnotationTool.pen:
        return 'Pen';
      case AppAnnotation.AnnotationTool.highlighter:
        return 'Highlighter';
      case AppAnnotation.AnnotationTool.eraser:
        return 'Eraser';
      case AppAnnotation.AnnotationTool.text:
        return 'Text';
      case AppAnnotation.AnnotationTool.stamp:
        return 'Stamp';
    }
  }

  IconData _getToolIcon(AppAnnotation.AnnotationTool tool) {
    switch (tool) {
      case AppAnnotation.AnnotationTool.pen:
        return Icons.edit;
      case AppAnnotation.AnnotationTool.highlighter:
        return Icons.highlight;
      case AppAnnotation.AnnotationTool.eraser:
        return Icons.cleaning_services;
      case AppAnnotation.AnnotationTool.text:
        return Icons.text_fields;
      case AppAnnotation.AnnotationTool.stamp:
        return Icons.push_pin;
    }
  }

  void _showTextInputDialog(Offset position) {
    showDialog(
      context: context,
      builder: (context) {
        String text = '';
        return AlertDialog(
          title: const Text('Add Text Annotation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Make a little swipe in the place you want the text',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your text...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => text = value,
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (text.isNotEmpty) {
                  _onTextInput(text, position);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Handle layer management changes
  void _handleLayerVisibilityChanged() {
    setState(() {
      // Force rebuild of annotation overlay
    });
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
    
    // Handle text tool differently - show dialog instead of drawing
    if (_currentTool == AppAnnotation.AnnotationTool.text) {
      _showTextInputDialog(details.localPosition);
      return;
    }
    
    if (_currentTool == AppAnnotation.AnnotationTool.eraser) {
      // Eraser mode - find and remove annotations at this position
      _eraseAnnotationsAt(_transformScreenToPdfCoordinates(details.localPosition));
    } else {
      // Drawing mode
      setState(() {
        _isDrawing = true;
        _currentDrawingPoints.clear();
        _currentDrawingPoints.add(_transformScreenToPdfCoordinates(details.localPosition));
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isAnnotationMode) return;
    
    if (_currentTool == AppAnnotation.AnnotationTool.eraser) {
      // Continue erasing
      _eraseAnnotationsAt(_transformScreenToPdfCoordinates(details.localPosition));
    } else if (_isDrawing) {
      // Continue drawing
      setState(() {
        _currentDrawingPoints.add(_transformScreenToPdfCoordinates(details.localPosition));
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isAnnotationMode) return;
    
    if (_currentTool == AppAnnotation.AnnotationTool.eraser) {
      // Eraser finished
      return;
    }
    
    if (_currentTool == AppAnnotation.AnnotationTool.text) {
      // Text tool is handled differently, no drawing needed
      return;
    }
    
    if (!_isDrawing) return;
    
    if (_currentDrawingPoints.isNotEmpty) {
      final layerId = _selectedLayer?.id ?? 'default';
      
      dynamic annotationData;
      
      switch (_currentTool) {
        case AppAnnotation.AnnotationTool.pen:
        case AppAnnotation.AnnotationTool.highlighter:
          annotationData = AppAnnotation.VectorPath(
            points: List.from(_currentDrawingPoints),
            strokeWidth: _currentTool == AppAnnotation.AnnotationTool.highlighter ? 8.0 : 2.0,
            color: _getColorFromTag(_currentColor),
            blendMode: _currentTool == AppAnnotation.AnnotationTool.highlighter ? BlendMode.multiply : BlendMode.srcOver,
          );
          break;
        case AppAnnotation.AnnotationTool.stamp:
          // For stamp, use the first point as position
          annotationData = AppAnnotation.StampData(
            type: _selectedStamp ?? AppAnnotation.StampType.fingering1,
            position: _currentDrawingPoints.first,
            size: 24.0,
            color: _getColorFromTag(_currentColor),
          );
          break;
        case AppAnnotation.AnnotationTool.text:
          // Text is handled in _onPanStart now, skip
          setState(() {
            _currentDrawingPoints.clear();
            _isDrawing = false;
          });
          return;
        case AppAnnotation.AnnotationTool.eraser:
          // Eraser is handled differently, skip creating annotation
          setState(() {
            _currentDrawingPoints.clear();
            _isDrawing = false;
          });
          return;
      }
      
      final annotation = AppAnnotation.Annotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pieceId: widget.piece.id,
        page: _currentPage,
        layerId: layerId,
        tool: _currentTool,
        colorTag: _currentColor,
        data: annotationData,
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
    const double eraserRadius = 30.0; // Eraser radius in pixels
    
    setState(() {
      // Find annotations to remove
      final annotationsToRemove = <AppAnnotation.Annotation>[];
      
      for (final annotation in _annotations) {
        if (annotation.page != _currentPage) continue;
        
        bool shouldErase = false;
        
        // Check different annotation types
        switch (annotation.tool) {
          case AppAnnotation.AnnotationTool.pen:
          case AppAnnotation.AnnotationTool.highlighter:
            // For path-based annotations, check if any point is within eraser radius
            if (annotation.vectorPath != null) {
              final path = annotation.vectorPath!;
              shouldErase = path.points.any((point) {
                final distance = (point - position).distance;
                return distance <= eraserRadius;
              });
            }
            break;
            
          case AppAnnotation.AnnotationTool.text:
            // For text annotations, check if position is within text area
            if (annotation.textData != null) {
              final textPos = annotation.textData!.position;
              final distance = (textPos - position).distance;
              shouldErase = distance <= eraserRadius;
            }
            break;
            
          case AppAnnotation.AnnotationTool.stamp:
            // For stamp annotations, check if position is within stamp area
            if (annotation.stampData != null) {
              final stampPos = annotation.stampData!.position;
              final distance = (stampPos - position).distance;
              shouldErase = distance <= eraserRadius;
            }
            break;
            
          case AppAnnotation.AnnotationTool.eraser:
            // Don't erase eraser annotations
            break;
        }
        
        if (shouldErase) {
          annotationsToRemove.add(annotation);
        }
      }
      
      // Remove annotations from UI
      for (final annotation in annotationsToRemove) {
        _annotations.remove(annotation);
        // TODO: Delete from database as well
        _deleteAnnotationFromDatabase(annotation);
      }
    });
  }

  Future<void> _deleteAnnotationFromDatabase(AppAnnotation.Annotation annotation) async {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      await annotationService.deleteAnnotation(annotation.id, annotation.pieceId);
      print('PDFScoreViewer: Deleted annotation ${annotation.id} from database');
    } catch (e) {
      print('PDFScoreViewer: Error deleting annotation from database: $e');
    }
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
    // Add haptic feedback for spot creation
    HapticFeedback.selectionClick();
    
    showDialog(
      context: context,
      builder: (context) => SpotCreationDialog(
        position: Offset(x, y),
        page: _currentPage,
        onSpotCreated: (spot) {
          // Add success haptic feedback
          HapticFeedback.mediumImpact();
          
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
      // Add haptic feedback for page navigation
      final pedalSettings = ref.read(bluetoothPedalSettingsProvider);
      if (pedalSettings.hapticFeedback) {
        HapticFeedback.lightImpact();
      }
      _pdfController.jumpToPage(_currentPage - 1);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      // Add haptic feedback for page navigation
      final pedalSettings = ref.read(bluetoothPedalSettingsProvider);
      if (pedalSettings.hapticFeedback) {
        HapticFeedback.lightImpact();
      }
      _pdfController.jumpToPage(_currentPage + 1);
    }
  }

  // Bluetooth Pedal Integration
  void _initializeBluetoothPedal() {
    final pedalSettings = ref.read(bluetoothPedalSettingsProvider);
    if (pedalSettings.isEnabled) {
      final pedalService = ref.read(bluetoothPedalServiceProvider);
      pedalService.startListening(
        onNextPage: _nextPage,
        onPreviousPage: _previousPage,
        onToggleFullscreen: _toggleFullscreen,
      );
      print('PDFScoreViewer: Bluetooth pedal support enabled');
    }
  }

  void _stopBluetoothPedal() {
    final pedalService = ref.read(bluetoothPedalServiceProvider);
    pedalService.stopListening();
    print('PDFScoreViewer: Bluetooth pedal support disabled');
  }

  void _toggleFullscreen() {
    // Toggle fullscreen mode
    // This could hide/show the toolbar and other UI elements
    setState(() {
      // Implementation depends on your fullscreen requirements
    });
    
    // Add haptic feedback
    final pedalSettings = ref.read(bluetoothPedalSettingsProvider);
    if (pedalSettings.hapticFeedback) {
      HapticFeedback.mediumImpact();
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

  Future<void> _loadAnnotationLayersFromDatabase() async {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      final layers = await annotationService.getLayersForPiece(widget.piece.id);
      setState(() {
        _layers = layers;
        
        // Create default layer if none exist
        if (layers.isEmpty) {
          final defaultLayer = AppAnnotation.AnnotationLayer(
            id: 'default',
            name: 'Default Layer',
            colorTag: AppAnnotation.ColorTag.blue,
            isVisible: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _layers = [defaultLayer];
          _selectedLayer = defaultLayer;
          _selectedLayerId = defaultLayer.id;
        } else {
          // Set first layer as selected if no layer is selected
          if (_selectedLayer == null) {
            _selectedLayer = layers.first;
            _selectedLayerId = layers.first.id;
          }
        }
      });
      print('PDFScoreViewer: Loaded ${_layers.length} annotation layers for piece ${widget.piece.id}');
    } catch (e) {
      print('PDFScoreViewer: Error loading annotation layers from database: $e');
      
      // Create default layer on error
      setState(() {
        final defaultLayer = AppAnnotation.AnnotationLayer(
          id: 'default',
          name: 'Default Layer',
          colorTag: AppAnnotation.ColorTag.blue,
          isVisible: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _layers = [defaultLayer];
        _selectedLayer = defaultLayer;
        _selectedLayerId = defaultLayer.id;
      });
    }
  }

  Future<void> _loadAnnotationsFromDatabase() async {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      final annotations = await annotationService.getAnnotationsForPiece(widget.piece.id);
      setState(() {
        _annotations = annotations;
      });
      print('PDFScoreViewer: Loaded ${annotations.length} annotations for piece ${widget.piece.id}');
    } catch (e) {
      print('PDFScoreViewer: Error loading annotations from database: $e');
    }
  }

  // Layer management methods
  void _onLayerToggle(AppAnnotation.AnnotationLayer layer, bool isVisible) async {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      final updatedLayer = layer.copyWith(isVisible: isVisible);
      
      await annotationService.updateLayer(widget.piece.id, updatedLayer);
      
      setState(() {
        final index = _layers.indexWhere((l) => l.id == layer.id);
        if (index != -1) {
          _layers[index] = updatedLayer;
        }
      });
    } catch (e) {
      print('PDFScoreViewer: Error toggling layer visibility: $e');
    }
  }

  void _onLayerCreate(AppAnnotation.AnnotationLayer layer) async {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      await annotationService.createLayer(widget.piece.id, layer);
      
      setState(() {
        _layers.add(layer);
        _selectedLayer = layer; // Select the newly created layer
      });
    } catch (e) {
      print('PDFScoreViewer: Error creating layer: $e');
    }
  }

  void _onLayerUpdate(AppAnnotation.AnnotationLayer layer) async {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      await annotationService.updateLayer(widget.piece.id, layer);
      
      setState(() {
        final index = _layers.indexWhere((l) => l.id == layer.id);
        if (index != -1) {
          _layers[index] = layer;
        }
        
        // Update selected layer if it's the one being updated
        if (_selectedLayer?.id == layer.id) {
          _selectedLayer = layer;
        }
      });
    } catch (e) {
      print('PDFScoreViewer: Error updating layer: $e');
    }
  }

  void _onLayerDelete(String layerId, {bool deleteAnnotations = false}) async {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      await annotationService.deleteLayer(widget.piece.id, layerId, deleteAnnotations: deleteAnnotations);
      
      setState(() {
        _layers.removeWhere((l) => l.id == layerId);
        
        // If we deleted the selected layer, select the first available layer
        if (_selectedLayer?.id == layerId) {
          _selectedLayer = _layers.isNotEmpty ? _layers.first : null;
        }
        
        // Remove annotations from local list if they were deleted
        if (deleteAnnotations) {
          _annotations.removeWhere((a) => a.layerId == layerId);
        } else {
          // Update annotations to use default layer
          for (int i = 0; i < _annotations.length; i++) {
            if (_annotations[i].layerId == layerId) {
              _annotations[i] = _annotations[i].copyWith(layerId: 'default');
            }
          }
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Layer deleted successfully'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      print('PDFScoreViewer: Error deleting layer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting layer: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _onLayerSelected(AppAnnotation.AnnotationLayer layer) {
    setState(() {
      _selectedLayer = layer;
      _selectedLayerId = layer.id;
    });
  }

  void _onLayerChanged(String layerId) {
    setState(() {
      _selectedLayerId = layerId;
      _selectedLayer = _layers.firstWhere((layer) => layer.id == layerId, orElse: () => _layers.first);
    });
    print('PDFScoreViewer: Selected layer changed to: $layerId');
  }

  void _onFilterChanged(AppAnnotation.AnnotationFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
    
    // Save filter preference
    try {
      final annotationService = ref.read(annotationServiceProvider);
      annotationService.saveFilterForPiece(widget.piece.id, filter);
    } catch (e) {
      print('PDFScoreViewer: Error saving filter: $e');
    }
  }

  /// Helper method to check if an annotation matches the current filter
  bool _annotationMatchesFilter(AppAnnotation.Annotation annotation, AppAnnotation.AnnotationFilter filter) {
    // Check layer visibility
    final layer = _layers.firstWhere((l) => l.id == annotation.layerId, orElse: () => _layers.first);
    if (!layer.isVisible) return false;
    
    // Check color filter
    if (filter.colorTags != null && filter.colorTags!.isNotEmpty && !filter.colorTags!.contains(annotation.colorTag)) {
      return false;
    }
    
    // Check tool filter
    if (filter.tools != null && filter.tools!.isNotEmpty && !filter.tools!.contains(annotation.tool)) {
      return false;
    }
    
    // Check page filter (if we had this property)
    // Note: Currently the filter doesn't have page filtering, but keeping this structure for future use
    
    // Check date range
    if (filter.showToday) {
      final today = DateTime.now();
      final isToday = annotation.createdAt.year == today.year && 
                     annotation.createdAt.month == today.month && 
                     annotation.createdAt.day == today.day;
      if (!isToday) return false;
    } else if (filter.showLast7Days) {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      if (annotation.createdAt.isBefore(sevenDaysAgo)) return false;
    } else if (filter.customStart != null || filter.customEnd != null) {
      if (filter.customStart != null && annotation.createdAt.isBefore(filter.customStart!)) {
        return false;
      }
      if (filter.customEnd != null && annotation.createdAt.isAfter(filter.customEnd!)) {
        return false;
      }
    }
    
    return true;
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
              NewToolbar.AnnotationToolbar(
                currentTool: _currentTool,
                currentColorTag: _currentColor,
                selectedLayerId: _selectedLayerId,
                selectedStamp: _selectedStamp,
                isAnnotationMode: _isAnnotationMode,
                onToolChanged: _onToolChanged,
                onColorChanged: _onColorChanged,
                onLayerChanged: _onLayerChanged,
                onStampSelected: _onStampSelected,
                onAnnotationModeToggle: _onAnnotationModeToggle,
                onUndo: _onUndo,
                onRedo: _onRedo,
                onClear: _onClear,
                onTextInput: _onTextInput,
                onShowFilters: _showFilterPanel,
                onShowLayers: _showLayerPanel,
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
                              child: Builder(
                                builder: (context) {
                                  final annotationService = ref.read(annotationServiceProvider);
                                  final visibleLayers = _layers.where((layer) => layer.isVisible).toList();
                                  
                                  // Apply both layer visibility and filter to annotations
                                  final pageAnnotations = _annotations.where((a) => a.page == _currentPage).toList();
                                  final filteredAnnotations = annotationService.filterAnnotationsAdvanced(
                                    pageAnnotations, 
                                    _layers, 
                                    _currentFilter,
                                  );
                                  
                                  return CustomPaint(
                                    painter: AnnotationOverlayPainter(
                                      annotations: filteredAnnotations,
                                      currentDrawingPoints: _currentDrawingPoints,
                                      currentTool: _currentTool,
                                      currentColor: _currentColor,
                                      zoomLevel: _zoomLevel,
                                      filter: _currentFilter,
                                      visibleLayers: visibleLayers,
                                    ),
                                  );
                                },
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
                              right: 20, // Add right constraint to prevent overflow
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _currentTool == AppAnnotation.AnnotationTool.text
                                      ? '✏️ TEXT mode - Swipe where you want text'
                                      : _currentTool == AppAnnotation.AnnotationTool.eraser
                                          ? '🗑️ ERASER mode - Swipe over annotations to delete'
                                          : '✏️ ${_currentTool.name.toUpperCase()} mode - Draw on the score',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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

                  // Layer Management Panel (TEMPORARILY DISABLED TO FIX LAYOUT LOOP)
                  // if (_isAnnotationMode)
                  //   Positioned(
                  //     top: 20,
                  //     right: 20,
                  //     child: LayerPanel(
                  //       pieceId: widget.piece.id,
                  //       layers: _layers,
                  //       onLayerToggle: (layer) => _onLayerToggle(layer, !layer.isVisible),
                  //       onLayerCreate: _onLayerCreate,
                  //       onLayerUpdate: _onLayerUpdate,
                  //       onLayerDelete: (layerId, {bool deleteAnnotations = false}) => _onLayerDelete(layerId, deleteAnnotations: deleteAnnotations),
                  //       onLayerSelected: (layer) => setState(() => _selectedLayerId = layer.id),
                  //       selectedLayer: _layers.firstWhere((l) => l.id == _selectedLayerId, orElse: () => _layers.first),
                  //     ),
                  //   ),

                  // Annotation Filter Panel (TEMPORARILY DISABLED TO FIX LAYOUT LOOP)  
                  // if (_isAnnotationMode)
                  //   Positioned(
                  //     bottom: 100,
                  //     left: 20,
                  //     child: AnnotationFilterPanel(
                  //       currentFilter: _currentFilter,
                  //       onFilterChanged: _onFilterChanged,
                  //       filteredAnnotations: _annotations.where((a) => _annotationMatchesFilter(a, _currentFilter)).length,
                  //       totalAnnotations: _annotations.length,
                  //     ),
                  //   ),
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
  final AppAnnotation.AnnotationFilter? filter;
  final List<AppAnnotation.AnnotationLayer> visibleLayers;

  AnnotationOverlayPainter({
    required this.annotations,
    required this.currentDrawingPoints,
    required this.currentTool,
    required this.currentColor,
    required this.zoomLevel,
    this.filter,
    this.visibleLayers = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Filter annotations based on current filter and visible layers
    final filteredAnnotations = _filterAnnotations(annotations);
    
    // Draw existing annotations
    for (final annotation in filteredAnnotations) {
      final opacity = _getAnnotationOpacity(annotation);
      _drawAnnotation(canvas, annotation, size, opacity);
    }

    // Draw current drawing stroke
    if (currentDrawingPoints.isNotEmpty) {
      _drawCurrentStroke(canvas, size);
    }
  }

  List<AppAnnotation.Annotation> _filterAnnotations(List<AppAnnotation.Annotation> annotations) {
    return annotations.where((annotation) {
      // Check layer visibility
      if (visibleLayers.isNotEmpty) {
        final isLayerVisible = visibleLayers.any((layer) => layer.id == annotation.layerId && layer.isVisible);
        if (!isLayerVisible) return false;
      }
      
      // Apply annotation filter
      if (filter != null) {
        // Color filter
        if (filter?.colorTags != null && filter!.colorTags!.isNotEmpty && 
            !filter!.colorTags!.contains(annotation.colorTag)) {
          return false;
        }
        
        // Tool filter
        if (filter?.tools != null && filter!.tools!.isNotEmpty && 
            !filter!.tools!.contains(annotation.tool)) {
          return false;
        }
        
        // Date range filter based on filter properties
        final now = DateTime.now();
        
        if (filter?.showToday == true) {
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(const Duration(days: 1));
          if (annotation.createdAt.isBefore(today) || annotation.createdAt.isAfter(tomorrow)) {
            return false;
          }
        } else if (filter?.showLast7Days == true) {
          final weekAgo = now.subtract(const Duration(days: 7));
          if (annotation.createdAt.isBefore(weekAgo)) {
            return false;
          }
        } else if (filter?.customStart != null || filter?.customEnd != null) {
          if (filter!.customStart != null && annotation.createdAt.isBefore(filter!.customStart!)) {
            return false;
          }
          if (filter!.customEnd != null && annotation.createdAt.isAfter(filter!.customEnd!)) {
            return false;
          }
        }
      }
      
      return true;
    }).toList();
  }

  double _getAnnotationOpacity(AppAnnotation.Annotation annotation) {
    if (filter?.fadeNonMatching == true) {
      // If annotation doesn't match filter criteria, fade it
      if (filter?.colorTags != null && filter!.colorTags!.isNotEmpty && 
          !filter!.colorTags!.contains(annotation.colorTag)) {
        return 0.3;
      }
      if (filter?.tools != null && filter!.tools!.isNotEmpty && 
          !filter!.tools!.contains(annotation.tool)) {
        return 0.3;
      }
    }
    return 1.0;
  }

  void _drawAnnotation(Canvas canvas, AppAnnotation.Annotation annotation, Size size, double opacity) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (annotation.tool) {
      case AppAnnotation.AnnotationTool.pen:
        paint
          ..color = _getColorFromTag(annotation.colorTag).withOpacity(opacity)
          ..strokeWidth = 2.0 * zoomLevel
          ..style = PaintingStyle.stroke;
        break;
      case AppAnnotation.AnnotationTool.highlighter:
        paint
          ..color = _getColorFromTag(annotation.colorTag).withOpacity(0.3 * opacity)
          ..strokeWidth = 8.0 * zoomLevel
          ..style = PaintingStyle.stroke;
        break;
      case AppAnnotation.AnnotationTool.text:
        _drawText(canvas, annotation, opacity);
        return;
      case AppAnnotation.AnnotationTool.stamp:
        _drawStamp(canvas, annotation, opacity);
        return;
      default:
        paint
          ..color = _getColorFromTag(annotation.colorTag).withOpacity(opacity)
          ..strokeWidth = 2.0 * zoomLevel
          ..style = PaintingStyle.stroke;
        break;
    }

    if (annotation.data is AppAnnotation.VectorPath) {
      final vectorPath = annotation.data as AppAnnotation.VectorPath;
      _drawPath(canvas, vectorPath.points, paint, size);
    }
  }

  void _drawText(Canvas canvas, AppAnnotation.Annotation annotation, double opacity) {
    if (annotation.data is! AppAnnotation.TextData) return;
    
    final textData = annotation.data as AppAnnotation.TextData;
    final textPainter = TextPainter(
      text: TextSpan(
        text: textData.text,
        style: TextStyle(
          color: _getColorFromTag(annotation.colorTag).withOpacity(opacity),
          fontSize: textData.fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.5),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        textData.position.dx,
        textData.position.dy,
      ),
    );
  }

  void _drawStamp(Canvas canvas, AppAnnotation.Annotation annotation, double opacity) {
    if (annotation.data is! AppAnnotation.StampData) return;
    
    final stampData = annotation.data as AppAnnotation.StampData;
    final symbol = _getStampSymbol(stampData.type);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          color: _getColorFromTag(annotation.colorTag).withOpacity(opacity),
          fontSize: stampData.size,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.5),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    // Center the stamp on the position
    final offset = Offset(
      stampData.position.dx - (textPainter.width / 2),
      stampData.position.dy - (textPainter.height / 2),
    );
    
    textPainter.paint(canvas, offset);
  }

  String _getStampSymbol(AppAnnotation.StampType stamp) {
    switch (stamp) {
      case AppAnnotation.StampType.fingering1:
        return '1';
      case AppAnnotation.StampType.fingering2:
        return '2';
      case AppAnnotation.StampType.fingering3:
        return '3';
      case AppAnnotation.StampType.fingering4:
        return '4';
      case AppAnnotation.StampType.fingering5:
        return '5';
      case AppAnnotation.StampType.pedal:
        return 'P';
      case AppAnnotation.StampType.bowingUp:
        return '↑';
      case AppAnnotation.StampType.bowingDown:
        return '↓';
      case AppAnnotation.StampType.accent:
        return '>';
      case AppAnnotation.StampType.rehearsalLetter:
        return 'A';
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
