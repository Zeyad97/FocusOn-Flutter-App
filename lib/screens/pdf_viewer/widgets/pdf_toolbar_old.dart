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
          // View Mode Dropdown
          DropdownButton<ViewMode>(
            value: viewMode,
            onChanged: (mode) => onViewModeChanged(mode!),
            dropdownColor: const Color(0xFF2A2640),
            style: const TextStyle(color: Colors.white),
            underline: Container(),
            items: ViewMode.values.map((mode) {
              return DropdownMenuItem(
                value: mode,
                child: Text(
                  mode.displayName,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
          
          // Zoom Controls
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
          
          // Page Navigation
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
        color: Colors.black.withOpacity(0.85),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top row with title and close
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    FeedbackSystem.light();
                    onClose();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        piece.composer,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$currentPage / $totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Control buttons row
            Row(
              children: [
                // Navigation controls
                _buildEnhancedActionButton(
                  icon: Icons.keyboard_arrow_left,
                  onPressed: currentPage > 1 
                      ? () => onPageChanged(currentPage - 1)
                      : null,
                  tooltip: 'Previous Page',
                ),
                const SizedBox(width: 8),
                _buildEnhancedActionButton(
                  icon: Icons.keyboard_arrow_right,
                  onPressed: currentPage < totalPages 
                      ? () => onPageChanged(currentPage + 1)
                      : null,
                  tooltip: 'Next Page',
                ),
                const SizedBox(width: 16),
                
                // Zoom controls
                _buildEnhancedActionButton(
                  icon: Icons.zoom_out,
                  onPressed: onZoomOut,
                  tooltip: 'Zoom Out',
                ),
                const SizedBox(width: 8),
                _buildEnhancedActionButton(
                  icon: Icons.zoom_in,
                  onPressed: onZoomIn,
                  tooltip: 'Zoom In',
                ),
                const SizedBox(width: 8),
                _buildEnhancedActionButton(
                  icon: Icons.fit_screen,
                  onPressed: onFitWidth,
                  tooltip: 'Fit Width',
                ),
                const SizedBox(width: 16),
                
                // Practice tools
                _buildEnhancedActionButton(
                  icon: Icons.place,
                  onPressed: onSpotModeToggle,
                  tooltip: 'Spot Mode',
                  isActive: isSpotMode,
                  activeColor: AppColors.spotRed,
                ),
                const SizedBox(width: 8),
                _buildEnhancedActionButton(
                  icon: Icons.edit,
                  onPressed: onAnnotationModeToggle,
                  tooltip: 'Annotation Mode',
                  isActive: isAnnotationMode,
                  activeColor: AppColors.primaryPurple,
                ),
                const SizedBox(width: 8),
                _buildEnhancedActionButton(
                  icon: Icons.music_note,
                  onPressed: onMetronomeToggle,
                  tooltip: 'Metronome',
                ),
                const Spacer(),
                
                // View mode and search
                _buildEnhancedActionButton(
                  icon: Icons.view_module,
                  onPressed: () => _showViewModeBottomSheet(context),
                  tooltip: 'View Mode',
                ),
                const SizedBox(width: 8),
                _buildEnhancedActionButton(
                  icon: Icons.search,
                  onPressed: () => _showSearchDialog(context),
                  tooltip: 'Search',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row - Title and close
            Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        piece.composer,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Concert date indicator
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Controls row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // View mode
                  DropdownButton<ViewMode>(
                    value: viewMode,
                    onChanged: (mode) => onViewModeChanged(mode!),
                    dropdownColor: Colors.black87,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(
                        value: ViewMode.singlePage,
                        child: Text('Single'),
                      ),
                      DropdownMenuItem(
                        value: ViewMode.twoPage,
                        child: Text('Two Page'),
                      ),
                      DropdownMenuItem(
                        value: ViewMode.verticalScroll,
                        child: Text('Scroll'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Zoom controls
                  IconButton(
                    onPressed: onZoomOut,
                    icon: Icon(Icons.zoom_out, color: Colors.white.withOpacity(0.8)),
                    iconSize: 20,
                  ),
                  Text(
                    '${(zoomLevel * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  IconButton(
                    onPressed: onZoomIn,
                    icon: Icon(Icons.zoom_in, color: Colors.white.withOpacity(0.8)),
                    iconSize: 20,
                  ),
                  IconButton(
                    onPressed: onFitWidth,
                    icon: Icon(Icons.fit_screen, color: Colors.white.withOpacity(0.8)),
                    iconSize: 20,
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
                    width: 60,
                    child: Text(
                      '$currentPage/$totalPages',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
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
            ),
            
            const SizedBox(height: 8),
            
            // Action buttons row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.create,
                    label: 'Spot',
                    isActive: isSpotMode,
                    activeColor: AppColors.errorRed,
                    onPressed: onSpotModeToggle,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.edit,
                    label: 'Annotate',
                    isActive: isAnnotationMode,
                    activeColor: AppColors.primaryBlue,
                    onPressed: onAnnotationModeToggle,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.music_note,
                    label: 'Metronome',
                    isActive: false,
                    activeColor: AppColors.successGreen,
                    onPressed: onMetronomeToggle,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.search,
                    label: 'Search',
                    isActive: false,
                    activeColor: AppColors.warningOrange,
                    onPressed: () {
                      _showSearchDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConcertUrgencyColor() {
    if (piece.concertDate == null) return AppColors.textSecondary;
    
    final daysUntil = piece.concertDate!.difference(DateTime.now()).inDays;
    if (daysUntil <= 3) return AppColors.errorRed;
    if (daysUntil <= 7) return AppColors.warningOrange;
    return AppColors.primaryBlue;
  }

  String _formatConcertDate() {
    if (piece.concertDate == null) return '';
    
    final daysUntil = piece.concertDate!.difference(DateTime.now()).inDays;
    if (daysUntil == 0) return 'Today!';
    if (daysUntil == 1) return 'Tomorrow';
    if (daysUntil <= 7) return '${daysUntil} days';
    return '${(daysUntil / 7).floor()} weeks';
  }

  void _showSearchDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.search, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Search & Navigation'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Text',
                  hintText: 'Enter text to search...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              
              // Quick navigation section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick Navigation:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                children: [
                  _QuickNavButton(
                    label: 'First Page',
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to page 1
                    },
                  ),
                  _QuickNavButton(
                    label: 'Last Page', 
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to last page
                    },
                  ),
                  _QuickNavButton(
                    label: 'Middle',
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to middle page
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              const Text(
                '💡 Pro Tip:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 4),
              const Text(
                'Text search requires a premium PDF library. Instead, use SPOTS to mark important sections like:\n• Difficult passages\n• Tempo changes\n• Key signatures\n• Repeat signs',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('💡 Tip: Use SPOT mode to mark important sections!'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.create),
            label: const Text('Create Spot Instead'),
          ),
        ],
      ),
    );
  }
}

class _QuickNavButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _QuickNavButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
              size: 18,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
