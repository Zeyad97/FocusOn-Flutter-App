import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/piece.dart';
import '../models/spot.dart';

/// Time tracking entry for practice sessions
class TimeEntry {
  final String id;
  final String pieceId;
  final String? spotId;
  final DateTime startTime;
  final DateTime endTime;
  final String sessionType;
  final Map<String, dynamic> metadata;
  
  const TimeEntry({
    required this.id,
    required this.pieceId,
    this.spotId,
    required this.startTime,
    required this.endTime,
    required this.sessionType,
    this.metadata = const {},
  });
  
  Duration get duration => endTime.difference(startTime);
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'pieceId': pieceId,
    'spotId': spotId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'sessionType': sessionType,
    'metadata': metadata,
  };
  
  factory TimeEntry.fromJson(Map<String, dynamic> json) => TimeEntry(
    id: json['id'],
    pieceId: json['pieceId'],
    spotId: json['spotId'],
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    sessionType: json['sessionType'],
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
  );
}

/// Practice session summary for analytics
class PracticeSessionSummary {
  final String id;
  final DateTime date;
  final Duration totalDuration;
  final int spotsWorked;
  final int piecesWorked;
  final Map<SpotColor, Duration> timeBySpotColor;
  final Map<String, Duration> timeByPiece;
  final double averageSuccessRate;
  final List<String> achievements;
  
  const PracticeSessionSummary({
    required this.id,
    required this.date,
    required this.totalDuration,
    required this.spotsWorked,
    required this.piecesWorked,
    required this.timeBySpotColor,
    required this.timeByPiece,
    required this.averageSuccessRate,
    required this.achievements,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'totalDuration': totalDuration.inMilliseconds,
    'spotsWorked': spotsWorked,
    'piecesWorked': piecesWorked,
    'timeBySpotColor': timeBySpotColor.map((k, v) => 
        MapEntry(k.name, v.inMilliseconds)),
    'timeByPiece': timeByPiece.map((k, v) => 
        MapEntry(k, v.inMilliseconds)),
    'averageSuccessRate': averageSuccessRate,
    'achievements': achievements,
  };
  
  factory PracticeSessionSummary.fromJson(Map<String, dynamic> json) {
    final timeBySpotColorMap = <SpotColor, Duration>{};
    final spotColorData = Map<String, dynamic>.from(json['timeBySpotColor'] ?? {});
    for (final entry in spotColorData.entries) {
      final color = SpotColor.values.firstWhere((c) => c.name == entry.key);
      timeBySpotColorMap[color] = Duration(milliseconds: entry.value);
    }
    
    final timeByPieceMap = <String, Duration>{};
    final pieceData = Map<String, dynamic>.from(json['timeByPiece'] ?? {});
    for (final entry in pieceData.entries) {
      timeByPieceMap[entry.key] = Duration(milliseconds: entry.value);
    }
    
    return PracticeSessionSummary(
      id: json['id'],
      date: DateTime.parse(json['date']),
      totalDuration: Duration(milliseconds: json['totalDuration']),
      spotsWorked: json['spotsWorked'],
      piecesWorked: json['piecesWorked'],
      timeBySpotColor: timeBySpotColorMap,
      timeByPiece: timeByPieceMap,
      averageSuccessRate: json['averageSuccessRate'].toDouble(),
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }
}

/// Weekly practice analytics
class WeeklyAnalytics {
  final DateTime weekStart;
  final Duration totalPracticeTime;
  final int totalSessions;
  final Map<DateTime, Duration> dailyPracticeTime;
  final Map<SpotColor, Duration> timeBySpotColor;
  final Map<String, Duration> timeByPiece;
  final double averageSessionLength;
  final double consistency; // 0-1 score based on daily practice
  final List<String> insights;
  
  const WeeklyAnalytics({
    required this.weekStart,
    required this.totalPracticeTime,
    required this.totalSessions,
    required this.dailyPracticeTime,
    required this.timeBySpotColor,
    required this.timeByPiece,
    required this.averageSessionLength,
    required this.consistency,
    required this.insights,
  });
}

/// Comprehensive time tracking service for practice analytics
class TimeTrackingService {
  static const String _timeEntriesKey = 'time_entries';
  static const String _sessionSummariesKey = 'session_summaries';
  
  Timer? _activeTimer;
  DateTime? _sessionStartTime;
  String? _currentPieceId;
  String? _currentSpotId;
  String? _currentSessionType;
  
  /// Start tracking time for a practice session
  void startSession({
    required String pieceId,
    String? spotId,
    String sessionType = 'practice',
  }) {
    stopSession(); // Stop any existing session
    
    _sessionStartTime = DateTime.now();
    _currentPieceId = pieceId;
    _currentSpotId = spotId;
    _currentSessionType = sessionType;
    
    // Start a timer to periodically save progress
    _activeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _savePartialEntry();
    });
  }
  
