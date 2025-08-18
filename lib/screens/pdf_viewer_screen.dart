import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/pdf_document.dart';
import '../models/spot.dart';
import '../services/spot_service.dart';
import '../services/srs_ai_engine.dart';
import '../providers/unified_library_provider.dart';
import '../providers/practice_provider.dart';

class PDFViewerScreen extends ConsumerStatefulWidget {
  final PDFDocument document;

  const PDFViewerScreen({super.key, required this.document});

  @override
  ConsumerState<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends ConsumerState<PDFViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  List<Spot> _spots = [];
  bool _isCreatingSpot = false;
  Offset? _selectionStart;
  Offset? _selectionEnd;
  SpotColor _selectedColor = SpotColor.yellow;
  bool _isFullScreen = false;
  int _currentPage = 1;
  int _totalPages = 0;
  
  @override
  void initState() {
    super.initState();
    _loadSpots();
  }
  
  Future<void> _loadSpots() async {
    final spots = await ref.read(spotServiceProvider).getSpotsForPiece(widget.document.id);
    if (mounted) {
      setState(() {
        _spots = spots;
      });
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen ? null : AppBar(
        title: Text(widget.document.title),
        actions: [
          IconButton(
            icon: Icon(_isCreatingSpot ? Icons.check : Icons.add_box),
            onPressed: () {
              setState(() {
                _isCreatingSpot = !_isCreatingSpot;
                _selectionStart = null;
                _selectionEnd = null;
              });
            },
          ),
          if (_isCreatingSpot) ...[
            IconButton(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getColorFromSpotColor(_selectedColor),
                  shape: BoxShape.circle,
                ),
              ),
              onPressed: _showColorPicker,
            ),
          ],
          IconButton(
            icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: _toggleFullScreen,
          ),
        ],
      ),
      body: GestureDetector(
        onPanStart: _isCreatingSpot ? _onPanStart : null,
        onPanUpdate: _isCreatingSpot ? _onPanUpdate : null,
        onPanEnd: _isCreatingSpot ? _onPanEnd : null,
        onTapUp: !_isCreatingSpot ? _onTap : null,
        child: Stack(
          children: [
            // PDF Display
            SfPdfViewer.file(
              File(widget.document.filePath),
              controller: _pdfController,
              onPageChanged: (PdfPageChangedDetails details) {
                setState(() {
                  _currentPage = details.newPageNumber;
                });
              },
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _totalPages = details.document.pages.count;
                });
              },
            ),
            
            // Overlay spots for current page
            ..._spots
                .where((spot) => spot.pageNumber == _currentPage)
                .map((spot) => _buildSpotOverlay(spot)),
            
            // Selection rectangle during creation
            if (_isCreatingSpot && _selectionStart != null && _selectionEnd != null)
              _buildSelectionRectangle(),
              
            // Page indicator
            if (!_isFullScreen)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              
            // Fullscreen exit button
            if (_isFullScreen)
              Positioned(
                top: 50,
                right: 16,
                child: FloatingActionButton(
                  heroTag: "pdf_viewer_fab",
                  mini: true,
                  onPressed: _toggleFullScreen,
                  child: const Icon(Icons.fullscreen_exit),
                ),
              ),
              
