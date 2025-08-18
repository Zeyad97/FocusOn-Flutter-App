import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/project.dart';
import '../models/piece.dart';
import '../models/spot.dart';
import '../models/practice_session.dart';

/// Data service for managing projects, pieces, spots, and practice sessions
class DataService {
  static const String _projectsKey = 'projects';
  static const String _piecesKey = 'pieces';
  static const String _spotsKey = 'spots';
  static const String _practiceSessionsKey = 'practice_sessions';

  /// Get all projects
  Future<List<Project>> getProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final projectsJson = prefs.getStringList(_projectsKey);
    
    // If no data exists, generate and save sample data
    if (projectsJson == null || projectsJson.isEmpty) {
      await _generateAndSaveSampleData();
      final newProjectsJson = prefs.getStringList(_projectsKey) ?? [];
      return newProjectsJson.map((json) => Project.fromJson(jsonDecode(json))).toList();
    }
    
    return projectsJson.map((json) => Project.fromJson(jsonDecode(json))).toList();
  }

  /// Get all pieces
  Future<List<Piece>> getPieces() async {
    final prefs = await SharedPreferences.getInstance();
    final piecesJson = prefs.getStringList(_piecesKey);
    
    // If no data exists, ensure sample data is generated
    if (piecesJson == null || piecesJson.isEmpty) {
      await _generateAndSaveSampleData();
      final newPiecesJson = prefs.getStringList(_piecesKey) ?? [];
      return newPiecesJson.map((json) => Piece.fromJson(jsonDecode(json))).toList();
    }
    
    return piecesJson.map((json) => Piece.fromJson(jsonDecode(json))).toList();
  }

  /// Get all spots
  Future<List<Spot>> getSpots() async {
    final prefs = await SharedPreferences.getInstance();
    final spotsJson = prefs.getStringList(_spotsKey);
    
    // If no data exists, ensure sample data is generated
    if (spotsJson == null || spotsJson.isEmpty) {
      await _generateAndSaveSampleData();
      final newSpotsJson = prefs.getStringList(_spotsKey) ?? [];
      return newSpotsJson.map((json) => Spot.fromJson(jsonDecode(json))).toList();
    }
    
    return spotsJson.map((json) => Spot.fromJson(jsonDecode(json))).toList();
  }

  /// Generate and save sample data if none exists
  Future<void> _generateAndSaveSampleData() async {
    await createSampleData();
  }

  /// Get spots for a specific project
  Future<List<Spot>> getSpotsForProject(String projectId) async {
    final projects = await getProjects();
    final pieces = await getPieces();
    final spots = await getSpots();
    
    final project = projects.firstWhere((p) => p.id == projectId);
    final projectPieces = pieces.where((p) => project.pieceIds.contains(p.id)).toList();
    final projectSpots = spots.where((s) => projectPieces.any((p) => p.id == s.pieceId)).toList();
    
    return projectSpots;
  }

  /// Get practice sessions
  Future<List<PracticeSession>> getPracticeSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_practiceSessionsKey) ?? [];
    return sessionsJson.map((json) => PracticeSession.fromJson(jsonDecode(json))).toList();
  }

  /// Save practice session
  Future<void> savePracticeSession(PracticeSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getPracticeSessions();
    
    // Remove existing session with same ID
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    
    final sessionsJson = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_practiceSessionsKey, sessionsJson);
  }

  /// Update spot after practice
  Future<void> updateSpotProgress(String spotId, SpotResult result, int practiceTimeMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final spots = await getSpots();
    final spotIndex = spots.indexWhere((s) => s.id == spotId);
    
    if (spotIndex == -1) return;
    
    final spot = spots[spotIndex];
    final now = DateTime.now();
    
    // Update SRS stats based on result
    int newRepetitions = spot.repetitions;
    double newEaseFactor = spot.easeFactor;
    int newInterval = spot.interval;
    ReadinessLevel newReadiness = spot.readinessLevel;
    SpotColor newColor = spot.color;
    
    switch (result) {
      case SpotResult.failed:
        newRepetitions = 0;
        newEaseFactor = (spot.easeFactor - 0.2).clamp(1.3, 2.5);
        newInterval = 1;
        newReadiness = ReadinessLevel.learning;
        newColor = SpotColor.red;
        break;
      case SpotResult.struggled:
        newRepetitions = 0;
        newEaseFactor = (spot.easeFactor - 0.15).clamp(1.3, 2.5);
        newInterval = 1;
        newReadiness = ReadinessLevel.learning;
        newColor = SpotColor.yellow;
        break;
      case SpotResult.good:
        newRepetitions = spot.repetitions + 1;
        if (newRepetitions == 1) {
          newInterval = 1;
        } else if (newRepetitions == 2) {
          newInterval = 6;
        } else {
          newInterval = (spot.interval * spot.easeFactor).round();
        }
        newReadiness = newRepetitions >= 3 ? ReadinessLevel.review : ReadinessLevel.learning;
        newColor = newRepetitions >= 3 ? SpotColor.green : SpotColor.yellow;
        break;
      case SpotResult.excellent:
        newRepetitions = spot.repetitions + 1;
        newEaseFactor = (spot.easeFactor + 0.1).clamp(1.3, 2.5);
        if (newRepetitions == 1) {
          newInterval = 4;
        } else if (newRepetitions == 2) {
          newInterval = 8;
        } else {
          newInterval = (spot.interval * newEaseFactor).round();
        }
        newReadiness = newRepetitions >= 2 ? ReadinessLevel.mastered : ReadinessLevel.review;
        newColor = SpotColor.green;
        break;
    }
    
    final updatedSpot = Spot(
      id: spot.id,
      pieceId: spot.pieceId,
      title: spot.title,
      description: spot.description,
      notes: spot.notes,
      pageNumber: spot.pageNumber,
      x: spot.x,
      y: spot.y,
      width: spot.width,
      height: spot.height,
      priority: spot.priority,
      readinessLevel: newReadiness,
      color: newColor,
      createdAt: spot.createdAt,
      updatedAt: now,
      lastPracticed: now,
      nextDue: now.add(Duration(days: newInterval)),
      practiceCount: spot.practiceCount + 1,
      successCount: result == SpotResult.good || result == SpotResult.excellent ? spot.successCount + 1 : spot.successCount,
      failureCount: result == SpotResult.failed || result == SpotResult.struggled ? spot.failureCount + 1 : spot.failureCount,
      easeFactor: newEaseFactor,
      interval: newInterval,
      repetitions: newRepetitions,
      recommendedPracticeTime: spot.recommendedPracticeTime,
      isActive: spot.isActive,
      metadata: spot.metadata,
    );
    
    spots[spotIndex] = updatedSpot;
    
    final spotsJson = spots.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_spotsKey, spotsJson);
  }

  /// Create sample data for testing
  Future<void> createSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if data already exists
    if (prefs.containsKey(_projectsKey)) return;
    
    final now = DateTime.now();
    
    // Create sample project
    final project = Project(
      id: 'proj_1',
      name: 'Spring Recital 2025',
      description: 'Preparing for spring recital',
      concertDate: now.add(Duration(days: 30)),
      pieceIds: ['piece_1', 'piece_2'],
      dailyPracticeGoal: Duration(minutes: 45),
      createdAt: now,
      updatedAt: now,
    );
    
    // Create sample pieces
    final pieces = [
      Piece(
        id: 'piece_1',
        title: 'Moonlight Sonata',
        composer: 'Beethoven',
        difficulty: 4,
        pdfFilePath: '/path/to/moonlight_sonata.pdf',
        spots: [],
        totalPages: 8,
        createdAt: now,
        updatedAt: now,
      ),
      Piece(
        id: 'piece_2',
        title: 'Clair de Lune',
        composer: 'Debussy',
        difficulty: 3,
        pdfFilePath: '/path/to/clair_de_lune.pdf',
        spots: [],
        totalPages: 6,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    
    // Create sample spots with varying difficulty and readiness
    final spots = [
      // Moonlight Sonata spots
      Spot(
        id: 'spot_1',
        pieceId: 'piece_1',
        title: 'Opening Adagio',
        description: 'Measures 1-8',
        pageNumber: 1,
        x: 0.1, y: 0.2, width: 0.8, height: 0.3,
        priority: SpotPriority.high,
        readinessLevel: ReadinessLevel.learning,
        color: SpotColor.red,
        createdAt: now,
        updatedAt: now,
        lastPracticed: now.subtract(Duration(days: 3)),
        nextDue: now.subtract(Duration(days: 1)), // Overdue
        practiceCount: 5,
        successCount: 2,
        failureCount: 3,
        easeFactor: 1.5,
        interval: 2,
        repetitions: 1,
        recommendedPracticeTime: 10,
        isActive: true,
      ),
      Spot(
        id: 'spot_2',
        pieceId: 'piece_1',
        title: 'Triplet Passage',
        description: 'Measures 15-22',
        pageNumber: 2,
        x: 0.1, y: 0.5, width: 0.8, height: 0.2,
        priority: SpotPriority.high,
        readinessLevel: ReadinessLevel.newSpot,
        color: SpotColor.red,
        createdAt: now,
        updatedAt: now,
        practiceCount: 0,
        successCount: 0,
        failureCount: 0,
        easeFactor: 2.5,
        interval: 1,
        repetitions: 0,
        recommendedPracticeTime: 15,
        isActive: true,
      ),
      // Clair de Lune spots
      Spot(
        id: 'spot_3',
        pieceId: 'piece_2',
        title: 'Arabesque Section',
        description: 'Measures 27-35',
        pageNumber: 3,
        x: 0.1, y: 0.1, width: 0.8, height: 0.4,
        priority: SpotPriority.medium,
        readinessLevel: ReadinessLevel.review,
        color: SpotColor.yellow,
        createdAt: now,
        updatedAt: now,
        lastPracticed: now.subtract(Duration(days: 5)),
        nextDue: now.add(Duration(days: 2)),
        practiceCount: 8,
        successCount: 6,
        failureCount: 2,
        easeFactor: 2.2,
        interval: 7,
        repetitions: 3,
        recommendedPracticeTime: 8,
        isActive: true,
      ),
      Spot(
        id: 'spot_4',
        pieceId: 'piece_2',
        title: 'Gentle Ending',
        description: 'Measures 65-72',
        pageNumber: 6,
        x: 0.1, y: 0.6, width: 0.8, height: 0.3,
        priority: SpotPriority.low,
        readinessLevel: ReadinessLevel.mastered,
        color: SpotColor.green,
        createdAt: now,
        updatedAt: now,
        lastPracticed: now.subtract(Duration(days: 10)),
        nextDue: now.add(Duration(days: 14)),
        practiceCount: 12,
        successCount: 11,
        failureCount: 1,
        easeFactor: 2.5,
        interval: 21,
        repetitions: 5,
        recommendedPracticeTime: 5,
        isActive: true,
      ),
    ];
    
    // Save sample data
    await prefs.setStringList(_projectsKey, [jsonEncode(project.toJson())]);
    await prefs.setStringList(_piecesKey, pieces.map((p) => jsonEncode(p.toJson())).toList());
    await prefs.setStringList(_spotsKey, spots.map((s) => jsonEncode(s.toJson())).toList());
  }

  /// Add a new project
  Future<void> addProject(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await getProjects();
    
    // Add the new project
    projects.add(project);
    
    // Save updated projects list
    final projectsJson = projects.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_projectsKey, projectsJson);
  }

  /// Update an existing project
  Future<void> updateProject(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await getProjects();
    
    // Find and replace the project
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
      
      // Save updated projects list
      final projectsJson = projects.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_projectsKey, projectsJson);
    }
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await getProjects();
    
    // Remove the project
    projects.removeWhere((p) => p.id == projectId);
    
    // Save updated projects list
    final projectsJson = projects.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_projectsKey, projectsJson);
  }

  /// Clear all projects (for testing)
  Future<void> clearProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_projectsKey);
  }
}

