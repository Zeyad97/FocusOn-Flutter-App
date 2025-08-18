import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/practice_session.dart';
import '../models/project.dart';
import '../models/spot.dart';
import '../services/data_service.dart';
import '../services/ai_practice_selector.dart';

// Real practice session state
class ActivePracticeSessionState {
  final PracticeSession? session;
  final SpotSession? currentSpot;
  final List<Spot> selectedSpots;
  final int currentSpotIndex;
  final bool isActive;
  final bool isRunning;
  final DateTime? sessionStartTime;
  final Map<String, SpotResult> spotResults;

  const ActivePracticeSessionState({
    this.session,
    this.currentSpot,
    this.selectedSpots = const [],
    this.currentSpotIndex = 0,
    this.isActive = false,
    this.isRunning = false,
    this.sessionStartTime,
    this.spotResults = const {},
  });

  bool get hasActiveSession => session != null && isActive;
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
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      spotResults: spotResults ?? this.spotResults,
    );
  }
}

// Real AI-powered practice session notifier
class ActivePracticeSessionNotifier extends StateNotifier<ActivePracticeSessionState> {
  final DataService _dataService;
  
  ActivePracticeSessionNotifier(this._dataService) : super(const ActivePracticeSessionState());

  /// Start practice session using REAL AI logic and data
  Future<void> startProjectPracticeSession(String projectName, SessionType sessionType) async {
    try {
      print('[Practice] Starting session for project: $projectName, type: $sessionType');
      
      // Get real data including practice history
      final projects = await _dataService.getProjects();
      final allSpots = await _dataService.getSpots();
      final practiceHistory = await _dataService.getPracticeSessions();
      
      print('[Practice] Found ${projects.length} projects, ${allSpots.length} total spots, ${practiceHistory.length} past sessions');
      
      final project = projects.firstWhere((p) => p.name == projectName);
      final projectSpots = await _dataService.getSpotsForProject(project.id);
      
      print('[Practice] Project spots: ${projectSpots.length}');
      
      // Use AI to select spots based on session type
      List<Spot> selectedSpots;
      switch (sessionType) {
        case SessionType.smart:
          // Use REAL AI that learns from practice history
          selectedSpots = AiPracticeSelector.selectAiPoweredSpots(
            projectSpots, 
            project: project,
            sessionDuration: project.dailyPracticeGoal,
            practiceHistory: practiceHistory, // Pass practice history to AI
          );
          break;
        case SessionType.critical:
          selectedSpots = AiPracticeSelector.selectCriticalSpots(projectSpots);
          break;
        case SessionType.balanced:
          selectedSpots = AiPracticeSelector.selectBalancedSpots(projectSpots);
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
        // No spots available for practice
        return;
      }
      
      // Create practice session
      final session = PracticeSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '$projectName - ${sessionType.displayName}',
        type: sessionType,
        status: SessionStatus.active,
        plannedDuration: project.dailyPracticeGoal,
        spotSessions: selectedSpots.map((spot) => SpotSession(
          id: 'session_${spot.id}',
          sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
          spotId: spot.id,
          orderIndex: selectedSpots.indexOf(spot),
          allocatedTime: Duration(minutes: spot.recommendedPracticeTime),
          status: SpotSessionStatus.pending,
        )).toList(),
        projectId: project.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Start with first spot
      final firstSpotSession = session.spotSessions.isNotEmpty ? session.spotSessions.first : null;
      
      state = state.copyWith(
        session: session,
        currentSpot: firstSpotSession,
        selectedSpots: selectedSpots,
        currentSpotIndex: 0,
        isActive: true,
        isRunning: true,
        sessionStartTime: DateTime.now(),
        spotResults: {},
      );
      
      // Start first spot session
      if (firstSpotSession != null) {
        await _startSpotSession(firstSpotSession);
      }
      
    } catch (e) {
      print('Error starting practice session: $e');
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
    if (state.currentRealSpot == null || state.currentSpot == null) return;
    
    final currentSpot = state.currentRealSpot!;
    final currentSpotSession = state.currentSpot!;
    
    // Update spot progress in real data
    await _dataService.updateSpotProgress(
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
    
    // Add result to tracking
    final newSpotResults = Map<String, SpotResult>.from(state.spotResults);
    newSpotResults[currentSpot.id] = result;
    
    // Move to next spot
    final nextIndex = state.currentSpotIndex + 1;
    
    if (nextIndex < state.selectedSpots.length) {
      // Start next spot
      final nextSpotSession = state.session!.spotSessions[nextIndex];
      
      state = state.copyWith(
        currentSpotIndex: nextIndex,
        spotResults: newSpotResults,
      );
      
      await _startSpotSession(nextSpotSession);
    } else {
      // Session completed
      await _completeSession();
    }
  }

  Future<void> _completeSession() async {
    if (state.session == null) return;
    
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
    
    // Save completed session
    await _dataService.savePracticeSession(completedSession);
    
    // Clear active session
    clearSession();
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
    
    await _dataService.savePracticeSession(cancelledSession);
    clearSession();
  }

  void clearSession() {
    state = const ActivePracticeSessionState();
  }
}

// Provider
final activePracticeSessionProvider = StateNotifierProvider<ActivePracticeSessionNotifier, ActivePracticeSessionState>((ref) {
  final dataService = ref.read(dataServiceProvider);
  return ActivePracticeSessionNotifier(dataService);
});
