import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/database/db_helper.dart';
import 'package:music_app/models/practice_spot.dart';
import 'package:music_app/services/spot_manager.dart';

void main() {
  group('Practice Spots Database Tests', () {
    setUp(() async {
      // Clear database before each test
      await DBHelper.clearAllData();
    });

    test('Create and retrieve practice spot', () async {
      // Create a spot
      final spotId = await SpotManager.createSpot(
        pieceName: "Test Piece",
        pageNumber: 1,
        x: 0.5,
        y: 0.3,
        width: 0.2,
        height: 0.1,
        color: "red",
        title: "Test Spot",
        priority: "high",
      );

      expect(spotId, greaterThan(0));

      // Retrieve the spot
      final spot = await DBHelper.getSpot(spotId);
      expect(spot, isNotNull);
      expect(spot!.piece, equals("Test Piece"));
      expect(spot.page, equals(1));
      expect(spot.x, equals(0.5));
      expect(spot.y, equals(0.3));
      expect(spot.color, equals("red"));
      expect(spot.title, equals("Test Spot"));
      expect(spot.priority, equals("high"));
      expect(spot.repeatCount, equals(0));
      expect(spot.readiness, equals(0));
    });

    test('Get spots for piece', () async {
      // Create multiple spots
      await SpotManager.createSpot(
        pieceName: "Chopin Nocturne",
        pageNumber: 1,
        x: 0.1, y: 0.1, width: 0.1, height: 0.1,
        color: "red",
        title: "Spot 1",
      );

      await SpotManager.createSpot(
        pieceName: "Chopin Nocturne", 
        pageNumber: 2,
        x: 0.2, y: 0.2, width: 0.1, height: 0.1,
        color: "yellow",
        title: "Spot 2",
      );

      await SpotManager.createSpot(
        pieceName: "Bach Invention",
        pageNumber: 1,
        x: 0.3, y: 0.3, width: 0.1, height: 0.1,
        color: "green",
        title: "Spot 3",
      );

      // Get spots for specific piece
      final chopinSpots = await SpotManager.getSpotsForPiece("Chopin Nocturne");
      expect(chopinSpots.length, equals(2));
      expect(chopinSpots[0].piece, equals("Chopin Nocturne"));
      expect(chopinSpots[1].piece, equals("Chopin Nocturne"));

      final bachSpots = await SpotManager.getSpotsForPiece("Bach Invention");
      expect(bachSpots.length, equals(1));
      expect(bachSpots[0].piece, equals("Bach Invention"));
    });

    test('Record practice and update readiness', () async {
      // Create a spot
      final spotId = await SpotManager.createSpot(
        pieceName: "Test Piece",
        pageNumber: 1,
        x: 0.5, y: 0.5, width: 0.1, height: 0.1,
        color: "red",
      );

      // Get initial spot
      final initialSpot = await DBHelper.getSpot(spotId);
      expect(initialSpot!.readiness, equals(0));
      expect(initialSpot.repeatCount, equals(0));

      // Record a good practice session
      await SpotManager.recordPractice(
        spotId: spotId,
        durationMinutes: 10,
        qualityScore: 4, // Good practice
      );

      // Check updated spot
      final updatedSpot = await DBHelper.getSpot(spotId);
      expect(updatedSpot!.readiness, greaterThan(0)); // Should improve
      expect(updatedSpot.repeatCount, equals(1));
      expect(updatedSpot.lastPractice, isNotNull);

      // Get practice history
      final history = await SpotManager.getPracticeHistory(spotId);
      expect(history.length, equals(1));
      expect(history[0]['duration_minutes'], equals(10));
      expect(history[0]['quality_score'], equals(4));
    });

    test('Due spots functionality', () async {
      // Create spots with different due dates
      final spotId1 = await SpotManager.createSpot(
        pieceName: "Piece 1", pageNumber: 1,
        x: 0.1, y: 0.1, width: 0.1, height: 0.1,
        color: "red",
      );

      final spotId2 = await SpotManager.createSpot(
        pieceName: "Piece 2", pageNumber: 1,
        x: 0.2, y: 0.2, width: 0.1, height: 0.1,
        color: "yellow",
      );

      // Initially both should be due (nextDue is null)
      final initialDueSpots = await SpotManager.getDueSpots();
      expect(initialDueSpots.length, equals(2));

      // Practice one spot to set future due date
      await SpotManager.recordPractice(
        spotId: spotId1,
        durationMinutes: 5,
        qualityScore: 5, // Excellent - should schedule further out
      );

      // Now only one should be due
      final updatedDueSpots = await SpotManager.getDueSpots();
      expect(updatedDueSpots.length, equals(1));
      expect(updatedDueSpots[0].id, equals(spotId2));
    });

    test('Search and filter functionality', () async {
      // Create spots with different attributes
      await SpotManager.createSpot(
        pieceName: "Chopin Ballade",
        pageNumber: 1,
        x: 0.1, y: 0.1, width: 0.1, height: 0.1,
        color: "red",
        title: "Difficult passage",
        priority: "high",
      );

      await SpotManager.createSpot(
        pieceName: "Mozart Sonata",
        pageNumber: 1,
        x: 0.2, y: 0.2, width: 0.1, height: 0.1,
        color: "yellow",
        title: "Easy section",
        priority: "low",
      );

      await SpotManager.createSpot(
        pieceName: "Bach Prelude",
        pageNumber: 1,
        x: 0.3, y: 0.3, width: 0.1, height: 0.1,
        color: "red",
        title: "Tricky fingering",
        priority: "medium",
      );

      // Search by text
      final searchResults = await SpotManager.searchSpots("difficult");
      expect(searchResults.length, equals(1));
      expect(searchResults[0].title, equals("Difficult passage"));

      // Filter by priority
      final highPrioritySpots = await SpotManager.getSpotsByPriority("high");
      expect(highPrioritySpots.length, equals(1));
      expect(highPrioritySpots[0].priority, equals("high"));

      // Filter by color
      final redSpots = await SpotManager.getSpotsByColor("red");
      expect(redSpots.length, equals(2));
      expect(redSpots.every((spot) => spot.color == "red"), isTrue);
    });

    test('Statistics calculation', () async {
      // Create some spots and practice sessions
      final spotId1 = await SpotManager.createSpot(
        pieceName: "Piece 1", pageNumber: 1,
        x: 0.1, y: 0.1, width: 0.1, height: 0.1,
        color: "red",
      );

      final spotId2 = await SpotManager.createSpot(
        pieceName: "Piece 2", pageNumber: 1,
        x: 0.2, y: 0.2, width: 0.1, height: 0.1,
        color: "yellow",
      );

      await SpotManager.recordPractice(spotId: spotId1, durationMinutes: 10);
      await SpotManager.recordPractice(spotId: spotId1, durationMinutes: 5);
      await SpotManager.recordPractice(spotId: spotId2, durationMinutes: 15);

      final stats = await SpotManager.getStatistics();
      expect(stats['totalSpots'], equals(2));
      expect(stats['totalPractices'], equals(3));
      expect(stats['totalPieces'], equals(2));
      expect(stats['dueForPractice'], greaterThanOrEqualTo(0));
      expect(stats['readinessAverage'], greaterThanOrEqualTo(0.0));
    });

    test('Soft delete functionality', () async {
      // Create a spot
      final spotId = await SpotManager.createSpot(
        pieceName: "Test Piece",
        pageNumber: 1,
        x: 0.5, y: 0.5, width: 0.1, height: 0.1,
        color: "red",
      );

      // Verify it exists
      final initialSpots = await SpotManager.getAllActiveSpots();
      expect(initialSpots.length, equals(1));

      // Soft delete
      await SpotManager.deleteSpot(spotId);

      // Should not appear in active spots
      final afterDeleteSpots = await SpotManager.getAllActiveSpots();
      expect(afterDeleteSpots.length, equals(0));

      // But should still exist in database (soft delete)
      final deletedSpot = await DBHelper.getSpot(spotId);
      expect(deletedSpot, isNotNull);
      expect(deletedSpot!.isActive, isFalse);
    });
  });
}
