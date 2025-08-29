import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot.dart';
import '../models/piece.dart';
import '../providers/app_settings_provider.dart';

// Provider for the learning system service
final learningSystemServiceProvider = Provider<LearningSystemService>((ref) {
  return LearningSystemService(ref);
});

class LearningSystemService {
  final Ref ref;

  LearningSystemService(this.ref);

  // Get practice recommendations based on learning profile
  List<PracticeRecommendation> getPracticeRecommendations(List<Spot> spots, List<dynamic> pieces) {
    final profile = ref.read(appSettingsProvider).learningSystemProfile;
    final recommendations = <PracticeRecommendation>[];

    switch (profile) {
      case 'Conservatory':
        recommendations.addAll(_getConservatoryRecommendations(spots, pieces));
        break;
      case 'Advanced':
        recommendations.addAll(_getAdvancedRecommendations(spots, pieces));
        break;
      case 'Standard':
      default:
        recommendations.addAll(_getStandardRecommendations(spots, pieces));
        break;
    }

    return recommendations;
  }

  List<PracticeRecommendation> _getConservatoryRecommendations(List<Spot> spots, List<dynamic> pieces) {
    return [
      PracticeRecommendation(
        title: 'Technical Foundation',
        description: 'Focus on scales, arpeggios, and fundamental technique for 20 minutes',
        priority: RecommendationPriority.high,
        estimatedTime: Duration(minutes: 20),
        type: RecommendationType.technique,
        spots: spots.where((s) => s.color == SpotColor.red).take(3).toList(),
      ),
      PracticeRecommendation(
        title: 'Sight-Reading',
        description: 'Practice reading new material to improve fluency',
        priority: RecommendationPriority.medium,
        estimatedTime: Duration(minutes: 15),
        type: RecommendationType.sightReading,
        spots: [],
      ),
      PracticeRecommendation(
        title: 'Repertoire Polish',
        description: 'Perfect challenging passages with slow, deliberate practice',
        priority: RecommendationPriority.high,
        estimatedTime: Duration(minutes: 30),
        type: RecommendationType.repertoire,
        spots: spots.where((s) => s.readinessLevel == ReadinessLevel.newSpot).take(5).toList(),
      ),
    ];
  }

  List<PracticeRecommendation> _getAdvancedRecommendations(List<Spot> spots, List<dynamic> pieces) {
    return [
      PracticeRecommendation(
        title: 'Challenging Spots',
        description: 'Work on your most difficult passages with focused attention',
        priority: RecommendationPriority.high,
        estimatedTime: Duration(minutes: 25),
        type: RecommendationType.problemSolving,
        spots: spots.where((s) => s.readinessLevel == ReadinessLevel.newSpot).take(4).toList(),
      ),
      PracticeRecommendation(
        title: 'Musical Expression',
        description: 'Focus on dynamics, phrasing, and artistic interpretation',
        priority: RecommendationPriority.medium,
        estimatedTime: Duration(minutes: 20),
        type: RecommendationType.musicality,
        spots: spots.where((s) => s.color == SpotColor.blue).take(3).toList(),
      ),
      PracticeRecommendation(
        title: 'Review & Maintenance',
        description: 'Keep previously learned material fresh and polished',
        priority: RecommendationPriority.medium,
        estimatedTime: Duration(minutes: 15),
        type: RecommendationType.maintenance,
        spots: spots.where((s) => s.readinessLevel == ReadinessLevel.review).take(6).toList(),
      ),
    ];
  }