            // Instructions overlay
            if (_isCreatingSpot)
              Positioned(
                top: _isFullScreen ? 100 : 80,
                left: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Drag to create practice spot',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpotOverlay(Spot spot) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height - (_isFullScreen ? 0 : 100); // Account for app bar
    
    return Positioned(
      left: spot.x * screenWidth,
      top: (_isFullScreen ? 0 : 100) + (spot.y * screenHeight),
      width: spot.width * screenWidth,
      height: spot.height * screenHeight,
      child: GestureDetector(
        onTap: () => _onSpotTap(spot),
        child: Container(
          decoration: BoxDecoration(
            color: spot.displayColor.withOpacity(0.3),
            border: Border.all(
              color: spot.displayColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: spot.displayColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                spot.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelectionRectangle() {
    final screenSize = MediaQuery.of(context).size;
    final appBarHeight = _isFullScreen ? 0.0 : 100.0;
    
    final left = _selectionStart!.dx.clamp(0.0, screenSize.width);
    final top = (_selectionStart!.dy - appBarHeight).clamp(0.0, screenSize.height - appBarHeight);
    final right = _selectionEnd!.dx.clamp(0.0, screenSize.width);
    final bottom = (_selectionEnd!.dy - appBarHeight).clamp(0.0, screenSize.height - appBarHeight);
    
    return Positioned(
      left: left < right ? left : right,
      top: appBarHeight + (top < bottom ? top : bottom),
      width: (right - left).abs(),
      height: (bottom - top).abs(),
      child: Container(
        decoration: BoxDecoration(
          color: _getColorFromSpotColor(_selectedColor).withOpacity(0.3),
          border: Border.all(
            color: _getColorFromSpotColor(_selectedColor),
            width: 2,
          ),
        ),
      ),
    );
  }
  
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _selectionStart = details.globalPosition;
      _selectionEnd = details.globalPosition;
    });
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _selectionEnd = details.globalPosition;
    });
  }
  
  void _onPanEnd(DragEndDetails details) {
    if (_selectionStart != null && _selectionEnd != null) {
      _createSpot();
    }
  }
  
  void _onTap(TapUpDetails details) {
    // Check if tap is on existing spot
    final tappedSpot = _getSpotAtPosition(details.globalPosition);
    if (tappedSpot != null) {
      _onSpotTap(tappedSpot);
    }
  }
  
  Spot? _getSpotAtPosition(Offset position) {
    final screenSize = MediaQuery.of(context).size;
    final appBarHeight = _isFullScreen ? 0.0 : 100.0;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height - appBarHeight;
    
    for (final spot in _spots.where((s) => s.pageNumber == _currentPage)) {
      final spotLeft = spot.x * screenWidth;
      final spotTop = appBarHeight + (spot.y * screenHeight);
      final spotRight = spotLeft + (spot.width * screenWidth);
      final spotBottom = spotTop + (spot.height * screenHeight);
      
      if (position.dx >= spotLeft && 
          position.dx <= spotRight &&
          position.dy >= spotTop && 
          position.dy <= spotBottom) {
        return spot;
      }
    }
    return null;
  }
  
  void _onSpotTap(Spot spot) {
    _showSpotPracticeDialog(spot);
  }
  
  Future<void> _createSpot() async {
    if (_selectionStart == null || _selectionEnd == null) return;
    
    final screenSize = MediaQuery.of(context).size;
    final appBarHeight = _isFullScreen ? 0.0 : 100.0;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height - appBarHeight;
    
    // Convert screen coordinates to relative coordinates
    final left = (_selectionStart!.dx) / screenWidth;
    final top = (_selectionStart!.dy - appBarHeight) / screenHeight;
    final right = (_selectionEnd!.dx) / screenWidth;
    final bottom = (_selectionEnd!.dy - appBarHeight) / screenHeight;
    
    final x = (left < right ? left : right).clamp(0.0, 1.0);
    final y = (top < bottom ? top : bottom).clamp(0.0, 1.0);
    final width = (right - left).abs().clamp(0.01, 1.0 - x);
    final height = (bottom - top).abs().clamp(0.01, 1.0 - y);
    
    // Show dialog to name the spot
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SpotCreationDialog(color: _selectedColor),
    );
    
    if (result != null) {
      final now = DateTime.now();
      final spot = Spot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pieceId: widget.document.id,
        title: result['title'],
        description: result['description'],
        pageNumber: _currentPage,
        x: x,
        y: y,
        width: width,
        height: height,
        priority: result['priority'],
        readinessLevel: ReadinessLevel.newSpot,
        color: _selectedColor,
        createdAt: now,
        updatedAt: now,
        // Ensure new spots appear in practice dashboard immediately
        nextDue: null,  // This makes them due immediately
        isActive: true, // Explicitly ensure they're active
      );
      
      print('PDF Viewer: Creating spot "${spot.title}" for piece "${widget.document.id}"');
      await ref.read(spotServiceProvider).saveSpot(spot);
      await _loadSpots();
      
      // Refresh both the unified library and practice dashboard
      ref.refresh(unifiedLibraryProvider);
      ref.read(practiceProvider.notifier).refresh();
      
      print('PDF Viewer: Spot saved and providers refreshed');
    }
    
