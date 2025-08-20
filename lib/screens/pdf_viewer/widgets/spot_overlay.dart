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
    final spotSize = 20.0 * widget.zoomLevel.clamp(0.5, 1.5);
    
    return Positioned(
      left: (widget.spot.x * widget.pageWidth) - (spotSize / 2),
      top: (widget.spot.y * widget.pageHeight) - (spotSize / 2),
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
                width: spotSize,
                height: spotSize,
                decoration: BoxDecoration(
                  color: spotColor.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: spotColor.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
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

  Widget _buildDetailedSpot(Color spotColor) {
    // Make spots larger and more visible
    final baseWidth = 180.0 * widget.zoomLevel;
    final baseHeight = 80.0 * widget.zoomLevel;
    
    return Positioned(
      left: widget.spot.x * widget.pageWidth,
      top: widget.spot.y * widget.pageHeight,
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
                constraints: BoxConstraints(
                  minWidth: baseWidth,
                  minHeight: baseHeight,
                  maxWidth: baseWidth * 1.2,
                ),
                decoration: BoxDecoration(
                  color: spotColor.withOpacity(0.25),
                  border: Border.all(
                    color: spotColor,
                    width: 3.0,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: spotColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with priority indicator and title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: spotColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _getSpotIcon(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.spot.title.isEmpty ? 'Practice Spot' : widget.spot.title,
                              style: TextStyle(
                                color: spotColor,
                                fontSize: (14 * widget.zoomLevel).clamp(12, 18),
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Status info with larger text
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: spotColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getReadinessLabel(),
                              style: TextStyle(
                                color: spotColor,
                                fontSize: (12 * widget.zoomLevel).clamp(10, 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (widget.spot.practiceCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${widget.spot.practiceCount}x practiced',
                                style: TextStyle(
                                  color: spotColor,
                                  fontSize: (10 * widget.zoomLevel).clamp(8, 12),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Edit indicator
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            color: spotColor.withOpacity(0.7),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to edit or practice',
                            style: TextStyle(
                              color: spotColor.withOpacity(0.7),
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    final iconColor = Colors.white;
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
    final spotSize = 32.0 * widget.zoomLevel;
    
    return Positioned(
      left: (widget.position.dx * widget.zoomLevel) - (spotSize / 2),
      top: (widget.position.dy * widget.zoomLevel) - (spotSize / 2),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: spotSize,
                  height: spotSize,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16.0 * widget.zoomLevel,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Create Spot',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
      title: Row(
        children: [
          Icon(Icons.create, color: AppColors.primaryPurple),
          const SizedBox(width: 8),
          const Text('Create Practice Spot'),
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickSetupChip('Difficult Section', SpotPriority.high, ReadinessLevel.newSpot, Colors.red),
                _buildQuickSetupChip('Practice More', SpotPriority.medium, ReadinessLevel.learning, Colors.orange),
                _buildQuickSetupChip('Review', SpotPriority.low, ReadinessLevel.review, Colors.blue),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Spot Title',
                hintText: 'e.g., "Measure 32-35 triplets"',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            
            const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SpotPriority.values.map((priority) {
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        size: 16,
                        color: _priority == priority ? Colors.white : _getPriorityColor(priority),
                      ),
                      const SizedBox(width: 4),
                      Text(_getPriorityLabel(priority)),
                    ],
                  ),
                  selected: _priority == priority,
                  onSelected: (selected) {
                    if (selected) setState(() => _priority = priority);
                  },
                  selectedColor: _getPriorityColor(priority),
                  labelStyle: TextStyle(
                    color: _priority == priority ? Colors.white : null,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            const Text('Current Level', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  labelStyle: TextStyle(
                    color: _readiness == readiness ? Colors.white : null,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Practice notes, tempo, fingering...',
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
              const Icon(Icons.add_circle_outline, size: 18),
              const SizedBox(width: 4),
              const Text('Create Spot'),
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
            Icon(Icons.check_circle, color: Colors.white),
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
        return SpotColor.yellow; // Learning spots need practice (yellow)
      case ReadinessLevel.review:
        return SpotColor.yellow; // Review spots need practice (yellow)
      case ReadinessLevel.mastered:
        return SpotColor.green; // Mastered spots are easy (green)
    }
  }

  DateTime _calculateNextDue() {
    switch (_readiness) {
      case ReadinessLevel.newSpot:
        return DateTime.now(); // Practice immediately
      case ReadinessLevel.learning:
        return DateTime.now().add(const Duration(hours: 4)); // Practice again soon
      case ReadinessLevel.review:
        return DateTime.now().add(const Duration(days: 1)); // Review tomorrow
      case ReadinessLevel.mastered:
        return DateTime.now().add(const Duration(days: 7)); // Review in a week
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

class _FullScreenSpotEditor extends StatefulWidget {
  final Spot spot;

  const _FullScreenSpotEditor({required this.spot});

  @override
  State<_FullScreenSpotEditor> createState() => _FullScreenSpotEditorState();
}

class _FullScreenSpotEditorState extends State<_FullScreenSpotEditor> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late SpotPriority _priority;
  late ReadinessLevel _readinessLevel;
  late SpotColor _spotColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.spot.title);
    _descriptionController = TextEditingController(text: widget.spot.description);
    _priority = widget.spot.priority;
    _readinessLevel = widget.spot.readinessLevel;
    _spotColor = widget.spot.color;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _getSpotDisplayColor() {
    switch (_spotColor) {
      case SpotColor.red:
        return AppColors.errorRed;
      case SpotColor.yellow:
        return AppColors.warningYellow;
      case SpotColor.green:
        return AppColors.successGreen;
      case SpotColor.blue:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Practice Spot'),
        backgroundColor: _getSpotDisplayColor(),
        foregroundColor: Colors.white,
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
                            color: isSelected ? Colors.white : displayColor,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getColorLabel(color),
                            style: TextStyle(
                              color: isSelected ? Colors.white : displayColor,
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
                return ChoiceChip(
                  label: Text(_getPriorityLabel(priority)),
                  selected: _priority == priority,
                  onSelected: (selected) {
                    if (selected) setState(() => _priority = priority);
                  },
                  selectedColor: _getPriorityColor(priority),
                  labelStyle: TextStyle(
                    color: _priority == priority ? Colors.white : null,
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
                return ChoiceChip(
                  label: Text(_getReadinessLabelForChip(readiness)),
                  selected: _readinessLevel == readiness,
                  onSelected: (selected) {
                    if (selected) setState(() => _readinessLevel = readiness);
                  },
                  selectedColor: _getReadinessColor(readiness),
                  labelStyle: TextStyle(
                    color: _readinessLevel == readiness ? Colors.white : null,
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForSpotColor(SpotColor color) {
    switch (color) {
      case SpotColor.red:
        return AppColors.errorRed;
      case SpotColor.yellow:
        return AppColors.warningYellow;
      case SpotColor.green:
        return AppColors.successGreen;
      case SpotColor.blue:
        return AppColors.primaryBlue;
    }
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

  void _saveSpot() {
    // TODO: Implement spot saving logic
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Spot "${_titleController.text}" saved!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
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
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close editor
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Spot deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