  List<PracticeRecommendation> _getStandardRecommendations(List<Spot> spots, List<dynamic> pieces) {
    return [
      PracticeRecommendation(
        title: 'Daily Warm-up',
        description: 'Start with gentle exercises to prepare your hands and mind',
        priority: RecommendationPriority.high,
        estimatedTime: Duration(minutes: 10),
        type: RecommendationType.warmup,
        spots: spots.where((s) => s.color == SpotColor.red).take(2).toList(),
      ),
      PracticeRecommendation(
        title: 'Main Focus',
        description: 'Work on your current piece with patience and attention',
        priority: RecommendationPriority.high,
        estimatedTime: Duration(minutes: 20),
        type: RecommendationType.focus,
        spots: spots.where((s) => s.readinessLevel == ReadinessLevel.newSpot).take(3).toList(),
      ),
      PracticeRecommendation(
        title: 'Fun & Exploration',
        description: 'Play something you enjoy or try something new',
        priority: RecommendationPriority.low,
        estimatedTime: Duration(minutes: 10),
        type: RecommendationType.enjoyment,
        spots: spots.where((s) => s.readinessLevel == ReadinessLevel.mastered).take(2).toList(),
      ),
    ];
  }

  // Get practice session structure based on profile
  PracticeSessionStructure getSessionStructure(Duration totalTime) {
    final profile = ref.read(appSettingsProvider).learningSystemProfile;
    
    switch (profile) {
      case 'Conservatory':
        return PracticeSessionStructure(
          warmupPercentage: 0.15,
          techniquePercentage: 0.25,
          repertoirePercentage: 0.45,
          cooldownPercentage: 0.15,
          recommendedBreaks: totalTime.inMinutes ~/ 20,
          focusIntensity: FocusIntensity.high,
        );
      case 'Advanced':
        return PracticeSessionStructure(
          warmupPercentage: 0.10,
          techniquePercentage: 0.20,
          repertoirePercentage: 0.55,
          cooldownPercentage: 0.15,
          recommendedBreaks: totalTime.inMinutes ~/ 25,
          focusIntensity: FocusIntensity.high,
        );
      case 'Standard':
      default:
        return PracticeSessionStructure(
          warmupPercentage: 0.20,
          techniquePercentage: 0.15,
          repertoirePercentage: 0.50,
          cooldownPercentage: 0.15,
          recommendedBreaks: totalTime.inMinutes ~/ 30,
          focusIntensity: FocusIntensity.medium,
        );
    }
  }

  // Get adaptive difficulty recommendations
  Map<String, dynamic> getAdaptiveSettings() {
    final profile = ref.read(appSettingsProvider).learningSystemProfile;
    final reviewFreq = ref.read(appSettingsProvider);
    
    return {
      'tempoReduction': profile == 'Conservatory' ? 0.6 : profile == 'Advanced' ? 0.7 : 0.8,
      'repetitionsPerSpot': profile == 'Conservatory' ? 8 : profile == 'Advanced' ? 6 : 4,
      'maxSessionLength': profile == 'Conservatory' ? 120 : profile == 'Advanced' ? 90 : 60,
      'criticalSpotFocus': reviewFreq.criticalSpotsFrequency / 100.0,
      'reviewSpotFocus': reviewFreq.reviewSpotsFrequency / 100.0,
      'maintenanceSpotFocus': reviewFreq.maintenanceSpotsFrequency / 100.0,
    };
  }
}

class PracticeRecommendation {
  final String title;
  final String description;
  final RecommendationPriority priority;
  final Duration estimatedTime;
  final RecommendationType type;
  final List<Spot> spots;

  PracticeRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedTime,
    required this.type,
    required this.spots,
  });
}

class PracticeSessionStructure {
  final double warmupPercentage;
  final double techniquePercentage;
  final double repertoirePercentage;
  final double cooldownPercentage;
  final int recommendedBreaks;
  final FocusIntensity focusIntensity;

  PracticeSessionStructure({
    required this.warmupPercentage,
    required this.techniquePercentage,
    required this.repertoirePercentage,
    required this.cooldownPercentage,
    required this.recommendedBreaks,
    required this.focusIntensity,
  });
}

enum RecommendationPriority { low, medium, high }
enum RecommendationType { warmup, technique, repertoire, sightReading, musicality, problemSolving, maintenance, focus, enjoyment }
enum FocusIntensity { low, medium, high }
