import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/practice_session.dart';
import '../models/project.dart';
import '../models/spot.dart';
import '../models/piece.dart';
import '../services/data_service.dart';
import '../services/spot_service.dart';
import '../services/database_service.dart';
import '../services/ai_practice_selector.dart';
import '../services/micro_breaks_service.dart';
import 'unified_library_provider.dart';
import 'practice_provider.dart';
import 'app_settings_provider.dart';

// Real practice session state
class ActivePracticeSessionState {
  final PracticeSession? session;
  final SpotSession? currentSpot;
  final List<Spot> selectedSpots;
  final int currentSpotIndex;
  final bool isActive;
  final bool isRunning;
  final bool isCompleted;
  final DateTime? sessionStartTime;
  final Map<String, SpotResult> spotResults;

  const ActivePracticeSessionState({
    this.session,
    this.currentSpot,
    this.selectedSpots = const [],
    this.currentSpotIndex = 0,
    this.isActive = false,
    this.isRunning = false,
    this.isCompleted = false,
    this.sessionStartTime,
    this.spotResults = const {},
  });

  bool get hasActiveSession => session != null && (isActive || isCompleted);
  int get totalSpots => selectedSpots.length;
  int get completedSpots => spotResults.length;
  double get progress => totalSpots > 0 ? completedSpots / totalSpots : 0.0;
  Spot? get currentRealSpot => currentSpotIndex < selectedSpots.length ? selectedSpots[currentSpotIndex] : null;

  ActivePracticeSessionState copyWith({
    PracticeSession? session,
    SpotSession? currentSpot,
    List<Spot>? selectedSpots,
    int? currentSpotIndex,
    bool? isActive,
    bool? isRunning,
    bool? isCompleted,
    DateTime? sessionStartTime,
    Map<String, SpotResult>? spotResults,
  }) {
    return ActivePracticeSessionState(
      session: session ?? this.session,
      currentSpot: currentSpot ?? this.currentSpot,
      selectedSpots: selectedSpots ?? this.selectedSpots,
      currentSpotIndex: currentSpotIndex ?? this.currentSpotIndex,
      isActive: isActive ?? this.isActive,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      spotResults: spotResults ?? this.spotResults,
    );
  }
}

// Real AI-powered practice session notifier
class ActivePracticeSessionNotifier extends StateNotifier<ActivePracticeSessionState> {
  final DataService _dataService;
  final SpotService _spotService;
  final DatabaseService _databaseService;
  final Ref _ref;
  
  ActivePracticeSessionNotifier(this._dataService, this._spotService, this._databaseService, this._ref) : super(const ActivePracticeSessionState());

