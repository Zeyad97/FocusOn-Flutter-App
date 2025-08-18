import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/spot.dart';

/// Status bar showing urgent practice spots and quick action
class PracticeStatusBar extends StatelessWidget {
  final List<Spot> urgentSpots;
  final List<Spot> criticalSpots;
  final VoidCallback onPracticeNow;

  const PracticeStatusBar({
    super.key,
    required this.urgentSpots,
    required this.criticalSpots,
    required this.onPracticeNow,
  });

  @override
  Widget build(BuildContext context) {
    final urgentCount = urgentSpots.length;
    final criticalCount = criticalSpots.length;
    
    if (urgentCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: criticalCount > 0 
              ? [AppColors.errorRed.withOpacity(0.1), AppColors.errorRed.withOpacity(0.05)]
              : [AppColors.warningOrange.withOpacity(0.1), AppColors.warningOrange.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: criticalCount > 0 
              ? AppColors.errorRed.withOpacity(0.3)
              : AppColors.warningOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: criticalCount > 0 ? AppColors.errorRed : AppColors.warningOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              criticalCount > 0 ? Icons.warning : Icons.schedule,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  criticalCount > 0 
                      ? 'Critical spots need attention!'
                      : 'Practice spots are due',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: criticalCount > 0 ? AppColors.errorRed : AppColors.warningOrange,
                  ),
                ),
                Text(
                  _buildStatusMessage(urgentCount, criticalCount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Practice button
          FilledButton.icon(
            onPressed: onPracticeNow,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Practice Now'),
            style: FilledButton.styleFrom(
              backgroundColor: criticalCount > 0 ? AppColors.errorRed : AppColors.warningOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _buildStatusMessage(int urgentCount, int criticalCount) {
    if (criticalCount > 0 && urgentCount > criticalCount) {
      return '$criticalCount critical, ${urgentCount - criticalCount} other spots due';
    } else if (criticalCount > 0) {
      return '$criticalCount critical spots need immediate practice';
    } else {
      return '$urgentCount spots are ready for practice';
    }
  }
}

