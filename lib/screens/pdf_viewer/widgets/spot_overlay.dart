import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/spot.dart';
import '../../../theme/app_theme.dart';
import '../../../services/srs_service.dart';
import '../../../services/spot_service.dart';
import '../../../providers/unified_library_provider.dart';
import '../../settings/settings_screen.dart';

/// Overlay widget for displaying and managing spots on PDF pages
class SpotOverlay extends ConsumerWidget {
  final List<Spot> spots;
  final double pageWidth;
  final double pageHeight;
  final double zoomLevel;
  final Offset? tentativeSpotPosition;
  final Function(Spot) onSpotTapped;
  final Function(Spot) onSpotLongPressed;

  const SpotOverlay({
    super.key,
    required this.spots,
    required this.pageWidth,
    required this.pageHeight,
    required this.zoomLevel,
    this.tentativeSpotPosition,
    required this.onSpotTapped,
    required this.onSpotLongPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: pageWidth * zoomLevel,
      height: pageHeight * zoomLevel,
      child: Stack(
        children: [
          // Existing spots
          ...spots.map((spot) => _SpotWidget(
            key: ValueKey('${spot.id}_${spot.updatedAt?.millisecondsSinceEpoch}_${spot.color}_${spot.priority.name}_${spot.readinessLevel.name}'),
            spot: spot,
            pageWidth: pageWidth,
            pageHeight: pageHeight,
            zoomLevel: zoomLevel,
            onTapped: () => onSpotTapped(spot),
            onLongPressed: () => onSpotLongPressed(spot),
          )).toList(),
          
          // Tentative spot during creation
          if (tentativeSpotPosition != null)
            _TentativeSpotWidget(
              position: tentativeSpotPosition!,
              zoomLevel: zoomLevel,
            ),
        ],
      ),
    );
  }
}

class _SpotWidget extends StatefulWidget {
  final Spot spot;
  final double pageWidth;
  final double pageHeight;
  final double zoomLevel;
  final VoidCallback onTapped;
  final VoidCallback onLongPressed;

  const _SpotWidget({
    super.key,
    required this.spot,
    required this.pageWidth,
    required this.pageHeight,
    required this.zoomLevel,
    required this.onTapped,
    required this.onLongPressed,
  });

  @override
  State<_SpotWidget> createState() => _SpotWidgetState();
}

