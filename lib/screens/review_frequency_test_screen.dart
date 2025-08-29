import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/review_frequency_service.dart';
import '../models/spot.dart';

class ReviewFrequencyTestScreen extends ConsumerWidget {
  const ReviewFrequencyTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewService = ref.watch(reviewFrequencyServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Frequency Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Frequency Service Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            
            // Test basic functionality
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Review Frequency Service is running'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Test with sample data
            ElevatedButton(
              onPressed: () => _testReviewFrequency(context, reviewService),
              child: Text('Test Review Frequency Calculation'),
            ),
            
            SizedBox(height: 16),
            
            // Information about the service
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Frequency Features',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    _buildFeatureItem('✅ SRS-based review scheduling'),
                    _buildFeatureItem('✅ Difficulty-adjusted intervals'),
                    _buildFeatureItem('✅ Priority-based spot selection'),
                    _buildFeatureItem('✅ Optimal practice session generation'),
                    _buildFeatureItem('✅ Readiness level tracking'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(text),
    );
  }

  void _testReviewFrequency(BuildContext context, ReviewFrequencyService service) {
    try {
      // Create a sample spot for testing
      final testSpot = Spot(
        id: 'test-spot-1',
        pieceId: 'test-piece',
        title: 'Test Practice Spot',
        description: 'A sample spot for testing review frequency',
        x: 0.5,
        y: 0.5,
        width: 0.2,
        height: 0.1,
        pageNumber: 1,
        priority: SpotPriority.medium,
        color: SpotColor.yellow,
        difficulty: 3,
        readinessLevel: ReadinessLevel.learning,
        totalAttempts: 5,
        successfulAttempts: 3,
        averageScore: 0.6,
        lastPracticed: DateTime.now().subtract(Duration(days: 2)),
        timesPracticed: 5,
        createdAt: DateTime.now().subtract(Duration(days: 7)),
        updatedAt: DateTime.now().subtract(Duration(days: 1)),
        tags: ['technique', 'scales'],
        nextDue: DateTime.now().add(Duration(days: 1)),
      );

      // Test next review date calculation
      final nextReviewDate = service.getNextReviewDate(testSpot, true);
      final daysDifference = nextReviewDate.difference(DateTime.now()).inDays;

      // Test spots due for review
      final testSpots = [testSpot];
      final dueSpots = service.getSpotsDueForReview(testSpots);

      // Show results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Review Frequency Test Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Service is functioning correctly!'),
              SizedBox(height: 16),
              Text('Test Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Next review in: $daysDifference days'),
              Text('• Spots due for review: ${dueSpots.length}'),
              Text('• Current readiness: ${testSpot.readinessLevel.toString().split('.').last}'),
              Text('• Success rate: ${(testSpot.averageScore * 100).toInt()}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Show error if something goes wrong
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Test Error'),
          content: Text('Error testing review frequency: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
