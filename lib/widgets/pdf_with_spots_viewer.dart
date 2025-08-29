import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/spot_manager.dart';
import '../models/practice_spot.dart';
import '../models/spot.dart';
import '../theme/app_theme.dart';
import '../screens/settings/settings_screen.dart';

/// Example widget showing how to integrate practice spots with PDF viewer
/// This demonstrates the key integration points with your UI
class PdfWithSpotsViewer extends ConsumerStatefulWidget {
  final String pieceName;
  final String pdfPath;
  final int currentPage;

  const PdfWithSpotsViewer({
    Key? key,
    required this.pieceName,
    required this.pdfPath,
    required this.currentPage,
  }) : super(key: key);

  @override
  ConsumerState<PdfWithSpotsViewer> createState() => _PdfWithSpotsViewerState();
}

class _PdfWithSpotsViewerState extends ConsumerState<PdfWithSpotsViewer> {
  String selectedColor = 'red';
  bool isMarkingMode = false;

  @override
  Widget build(BuildContext context) {
    // Watch spots for current page
    final spotsForPageAsync = ref.watch(spotsForPageProvider((
      piece: widget.pieceName,
      page: widget.currentPage,
    )));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pieceName),
        actions: [
          // Color selector
          PopupMenuButton<String>(
            icon: Icon(Icons.color_lens, color: _getColorFromString(selectedColor)),
            onSelected: (color) => setState(() => selectedColor = color),
            itemBuilder: (context) => PracticeSpot.availableColors
                .map((color) => PopupMenuItem(
                      value: color,
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: _getColorFromString(color)),
                          const SizedBox(width: 8),
                          Text(color.toUpperCase()),
                        ],
                      ),
                    ))
                .toList(),
          ),
          // Toggle marking mode
          IconButton(
            icon: Icon(
              isMarkingMode ? Icons.edit_off : Icons.edit,
              color: isMarkingMode ? Colors.orange : null,
            ),
            onPressed: () => setState(() => isMarkingMode = !isMarkingMode),
            tooltip: isMarkingMode ? 'Exit marking mode' : 'Enter marking mode',
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF Viewer (placeholder - replace with your actual PDF viewer)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'PDF Content Here\nPage ${widget.currentPage}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isMarkingMode 
                        ? 'Tap and drag to create practice spots'
                        : 'Enable marking mode to add spots',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          // Gesture detector for creating spots
          if (isMarkingMode)
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              // Prevent conflicts with PDF scrolling
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),

          // Spots overlay
          spotsForPageAsync.when(
            data: (spots) => SpotOverlay(
              spots: spots,
              onSpotTap: _onSpotTap,
              onSpotLongPress: _onSpotLongPress,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Current selection indicator
          if (_currentSelection != null)
            Positioned(
              left: _currentSelection!.dx,
              top: _currentSelection!.dy,
              child: Container(
                width: _currentSelection!.width,
                height: _currentSelection!.height,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _getColorFromString(selectedColor),
                    width: 2,
                  ),
                  color: _getColorFromString(selectedColor).withOpacity(0.2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ====================================================================
  // SPOT CREATION LOGIC
  // ====================================================================

  Offset? _panStart;
  SelectionRect? _currentSelection;

  void _onPanStart(DragStartDetails details) {
    _panStart = details.localPosition;
    setState(() {
      _currentSelection = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_panStart == null) return;

    final current = details.localPosition;
    final rect = Rect.fromPoints(_panStart!, current);
    
    setState(() {
      _currentSelection = SelectionRect(
        dx: rect.left,
        dy: rect.top,
        width: rect.width.abs(),
        height: rect.height.abs(),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) async {
    if (_currentSelection == null || _panStart == null) return;

    // Convert to relative coordinates (0.0 to 1.0)
    final screenSize = MediaQuery.of(context).size;
    final relativeX = _currentSelection!.dx / screenSize.width;
    final relativeY = _currentSelection!.dy / screenSize.height;
    final relativeWidth = _currentSelection!.width / screenSize.width;
    final relativeHeight = _currentSelection!.height / screenSize.height;

    // Show spot creation dialog
    await _showSpotCreationDialog(
      relativeX: relativeX,
      relativeY: relativeY,
      relativeWidth: relativeWidth,
      relativeHeight: relativeHeight,
    );

    setState(() {
      _currentSelection = null;
      _panStart = null;
    });
  }

  Future<void> _showSpotCreationDialog({
    required double relativeX,
    required double relativeY,
    required double relativeWidth,
    required double relativeHeight,
  }) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String priority = 'medium';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Practice Spot'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Spot Title',
                  hintText: 'e.g., "Difficult passage mm. 12-16"',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Any additional notes...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: PracticeSpot.availablePriorities
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
                    .toList(),
                onChanged: (value) => setDialogState(() => priority = value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Color: ', style: Theme.of(context).textTheme.bodyMedium),
                  Icon(Icons.circle, color: _getColorFromString(selectedColor)),
                  const SizedBox(width: 8),
                  Text(selectedColor.toUpperCase()),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create Spot'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await SpotManager.createSpot(
          pieceName: widget.pieceName,
          pageNumber: widget.currentPage,
          x: relativeX,
          y: relativeY,
          width: relativeWidth,
          height: relativeHeight,
          color: selectedColor,
          title: titleController.text.isNotEmpty ? titleController.text : null,
          description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
          priority: priority,
        );

        // Refresh the spots list
        ref.invalidate(spotsForPageProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Practice spot created!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating spot: $e')),
          );
        }
      }
    }
  }

  // ====================================================================
  // SPOT INTERACTION
  // ====================================================================

  void _onSpotTap(PracticeSpot spot) {
    _showSpotMenu(spot);
  }

  void _onSpotLongPress(PracticeSpot spot) {
    _showPracticeDialog(spot);
  }

  void _showSpotMenu(PracticeSpot spot) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Start Practice'),
            onTap: () {
              Navigator.pop(context);
              _showPracticeDialog(spot);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Spot'),
            onTap: () {
              Navigator.pop(context);
              _showEditSpotDialog(spot);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              _showSpotDetails(spot);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Spot'),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteSpot(spot);
            },
          ),
        ],
      ),
    );
  }

  void _showPracticeDialog(PracticeSpot spot) {
    int practiceMinutes = 5;
    int qualityScore = 3;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Practice: ${spot.displayTitle}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How long did you practice this spot?'),
              const SizedBox(height: 16),
              Slider(
                value: practiceMinutes.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                label: '$practiceMinutes minutes',
                onChanged: (value) => setDialogState(() => practiceMinutes = value.toInt()),
              ),
              const SizedBox(height: 16),
              Text('How did it go?'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final score = index + 1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => qualityScore = score),
                    child: Icon(
                      Icons.star,
                      color: score <= qualityScore ? Colors.orange : Colors.grey,
                      size: 32,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SpotManager.recordPractice(
                spotId: spot.id!,
                durationMinutes: practiceMinutes,
                qualityScore: qualityScore,
              );
              
              ref.invalidate(spotsForPageProvider);
              ref.invalidate(dueSpotsProvider);
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Practice session recorded!')),
              );
            },
            child: const Text('Record Practice'),
          ),
        ],
      ),
    );
  }

  void _showEditSpotDialog(PracticeSpot spot) {
    // Implementation for editing spot details
    // Similar to creation dialog but pre-filled with current values
  }

  void _showSpotDetails(PracticeSpot spot) {
    // Implementation for showing spot details and history
  }

  void _confirmDeleteSpot(PracticeSpot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Spot'),
        content: Text('Are you sure you want to delete "${spot.displayTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SpotManager.deleteSpot(spot.id!);
              ref.invalidate(spotsForPageProvider);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Spot deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // UTILITY METHODS
  // ====================================================================

  Color _getColorFromString(String colorName) {
    final colorblindMode = ref.watch(colorblindModeProvider);
    
    SpotColor spotColor;
    switch (colorName.toLowerCase()) {
      case 'red': 
        spotColor = SpotColor.red;
        break;
      case 'yellow': 
        spotColor = SpotColor.yellow;
        break;
      case 'green': 
        spotColor = SpotColor.green;
        break;
      case 'blue':
        spotColor = SpotColor.blue;
        break;
      default: 
        spotColor = SpotColor.red;
        break;
    }
    
    return AppColors.getSpotColorByEnum(spotColor, colorblindMode: colorblindMode);
  }
}

/// Widget for displaying spot overlays on the PDF
class SpotOverlay extends StatelessWidget {
  final List<PracticeSpot> spots;
  final Function(PracticeSpot) onSpotTap;
  final Function(PracticeSpot) onSpotLongPress;

  const SpotOverlay({
    Key? key,
    required this.spots,
    required this.onSpotTap,
    required this.onSpotLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: spots.map((spot) {
        // Convert relative coordinates back to absolute
        final left = spot.x * screenSize.width;
        final top = spot.y * screenSize.height;
        final width = spot.width * screenSize.width;
        final height = spot.height * screenSize.height;

        return Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            onTap: () => onSpotTap(spot),
            onLongPress: () => onSpotLongPress(spot),
            // Prevent spot from interfering with scrolling
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _getSpotColor(spot.color),
                  width: 2,
                ),
                color: _getSpotColor(spot.color).withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // Readiness indicator
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${spot.readiness}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Title (if space allows)
                  if (spot.title != null && width > 60 && height > 30)
                    Positioned(
                      bottom: 2,
                      left: 2,
                      right: 2,
                      child: Text(
                        spot.title!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getSpotColor(String colorName) {
    final colorblindMode = ref.watch(colorblindModeProvider);
    
    SpotColor spotColor;
    switch (colorName.toLowerCase()) {
      case 'red': 
        spotColor = SpotColor.red;
        break;
      case 'yellow': 
        spotColor = SpotColor.yellow;
        break;
      case 'green': 
        spotColor = SpotColor.green;
        break;
      case 'blue':
        spotColor = SpotColor.blue;
        break;
      default: 
        spotColor = SpotColor.red;
        break;
    }
    
    return AppColors.getSpotColorByEnum(spotColor, colorblindMode: colorblindMode);
  }
}

/// Helper class for selection rectangle
class SelectionRect {
  final double dx;
  final double dy;
  final double width;
  final double height;

  const SelectionRect({
    required this.dx,
    required this.dy,
    required this.width,
    required this.height,
  });
}
