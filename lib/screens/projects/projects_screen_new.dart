import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

// Project model
class Project {
  final String id;
  final String name;
  final String description;
  final DateTime? concertDate;
  final List<String> pieces;
  final Color color;
  final double progress;
  final bool isPinned;
  final String status;

  Project({
    required this.id,
    required this.name,
    required this.description,
    this.concertDate,
    required this.pieces,
    required this.color,
    required this.progress,
    this.isPinned = false,
    this.status = 'In Progress',
  });
}

// Projects provider
final projectsProvider = StateNotifierProvider<ProjectsNotifier, List<Project>>((ref) {
  return ProjectsNotifier();
});

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier() : super([]) {
    _loadProjects();
  }

  void _loadProjects() {
    // Load with some demo projects that look professional
    state = [
      Project(
        id: '1',
        name: 'Spring Recital 2025',
        description: 'Annual spring performance featuring romantic piano works',
        concertDate: DateTime.now().add(const Duration(days: 21)),
        pieces: ['Chopin Nocturne Op. 9 No. 2', 'Debussy Clair de Lune', 'Beethoven Moonlight Sonata'],
        color: AppColors.primaryPurple,
        progress: 0.78,
        isPinned: true,
        status: 'Critical',
      ),
      Project(
        id: '2',
        name: 'Competition Prep',
        description: 'International Piano Competition preparation',
        concertDate: DateTime.now().add(const Duration(days: 8)),
        pieces: ['Chopin Ballade No. 1', 'Rachmaninoff Prelude Op. 23 No. 5'],
        color: AppColors.errorRed,
        progress: 0.92,
        isPinned: true,
        status: 'Urgent',
      ),
      Project(
        id: '3',
        name: 'Chamber Music',
        description: 'Piano trio performance with violin and cello',
        concertDate: DateTime.now().add(const Duration(days: 35)),
        pieces: ['Brahms Piano Trio No. 1', 'Schubert Piano Trio No. 2'],
        color: AppColors.successGreen,
        progress: 0.65,
        status: 'On Track',
      ),
      Project(
        id: '4',
        name: 'Teaching Portfolio',
        description: 'Building repertoire for student demonstrations',
        pieces: ['Bach Invention No. 4', 'Mozart Sonata K.331', 'Chopin Waltz Op. 64 No. 2'],
        color: AppColors.warningOrange,
        progress: 0.43,
        status: 'Ongoing',
      ),
    ];
  }

  void updateProgress(String projectId, double newProgress) {
    state = state.map((project) {
      if (project.id == projectId) {
        return Project(
          id: project.id,
          name: project.name,
          description: project.description,
          concertDate: project.concertDate,
          pieces: project.pieces,
          color: project.color,
          progress: newProgress,
          isPinned: project.isPinned,
          status: project.status,
        );
      }
      return project;
    }).toList();
  }

  void togglePin(String projectId) {
    state = state.map((project) {
      if (project.id == projectId) {
        return Project(
          id: project.id,
          name: project.name,
          description: project.description,
          concertDate: project.concertDate,
          pieces: project.pieces,
          color: project.color,
          progress: project.progress,
          isPinned: !project.isPinned,
          status: project.status,
        );
      }
      return project;
    }).toList();
  }
}

/// Projects screen for setlist/project management
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final filteredProjects = _getFilteredProjects(projects);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryPurple,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Projects',
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
                        AppColors.primaryPurple,
                        AppColors.warningOrange,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats
                    _buildQuickStats(projects),
                    
                    const SizedBox(height: 24),

                    // Filter Chips
                    _buildFilterChips(),
                    
                    const SizedBox(height: 24),

                    // Projects List
                    ...filteredProjects.map((project) => _buildProjectCard(project)),
                    
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewProject,
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Project', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  List<Project> _getFilteredProjects(List<Project> projects) {
    switch (_selectedFilter) {
      case 'Urgent':
        return projects.where((p) => p.concertDate != null && 
          p.concertDate!.difference(DateTime.now()).inDays <= 14).toList();
      case 'In Progress':
        return projects.where((p) => p.progress < 1.0).toList();
      case 'Pinned':
        return projects.where((p) => p.isPinned).toList();
      default:
        return projects;
    }
  }

  Widget _buildQuickStats(List<Project> projects) {
    final urgentCount = projects.where((p) => p.concertDate != null && 
      p.concertDate!.difference(DateTime.now()).inDays <= 14).length;
    final inProgressCount = projects.where((p) => p.progress < 1.0).length;
    final avgProgress = projects.isEmpty ? 0.0 : 
      projects.map((p) => p.progress).reduce((a, b) => a + b) / projects.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Projects',
            '${projects.length}',
            Icons.folder,
            AppColors.primaryPurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Urgent',
            '$urgentCount',
            Icons.schedule,
            AppColors.errorRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg Progress',
            '${(avgProgress * 100).toInt()}%',
            Icons.trending_up,
            AppColors.successGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Urgent', 'In Progress', 'Pinned'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: AppColors.primaryPurple.withOpacity(0.2),
              checkmarkColor: AppColors.primaryPurple,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final isUrgent = project.concertDate != null && 
      project.concertDate!.difference(DateTime.now()).inDays <= 14;
    final daysLeft = project.concertDate?.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isUrgent ? Border.all(color: AppColors.errorRed.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openProject(project),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: project.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      project.isPinned ? Icons.push_pin : Icons.folder,
                      color: project.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isUrgent && daysLeft != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              daysLeft <= 0 ? 'Due Today!' : '$daysLeft days left',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.errorRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(projectsProvider.notifier).togglePin(project.id),
                    icon: Icon(
                      project.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: project.isPinned ? project.color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                project.description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 16),

              // Pieces
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: project.pieces.map((piece) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: project.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    piece,
                    style: TextStyle(
                      fontSize: 12,
                      color: project.color,
                    ),
                  ),
                )).toList(),
              ),

              const SizedBox(height: 16),

              // Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(project.progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: project.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: project.progress,
                      backgroundColor: project.color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(project.color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),

              if (project.concertDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(project.concertDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isUrgent ? AppColors.errorRed : AppColors.textSecondary,
                        fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) return 'Overdue';
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference <= 7) return 'In $difference days';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openProject(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder_open, color: project.color),
            const SizedBox(width: 8),
            Expanded(child: Text(project.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.description),
            const SizedBox(height: 16),
            Text(
              'Pieces (${project.pieces.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...project.pieces.map((piece) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $piece'),
            )),
            const SizedBox(height: 16),
            Text(
              'Progress: ${(project.progress * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: project.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startPracticeSession(project);
            },
            style: FilledButton.styleFrom(backgroundColor: project.color),
            child: const Text('Start Practice'),
          ),
        ],
      ),
    );
  }

  void _startPracticeSession(Project project) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting practice session for ${project.name}'),
        backgroundColor: project.color,
      ),
    );
  }

  void _addNewProject() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new project feature coming soon!'),
        backgroundColor: AppColors.primaryPurple,
      ),
    );
  }
}
