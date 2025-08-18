import 'package:flutter/material.dart';
import '../../../models/piece.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/feedback_system.dart';
import '../../../utils/animations.dart';
import '../../../widgets/enhanced_components.dart';
import '../pdf_score_viewer.dart';

/// Top toolbar for PDF Score Viewer with controls
class PDFToolbar extends StatelessWidget {
  final Piece piece;
  final int currentPage;
  final int totalPages;
  final double zoomLevel;
  final ViewMode viewMode;
  final bool isSpotMode;
  final bool isAnnotationMode;
  final Function(int) onPageChanged;
  final Function(ViewMode) onViewModeChanged;
  final VoidCallback onSpotModeToggle;
  final VoidCallback onAnnotationModeToggle;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitWidth;
  final VoidCallback onMetronomeToggle;
  final VoidCallback onClose;

  const PDFToolbar({
    super.key,
    required this.piece,
    required this.currentPage,
    required this.totalPages,
    required this.zoomLevel,
    required this.viewMode,
    required this.isSpotMode,
    required this.isAnnotationMode,
    required this.onPageChanged,
    required this.onViewModeChanged,
    required this.onSpotModeToggle,
    required this.onAnnotationModeToggle,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitWidth,
    required this.onMetronomeToggle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - animation)),
          child: Opacity(
            opacity: animation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E1B31),
                    Color(0xFF2A2640),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopRow(context),
                    const SizedBox(height: 8),
                    _buildControlsRow(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                piece.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                piece.composer,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (piece.concertDate != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getConcertUrgencyColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatConcertDate(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControlsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Action buttons
          _ActionButton(
            icon: isSpotMode ? Icons.location_on : Icons.location_off,
            label: 'Spots',
            isActive: isSpotMode,
            onPressed: onSpotModeToggle,
          ),
          _ActionButton(
            icon: isAnnotationMode ? Icons.edit : Icons.edit_off,
            label: 'Annotate',
            isActive: isAnnotationMode,
            onPressed: onAnnotationModeToggle,
          ),
          _ActionButton(
            icon: Icons.speed,
            label: 'Metronome',
            onPressed: onMetronomeToggle,
          ),
          _ActionButton(
            icon: Icons.search,
            label: 'Search',
            onPressed: () => _showSearchDialog(context),
          ),
          
          const SizedBox(width: 16),
          
          // Zoom controls
          IconButton(
            onPressed: onZoomOut,
            icon: Icon(Icons.zoom_out, color: Colors.white.withOpacity(0.8)),
          ),
          Text(
            '${(zoomLevel * 100).round()}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          IconButton(
            onPressed: onZoomIn,
            icon: Icon(Icons.zoom_in, color: Colors.white.withOpacity(0.8)),
          ),
          IconButton(
            onPressed: onFitWidth,
            icon: Icon(Icons.fit_screen, color: Colors.white.withOpacity(0.8)),
          ),
          
          const SizedBox(width: 16),
          
          // Page navigation
          IconButton(
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            icon: Icon(
              Icons.chevron_left,
              color: currentPage > 1 ? Colors.white : Colors.white.withOpacity(0.3),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '$currentPage/$totalPages',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
            icon: Icon(
              Icons.chevron_right,
              color: currentPage < totalPages ? Colors.white : Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Search in Document'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter search text...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Color _getConcertUrgencyColor() {
    if (piece.concertDate == null) return AppColors.textSecondary;
    
    final daysUntil = piece.concertDate!.difference(DateTime.now()).inDays;
    if (daysUntil <= 7) return AppColors.errorRed;
    if (daysUntil <= 30) return AppColors.warningOrange;
    return AppColors.successGreen;
  }

  String _formatConcertDate() {
    if (piece.concertDate == null) return '';
    
    final daysUntil = piece.concertDate!.difference(DateTime.now()).inDays;
    if (daysUntil == 0) return 'Today';
    if (daysUntil == 1) return 'Tomorrow';
    if (daysUntil > 0) return '${daysUntil}d';
    return 'Past';
  }
}

/// Custom action button for the PDF toolbar
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            FeedbackSystem.light();
            onPressed();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive 
                  ? AppColors.primaryPurple.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive 
                  ? Border.all(color: AppColors.primaryPurple.withOpacity(0.5))
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive 
                      ? AppColors.primaryPurple 
                      : Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive 
                        ? AppColors.primaryPurple 
                        : Colors.white.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
