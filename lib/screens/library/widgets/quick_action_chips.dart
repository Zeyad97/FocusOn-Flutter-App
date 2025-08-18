import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/spot.dart';

/// Quick action chips for different practice modes
class QuickActionChips extends StatelessWidget {
  final List<Spot> urgentSpots;
  final List<Spot> criticalSpots;
  final VoidCallback onSmartPractice;
  final VoidCallback onCriticalSpots;
  final VoidCallback onWarmup;

  const QuickActionChips({
    super.key,
    required this.urgentSpots,
    required this.criticalSpots,
    required this.onSmartPractice,
    required this.onCriticalSpots,
    required this.onWarmup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Smart Practice chip
            _ActionChip(
              label: 'Smart Practice',
              icon: Icons.psychology,
              color: AppColors.primaryBlue,
              badge: urgentSpots.length > 0 ? urgentSpots.length : null,
              onTap: onSmartPractice,
            ),
            
            const SizedBox(width: 8),
            
            // Critical Spots chip
            if (criticalSpots.isNotEmpty)
              _ActionChip(
                label: 'Critical Spots',
                icon: Icons.warning,
                color: AppColors.errorRed,
                badge: criticalSpots.length,
                onTap: onCriticalSpots,
              ),
            
            if (criticalSpots.isNotEmpty) const SizedBox(width: 8),
            
            // Warmup chip
            _ActionChip(
              label: 'Warmup',
              icon: Icons.self_improvement,
              color: AppColors.successGreen,
              onTap: onWarmup,
            ),
            
            const SizedBox(width: 8),
            
            // Quick Review chip
            _ActionChip(
              label: 'Quick Review',
              icon: Icons.quiz,
              color: AppColors.textSecondary,
              onTap: () {
                // TODO: Implement quick review
              },
            ),
            
            const SizedBox(width: 8),
            
            // Performance Mode chip
            _ActionChip(
              label: 'Performance',
              icon: Icons.piano,
              color: AppColors.warningOrange,
              onTap: () {
                // TODO: Implement performance mode
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int? badge;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ActionChip(
          onPressed: onTap,
          avatar: Icon(
            icon,
            color: color,
            size: 18,
          ),
          label: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: color.withOpacity(0.1),
          side: BorderSide(
            color: color.withOpacity(0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        
        // Badge
        if (badge != null && badge! > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