// Providers
final dataServiceProvider = Provider<DataService>((ref) => DataService());

// Mutable Projects Provider
class ProjectsNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  final DataService _dataService;

  ProjectsNotifier(this._dataService) : super(const AsyncValue.loading()) {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      await _dataService.createSampleData(); // Ensure sample data exists
      final projects = await _dataService.getProjects();
      state = AsyncValue.data(projects);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addProject(Project project) async {
    try {
      await _dataService.addProject(project);
      final projects = await _dataService.getProjects();
      state = AsyncValue.data(projects);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProject(Project project) async {
    try {
      await _dataService.updateProject(project);
      final projects = await _dataService.getProjects();
      state = AsyncValue.data(projects);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await _dataService.deleteProject(projectId);
      final projects = await _dataService.getProjects();
      state = AsyncValue.data(projects);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadProjects();
  }
}

final projectsProvider = StateNotifierProvider<ProjectsNotifier, AsyncValue<List<Project>>>((ref) {
  final dataService = ref.read(dataServiceProvider);
  return ProjectsNotifier(dataService);
});

final piecesProvider = FutureProvider<List<Piece>>((ref) async {
  final dataService = ref.read(dataServiceProvider);
  return dataService.getPieces();
});

final spotsProvider = FutureProvider<List<Spot>>((ref) async {
  final dataService = ref.read(dataServiceProvider);
  return dataService.getSpots();
});

final practiceSessionsProvider = FutureProvider<List<PracticeSession>>((ref) async {
  final dataService = ref.read(dataServiceProvider);
  return dataService.getPracticeSessions();
});
