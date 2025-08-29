import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/learning_system_service.dart';
import '../services/review_frequency_service.dart';
import '../providers/app_settings_provider.dart';
import '../providers/practice_provider.dart';
import '../providers/unified_library_provider.dart';
import '../models/spot.dart';
import '../theme/app_theme.dart';

class LearningRecommendationsWidget extends ConsumerWidget {
  const LearningRecommendationsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final learningService = ref.read(learningSystemServiceProvider);
    final practiceState = ref.watch(practiceProvider);
    final pieces = ref.watch(unifiedLibraryProvider);
    
    // Get real data from practice state and pieces
    final List<Spot> spots = [
      ...(practiceState.dailyPlan ?? []),
      ...(practiceState.urgentSpots ?? []),
    ];
    final pieceList = pieces.when(
      data: (pieceList) => pieceList,
      loading: () => <String>[],
      error: (_, __) => <String>[],
    );
    
    // Generate intelligent recommendations based on real data
    final recommendations = learningService.getPracticeRecommendations(spots, pieceList);
    final sessionStructure = learningService.getSessionStructure(const Duration(minutes: 60));
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: AppColors.primaryPurple,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Learning Recommendations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      settings.learningSystemProfile.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPurple,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Session Structure Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.1),
                    AppColors.accentPurple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Session Structure',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStructureBar(sessionStructure),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStructureLegend('Warm-up', Colors.green, sessionStructure.warmupPercentage),
                      _buildStructureLegend('Technique', Colors.blue, sessionStructure.techniquePercentage),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStructureLegend('Repertoire', AppColors.primaryPurple, sessionStructure.repertoirePercentage),
                      _buildStructureLegend('Cool-down', Colors.orange, sessionStructure.cooldownPercentage),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Individual Recommendations
            Text(
              'Today\'s Focus Areas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            ...recommendations.map((rec) => _buildRecommendationCard(rec)).toList(),
            
            const SizedBox(height: 16),
            
            // Review Frequency Insights
            _buildReviewFrequencyInsights(settings),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureBar(PracticeSessionStructure structure) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: (structure.warmupPercentage * 100).round(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
          Expanded(
            flex: (structure.techniquePercentage * 100).round(),
            child: Container(color: Colors.blue),
          ),
          Expanded(
            flex: (structure.repertoirePercentage * 100).round(),
            child: Container(color: AppColors.primaryPurple),
          ),
          Expanded(
            flex: (structure.cooldownPercentage * 100).round(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructureLegend(String label, Color color, double percentage) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label (${(percentage * 100).round()}%)',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(PracticeRecommendation rec) {
    final priorityColor = rec.priority == RecommendationPriority.high
        ? Colors.red
        : rec.priority == RecommendationPriority.medium
            ? Colors.orange
            : Colors.green;

    final typeIcon = _getTypeIcon(rec.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              typeIcon,
              size: 16,
              color: priorityColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rec.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${rec.estimatedTime.inMinutes}min',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  rec.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (rec.spots.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${rec.spots.length} spots to practice',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.warmup:
        return Icons.wb_sunny;
      case RecommendationType.technique:
        return Icons.fitness_center;
      case RecommendationType.repertoire:
        return Icons.music_note;
      case RecommendationType.sightReading:
        return Icons.visibility;
      case RecommendationType.musicality:
        return Icons.palette;
      case RecommendationType.problemSolving:
        return Icons.build;
      case RecommendationType.maintenance:
        return Icons.refresh;
      case RecommendationType.focus:
        return Icons.center_focus_strong;
      case RecommendationType.enjoyment:
        return Icons.favorite;
    }
  }

  Widget _buildReviewFrequencyInsights(AppSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Frequency Settings',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildFrequencyRow(
            'Critical Spots',
            settings.criticalSpotsFrequency,
            Colors.red,
            _calculateInterval(settings.criticalSpotsFrequency, 'critical'),
          ),
          _buildFrequencyRow(
            'Review Spots',
            settings.reviewSpotsFrequency,
            Colors.orange,
            _calculateInterval(settings.reviewSpotsFrequency, 'review'),
          ),
          _buildFrequencyRow(
            'Maintenance',
            settings.maintenanceSpotsFrequency,
            Colors.green,
            _calculateInterval(settings.maintenanceSpotsFrequency, 'maintenance'),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyRow(String label, double frequency, Color color, String interval) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            '${frequency.round()}% ($interval)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateInterval(double frequency, String type) {
    switch (type) {
      case 'critical':
        return 'Every ${(3 - frequency / 30).round().clamp(1, 3)} days';
      case 'review':
        return 'Every ${(7 - frequency / 15).round().clamp(2, 7)} days';
      case 'maintenance':
        return 'Every ${(14 - frequency / 8).round().clamp(7, 14)} days';
      default:
        return 'Weekly';
    }
  }
}
