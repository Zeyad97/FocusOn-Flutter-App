import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../models/session_type.dart';

// Practice data models
class PracticeSession {
  final DateTime date;
  final int durationMinutes;
  final int spotsWorked;
  final double progressPercent;
  final String type;

  PracticeSession({
    required this.date,
    required this.durationMinutes,
    required this.spotsWorked,
    required this.progressPercent,
    required this.type,
  });
}

class PracticeStats {
  final int totalTimeToday;
  final int spotsWorkedToday;
  final double progressToday;
  final int streak;
  final List<PracticeSession> recentSessions;

  PracticeStats({
    required this.totalTimeToday,
    required this.spotsWorkedToday,
    required this.progressToday,
    required this.streak,
    required this.recentSessions,
  });
}

// Practice providers
final practiceStatsProvider = StateNotifierProvider<PracticeStatsNotifier, PracticeStats>((ref) {
  return PracticeStatsNotifier();
});

class PracticeStatsNotifier extends StateNotifier<PracticeStats> {
  PracticeStatsNotifier() : super(PracticeStats(
    totalTimeToday: 0,
    spotsWorkedToday: 0,
    progressToday: 0.0,
    streak: 0,
    recentSessions: [],
  )) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    state = PracticeStats(
      totalTimeToday: prefs.getInt('practice_time_$todayKey') ?? 0,
      spotsWorkedToday: prefs.getInt('spots_worked_$todayKey') ?? 0,
      progressToday: prefs.getDouble('progress_$todayKey') ?? 0.0,
      streak: prefs.getInt('practice_streak') ?? 0,
      recentSessions: _loadRecentSessions(prefs),
    );
  }

  List<PracticeSession> _loadRecentSessions(SharedPreferences prefs) {
    final sessions = <PracticeSession>[];
    final now = DateTime.now();
    
    // Generate some recent sessions for demo
    for (int i = 0; i < 5; i++) {
      final date = now.subtract(Duration(days: i));
      final timeKey = '${date.year}-${date.month}-${date.day}';
      final time = prefs.getInt('practice_time_$timeKey') ?? (20 + (i * 5));
      final spots = prefs.getInt('spots_worked_$timeKey') ?? (5 + i);
      
      sessions.add(PracticeSession(
        date: date,
        durationMinutes: time,
        spotsWorked: spots,
        progressPercent: 5.0 + (i * 2),
        type: i == 0 ? 'Smart Practice' : i == 1 ? 'Critical Spots' : 'Warmup',
      ));
    }
    
    return sessions;
  }

  Future<void> addPracticeSession(String type, int duration, int spots, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    // Update today's stats
    final newTotalTime = state.totalTimeToday + duration;
    final newSpotsWorked = state.spotsWorkedToday + spots;
    final newProgress = state.progressToday + progress;
    
    await prefs.setInt('practice_time_$todayKey', newTotalTime);
    await prefs.setInt('spots_worked_$todayKey', newSpotsWorked);
    await prefs.setDouble('progress_$todayKey', newProgress);
    
    // Update streak
    final newStreak = state.streak + 1;
    await prefs.setInt('practice_streak', newStreak);
    
    // Add new session
    final newSession = PracticeSession(
      date: today,
      durationMinutes: duration,
      spotsWorked: spots,
      progressPercent: progress,
      type: type,
    );
    
    final updatedSessions = [newSession, ...state.recentSessions];
    if (updatedSessions.length > 10) {
      updatedSessions.removeLast();
    }
    
    state = PracticeStats(
      totalTimeToday: newTotalTime,
      spotsWorkedToday: newSpotsWorked,
      progressToday: newProgress,
      streak: newStreak,
      recentSessions: updatedSessions,
    );
  }
}

/// Practice dashboard screen for session management
class PracticeDashboardScreen extends ConsumerStatefulWidget {
  const PracticeDashboardScreen({super.key});

  @override
  ConsumerState<PracticeDashboardScreen> createState() => _PracticeDashboardScreenState();
}

