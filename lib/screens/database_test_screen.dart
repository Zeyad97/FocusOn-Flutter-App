import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/spot_manager.dart';
import '../models/practice_spot.dart';

/// Simple test screen to verify the new database works
class DatabaseTestScreen extends ConsumerStatefulWidget {
  const DatabaseTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends ConsumerState<DatabaseTestScreen> {
  List<PracticeSpot> spots = [];
  String status = 'Ready to test database';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: $status',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            
            // Test buttons
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _testCreateSpot,
                  child: const Text('Create Test Spot'),
                ),
                ElevatedButton(
                  onPressed: _testLoadSpots,
                  child: const Text('Load Spots'),
                ),
                ElevatedButton(
                  onPressed: _testPracticeSession,
                  child: const Text('Test Practice'),
                ),
                ElevatedButton(
                  onPressed: _testStatistics,
                  child: const Text('Get Stats'),
                ),
                ElevatedButton(
                  onPressed: _clearDatabase,
                  child: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Spots list
            Expanded(
              child: spots.isEmpty
                  ? const Center(child: Text('No spots found'))
                  : ListView.builder(
                      itemCount: spots.length,
                      itemBuilder: (context, index) {
                        final spot = spots[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getSpotColor(spot.color),
                              child: Text('${spot.id}'),
                            ),
                            title: Text(spot.displayTitle),
                            subtitle: Text(
                              'Piece: ${spot.piece}\n'
                              'Page: ${spot.page}\n'
                              'Readiness: ${spot.readiness}%\n'
                              'Practiced: ${spot.repeatCount} times',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteSpot(spot.id!),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testCreateSpot() async {
    try {
      setState(() => status = 'Creating test spot...');
      
      final spotId = await SpotManager.createSpot(
        pieceName: 'Test Piece ${DateTime.now().millisecondsSinceEpoch}',
        pageNumber: 1,
        x: 0.5,
        y: 0.3,
        width: 0.2,
        height: 0.1,
        color: ['red', 'yellow', 'green'][DateTime.now().second % 3],
        title: 'Test Spot ${DateTime.now().second}',
        description: 'This is a test spot created at ${DateTime.now()}',
        priority: ['low', 'medium', 'high'][DateTime.now().second % 3],
      );
      
      setState(() => status = 'Created spot with ID: $spotId');
      await _testLoadSpots();
    } catch (e) {
      setState(() => status = 'Error creating spot: $e');
    }
  }

  Future<void> _testLoadSpots() async {
    try {
      setState(() => status = 'Loading spots...');
      
      final loadedSpots = await SpotManager.getAllActiveSpots();
      
      setState(() {
        spots = loadedSpots;
        status = 'Loaded ${spots.length} spots';
      });
    } catch (e) {
      setState(() => status = 'Error loading spots: $e');
    }
  }

  Future<void> _testPracticeSession() async {
    if (spots.isEmpty) {
      setState(() => status = 'No spots to practice. Create a spot first.');
      return;
    }

    try {
      setState(() => status = 'Recording practice session...');
      
      final spot = spots.first;
      await SpotManager.recordPractice(
        spotId: spot.id!,
        durationMinutes: 5,
        qualityScore: 4, // Good practice
        notes: 'Test practice session at ${DateTime.now()}',
      );
      
      setState(() => status = 'Practice recorded for spot ${spot.id}');
      await _testLoadSpots(); // Refresh to see updated readiness
    } catch (e) {
      setState(() => status = 'Error recording practice: $e');
    }
  }

  Future<void> _testStatistics() async {
    try {
      setState(() => status = 'Getting statistics...');
      
      final stats = await SpotManager.getStatistics();
      
      setState(() => status = 'Stats: ${stats.toString()}');
    } catch (e) {
      setState(() => status = 'Error getting stats: $e');
    }
  }

  Future<void> _deleteSpot(int spotId) async {
    try {
      await SpotManager.deleteSpot(spotId);
      setState(() => status = 'Deleted spot $spotId');
      await _testLoadSpots();
    } catch (e) {
      setState(() => status = 'Error deleting spot: $e');
    }
  }

  Future<void> _clearDatabase() async {
    try {
      setState(() => status = 'Clearing database...');
      
      // Delete all spots one by one
      for (final spot in spots) {
        await SpotManager.deleteSpot(spot.id!);
      }
      
      await _testLoadSpots();
      setState(() => status = 'Database cleared');
    } catch (e) {
      setState(() => status = 'Error clearing database: $e');
    }
  }

  Color _getSpotColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'yellow': return Colors.orange;
      case 'green': return Colors.green;
      default: return Colors.grey;
    }
  }
}