  /// Stop current session and save time entry
  Future<TimeEntry?> stopSession({Map<String, dynamic>? metadata}) async {
    if (_sessionStartTime == null || _currentPieceId == null) {
      return null;
    }
    
    _activeTimer?.cancel();
    _activeTimer = null;
    
    final endTime = DateTime.now();
    final entry = TimeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pieceId: _currentPieceId!,
      spotId: _currentSpotId,
      startTime: _sessionStartTime!,
      endTime: endTime,
      sessionType: _currentSessionType ?? 'practice',
      metadata: metadata ?? {},
    );
    
    await _saveTimeEntry(entry);
    
    // Clear current session
    _sessionStartTime = null;
    _currentPieceId = null;
    _currentSpotId = null;
    _currentSessionType = null;
    
    return entry;
  }
  
  /// Get current session duration
  Duration getCurrentSessionDuration() {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }
  
  /// Check if session is currently active
  bool get isSessionActive => _sessionStartTime != null;
  
  /// Get current session info
  Map<String, dynamic>? getCurrentSessionInfo() {
    if (!isSessionActive) return null;
    
    return {
      'pieceId': _currentPieceId,
      'spotId': _currentSpotId,
      'sessionType': _currentSessionType,
      'duration': getCurrentSessionDuration(),
      'startTime': _sessionStartTime,
    };
  }
  
  /// Save partial entry for crash recovery
  Future<void> _savePartialEntry() async {
    if (!isSessionActive) return;
    
    final prefs = await SharedPreferences.getInstance();
    final partialEntry = {
      'pieceId': _currentPieceId,
      'spotId': _currentSpotId,
      'sessionType': _currentSessionType,
      'startTime': _sessionStartTime!.toIso8601String(),
    };
    
    await prefs.setString('partial_time_entry', jsonEncode(partialEntry));
  }
  
  /// Recover partial entry after app restart
  Future<void> recoverPartialEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final partialEntryJson = prefs.getString('partial_time_entry');
    
    if (partialEntryJson != null) {
      try {
        final partialEntry = jsonDecode(partialEntryJson);
        final startTime = DateTime.parse(partialEntry['startTime']);
        
        // Only recover if session was recent (within last hour)
        if (DateTime.now().difference(startTime).inHours < 1) {
          final entry = TimeEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            pieceId: partialEntry['pieceId'],
            spotId: partialEntry['spotId'],
            startTime: startTime,
            endTime: DateTime.now(),
            sessionType: partialEntry['sessionType'] ?? 'practice',
            metadata: {'recovered': true},
          );
          
          await _saveTimeEntry(entry);
        }
        
        // Clear partial entry
        await prefs.remove('partial_time_entry');
      } catch (e) {
        // Ignore errors in recovery
      }
    }
  }
  
  /// Save time entry to storage
  Future<void> _saveTimeEntry(TimeEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAllTimeEntries();
    entries.add(entry);
    
    // Keep only last 1000 entries to prevent storage bloat
    if (entries.length > 1000) {
      entries.removeRange(0, entries.length - 1000);
    }
    
    final entriesJson = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_timeEntriesKey, entriesJson);
  }
  
  /// Get all time entries
  Future<List<TimeEntry>> getAllTimeEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_timeEntriesKey) ?? [];
    
    return entriesJson.map((json) => 
        TimeEntry.fromJson(jsonDecode(json))).toList();
  }
  
  /// Get time entries for a specific piece
  Future<List<TimeEntry>> getTimeEntriesForPiece(String pieceId) async {
    final allEntries = await getAllTimeEntries();
    return allEntries.where((entry) => entry.pieceId == pieceId).toList();
  }
  
  /// Get time entries for a specific date range
  Future<List<TimeEntry>> getTimeEntriesForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final allEntries = await getAllTimeEntries();
    return allEntries.where((entry) =>
        entry.startTime.isAfter(start) && entry.startTime.isBefore(end)).toList();
  }
  
  /// Calculate total practice time for a piece
  Future<Duration> getTotalPracticeTime(String pieceId) async {
    final entries = await getTimeEntriesForPiece(pieceId);
    return entries.fold(Duration.zero, (sum, entry) => sum + entry.duration);
  }
  
  /// Calculate today's practice time
  Future<Duration> getTodaysPracticeTime() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final entries = await getTimeEntriesForDateRange(startOfDay, endOfDay);
    return entries.fold(Duration.zero, (sum, entry) => sum + entry.duration);
  }
  
  /// Generate practice session summary
  Future<PracticeSessionSummary> generateSessionSummary(
    List<TimeEntry> sessionEntries,
  ) async {
    if (sessionEntries.isEmpty) {
      return PracticeSessionSummary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        totalDuration: Duration.zero,
        spotsWorked: 0,
        piecesWorked: 0,
        timeBySpotColor: {},
        timeByPiece: {},
        averageSuccessRate: 0.0,
        achievements: [],
      );
    }
    
    final sessionDate = sessionEntries.first.startTime;
    final totalDuration = sessionEntries.fold(Duration.zero, 
        (sum, entry) => sum + entry.duration);
    
    final uniqueSpots = sessionEntries
        .where((entry) => entry.spotId != null)
        .map((entry) => entry.spotId!)
        .toSet();
    
    final uniquePieces = sessionEntries
        .map((entry) => entry.pieceId)
        .toSet();
    
    // Calculate time by piece
    final timeByPiece = <String, Duration>{};
    for (final entry in sessionEntries) {
      timeByPiece[entry.pieceId] = (timeByPiece[entry.pieceId] ?? Duration.zero) + entry.duration;
    }
    
    // TODO: Calculate time by spot color (need piece/spot data)
    final timeBySpotColor = <SpotColor, Duration>{};
    
    // TODO: Calculate average success rate from session results
    final averageSuccessRate = 0.0;
    
    // Generate achievements
    final achievements = _generateAchievements(sessionEntries, totalDuration);
    
    final summary = PracticeSessionSummary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: sessionDate,
      totalDuration: totalDuration,
      spotsWorked: uniqueSpots.length,
      piecesWorked: uniquePieces.length,
      timeBySpotColor: timeBySpotColor,
      timeByPiece: timeByPiece,
      averageSuccessRate: averageSuccessRate,
      achievements: achievements,
    );
    
    await _saveSessionSummary(summary);
    return summary;
  }
  
  /// Generate weekly analytics
  Future<WeeklyAnalytics> generateWeeklyAnalytics([DateTime? weekStart]) async {
    final start = weekStart ?? _getWeekStart(DateTime.now());
    final end = start.add(const Duration(days: 7));
    
    final entries = await getTimeEntriesForDateRange(start, end);
    
    final totalPracticeTime = entries.fold(Duration.zero, 
        (sum, entry) => sum + entry.duration);
    
    // Group by day
    final dailyPracticeTime = <DateTime, Duration>{};
    for (int i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayEntries = entries.where((entry) =>
          entry.startTime.isAfter(dayStart) && entry.startTime.isBefore(dayEnd));
      
      dailyPracticeTime[dayStart] = dayEntries.fold(Duration.zero,
          (sum, entry) => sum + entry.duration);
    }
    
    // Calculate time by spot color and piece
    final timeBySpotColor = <SpotColor, Duration>{};
    final timeByPiece = <String, Duration>{};
    
    for (final entry in entries) {
      timeByPiece[entry.pieceId] = (timeByPiece[entry.pieceId] ?? Duration.zero) + entry.duration;
    }
    
    // Calculate session metrics
    final sessionDurations = <Duration>[];
    var currentSession = <TimeEntry>[];
    
    for (final entry in entries) {
      if (currentSession.isEmpty || 
          entry.startTime.difference(currentSession.last.endTime).inMinutes < 30) {
        currentSession.add(entry);
      } else {
        // End of session
        if (currentSession.isNotEmpty) {
          final sessionDuration = currentSession.fold(Duration.zero,
              (sum, e) => sum + e.duration);
          sessionDurations.add(sessionDuration);
        }
        currentSession = [entry];
      }
    }
    
    // Add final session
    if (currentSession.isNotEmpty) {
      final sessionDuration = currentSession.fold(Duration.zero,
          (sum, e) => sum + e.duration);
      sessionDurations.add(sessionDuration);
    }
    
    final averageSessionLength = sessionDurations.isEmpty ? 0.0 :
        sessionDurations.map((d) => d.inMinutes).reduce((a, b) => a + b) / 
        sessionDurations.length;
    
    // Calculate consistency (days practiced / 7)
    final daysPracticed = dailyPracticeTime.values
        .where((duration) => duration.inMinutes > 0)
        .length;
    final consistency = daysPracticed / 7.0;
    
    // Generate insights
    final insights = _generateWeeklyInsights(
      totalPracticeTime,
      sessionDurations.length,
      consistency,
      dailyPracticeTime,
    );
    
    return WeeklyAnalytics(
      weekStart: start,
      totalPracticeTime: totalPracticeTime,
      totalSessions: sessionDurations.length,
      dailyPracticeTime: dailyPracticeTime,
      timeBySpotColor: timeBySpotColor,
      timeByPiece: timeByPiece,
      averageSessionLength: averageSessionLength,
      consistency: consistency,
      insights: insights,
    );
  }
  
  /// Save session summary
  Future<void> _saveSessionSummary(PracticeSessionSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    final summaries = await getAllSessionSummaries();
    summaries.add(summary);
    
    // Keep only last 100 summaries
    if (summaries.length > 100) {
      summaries.removeRange(0, summaries.length - 100);
    }
    
    final summariesJson = summaries.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_sessionSummariesKey, summariesJson);
  }
  
  /// Get all session summaries
  Future<List<PracticeSessionSummary>> getAllSessionSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final summariesJson = prefs.getStringList(_sessionSummariesKey) ?? [];
    
    return summariesJson.map((json) => 
        PracticeSessionSummary.fromJson(jsonDecode(json))).toList();
  }
  
  /// Generate practice achievements
  List<String> _generateAchievements(
    List<TimeEntry> entries,
    Duration totalDuration,
  ) {
    final achievements = <String>[];
    
    // Duration achievements
    if (totalDuration.inMinutes >= 60) {
      achievements.add('Marathon Practice (60+ minutes)');
    } else if (totalDuration.inMinutes >= 30) {
      achievements.add('Solid Session (30+ minutes)');
    }
    
    // Consistency achievements
    if (entries.length >= 10) {
      achievements.add('Deep Focus (10+ practice items)');
    }
    
    // Variety achievements
    final uniquePieces = entries.map((e) => e.pieceId).toSet();
    if (uniquePieces.length >= 3) {
      achievements.add('Well-Rounded Practice (3+ pieces)');
    }
    
    return achievements;
  }
  
  /// Generate weekly insights
  List<String> _generateWeeklyInsights(
    Duration totalTime,
    int totalSessions,
    double consistency,
    Map<DateTime, Duration> dailyTime,
  ) {
    final insights = <String>[];
    
    // Practice time insights
    final averageDaily = totalTime.inMinutes / 7;
    if (averageDaily >= 60) {
      insights.add('Excellent practice volume (${averageDaily.round()}min/day average)');
    } else if (averageDaily >= 30) {
      insights.add('Good practice consistency (${averageDaily.round()}min/day average)');
    } else {
      insights.add('Consider increasing practice time (${averageDaily.round()}min/day average)');
    }
    
    // Consistency insights
    if (consistency >= 0.8) {
      insights.add('Outstanding consistency - you practiced ${(consistency * 7).round()}/7 days!');
    } else if (consistency >= 0.5) {
      insights.add('Good consistency - try to practice more regularly');
    } else {
      insights.add('Focus on building a daily practice habit');
    }
    
    // Pattern insights
    final bestDay = dailyTime.entries
        .reduce((a, b) => a.value.inMinutes > b.value.inMinutes ? a : b);
    final dayName = _getDayName(bestDay.key);
    insights.add('Your most productive day was $dayName (${bestDay.value.inMinutes}min)');
    
    return insights;
  }
  
  /// Get start of week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final daysToMonday = weekday - 1;
    final monday = date.subtract(Duration(days: daysToMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }
  
  /// Get day name
  String _getDayName(DateTime date) {
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 
                     'Friday', 'Saturday', 'Sunday'];
    return dayNames[date.weekday - 1];
  }
  
  /// Clear all time tracking data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timeEntriesKey);
    await prefs.remove(_sessionSummariesKey);
    await prefs.remove('partial_time_entry');
  }
  
  /// Export time tracking data as JSON
  Future<Map<String, dynamic>> exportData() async {
    final entries = await getAllTimeEntries();
    final summaries = await getAllSessionSummaries();
    
    return {
      'timeEntries': entries.map((e) => e.toJson()).toList(),
      'sessionSummaries': summaries.map((s) => s.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }
}
