import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/piece.dart';
import '../../../models/spot.dart';
import '../library_screen.dart';
import 'piece_settings_dialog.dart';

/// Card component for displaying a piece in grid or list view
class PieceCard extends StatelessWidget {
  final Piece piece;
  final ViewMode viewMode;
  final VoidCallback onTap;

  const PieceCard({
    super.key,
    required this.piece,
    required this.viewMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (viewMode == ViewMode.grid) {
      return _buildGridCard(context);
    } else {
      return _buildListCard(context);
    }
  }

  Widget _buildGridCard(BuildContext context) {
    final readinessPercentage = piece.readinessPercentage;
    final urgentSpots = piece.spots.where((spot) => spot.isDue).length;
    final criticalSpots = piece.spots.where((spot) => spot.color == SpotColor.red).length;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with readiness indicator
              Row(
                children: [
                  CircularProgressIndicator(
                    value: readinessPercentage / 100,
                    strokeWidth: 3,
                    backgroundColor: AppColors.textSecondary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getReadinessColor(readinessPercentage),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${readinessPercentage.round()}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getReadinessColor(readinessPercentage),
                      ),
                    ),
                  ),
                  if (piece.concertDate != null) ...[
                    Icon(
                      Icons.event,
                      size: 16,
                      color: _getConcertUrgencyColor(),
                    ),
                    const SizedBox(width: 4),
                  ],
                  // Settings button
                  GestureDetector(
                    onTap: () => _showPieceSettings(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.settings,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Title
              Text(
                piece.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Composer
              Text(
                piece.composer,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (piece.keySignature != null) ...[
                const SizedBox(height: 4),
                Text(
                  piece.keySignature!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Spots indicator with color breakdown
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildSpotIndicator(
                    count: piece.spots.length,
                    color: AppColors.textSecondary,
                    label: 'total',
                  ),
                  if (urgentSpots > 0)
                    _buildSpotIndicator(
                      count: urgentSpots,
                      color: AppColors.warningOrange,
                      label: 'due',
                    ),
                  if (criticalSpots > 0)
                    _buildSpotIndicator(
                      count: criticalSpots,
                      color: AppColors.errorRed,
                      label: 'critical',
                    ),
                  // Show color-specific spot counts
                  ..._buildColorSpecificIndicators(),
                ],
              ),
              
              // Difficulty stars
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < piece.difficulty ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppColors.warningOrange,
                  );
                }),
              ),
              
              // Last opened
              if (piece.lastOpened != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last opened ${_formatLastOpened(piece.lastOpened!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final readinessPercentage = piece.readinessPercentage;
    final urgentSpots = piece.spots.where((spot) => spot.isDue).length;
    final criticalSpots = piece.spots.where((spot) => spot.color == SpotColor.red).length;

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Readiness indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: readinessPercentage / 100,
                  strokeWidth: 3,
                  backgroundColor: AppColors.textSecondary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getReadinessColor(readinessPercentage),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            piece.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (piece.concertDate != null) ...[
                          Icon(
                            Icons.event,
                            size: 16,
                            color: _getConcertUrgencyColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatConcertDate(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getConcertUrgencyColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Settings button
                        GestureDetector(
                          onTap: () => _showPieceSettings(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.settings,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Text(
                          piece.composer,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (piece.keySignature != null) ...[
                          Text(
                            ' • ${piece.keySignature}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        // Difficulty stars
                        ...List.generate(5, (index) {
                          return Icon(
                            index < piece.difficulty ? Icons.star : Icons.star_border,
                            size: 14,
                            color: AppColors.warningOrange,
                          );
                        }),
                        
                        const SizedBox(width: 16),
                        
                        // Spots indicators - use Flexible to prevent overflow
                        Flexible(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildSpotIndicator(
                                count: piece.spots.length,
                                color: AppColors.textSecondary,
                                label: 'total',
                              ),
                              if (urgentSpots > 0)
                                _buildSpotIndicator(
                                  count: urgentSpots,
                                  color: AppColors.warningOrange,
                                  label: 'due',
                                ),
                              if (criticalSpots > 0)
                                _buildSpotIndicator(
                                  count: criticalSpots,
                                  color: AppColors.errorRed,
                                  label: 'critical',
                                ),
                              // Show color-specific spot counts
                              ..._buildColorSpecificIndicators(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Readiness percentage
              Text(
                '${readinessPercentage.round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getReadinessColor(readinessPercentage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildColorSpecificIndicators() {
    print('PieceCard: Building color indicators for piece "${piece.title}"');
    print('PieceCard: Piece has ${piece.spots.length} spots');
    for (final spot in piece.spots) {
      print('  - Spot "${spot.title}" color: ${spot.color.name}');
    }
    
    final indicators = <Widget>[];
    
    // Count spots by color
    final redSpots = piece.spots.where((spot) => spot.color == SpotColor.red).length;
    final yellowSpots = piece.spots.where((spot) => spot.color == SpotColor.yellow).length;
    final greenSpots = piece.spots.where((spot) => spot.color == SpotColor.green).length;
    final blueSpots = piece.spots.where((spot) => spot.color == SpotColor.blue).length;
    
    print('PieceCard: Color counts - Red: $redSpots, Yellow: $yellowSpots, Green: $greenSpots, Blue: $blueSpots');
    
    // Add indicators for each color that has spots
    if (redSpots > 0) {
      indicators.add(_buildSpotIndicator(
        count: redSpots,
        color: Colors.red,
        label: 'red',
      ));
    }
    
    if (yellowSpots > 0) {
      indicators.add(_buildSpotIndicator(
        count: yellowSpots,
        color: Colors.orange,
        label: 'yellow',
      ));
    }
    
    if (greenSpots > 0) {
      indicators.add(_buildSpotIndicator(
        count: greenSpots,
        color: Colors.green,
        label: 'green',
      ));
    }
    
    if (blueSpots > 0) {
      indicators.add(_buildSpotIndicator(
        count: blueSpots,
        color: Colors.blue,
        label: 'blue',
      ));
    }
    
    print('PieceCard: Created ${indicators.length} indicators');
    return indicators;
  }

  Widget _buildSpotIndicator({
    required int count,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getReadinessColor(double percentage) {
    if (percentage >= 80) return AppColors.successGreen;
    if (percentage >= 60) return AppColors.warningOrange;
    return AppColors.errorRed;
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
    if (daysUntil == 0) return 'Today';
    if (daysUntil == 1) return 'Tomorrow';
    if (daysUntil <= 7) return '${daysUntil}d';
    return '${(daysUntil / 7).floor()}w';
  }

  String _formatLastOpened(DateTime lastOpened) {
    final difference = DateTime.now().difference(lastOpened);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showPieceSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PieceSettingsDialog(piece: piece),
    ).then((result) {
      // If settings were updated, the dialog will return true
      // The parent widget can listen for state changes through providers
      if (result == true) {
        // Settings were saved, no additional action needed
        // as the provider will notify listeners automatically
      }
    });
  }
}
