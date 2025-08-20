import 'dart:io';
import 'dart:async';
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
        // Prevent gesture conflicts with PDF scrolling
        behavior: HitTestBehavior.deferToChild,
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
              
            // Help button for spots
            if (!_isFullScreen && _spots.isNotEmpty)
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton(
                  heroTag: "spot_help_fab",
                  mini: true,
                  onPressed: _showSpotHelp,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.help_outline),
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
    
    final isSmallSpot = (spot.width * screenWidth) < 100 || (spot.height * screenHeight) < 40;
    
    return Positioned(
      left: spot.x * screenWidth,
      top: (_isFullScreen ? 0 : 100) + (spot.y * screenHeight),
      width: spot.width * screenWidth,
      height: spot.height * screenHeight,
      child: GestureDetector(
        onTap: () => _onSpotTap(spot),
        child: Container(
          decoration: BoxDecoration(
            color: spot.displayColor.withOpacity(0.15),
            border: Border.all(
              color: spot.displayColor,
              width: 2.5,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: spot.displayColor.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isSmallSpot ? _buildCompactSpotContent(spot) : _buildDetailedSpotContent(spot),
        ),
      ),
    );
  }

  Widget _buildCompactSpotContent(Spot spot) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: spot.displayColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSpotPriorityIcon(spot.priority),
              color: Colors.white,
              size: 12,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                spot.title.isEmpty ? 'Spot' : spot.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedSpotContent(Spot spot) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with priority and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: spot.displayColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _getSpotPriorityIcon(spot.priority),
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  spot.title.isEmpty ? 'Practice Spot' : spot.title,
                  style: TextStyle(
                    color: spot.displayColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Status info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: spot.displayColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getReadinessDisplayName(spot.readinessLevel),
                  style: TextStyle(
                    color: spot.displayColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (spot.practiceCount > 0)
                Text(
                  '${spot.practiceCount}x',
                  style: TextStyle(
                    color: spot.displayColor.withOpacity(0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getSpotPriorityIcon(SpotPriority priority) {
    switch (priority) {
      case SpotPriority.low:
        return Icons.circle;
      case SpotPriority.medium:
        return Icons.warning_amber;
      case SpotPriority.high:
        return Icons.priority_high;
    }
  }

  String _getReadinessDisplayName(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.newSpot:
        return 'New';
      case ReadinessLevel.learning:
        return 'Learning';
      case ReadinessLevel.review:
        return 'Review';
      case ReadinessLevel.mastered:
        return 'Mastered';
    }
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

  void _showSpotHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('How to Use Practice Spots'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                Icons.touch_app,
                'Tap any spot',
                'Open the practice dialog with timer and note-taking features',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.timer,
                'Use the practice timer',
                'Track how long you spend on each section',
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.star_rate,
                'Rate your practice',
                'Choose Failed, Struggled, Good, or Excellent to track progress',
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.analytics,
                'Track your progress',
                'See practice count and success rate for each spot',
                Colors.purple,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spot Colors:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildColorInfo(Colors.red, 'Red: New/Critical spots'),
                    _buildColorInfo(Colors.orange, 'Orange: Learning'),
                    _buildColorInfo(Colors.yellow, 'Yellow: Review needed'),
                    _buildColorInfo(Colors.green, 'Green: Mastered'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorInfo(Color color, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
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
      
      // Assign color based on priority
      SpotColor spotColor;
      switch (result['priority'] as SpotPriority) {
        case SpotPriority.high:
          spotColor = SpotColor.red;
          break;
        case SpotPriority.medium:
          spotColor = SpotColor.yellow;
          break;
        case SpotPriority.low:
          spotColor = SpotColor.green;
          break;
      }
      
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
        color: spotColor,
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

class SpotPracticeDialog extends StatefulWidget {
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
  State<SpotPracticeDialog> createState() => _SpotPracticeDialogState();
}

class _SpotPracticeDialogState extends State<SpotPracticeDialog> {
  int _practiceTime = 0;
  Timer? _timer;
  bool _isRunning = false;
  String _notes = '';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _practiceTime++;
        });
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _practiceTime = 0;
      _isRunning = false;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getPriorityColor() {
    switch (widget.spot.priority) {
      case SpotPriority.low:
        return Colors.green;
      case SpotPriority.medium:
        return Colors.orange;
      case SpotPriority.high:
        return Colors.red;
    }
  }

  IconData _getPriorityIcon() {
    switch (widget.spot.priority) {
      case SpotPriority.low:
        return Icons.circle;
      case SpotPriority.medium:
        return Icons.warning_amber;
      case SpotPriority.high:
        return Icons.priority_high;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPriorityIcon(),
              color: priorityColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.spot.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Page ${widget.spot.pageNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Spot'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Spot', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              Navigator.pop(context);
              if (value == 'edit') {
                widget.onEditSpot();
              } else if (value == 'delete') {
                widget.onDeleteSpot();
              }
            },
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spot Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.spot.description != null && widget.spot.description!.isNotEmpty) ...[
                    Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(widget.spot.description!),
                    SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      _buildInfoChip(
                        'Priority',
                        widget.spot.priority.displayName,
                        priorityColor,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        'Level',
                        widget.spot.readinessLevel.displayName,
                        Colors.blue,
                      ),
                    ],
                  ),
                  if (widget.spot.practiceCount > 0) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          'Practice Count',
                          '${widget.spot.practiceCount}x',
                          Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          'Success Rate',
                          '${((widget.spot.successCount / widget.spot.practiceCount) * 100).toStringAsFixed(0)}%',
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Practice Timer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Practice Timer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatTime(_practiceTime),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _isRunning ? Colors.green : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleTimer,
                        icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isRunning ? 'Pause' : 'Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRunning ? Colors.orange : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Practice Notes
            TextField(
              decoration: InputDecoration(
                labelText: 'Practice Notes (Optional)',
                hintText: 'How did it feel? Any observations...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 2,
              onChanged: (value) => _notes = value,
            ),

            const SizedBox(height: 20),

            Text(
              'How did the practice go?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        
        // Practice result buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResultButton(
              'Failed',
              Icons.sentiment_very_dissatisfied,
              Colors.red,
              SpotResult.failed,
            ),
            const SizedBox(width: 4),
            _buildResultButton(
              'Struggled',
              Icons.sentiment_dissatisfied,
              Colors.orange,
              SpotResult.struggled,
            ),
            const SizedBox(width: 4),
            _buildResultButton(
              'Good',
              Icons.sentiment_satisfied,
              Colors.blue,
              SpotResult.good,
            ),
            const SizedBox(width: 4),
            _buildResultButton(
              'Excellent',
              Icons.sentiment_very_satisfied,
              Colors.green,
              SpotResult.excellent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildResultButton(String text, IconData icon, Color color, SpotResult result) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          onPressed: () {
            _timer?.cancel();
            widget.onPracticeComplete(result);
            Navigator.pop(context);
            
            // Show feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Practice marked as $text!'),
                  ],
                ),
                backgroundColor: color,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