    setState(() {
      _selectionStart = null;
      _selectionEnd = null;
      _isCreatingSpot = false;
    });
  }
  
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Select Difficulty',
          style: TextStyle(color: Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _colorOption(SpotColor.red, 'Hard/Critical'),
            _colorOption(SpotColor.yellow, 'Medium'),
            _colorOption(SpotColor.green, 'Easy/Mastered'),
          ],
        ),
      ),
    );
  }
  
  Widget _colorOption(SpotColor color, String label) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getColorFromSpotColor(color),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(color: Colors.black),
      ),
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
        Navigator.pop(context);
      },
    );
  }
  
  void _showSpotPracticeDialog(Spot spot) {
    showDialog(
      context: context,
      builder: (context) => SpotPracticeDialog(
        spot: spot,
        onPracticeComplete: (result) => _onPracticeComplete(spot, result),
        onEditSpot: () => _editSpot(spot),
        onDeleteSpot: () => _deleteSpot(spot),
      ),
    );
  }
  
  Future<void> _onPracticeComplete(Spot spot, SpotResult result) async {
    // Update spot using SRS AI Engine
    final updatedSpot = await ref.read(srsAiEngineProvider).updateSpotAfterPractice(spot, result);
    await ref.read(spotServiceProvider).saveSpot(updatedSpot);
    await _loadSpots();
    
    // Refresh both the unified library and practice dashboard
    ref.refresh(unifiedLibraryProvider);
    ref.read(practiceProvider.notifier).refresh();
    
    // Show feedback
    if (mounted) {
      final message = result == SpotResult.excellent || result == SpotResult.good
          ? 'Great! Next review in ${updatedSpot.interval} days'
          : 'Keep practicing! This spot will appear again soon';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
  
  Future<void> _editSpot(Spot spot) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SpotEditDialog(spot: spot),
    );
    
    if (result != null) {
      final updatedSpot = spot.copyWith(
        title: result['title'],
        description: result['description'],
        priority: result['priority'],
        color: result['color'],
        updatedAt: DateTime.now(),
      );
      
      await ref.read(spotServiceProvider).saveSpot(updatedSpot);
      await _loadSpots();
      
      // Refresh both the unified library and practice dashboard
      ref.refresh(unifiedLibraryProvider);
      ref.read(practiceProvider.notifier).refresh();
    }
  }
  
  Future<void> _deleteSpot(Spot spot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Spot'),
        content: Text('Are you sure you want to delete "${spot.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(spotServiceProvider).deleteSpot(spot.id);
      await _loadSpots();
      
      // Refresh both the unified library and practice dashboard
      ref.refresh(unifiedLibraryProvider);
      ref.read(practiceProvider.notifier).refresh();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Spot deleted')),
        );
      }
    }
  }
  
  Color _getColorFromSpotColor(SpotColor spotColor) {
    switch (spotColor) {
      case SpotColor.red:
        return Colors.red;
      case SpotColor.yellow:
        return Colors.orange;
      case SpotColor.green:
        return Colors.green;
      case SpotColor.blue:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}

class _SpotCreationDialog extends StatefulWidget {
  final SpotColor color;
  
  const _SpotCreationDialog({required this.color});

  @override
  State<_SpotCreationDialog> createState() => _SpotCreationDialogState();
}

class _SpotCreationDialogState extends State<_SpotCreationDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  SpotPriority _priority = SpotPriority.medium;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        'Create Practice Spot',
        style: TextStyle(color: Colors.black),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Spot Name',
              labelStyle: TextStyle(color: Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black26),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              labelStyle: TextStyle(color: Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black26),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<SpotPriority>(
            value: _priority,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Priority',
              labelStyle: TextStyle(color: Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black26),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            dropdownColor: Colors.white,
            items: SpotPriority.values.map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Text(
                  priority.displayName,
                  style: TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _priority = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              Navigator.pop(context, {
                'title': _titleController.text.trim(),
                'description': _descriptionController.text.trim(),
                'priority': _priority,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text('Create'),
        ),
      ],
    );
  }
}