class _SpotWidgetState extends State<_SpotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    
    // Add subtle pulse for high priority spots
    if (widget.spot.priority == SpotPriority.high) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spotColor = _getSpotColor();
    final isSmallZoom = widget.zoomLevel < 0.8;
    
    // For small zoom levels, show compact circular spots
    if (isSmallZoom) {
      return _buildCompactSpot(spotColor);
    }
    
    // For normal/large zoom levels, show detailed rectangular spots
    return _buildDetailedSpot(spotColor);
  }

  Widget _buildCompactSpot(Color spotColor) {
    // Make dots smaller and positioned exactly at touch location
    final dotSize = 16.0 * widget.zoomLevel.clamp(0.5, 1.5);
    
    return Positioned(
      // Position dot exactly at the touch coordinates (centered)
      left: (widget.spot.x * widget.pageWidth * widget.zoomLevel) - (dotSize / 2),
      top: (widget.spot.y * widget.pageHeight * widget.zoomLevel) - (dotSize / 2),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final scale = widget.spot.priority == SpotPriority.high
              ? _scaleAnimation.value * _pulseAnimation.value
              : _scaleAnimation.value;
              
          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: widget.onTapped,
              onLongPress: widget.onLongPressed,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: spotColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: spotColor.withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                // Remove icon for cleaner dot appearance
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailedSpot(Color spotColor) {
    // Show larger dots at higher zoom levels, positioned exactly at touch location
    final dotSize = 24.0 * widget.zoomLevel.clamp(0.8, 2.0);
    
    return Positioned(
      // Position dot exactly at the touch coordinates (centered)
      left: (widget.spot.x * widget.pageWidth * widget.zoomLevel) - (dotSize / 2),
      top: (widget.spot.y * widget.pageHeight * widget.zoomLevel) - (dotSize / 2),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final scale = widget.spot.priority == SpotPriority.high
              ? _scaleAnimation.value * _pulseAnimation.value
              : _scaleAnimation.value;
              
          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: () => _showFullScreenSpotEditor(),
              onLongPress: widget.onLongPressed,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: spotColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: spotColor.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                // Add small priority indicator inside the dot
                child: widget.spot.priority == SpotPriority.high
                    ? Center(
                        child: Icon(
                          Icons.priority_high,
                          color: Colors.white,
                          size: dotSize * 0.5,
                        ),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenSpotEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenSpotEditor(spot: widget.spot),
      ),
    );
  }

  Color _getSpotColor() {
    // Color based on priority for better visibility
    switch (widget.spot.priority) {
      case SpotPriority.high:
        return AppColors.errorRed; // Red for high priority
      case SpotPriority.medium:
        return AppColors.warningYellow; // Yellow for medium priority
      case SpotPriority.low:
        return AppColors.successGreen; // Green for low priority
    }
  }

  Widget _getSpotIcon() {
    final iconColor = Theme.of(context).colorScheme.onPrimary;
    final iconSize = (12.0 * widget.zoomLevel).clamp(8.0, 16.0);
    
    switch (widget.spot.priority) {
      case SpotPriority.low:
        return Icon(Icons.circle, color: iconColor, size: iconSize);
      case SpotPriority.medium:
        return Icon(Icons.warning_amber, color: iconColor, size: iconSize);
      case SpotPriority.high:
        return Icon(Icons.priority_high, color: iconColor, size: iconSize);
    }
  }

  String _getReadinessLabel() {
    switch (widget.spot.readinessLevel) {
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
}

class _TentativeSpotWidget extends StatefulWidget {
  final Offset position;
  final double zoomLevel;

  const _TentativeSpotWidget({
    required this.position,
    required this.zoomLevel,
  });

  @override
  State<_TentativeSpotWidget> createState() => _TentativeSpotWidgetState();
}

class _TentativeSpotWidgetState extends State<_TentativeSpotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = 20.0 * widget.zoomLevel;
    
    return Positioned(
      // Position dot exactly at the touch coordinates (centered)
      left: (widget.position.dx * widget.zoomLevel) - (dotSize / 2),
      top: (widget.position.dy * widget.zoomLevel) - (dotSize / 2),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onPrimary,
                size: dotSize * 0.5,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Quick spot creation dialog
class SpotCreationDialog extends ConsumerStatefulWidget {
  final Offset position;
  final int page;
  final Function(Spot) onSpotCreated;

  const SpotCreationDialog({
    super.key,
    required this.position,
    required this.page,
    required this.onSpotCreated,
  });

  @override
  ConsumerState<SpotCreationDialog> createState() => _SpotCreationDialogState();
}

class _SpotCreationDialogState extends ConsumerState<SpotCreationDialog> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  SpotPriority _priority = SpotPriority.medium;
  ReadinessLevel _readiness = ReadinessLevel.newSpot;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.create, color: AppColors.primaryPurple),
          const SizedBox(width: 8),
          Text(
            'Create Practice Spot',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick setup buttons
            Text(
              'Quick Setup',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickSetupChip('Difficult Section', SpotPriority.high, ReadinessLevel.newSpot, Colors.red),
                _buildQuickSetupChip('Practice More', SpotPriority.medium, ReadinessLevel.learning, Colors.orange),
                _buildQuickSetupChip('Review', SpotPriority.low, ReadinessLevel.review, Colors.green),
                _buildQuickSetupChip('Nearly Mastered', SpotPriority.low, ReadinessLevel.mastered, Colors.blue),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            TextField(
              controller: _titleController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Spot Title',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                hintText: 'e.g., "Measure 32-35 triplets"',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            
            Text('Priority Level', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SpotPriority.values.map((priority) {
                final isSelected = _priority == priority;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        size: 16,
                        color: isSelected ? Colors.white : _getPriorityColor(priority),
                      ),
                      const SizedBox(width: 4),
                      Text(_getPriorityLabel(priority)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _priority = priority);
                  },
                  selectedColor: _getPriorityColor(priority),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            Text('Current Level', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ReadinessLevel.values.map((readiness) {
                final isSelected = _readiness == readiness;
                return ChoiceChip(
                  label: Text(_getReadinessLabel(readiness)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _readiness = readiness);
                  },
                  selectedColor: _getReadinessColor(readiness),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _notesController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                hintText: 'Practice notes, tempo, fingering...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                prefixIcon: Icon(Icons.note_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createSpot,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
              const SizedBox(width: 4),
              const Text('Create Spot', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSetupChip(String label, SpotPriority priority, ReadinessLevel readiness, Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          _priority = priority;
          _readiness = readiness;
          if (_titleController.text.isEmpty) {
            _titleController.text = label;
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getPriorityIcon(priority),
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createSpot() {
    String title = _titleController.text.trim();
    
    // Auto-generate title if empty
    if (title.isEmpty) {
      title = _generateDefaultTitle();
    }

    final spot = Spot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pieceId: '', // Will be set by parent
      title: title,
      description: _notesController.text.trim(),
      pageNumber: widget.page,
      x: widget.position.dx,
      y: widget.position.dy,
      width: 0.15, // Slightly larger default size
      height: 0.08,
      priority: _priority,
      readinessLevel: _readiness,
      color: _getSpotColorFromReadiness(_readiness),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      nextDue: _calculateNextDue(),
      practiceCount: 0,
    );

    widget.onSpotCreated(spot);
    Navigator.of(context).pop();
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 8),
            Text('Practice spot "$title" created!'),
          ],
        ),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _generateDefaultTitle() {
    switch (_priority) {
      case SpotPriority.high:
        return 'Difficult Section';
      case SpotPriority.medium:
        return 'Practice Area';
      case SpotPriority.low:
        return 'Review Section';
    }
  }

  SpotColor _getSpotColorFromReadiness(ReadinessLevel readiness) {
    switch (readiness) {
      case ReadinessLevel.newSpot:
        return SpotColor.red; // New spots are critical (red)
      case ReadinessLevel.learning:
        return SpotColor.yellow; // Learning spots need practice (yellow/orange)
      case ReadinessLevel.review:
        return SpotColor.green; // Review spots are stable (green)
      case ReadinessLevel.mastered:
        return SpotColor.blue; // Mastered spots are nearly solved (blue)
    }
  }

  DateTime _calculateNextDue() {
    // Use the SRS service with user's frequency settings
    final srsService = ref.read(srsServiceProvider);
    
    // Create a temporary spot to calculate next due date
    final tempSpot = Spot(
      id: '',
      pieceId: '', // Temporary empty pieceId for calculation
      title: '',
      description: '',
      pageNumber: widget.page,
      x: widget.position.dx,
      y: widget.position.dy,
      width: 0.15,
      height: 0.08,
      priority: _priority,
      readinessLevel: _readiness,
      color: _getSpotColorFromReadiness(_readiness),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      nextDue: DateTime.now(),
      practiceCount: 0,
    );
    
    // Calculate initial due date for new spots based on readiness level
    final result = _readiness == ReadinessLevel.newSpot 
        ? SpotResult.good  // New spots get standard interval
        : SpotResult.excellent;  // Other readiness levels get longer intervals
        
    return srsService.calculateNextDue(tempSpot, result);
  }

  String _getPriorityLabel(SpotPriority priority) {
    switch (priority) {
      case SpotPriority.low:
        return 'Low';
      case SpotPriority.medium:
        return 'Medium';
      case SpotPriority.high:
        return 'High';
    }
  }

  IconData _getPriorityIcon(SpotPriority priority) {
    switch (priority) {
      case SpotPriority.low:
        return Icons.circle_outlined;
      case SpotPriority.medium:
        return Icons.warning_amber_outlined;
      case SpotPriority.high:
        return Icons.priority_high;
    }
  }

  Color _getPriorityColor(SpotPriority priority) {
    switch (priority) {
      case SpotPriority.low:
        return AppColors.successGreen;
      case SpotPriority.medium:
        return AppColors.warningOrange;
      case SpotPriority.high:
        return AppColors.errorRed;
    }
  }

  String _getReadinessLabel(ReadinessLevel readiness) {
    switch (readiness) {
      case ReadinessLevel.newSpot:
        return 'New Spot';
      case ReadinessLevel.learning:
        return 'Learning';
      case ReadinessLevel.review:
        return 'Review';
      case ReadinessLevel.mastered:
        return 'Mastered';
    }
  }

  Color _getReadinessColor(ReadinessLevel readiness) {
    switch (readiness) {
      case ReadinessLevel.newSpot:
        return AppColors.errorRed;
      case ReadinessLevel.learning:
        return AppColors.warningOrange;
      case ReadinessLevel.review:
        return AppColors.warningYellow;
      case ReadinessLevel.mastered:
        return AppColors.successGreen;
    }
  }
}

/// Public function to open the spot editor from external screens
Future<bool?> openSpotEditor(BuildContext context, Spot spot) {
  return Navigator.of(context).push(
    MaterialPageRoute<bool>(
      builder: (context) => _FullScreenSpotEditor(spot: spot),
    ),
  );
}

class _FullScreenSpotEditor extends ConsumerStatefulWidget {
  final Spot spot;

  const _FullScreenSpotEditor({required this.spot});

  @override
  ConsumerState<_FullScreenSpotEditor> createState() => _FullScreenSpotEditorState();
}

class _FullScreenSpotEditorState extends ConsumerState<_FullScreenSpotEditor> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late SpotPriority _priority;
  late ReadinessLevel _readinessLevel;
  late SpotColor _spotColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.spot.title);
    _descriptionController = TextEditingController(text: widget.spot.description);
    _notesController = TextEditingController(text: widget.spot.notes ?? '');
    _priority = widget.spot.priority;
    _readinessLevel = widget.spot.readinessLevel;
    _spotColor = widget.spot.color;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Color _getSpotDisplayColor() {
    final colorblindMode = ref.watch(colorblindModeProvider);
    return AppColors.getSpotColorByEnum(_spotColor, colorblindMode: colorblindMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Practice Spot'),
        backgroundColor: _getSpotDisplayColor(),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Spot Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.edit),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 20),
            
            // Color/Difficulty Selection
            Text(
              'Difficulty Color',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: SpotColor.values.map((color) {
                final isSelected = _spotColor == color;
                final displayColor = _getColorForSpotColor(color);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _spotColor = color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? displayColor : displayColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: displayColor,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle,
                            color: isSelected ? Theme.of(context).colorScheme.onPrimary : displayColor,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getColorLabel(color),
                            style: TextStyle(
                              color: isSelected ? Theme.of(context).colorScheme.onPrimary : displayColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Priority
            Text(
              'Priority Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: SpotPriority.values.map((priority) {
                final isSelected = _priority == priority;
                return ChoiceChip(
                  label: Text(_getPriorityLabel(priority)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _priority = priority);
                  },
                  selectedColor: _getPriorityColor(priority),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Readiness Level
            Text(
              'Current Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ReadinessLevel.values.map((readiness) {
                final isSelected = _readinessLevel == readiness;
                return ChoiceChip(
                  label: Text(_getReadinessLabelForChip(readiness)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _readinessLevel = readiness);
                  },
                  selectedColor: _getReadinessColor(readiness),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Practice Notes',
                hintText: 'Tempo, fingering, specific challenges...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 4,
            ),
            
            const SizedBox(height: 30),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSpot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getSpotDisplayColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForSpotColor(SpotColor color) {
    final colorblindMode = ref.watch(colorblindModeProvider);
    return AppColors.getSpotColorByEnum(color, colorblindMode: colorblindMode);
  }

  String _getColorLabel(SpotColor color) {
    switch (color) {
      case SpotColor.red:
        return 'Hard';
      case SpotColor.yellow:
        return 'Medium';
      case SpotColor.green:
        return 'Easy';
      case SpotColor.blue:
        return 'Solved';
    }
  }

  String _getPriorityLabel(SpotPriority priority) {
    switch (priority) {
      case SpotPriority.low:
        return 'Low';
      case SpotPriority.medium:
        return 'Medium';
      case SpotPriority.high:
        return 'High';
    }
  }

  Color _getPriorityColor(SpotPriority priority) {
    switch (priority) {
      case SpotPriority.low:
        return AppColors.successGreen;
      case SpotPriority.medium:
        return AppColors.warningOrange;
      case SpotPriority.high:
        return AppColors.errorRed;
    }
  }

  String _getReadinessLabelForChip(ReadinessLevel readiness) {
    switch (readiness) {
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

  Color _getReadinessColor(ReadinessLevel readiness) {
    switch (readiness) {
      case ReadinessLevel.newSpot:
        return AppColors.errorRed;
      case ReadinessLevel.learning:
        return AppColors.warningOrange;
      case ReadinessLevel.review:
        return AppColors.warningYellow;
      case ReadinessLevel.mastered:
        return AppColors.successGreen;
    }
  }

  void _saveSpot() async {
    try {
      // Create updated spot with new values
      final updatedSpot = widget.spot.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        notes: _notesController.text.trim(),
        color: _spotColor,
        priority: _priority,
        readinessLevel: _readinessLevel,
        updatedAt: DateTime.now(), // Update the timestamp
      );
      
      // Save to database
      await ref.read(spotServiceProvider).saveSpot(updatedSpot);
      
      // Refresh the unified library
      await ref.read(unifiedLibraryProvider.notifier).refresh();
      
      Navigator.pop(context, true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Spot "${_titleController.text}" saved successfully!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      Navigator.pop(context, false); // Return false to indicate failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save spot: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Spot'),
        content: const Text('Are you sure you want to delete this practice spot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              try {
                print('SpotEditor: About to delete spot "${widget.spot.title}" (id: ${widget.spot.id})');
                
                // Delete the spot from the database
                await ref.read(spotServiceProvider).deleteSpot(widget.spot.id);
                
                print('SpotEditor: Spot deleted from database, refreshing unified library...');
                
                // Refresh the unified library so the deletion appears everywhere
                await ref.read(unifiedLibraryProvider.notifier).refresh();
                
                print('SpotEditor: Library refreshed, closing editor...');
                
                Navigator.pop(context, true); // Close editor with success result
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Spot deleted successfully'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
                
                print('SpotEditor: Success message shown');
              } catch (e) {
                print('SpotEditor: Error deleting spot: $e');
                Navigator.pop(context, false); // Close editor with error result
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete spot: $e'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