  /// Start practice session using REAL AI logic and data
  Future<void> startProjectPracticeSession(String projectName, SessionType sessionType) async {
    try {
      print('[Practice] Starting session for project: $projectName, type: $sessionType');
      
      // Get real data including practice history
      final projects = await _dataService.getProjects();
      final allSpots = await _spotService.getAllActiveSpots(); // Use real user spots from database
      final practiceHistory = await _dataService.getPracticeSessions();
      
      print('[Practice] Found ${projects.length} projects, ${allSpots.length} total spots, ${practiceHistory.length} past sessions');
      
      final project = projects.where((p) => p.name == projectName).firstOrNull;
      Project actualProject;
      List<Spot> projectSpots;
      
      if (project == null) {
        // If project doesn't exist, use all available spots
        print('[Practice] Project "$projectName" not found, using all available spots');
        if (projects.isEmpty) {
          throw Exception('No projects available');
        }
        actualProject = projects.first;
        projectSpots = allSpots; // Use all real user spots
        print('[Practice] Using fallback project: ${actualProject.name} with ${projectSpots.length} spots');
      } else {
        actualProject = project;
        // Get pieces from unified library instead of separate data service
        final unifiedLibraryState = _ref.read(unifiedLibraryProvider);
        List<Piece> projectPieces = [];
        
        await unifiedLibraryState.when(
          data: (pieces) async {
            projectPieces = pieces.where((p) => actualProject.pieceIds.contains(p.id)).toList();
          },
          loading: () async {},
          error: (error, stack) async {
            print('[Practice] Error loading unified library: $error');
          },
        );
        
        // Get spots from database (not just library)
        final allDatabaseSpots = await _spotService.getAllActiveSpots();
        projectSpots = allDatabaseSpots
            .where((spot) => spot.pieceId.startsWith(actualProject.name))
            .toList();
        print('[Practice] Project spots from DATABASE: ${projectSpots.length}');
        
        // Also add spots from unified library pieces as backup
        for (final piece in projectPieces) {
          // Add any spots not already in our database list
          for (final librarySpot in piece.spots) {
            if (!projectSpots.any((dbSpot) => dbSpot.id == librarySpot.id)) {
              projectSpots.add(librarySpot);
            }
          }
        }
        print('[Practice] Combined project spots (database + library): ${projectSpots.length}');
      }
      
      // Use AI to select spots based on session type
      List<Spot> selectedSpots;
      switch (sessionType) {
        case SessionType.smart:
          // Use REAL AI that learns from practice history
          selectedSpots = AiPracticeSelector.selectAiPoweredSpots(
            projectSpots, 
            project: actualProject,
            sessionDuration: actualProject.dailyPracticeGoal,
            practiceHistory: practiceHistory, // Pass practice history to AI
          );
          break;
        case SessionType.critical:
          selectedSpots = AiPracticeSelector.selectCriticalSpots(projectSpots);
          break;
        case SessionType.balanced:
          // Get review frequency settings from app settings
          final appSettings = _ref.read(appSettingsProvider);
          selectedSpots = AiPracticeSelector.selectBalancedSpots(
            projectSpots,
            criticalFrequency: appSettings.criticalSpotsFrequency,
            reviewFrequency: appSettings.reviewSpotsFrequency,
            maintenanceFrequency: appSettings.maintenanceSpotsFrequency,
          );
          break;
        case SessionType.maintenance:
          selectedSpots = AiPracticeSelector.selectRepertoireSpots(projectSpots);
          break;
        case SessionType.warmup:
          selectedSpots = AiPracticeSelector.selectWarmupSpots(projectSpots);
          break;
        case SessionType.custom:
          // For custom, let user select spots (not implemented yet)
          selectedSpots = AiPracticeSelector.selectAiPoweredSpots(projectSpots);
          break;
      }
      
      if (selectedSpots.isEmpty) {
        // No spots available - set a special state to show user guidance
        state = state.copyWith(
          session: null,
          isActive: false,
          currentSpot: null,
          selectedSpots: [],
        );
        print('[Practice] No spots available for practice. User needs to create spots first.');
        return;
      }
      
      // Create practice session
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final session = PracticeSession(
        id: sessionId,
        name: '${actualProject.name} - ${sessionType.displayName}',
        type: sessionType,
        status: SessionStatus.active,
        plannedDuration: actualProject.dailyPracticeGoal,
        spotSessions: selectedSpots.map((spot) => SpotSession(
          id: 'session_${spot.id}',
          sessionId: sessionId, // Use the same session ID
          spotId: spot.id,
          orderIndex: selectedSpots.indexOf(spot),
          allocatedTime: Duration(minutes: spot.recommendedPracticeTime),
          status: SpotSessionStatus.pending,
        )).toList(),
        projectId: actualProject.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Auto-start with first spot so session begins properly
      final firstSpotSession = session.spotSessions.isNotEmpty ? session.spotSessions.first : null;
      
      state = state.copyWith(
        session: session,
        currentSpot: firstSpotSession, // Auto-select first spot
        selectedSpots: selectedSpots,
        currentSpotIndex: 0,
        isActive: true,
        isRunning: true, // Start running so user can practice immediately
        sessionStartTime: DateTime.now(),
        spotResults: {},
      );
      
      // Auto-start first spot session for immediate practice
      if (firstSpotSession != null) {
        await _startSpotSession(firstSpotSession);
      }
      
      print('[Practice] Session started successfully with ${selectedSpots.length} spots. User can manually select spots to practice.');
      
    } catch (e) {
      print('Error starting practice session: $e');
    }
  }

  /// Start a practice session for a single specific spot
  Future<void> startSingleSpotSession(Spot spot) async {
    try {
      print('[Practice] Starting single spot session for: ${spot.title}');
      
      // Get the piece for this spot
      final unifiedLibraryState = _ref.read(unifiedLibraryProvider);
      Piece? piece;
      
      await unifiedLibraryState.when(
        data: (pieces) async {
          piece = pieces.where((p) => p.id == spot.pieceId).firstOrNull;
        },
        loading: () async {},
        error: (error, stack) async {
          print('[Practice] Error loading unified library: $error');
        },
      );
      
      if (piece == null) {
        throw Exception('Could not find piece for spot ${spot.title}');
      }
      
      // Create a session with just this one spot
      final sessionId = 'single_spot_${DateTime.now().millisecondsSinceEpoch}';
      final session = PracticeSession(
        id: sessionId,
        name: 'Practice: ${spot.title}',
        type: SessionType.custom,
        status: SessionStatus.active,
        plannedDuration: Duration(minutes: spot.recommendedPracticeTime),
        spotSessions: [
          SpotSession(
            id: 'session_${spot.id}',
            sessionId: sessionId, // Use the same session ID
            spotId: spot.id,
            orderIndex: 0,
            allocatedTime: Duration(minutes: spot.recommendedPracticeTime),
            status: SpotSessionStatus.pending,
          ),
        ],
        projectId: 'single_spot_project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Start the session with this single spot
      final spotSession = session.spotSessions.first;
      
      state = state.copyWith(
        session: session,
        currentSpot: spotSession,
        selectedSpots: [spot], // Only this one spot
        currentSpotIndex: 0,
        isActive: true,
        isRunning: true,
        sessionStartTime: DateTime.now(),
        spotResults: {},
      );
      
      // Start the spot session
      await _startSpotSession(spotSession);
      
      print('[Practice] Single spot session started successfully for: ${spot.title}');
      
    } catch (e) {
      print('Error starting single spot session: $e');
      throw e;
    }
  }

  /// Start a practice session for a specific piece
  Future<void> startPieceSession(Piece piece, SessionType sessionType) async {
    try {
      print('[Practice] Starting piece session for: ${piece.title}, type: $sessionType');
      
      // Get all spots for this piece
      final pieceSpots = await _spotService.getSpotsForPiece(piece.id);
      
      if (pieceSpots.isEmpty) {
        print('[Practice] No spots found for piece ${piece.title}, creating default spot');
        // Create a default "Full Piece" spot if none exist
        final defaultSpot = Spot(
          id: 'spot_${piece.id}_${DateTime.now().millisecondsSinceEpoch}',
          pieceId: piece.id,
          title: 'Full Piece',
          description: 'Practice the entire piece',
          pageNumber: 1,
          x: 0.0,
          y: 0.0,
          width: 1.0,
          height: 1.0,
          priority: SpotPriority.medium,
          readinessLevel: ReadinessLevel.learning,
          color: SpotColor.blue,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _spotService.saveSpot(defaultSpot);
        pieceSpots.add(defaultSpot);
      }
      
      print('[Practice] Found ${pieceSpots.length} spots for piece');
      
      // Apply session type filtering to piece spots
      print('[Practice] Applying filtering for session type: $sessionType');
      List<Spot> selectedSpots;
      switch (sessionType) {
        case SessionType.smart:
          // Smart practice: Include ALL active spots with AI prioritization
          selectedSpots = pieceSpots.where((s) => s.isActive).toList();
          // Apply AI prioritization but keep all spots
          if (selectedSpots.isNotEmpty) {
            selectedSpots = AiPracticeSelector.selectAiPoweredSpots(
              selectedSpots,
              sessionDuration: Duration(minutes: 30),
              maxSpots: selectedSpots.length, // Use ALL spots for smart practice
            );
          }
          break;
        case SessionType.critical:
          selectedSpots = AiPracticeSelector.selectCriticalSpots(pieceSpots);
          break;
        case SessionType.balanced:
          // Get review frequency settings from app settings
          final appSettings = _ref.read(appSettingsProvider);
          selectedSpots = AiPracticeSelector.selectBalancedSpots(
            pieceSpots,
            criticalFrequency: appSettings.criticalSpotsFrequency,
            reviewFrequency: appSettings.reviewSpotsFrequency,
            maintenanceFrequency: appSettings.maintenanceSpotsFrequency,
          );
          break;
        case SessionType.maintenance:
          selectedSpots = AiPracticeSelector.selectRepertoireSpots(pieceSpots);
          break;
        case SessionType.warmup:
          selectedSpots = AiPracticeSelector.selectWarmupSpots(pieceSpots);
          break;
        case SessionType.custom:
          selectedSpots = pieceSpots; // Use all spots for custom
          break;
      }
      
      print('[Practice] Session type $sessionType filtered to ${selectedSpots.length} spots');
      
      // If no spots match the filter, show a message
      if (selectedSpots.isEmpty) {
        print('[Practice] No spots found for session type $sessionType');
        // You could throw an exception or show a message to the user here
        throw Exception('No spots available for ${sessionType.displayName} practice. Try a different session type.');
      }
      
      // Create a temporary project for this piece
      final tempProject = Project(
        id: 'temp_${piece.id}',
        name: '${piece.title} Practice',
        description: 'Practice session for ${piece.title}',
        pieceIds: [piece.id],
        dailyPracticeGoal: Duration(minutes: 30), // Default 30 minutes
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Create session
      final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      final session = PracticeSession(
        id: sessionId,
        name: '${piece.title} Practice Session - ${sessionType.displayName}',
        type: sessionType,
        status: SessionStatus.active,
        plannedDuration: Duration(minutes: 30), // Default 30 minutes
        spotSessions: selectedSpots.map((spot) => SpotSession(
          id: 'session_${spot.id}',
          sessionId: sessionId, // Use the same session ID
          spotId: spot.id,
          orderIndex: selectedSpots.indexOf(spot),
          allocatedTime: Duration(minutes: spot.recommendedPracticeTime),
          status: SpotSessionStatus.pending,
        )).toList(),
        projectId: tempProject.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      state = state.copyWith(
        session: session,
        currentSpot: session.spotSessions.first, // Auto-select first spot
        selectedSpots: selectedSpots, // Use filtered spots, not all piece spots
        currentSpotIndex: 0,
        isActive: true,
        isRunning: true, // Start running so user can practice immediately
        sessionStartTime: DateTime.now(),
        spotResults: {},
      );
      
      // Auto-start first spot session
      if (session.spotSessions.isNotEmpty) {
        await _startSpotSession(session.spotSessions.first);
      }
      
      print('[Practice] Piece session started successfully with ${selectedSpots.length} filtered spots');
      print('[Practice] Session state: isActive=${state.isActive}, hasActiveSession=${state.hasActiveSession}');
      print('[Practice] Session status: ${session.status}');
      
    } catch (e) {
      print('Error starting piece session: $e');
      throw e;
    }
  }

  Future<void> _startSpotSession(SpotSession spotSession) async {
    if (state.session == null) return;
    
    final updatedSpotSession = SpotSession(
      id: spotSession.id,
      sessionId: spotSession.sessionId,
      spotId: spotSession.spotId,
      orderIndex: spotSession.orderIndex,
      allocatedTime: spotSession.allocatedTime,
      status: SpotSessionStatus.active,
      startTime: DateTime.now(),
      endTime: spotSession.endTime,
      result: spotSession.result,
      notes: spotSession.notes,
      metadata: spotSession.metadata,
    );
    
    // Update session with active spot
    final updatedSpotSessions = List<SpotSession>.from(state.session!.spotSessions);
    final index = updatedSpotSessions.indexWhere((s) => s.id == spotSession.id);
    if (index != -1) {
      updatedSpotSessions[index] = updatedSpotSession;
    }
    
    final updatedSession = PracticeSession(
      id: state.session!.id,
      name: state.session!.name,
      type: state.session!.type,
      status: state.session!.status,
      startTime: state.session!.startTime,
      endTime: state.session!.endTime,
      plannedDuration: state.session!.plannedDuration,
      spotSessions: updatedSpotSessions,
      microBreaksEnabled: state.session!.microBreaksEnabled,
      microBreakInterval: state.session!.microBreakInterval,
      microBreakDuration: state.session!.microBreakDuration,
      projectId: state.session!.projectId,
      metadata: state.session!.metadata,
      createdAt: state.session!.createdAt,
      updatedAt: DateTime.now(),
    );
    
    state = state.copyWith(
      session: updatedSession,
      currentSpot: updatedSpotSession,
    );
  }

  /// Complete current spot with result and move to next
  Future<void> completeCurrentSpot(SpotResult result) async {
    print('[Practice] DEBUG: completeCurrentSpot called with result: $result');
    if (state.currentRealSpot == null || state.currentSpot == null) {
      print('[Practice] DEBUG: Cannot complete spot - currentRealSpot or currentSpot is null');
      return;
    }
    
    final currentSpot = state.currentRealSpot!;
    final currentSpotSession = state.currentSpot!;
    
    // Update spot progress in real data using SpotService
    await _spotService.recordPracticeSession(
      currentSpot.id, 
      result, 
      currentSpot.recommendedPracticeTime,
    );
    
    // Complete current spot session
    final completedSpotSession = SpotSession(
      id: currentSpotSession.id,
      sessionId: currentSpotSession.sessionId,
      spotId: currentSpotSession.spotId,
      orderIndex: currentSpotSession.orderIndex,
      allocatedTime: currentSpotSession.allocatedTime,
      status: SpotSessionStatus.completed,
      startTime: currentSpotSession.startTime,
      endTime: DateTime.now(),
      result: result,
      notes: currentSpotSession.notes,
      metadata: currentSpotSession.metadata,
    );
    
    print('[Practice] DEBUG: Completed spot session - Duration: ${completedSpotSession.actualDuration?.inMinutes ?? 0} min');
    
    // Instead of saving individual sessions, just update the main session
    // The main session will be saved when the full session is completed or finished
    
    // Update the session with the completed spot session
    final updatedSpotSessions = List<SpotSession>.from(state.session!.spotSessions);
    updatedSpotSessions[state.currentSpotIndex] = completedSpotSession;
    
    final updatedSession = PracticeSession(
      id: state.session!.id,
      name: state.session!.name,
      type: state.session!.type,
      status: state.session!.status,
      startTime: state.session!.startTime,
      endTime: state.session!.endTime,
      plannedDuration: state.session!.plannedDuration,
      spotSessions: updatedSpotSessions,
      microBreaksEnabled: state.session!.microBreaksEnabled,
      microBreakInterval: state.session!.microBreakInterval,
      microBreakDuration: state.session!.microBreakDuration,
      projectId: state.session!.projectId,
      metadata: state.session!.metadata,
      createdAt: state.session!.createdAt,
      updatedAt: DateTime.now(),
    );
    
    // Add result to tracking
    final newSpotResults = Map<String, SpotResult>.from(state.spotResults);
    newSpotResults[currentSpot.id] = result;
    
    // Move to next spot
    final nextIndex = state.currentSpotIndex + 1;
    
    if (nextIndex < state.selectedSpots.length) {
      // Start next spot
      final nextSpotSession = updatedSession.spotSessions[nextIndex];
      
      state = state.copyWith(
        session: updatedSession,
        currentSpotIndex: nextIndex,
        spotResults: newSpotResults,
      );
      
      await _startSpotSession(nextSpotSession);
    } else {
      // Session completed - update state with final session
      state = state.copyWith(
        session: updatedSession,
        spotResults: newSpotResults,
      );
      await _completeSession();
    }
  }

  Future<void> _completeSession() async {
    if (state.session == null) return;
    
    // STOP TIMER IMMEDIATELY to prevent break popups during completion screen
    try {
      _ref.read(practiceTimerProvider.notifier).stopPracticeSession();
      print('[Practice] ✅ Stopped practice timer on session completion');
    } catch (e) {
      print('[Practice] ❌ Error stopping practice timer: $e');
    }
    
    final completedSession = PracticeSession(
      id: state.session!.id,
      name: state.session!.name,
      type: state.session!.type,
      status: SessionStatus.completed,
      startTime: state.sessionStartTime,
      endTime: DateTime.now(),
      plannedDuration: state.session!.plannedDuration,
      spotSessions: state.session!.spotSessions,
      microBreaksEnabled: state.session!.microBreaksEnabled,
      microBreakInterval: state.session!.microBreakInterval,
      microBreakDuration: state.session!.microBreakDuration,
      projectId: state.session!.projectId,
      metadata: state.session!.metadata,
      createdAt: state.session!.createdAt,
      updatedAt: DateTime.now(),
    );
    
    print('[Practice] DEBUG: Completing session with:');
    print('[Practice] DEBUG:   ID: ${completedSession.id}');
    print('[Practice] DEBUG:   Status: ${completedSession.status}');
    print('[Practice] DEBUG:   Start Time: ${completedSession.startTime}');
    print('[Practice] DEBUG:   End Time: ${completedSession.endTime}');
    print('[Practice] DEBUG:   Actual Duration: ${completedSession.actualDuration?.inMinutes ?? 0} minutes');
    print('[Practice] DEBUG:   Spot Sessions: ${completedSession.spotSessions.length}');
    for (final spotSession in completedSession.spotSessions) {
      print('[Practice] DEBUG:     Spot ${spotSession.spotId}: Status=${spotSession.status}, Duration=${spotSession.actualDuration?.inMinutes ?? 0} min');
    }
    
    // Save completed session to DATABASE (not just SharedPreferences)
    try {
      print('[Practice] Attempting to save session to database: ${completedSession.id}');
      print('[Practice] Session details before saving:');
      print('[Practice]   Start Time: ${completedSession.startTime}');
      print('[Practice]   End Time: ${completedSession.endTime}');
      print('[Practice]   Status: ${completedSession.status}');
      print('[Practice]   Actual Duration: ${completedSession.actualDuration?.inMinutes ?? 0} minutes');
      print('[Practice]   Spot Sessions: ${completedSession.spotSessions.length}');
      for (final spotSession in completedSession.spotSessions) {
        print('[Practice]     Spot ${spotSession.spotId}: Status=${spotSession.status}, Duration=${spotSession.actualDuration?.inMinutes ?? 0} min');
      }
      
      await _databaseService.insertPracticeSession(completedSession);
      print('[Practice] ✅ Session saved to database successfully: ${completedSession.id}');
    } catch (e) {
      print('[Practice] ❌ Error saving session to database: $e');
    }
    
    // Also save to data service for compatibility (legacy)
    try {
      await _dataService.savePracticeSession(completedSession);
      print('[Practice] ✅ Session saved to data service (legacy): ${completedSession.id}');
    } catch (e) {
      print('[Practice] ❌ Error saving session to data service: $e');
    }
    
    print('[Practice] Session completion process finished: ${completedSession.id}');
    
    // Add a small delay to ensure database transaction is completed
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Refresh practice provider stats to show updated today's progress
    try {
      _ref.read(practiceProvider.notifier).refresh();
      print('[Practice] ✅ Refreshed practice provider stats after session completion');
    } catch (e) {
      print('[Practice] ❌ Error refreshing practice provider: $e');
    }
    
    // Mark session as completed instead of clearing it
    state = state.copyWith(
      isActive: false,
      isRunning: false,
      isCompleted: true,
    );
  }

  void pauseSession() {
    if (!state.isActive) return;
    state = state.copyWith(isRunning: false);
  }

  void resumeSession() {
    if (!state.isActive) return;
    state = state.copyWith(isRunning: true);
  }

  Future<void> cancelSession() async {
    if (state.session == null) return;
    
    final cancelledSession = PracticeSession(
      id: state.session!.id,
      name: state.session!.name,
      type: state.session!.type,
      status: SessionStatus.cancelled,
      startTime: state.sessionStartTime,
      endTime: DateTime.now(),
      plannedDuration: state.session!.plannedDuration,
      spotSessions: state.session!.spotSessions,
      microBreaksEnabled: state.session!.microBreaksEnabled,
      microBreakInterval: state.session!.microBreakInterval,
      microBreakDuration: state.session!.microBreakDuration,
      projectId: state.session!.projectId,
      metadata: state.session!.metadata,
      createdAt: state.session!.createdAt,
      updatedAt: DateTime.now(),
    );
    
    // Save cancelled session to DATABASE
    try {
      print('[Practice] Attempting to save cancelled session to database: ${cancelledSession.id}');
      await _databaseService.insertPracticeSession(cancelledSession);
      print('[Practice] ✅ Cancelled session saved to database successfully: ${cancelledSession.id}');
    } catch (e) {
      print('[Practice] ❌ Error saving cancelled session to database: $e');
    }
    
    try {
      await _dataService.savePracticeSession(cancelledSession);
      print('[Practice] ✅ Cancelled session saved to data service: ${cancelledSession.id}');
    } catch (e) {
      print('[Practice] ❌ Error saving cancelled session to data service: $e');
    }
    
    // Refresh practice provider stats even for cancelled sessions
    try {
      _ref.read(practiceProvider.notifier).refresh();
      print('[Practice] ✅ Refreshed practice provider stats after session cancellation');
    } catch (e) {
      print('[Practice] ❌ Error refreshing practice provider: $e');
    }
    
    clearSession();
  }

  void clearSession() {
    state = const ActivePracticeSessionState();
  }
  
  Future<void> finishSession() async {
    // If session exists and not already completed, complete it first
    if (state.session != null && state.session!.status != SessionStatus.completed) {
      print('[Practice] Manually finishing session: ${state.session!.id}');
      await _completeSession();
    }
    // Then clear the session state
    clearSession();
  }
  
  void finishCompletedSession() {
    // Called when user dismisses the completion screen
    clearSession();
  }
}

// Provider
final activePracticeSessionProvider = StateNotifierProvider<ActivePracticeSessionNotifier, ActivePracticeSessionState>((ref) {
  final dataService = ref.read(dataServiceProvider);
  final spotService = ref.read(spotServiceProvider);
  final databaseService = ref.read(databaseServiceProvider);
  return ActivePracticeSessionNotifier(dataService, spotService, databaseService, ref);
});
