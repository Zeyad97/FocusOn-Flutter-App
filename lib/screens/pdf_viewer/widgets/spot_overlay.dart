import 'package:flutter/material.dart';
import '../../../models/spot.dart';
import '../../../theme/app_theme.dart';

/// Overlay widget for displaying and managing spots on PDF pages
class SpotOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: pageWidth * zoomLevel,
      height: pageHeight * zoomLevel,
      child: Stack(
        children: [
          // Existing spots
          ...spots.map((spot) => _SpotWidget(
            spot: spot,
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
  final double zoomLevel;
  final VoidCallback onTapped;
  final VoidCallback onLongPressed;

  const _SpotWidget({
    required this.spot,
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
    final spotSize = 24.0 * widget.zoomLevel;
    
    return Positioned(
      left: (widget.spot.x * widget.zoomLevel) - (spotSize / 2),
      top: (widget.spot.y * widget.zoomLevel) - (spotSize / 2),
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
              child: Container(
                width: spotSize,
                height: spotSize,
                decoration: BoxDecoration(
                  color: spotColor.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: spotColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: _getSpotIcon(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getSpotColor() {
    switch (widget.spot.readinessLevel) {
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

  Widget _getSpotIcon() {
    final iconColor = Colors.white;
    final iconSize = 12.0 * widget.zoomLevel;
    
    switch (widget.spot.priority) {
      case SpotPriority.low:
        return Icon(Icons.circle, color: iconColor, size: iconSize);
      case SpotPriority.medium:
        return Icon(Icons.warning, color: iconColor, size: iconSize);
      case SpotPriority.high:
        return Icon(Icons.priority_high, color: iconColor, size: iconSize);
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
    final spotSize = 24.0 * widget.zoomLevel;
    
    return Positioned(
      left: (widget.position.dx * widget.zoomLevel) - (spotSize / 2),
      top: (widget.position.dy * widget.zoomLevel) - (spotSize / 2),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: spotSize,
              height: spotSize,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 12.0 * widget.zoomLevel,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Quick spot creation dialog
class SpotCreationDialog extends StatefulWidget {
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
  State<SpotCreationDialog> createState() => _SpotCreationDialogState();
}

class _SpotCreationDialogState extends State<SpotCreationDialog> {
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
      title: const Text('Create Practice Spot'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Spot Title',
                hintText: 'e.g., "Measure 32-35 triplets"',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            
            const Text('Priority Level'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SpotPriority.values.map((priority) {
                return ChoiceChip(
                  label: Text(_getPriorityLabel(priority)),
                  selected: _priority == priority,
                  onSelected: (selected) {
                    if (selected) setState(() => _priority = priority);
                  },
                  selectedColor: _getPriorityColor(priority),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            const Text('Current Readiness'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ReadinessLevel.values.map((readiness) {
                return ChoiceChip(
                  label: Text(_getReadinessLabel(readiness)),
                  selected: _readiness == readiness,
                  onSelected: (selected) {
                    if (selected) setState(() => _readiness = readiness);
                  },
                  selectedColor: _getReadinessColor(readiness),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Practice notes, tempo, fingering...',
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
          child: const Text('Create Spot'),
        ),
      ],
    );
  }

  void _createSpot() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a spot title')),
      );
      return;
    }

    final spot = Spot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pieceId: '', // Will be set by parent
      title: _titleController.text.trim(),
      description: _notesController.text.trim(),
      pageNumber: widget.page,
      x: widget.position.dx,
      y: widget.position.dy,
      width: 0.1,
      height: 0.05,
      priority: _priority,
      readinessLevel: _readiness,
      color: SpotColor.red,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      nextDue: DateTime.now().add(const Duration(days: 1)),
      practiceCount: 0,
    );

    widget.onSpotCreated(spot);
    Navigator.of(context).pop();
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
        return Colors.blue;
      case SpotPriority.medium:
        return Colors.orange;
      case SpotPriority.high:
        return Colors.red;
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
