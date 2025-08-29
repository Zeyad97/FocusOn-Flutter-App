import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/project.dart';

class UserState {
  final String? currentProjectId;
  final String? currentProjectName;
  final Map<String, dynamic> preferences;
  
  const UserState({
    this.currentProjectId,
    this.currentProjectName,
    this.preferences = const {},
  });
  
  UserState copyWith({
    String? currentProjectId,
    String? currentProjectName,
    Map<String, dynamic>? preferences,
  }) {
    return UserState(
      currentProjectId: currentProjectId ?? this.currentProjectId,
      currentProjectName: currentProjectName ?? this.currentProjectName,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final DatabaseService _databaseService;
  
  UserNotifier(this._databaseService) : super(const UserState()) {
    _loadUserState();
  }
  
  Future<void> _loadUserState() async {
    final prefs = await SharedPreferences.getInstance();
    final currentProjectId = prefs.getString('current_project_id');
    String? currentProjectName;
    
    if (currentProjectId != null) {
      try {
        final project = await _databaseService.getProject(currentProjectId);
        currentProjectName = project?.name;
      } catch (e) {
        // Project might not exist anymore
        await prefs.remove('current_project_id');
      }
    }
    
    // If no current project, try to set the first available project
    if (currentProjectId == null || currentProjectName == null) {
      final projects = await _databaseService.getAllProjects();
      if (projects.isNotEmpty) {
        final firstProject = projects.first;
        await setCurrentProject(firstProject.id, firstProject.name);
        return;
      } else {
        // Create a default project if none exist
        final defaultProject = Project(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: "My Practice",
          description: "Default practice project",
          pieceIds: [], // Start with empty list - pieces will be added when imported
          dailyPracticeGoal: Duration(minutes: 30),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _databaseService.saveProject(defaultProject);
        await setCurrentProject(defaultProject.id, defaultProject.name);
        return;
      }
    }
    
    state = state.copyWith(
      currentProjectId: currentProjectId,
      currentProjectName: currentProjectName,
    );
  }
  
  Future<void> setCurrentProject(String projectId, String projectName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_project_id', projectId);
    
    state = state.copyWith(
      currentProjectId: projectId,
      currentProjectName: projectName,
    );
  }
  
  String get currentProjectName => state.currentProjectName ?? "My Practice";
  String? get currentProjectId => state.currentProjectId;
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return UserNotifier(databaseService);
});

// Convenience provider for current project name
final currentProjectNameProvider = Provider<String>((ref) {
  final userState = ref.watch(userProvider);
  return userState.currentProjectName ?? "My Practice";
});

// Convenience provider for current project ID
final currentProjectIdProvider = Provider<String?>((ref) {
  final userState = ref.watch(userProvider);
  return userState.currentProjectId;
});