class _SpotEditDialog extends StatefulWidget {
  final Spot spot;
  
  const _SpotEditDialog({required this.spot});

  @override
  State<_SpotEditDialog> createState() => _SpotEditDialogState();
}

class _SpotEditDialogState extends State<_SpotEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late SpotPriority _priority;
  late SpotColor _color;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.spot.title);
    _descriptionController = TextEditingController(text: widget.spot.description ?? '');
    _priority = widget.spot.priority;
    _color = widget.spot.color;
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        'Edit Practice Spot',
        style: TextStyle(color: Colors.black),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Spot Name',
              labelStyle: TextStyle(color: Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black26),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              labelStyle: TextStyle(color: Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black26),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<SpotPriority>(
            value: _priority,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Priority',
              labelStyle: TextStyle(color: Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black26),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            dropdownColor: Colors.white,
            items: SpotPriority.values.map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Text(
                  priority.displayName,
                  style: TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _priority = value!;
              });
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<SpotColor>(
            value: _color,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Color',
              labelStyle: TextStyle(color: Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black26),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            dropdownColor: Colors.white,
            items: SpotColor.values.map((color) {
              return DropdownMenuItem(
                value: color,
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _getDisplayColor(color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      color.displayName,
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _color = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              Navigator.pop(context, {
                'title': _titleController.text.trim(),
                'description': _descriptionController.text.trim(),
                'priority': _priority,
                'color': _color,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text('Save'),
        ),
      ],
    );
  }
  
  Color _getDisplayColor(SpotColor color) {
    switch (color) {
      case SpotColor.red:
        return Colors.red;
      case SpotColor.yellow:
        return Colors.orange;
      case SpotColor.green:
        return Colors.green;
      case SpotColor.blue:
        return Colors.blue;
    }
  }
}

class SpotPracticeDialog extends StatelessWidget {
  final Spot spot;
  final Function(SpotResult) onPracticeComplete;
  final VoidCallback onEditSpot;
  final VoidCallback onDeleteSpot;
  
  const SpotPracticeDialog({
    super.key,
    required this.spot,
    required this.onPracticeComplete,
    required this.onEditSpot,
    required this.onDeleteSpot,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('Practice: ${spot.title}')),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              Navigator.pop(context);
              if (value == 'edit') {
                onEditSpot();
              } else if (value == 'delete') {
                onDeleteSpot();
              }
            },
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (spot.description != null && spot.description!.isNotEmpty) ...[
            Text(spot.description!),
            SizedBox(height: 12),
          ],
          Text('Priority: ${spot.priority.displayName}'),
          Text('Level: ${spot.readinessLevel.displayName}'),
          if (spot.practiceCount > 0) ...[
            SizedBox(height: 8),
            Text('Practiced: ${spot.practiceCount} times'),
            Text('Success rate: ${((spot.successCount / spot.practiceCount) * 100).toStringAsFixed(1)}%'),
          ],
          SizedBox(height: 20),
          Text('How did the practice go?', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            onPracticeComplete(SpotResult.failed);
            Navigator.pop(context);
          },
          child: Text('Failed', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () {
            onPracticeComplete(SpotResult.struggled);
            Navigator.pop(context);
          },
          child: Text('Struggled', style: TextStyle(color: Colors.orange)),
        ),
        TextButton(
          onPressed: () {
            onPracticeComplete(SpotResult.good);
            Navigator.pop(context);
          },
          child: Text('Good', style: TextStyle(color: Colors.blue)),
        ),
        ElevatedButton(
          onPressed: () {
            onPracticeComplete(SpotResult.excellent);
            Navigator.pop(context);
          },
          child: Text('Excellent'),
        ),
      ],
    );
  }
}