class _PracticeDashboardScreenState extends ConsumerState<PracticeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final practiceStats = ref.watch(practiceStatsProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.successGreen,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Practice Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.successGreen,
                        AppColors.primaryPurple,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(75),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Smart Practice',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AI-Powered Learning',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dashboard content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Today's Practice Stats
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.today,
                                  color: AppColors.successGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Today\'s Practice',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              _buildStatCard(
                                'Time',
                                '${practiceStats.totalTimeToday}m',
                                Icons.schedule,
                                AppColors.primaryPurple,
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                'Spots',
                                '${practiceStats.spotsWorkedToday}',
                                Icons.center_focus_strong,
                                AppColors.warningOrange,
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                'Progress',
                                '+${practiceStats.progressToday.toStringAsFixed(0)}%',
                                Icons.trending_up,
                                AppColors.successGreen,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Practice Actions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Start',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _buildQuickActionCard(
                                'Quick Practice',
                                'Choose your session type',
                                Icons.psychology,
                                AppColors.primaryPurple,
                                () => _startSmartPractice(),
                              ),
                              _buildQuickActionCard(
                                'Critical Spots',
                                '3 urgent spots',
                                Icons.warning,
                                AppColors.errorRed,
                                () => _startCriticalSpots(),
                              ),
                              _buildQuickActionCard(
                                'Warmup',
                                'Technical exercises',
                                Icons.self_improvement,
                                AppColors.successGreen,
                                () => _startWarmup(),
                              ),
                              _buildQuickActionCard(
                                'Review Mode',
                                'Quick overview',
                                Icons.quiz,
                                AppColors.warningOrange,
                                () => _startReview(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recent Sessions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Recent Sessions',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: const Text('View All'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          ...List.generate(
                            practiceStats.recentSessions.take(3).length,
                            (index) {
                              final session = practiceStats.recentSessions[index];
                              final sessionData = {
                                'title': session.type,
                                'duration': '${session.durationMinutes} minutes',
                                'spots': '${session.spotsWorked} spots practiced',
                                'time': _getTimeAgo(session.date),
                                'color': _getSessionColor(session.type),
                                'progress': '+${session.progressPercent.toStringAsFixed(1)}%',
                              };
                              return _buildSessionCard(sessionData);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Practice Analytics Preview
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This Week\'s Progress',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Practice Time',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '4h 32m',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: 0.76,
                                      backgroundColor: AppColors.borderLight,
                                      valueColor: AlwaysStoppedAnimation(AppColors.primaryPurple),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '76% of weekly goal',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 24),

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      color: AppColors.successGreen,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '5-day',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.successGreen,
                                      ),
                                    ),
                                    Text(
                                      'streak',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (session['color'] as Color).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (session['color'] as Color).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (session['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.play_circle_fill,
              color: session['color'],
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session['duration']} • ${session['spots']}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (session['progress'] != null)
                Text(
                  session['progress'],
                  style: TextStyle(
                    color: AppColors.successGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                session['time'],
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startSmartPractice() {
    // Show practice type selection dialog like in Projects screen
    _showPracticeTypeSelectionDialog();
  }

  void _showPracticeTypeSelectionDialog() async {
    print('DEBUG: Showing practice type selection dialog in Practice Dashboard');
    final sessionType = await showDialog<SessionType>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.psychology,
                color: AppColors.primaryPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Practice Type',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'All Pieces',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Smart Practice option
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.psychology, color: AppColors.primaryPurple),
                  title: const Text('Smart Practice'),
                  subtitle: const Text('Practice ALL spots with AI prioritization'),
                  onTap: () {
                    print('DEBUG: Smart Practice option tapped in Practice Dashboard!');
                    Navigator.pop(context, SessionType.smart);
                  },
                ),
              ),
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.warning_amber, color: AppColors.spotRed),
                  title: const Text('Critical Focus'),
                  subtitle: const Text('Practice ONLY red (critical) spots'),
                  onTap: () => Navigator.pop(context, SessionType.critical),
                ),
              ),
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.balance, color: AppColors.spotYellow),
                  title: const Text('Balanced Practice'),
                  subtitle: const Text('Practice ONLY yellow/blue (medium) spots'),
                  onTap: () => Navigator.pop(context, SessionType.balanced),
                ),
              ),
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.tune, color: AppColors.spotGreen),
                  title: const Text('Maintenance'),
                  subtitle: const Text('Practice ONLY green (maintenance) spots'),
                  onTap: () => Navigator.pop(context, SessionType.maintenance),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (sessionType != null) {
      // Handle the selected practice type
      print('DEBUG: Selected practice type in Dashboard: $sessionType');
      _startPracticeWithType(sessionType);
    }
  }

  void _startPracticeWithType(SessionType sessionType) {
    // Start practice session based on selected type
    String typeName;
    switch (sessionType) {
      case SessionType.smart:
        typeName = 'Smart Practice';
        break;
      case SessionType.critical:
        typeName = 'Critical Focus';
        break;
      case SessionType.balanced:
        typeName = 'Balanced Practice';
        break;
      case SessionType.maintenance:
        typeName = 'Maintenance';
        break;
    }
    
    _showPracticeDialog(
      typeName,
      'Start your $typeName session',
      AppColors.primaryPurple,
      () => _runPracticeSession(typeName, 25, 5, 8.5),
    );
  }

  void _startCriticalSpots() {
    _showPracticeDialog(
      'Critical Spots',
      'Focus on your most challenging sections',
      AppColors.errorRed,
      () => _runPracticeSession('Critical Spots', 20, 8, 12.0),
    );
  }

  void _startWarmup() {
    _showPracticeDialog(
      'Warmup Session',
      'Technical exercises and scales',
      AppColors.successGreen,
      () => _runPracticeSession('Warmup', 15, 3, 5.0),
    );
  }

  void _startReview() {
    _showPracticeDialog(
      'Review Mode',
      'Quick overview of learned pieces',
      AppColors.warningOrange,
      () => _runPracticeSession('Review', 18, 4, 6.5),
    );
  }

  void _showPracticeDialog(String title, String description, Color color, VoidCallback onStart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.play_circle, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will start a guided practice session and track your progress.',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onStart();
            },
            style: FilledButton.styleFrom(backgroundColor: color),
            child: const Text('Start Session'),
          ),
        ],
      ),
    );
  }

  void _runPracticeSession(String type, int duration, int spots, double progress) {
    // Show practice session in progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
            ),
            const SizedBox(width: 12),
            Text('$type Session'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Session in progress...'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated duration: ${duration}m',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );

    // Simulate session duration
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      
      // Add the practice session to stats
      ref.read(practiceStatsProvider.notifier).addPracticeSession(type, duration, spots, progress);
      
      // Show completion dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.successGreen),
              const SizedBox(width: 8),
              const Text('Session Complete!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Great job! You\'ve completed your $type session.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Summary:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.successGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('• Duration: ${duration} minutes'),
                    Text('• Spots worked: $spots'),
                    Text('• Progress: +${progress.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: AppColors.successGreen),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      );
    });
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Color _getSessionColor(String type) {
    switch (type) {
      case 'Smart Practice':
        return AppColors.primaryPurple;
      case 'Critical Spots':
        return AppColors.errorRed;
      case 'Warmup':
        return AppColors.successGreen;
      case 'Review':
        return AppColors.warningOrange;
      default:
        return AppColors.primaryPurple;
    }
  }

  IconData _getSessionIcon(String type) {
    switch (type) {
      case 'Smart Practice':
        return Icons.psychology;
      case 'Critical Spots':
        return Icons.warning;
      case 'Warmup':
        return Icons.self_improvement;
      case 'Review':
        return Icons.quiz;
      default:
        return Icons.music_note;
    }
  }
}
