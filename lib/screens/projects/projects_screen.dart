import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/project.dart';
import '../../models/piece.dart';
import '../../models/practice_session.dart';
import '../../services/data_service.dart';
import '../../providers/practice_session_provider.dart';
import '../../providers/unified_library_provider.dart';
import '../../utils/snackbar_utils.dart';
import '../practice/active_practice_session_screen.dart';
import 'widgets/add_project_dialog.dart';
import 'piece_management_screen.dart';
import 'widgets/project_pieces_manager.dart';
import '../settings/settings_screen.dart';

/// Projects & Setlists screen integrated with actual music practice system
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
    final pieces = ref.watch(unifiedLibraryProvider);
    final filteredProjects = _getFilteredProjects(projects);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple,
                      AppColors.accentPurple,
                    ],
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: const Text(
                    'Projects & Setlists',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  background: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        top: 60,
                        child: Icon(
                          Icons.folder_special_outlined,
                          color: Colors.white.withOpacity(0.15),
                          size: 28,
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
                    _buildQuickStats(projects, pieces),
                    
                    const SizedBox(height: 24),

                    // Filter Chips
                    _buildFilterChips(),
                    
                    const SizedBox(height: 20),

                    // Projects Grid
                    if (filteredProjects.isEmpty)
                      _buildEmptyState()
                    else
                      _buildProjectsGrid(filteredProjects, pieces),
                    
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple,
              AppColors.accentPurple,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showCreateProjectDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_outlined, color: Colors.white, size: 22),
          label: const Text(
            'New Project',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddProjectDialog(),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        _createProject(
          title: result['title'] ?? '',
          description: result['description'] ?? '',
          concertDate: result['concertDate'],
          dailyGoal: result['dailyGoal'] ?? const Duration(minutes: 30),
          pieceIds: result['pieceIds'] ?? <String>[],
        );
      }
    });
  }

  Future<void> _createProject({
    required String title,
    required String description,
    DateTime? concertDate,
    Duration? dailyGoal,
    List<String>? pieceIds,
  }) async {
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project title cannot be empty'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: title.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      concertDate: concertDate,
      pieceIds: pieceIds ?? [], // Use the selected pieces
      dailyPracticeGoal: dailyGoal ?? const Duration(minutes: 30),
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(projectsProvider.notifier).addProject(project);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created project "${project.name}"'),
            backgroundColor: AppColors.successGreen,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Project will be visible in the list now
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create project: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  List<Project> _getFilteredProjects(AsyncValue<List<Project>> projects) {
    return projects.when(
      data: (projectList) {
        switch (_selectedFilter) {
          case 'Urgent':
            return projectList.where((p) => p.urgency == ProjectUrgency.high || 
              p.urgency == ProjectUrgency.critical).toList();
          case 'Active':
            return projectList.where((p) => p.concertDate != null && 
              p.daysUntilConcert != null && p.daysUntilConcert! > 0).toList();
          case 'Completed':
            return projectList.where((p) => p.concertDate != null && 
              p.daysUntilConcert != null && p.daysUntilConcert! < 0).toList();
          default:
            return projectList;
        }
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  Widget _buildQuickStats(AsyncValue<List<Project>> projects, AsyncValue<List<Piece>> pieces) {
    return projects.when(
      data: (projectList) {
        final urgentCount = projectList.where((p) => p.urgency == ProjectUrgency.high || 
          p.urgency == ProjectUrgency.critical).length;
        final activeCount = projectList.where((p) => p.concertDate != null && 
          p.daysUntilConcert != null && p.daysUntilConcert! > 0).length;
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Projects',
                '${projectList.length}',
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
                'Active',
                '$activeCount',
                Icons.trending_up,
                AppColors.successGreen,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
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
    final filters = ['All', 'Active', 'Urgent', 'Completed'];
    
    return Container(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: AppColors.primaryPurple,
                checkmarkColor: Colors.white,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectsGrid(List<Project> projects, AsyncValue<List<Piece>> pieces) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectCard(project, pieces);
      },
    );
  }

  Widget _buildProjectCard(Project project, AsyncValue<List<Piece>> pieces) {
    final isUrgent = project.concertDate != null && 
      project.daysUntilConcert != null && project.daysUntilConcert! <= 14;

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
        onTap: () => _openProject(project, pieces),
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
                      color: _getUrgencyColor(project.urgency).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getUrgencyIcon(project.urgency),
                      color: _getUrgencyColor(project.urgency),
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
                        const SizedBox(height: 4),
                        if (project.daysUntilConcert != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isUrgent ? AppColors.errorRed : AppColors.primaryPurple,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isUrgent ? [
                                BoxShadow(
                                  color: AppColors.errorRed.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ] : [
                                BoxShadow(
                                  color: AppColors.primaryPurple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  project.daysUntilConcert! <= 0 ? Icons.error : 
                                  project.daysUntilConcert! <= 7 ? Icons.warning :
                                  Icons.schedule,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  project.daysUntilConcert! <= 0 
                                      ? 'DUE TODAY!' 
                                      : project.daysUntilConcert! == 1
                                          ? '1 DAY LEFT'
                                          : '${project.daysUntilConcert} DAYS LEFT',
                                  style: TextStyle(
                                    fontSize: isUrgent ? 13 : 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _startProjectPractice(project, pieces),
                    icon: Icon(
                      Icons.play_circle_filled,
                      color: AppColors.primaryPurple,
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              if (project.description != null)
                Text(
                  project.description!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 16),

              // Pieces
              pieces.when(
                data: (pieceList) {
                  print('ProjectsScreen: Filtering pieces for project ${project.name}');
                  print('ProjectsScreen: Project piece IDs: ${project.pieceIds}');
                  print('ProjectsScreen: Available pieces: ${pieceList.map((p) => '${p.id}:${p.title}').toList()}');
                  
                  final projectPieces = pieceList.where((p) => project.pieceIds.contains(p.id)).toList();
                  print('ProjectsScreen: Found ${projectPieces.length} project pieces: ${projectPieces.map((p) => '${p.id}:${p.title}').toList()}');

                  if (projectPieces.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warningOrange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.music_note_outlined,
                            size: 16,
                            color: AppColors.warningOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No pieces assigned yet',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warningOrange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _navigateToPieceManagement(project),
                            child: Icon(
                              Icons.add_circle_outline,
                              size: 16,
                              color: AppColors.warningOrange,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: projectPieces.isEmpty 
                        ? [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryPurple.withOpacity(0.3),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 16,
                                    color: AppColors.primaryPurple,
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProjectPiecesManager(project: project),
                                        ),
                                      );
                                      
                                      if (result == true) {
                                        ref.read(projectsProvider.notifier).refresh();
                                      }
                                    },
                                    child: Text(
                                      'Add pieces to this project',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryPurple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        : projectPieces.asMap().entries.map((entry) {
                            final index = entry.key;
                            final piece = entry.value;
                            
                            // Use difficulty-based color instead of spot color
                            Color difficultyColor = _getDifficultyColor(piece.difficulty);
                            
                            return Container(
                              margin: const EdgeInsets.only(right: 4),
                              child: Tooltip(
                                message: '${piece.title}\nDifficulty: ${piece.difficulty}/5 (${_getDifficultyLabel(piece.difficulty)})',
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: difficultyColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: difficultyColor.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${piece.difficulty}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 16),

              // Progress
              pieces.when(
                data: (pieceList) {
                  final projectPieces = pieceList.where((p) => project.pieceIds.contains(p.id)).toList();
                  
                  final readiness = projectPieces.isNotEmpty ? project.calculateReadiness(projectPieces) : 0.0;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Readiness',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(readiness * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getUrgencyColor(project.urgency),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: readiness,
                          backgroundColor: _getUrgencyColor(project.urgency).withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(_getUrgencyColor(project.urgency)),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
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

  Color _getUrgencyColor(ProjectUrgency urgency) {
    switch (urgency) {
      case ProjectUrgency.none:
        return AppColors.textSecondary;
      case ProjectUrgency.low:
        return AppColors.successGreen;
      case ProjectUrgency.medium:
        return AppColors.warningOrange;
      case ProjectUrgency.high:
        return AppColors.errorRed;
      case ProjectUrgency.critical:
        return AppColors.errorRed;
    }
  }

  IconData _getUrgencyIcon(ProjectUrgency urgency) {
    switch (urgency) {
      case ProjectUrgency.none:
        return Icons.folder;
      case ProjectUrgency.low:
        return Icons.folder_outlined;
      case ProjectUrgency.medium:
        return Icons.schedule;
      case ProjectUrgency.high:
        return Icons.priority_high;
      case ProjectUrgency.critical:
        return Icons.warning;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_special_outlined,
              size: 60,
              color: AppColors.primaryPurple.withOpacity(0.6),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'No projects yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Create projects to organize your music\ninto concerts and practice goals',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryPurple,
                  AppColors.accentPurple,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _showCreateProjectDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_outlined, size: 20),
              label: const Text(
                'Create Your First Project',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
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

  void _openProject(Project project, AsyncValue<List<Piece>> pieces) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder_open, color: _getUrgencyColor(project.urgency)),
            const SizedBox(width: 8),
            Expanded(child: Text(project.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.description ?? ''),
            const SizedBox(height: 16),
            pieces.when(
              data: (pieceList) {
                final projectPieces = pieceList.where((p) => project.pieceIds.contains(p.id)).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pieces (${projectPieces.length}):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...projectPieces.map((piece) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${piece.title} - ${piece.composer}'),
                    )),
                    const SizedBox(height: 16),
                    Text(
                      'Readiness: ${projectPieces.isNotEmpty ? (project.calculateReadiness(projectPieces) * 100).toInt() : 0}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getUrgencyColor(project.urgency),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading pieces'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => PieceManagementScreen(project: project),
                ),
              );
              
              // If pieces were updated, refresh the projects list
              if (result == true) {
                ref.read(projectsProvider.notifier).refresh();
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Manage Pieces'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startProjectPractice(project, pieces);
            },
            style: FilledButton.styleFrom(backgroundColor: _getUrgencyColor(project.urgency)),
            child: const Text('Start Practice'),
          ),
        ],
      ),
    );
  }

  void _startProjectPractice(Project project, AsyncValue<List<Piece>> pieces) async {
    pieces.when(
      data: (pieceList) async {
        final projectPieces = pieceList.where((p) => project.pieceIds.contains(p.id)).toList();

        if (projectPieces.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('This project has no pieces yet. Add pieces to start practicing!'),
              backgroundColor: AppColors.warningOrange,
              action: SnackBarAction(
                label: 'Add Pieces',
                textColor: Colors.white,
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PieceManagementScreen(project: project),
                    ),
                  );
                  
                  if (result == true) {
                    ref.read(projectsProvider.notifier).refresh();
                  }
                },
              ),
            ),
          );
          return;
        }

        // Show enhanced practice dialog like Lovable
        _showEnhancedPracticeDialog(project, projectPieces);
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading pieces...')),
        );
      },
      error: (_, __) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading pieces')),
        );
      },
    );
  }

  void _showEnhancedPracticeDialog(Project project, List<Piece> projectPieces) {
    // Sort pieces by priority (most critical spots first)
    final sortedPieces = [...projectPieces];
    sortedPieces.sort((a, b) {
      final aCritical = a.criticalSpots.length;
      final bCritical = b.criticalSpots.length;
      if (aCritical != bCritical) return bCritical.compareTo(aCritical);
      
      final aPractice = a.practiceSpots.length;
      final bPractice = b.practiceSpots.length;
      return bPractice.compareTo(aPractice);
    });

    int selectedDuration = 30; // Default 30 minutes
    bool microbreakEnabled = false;
    bool interleaveEnabled = true;
    Piece? selectedPiece;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                  Icons.play_circle_filled,
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
                      'Start Practice Session',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      project.name,
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
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI Suggestions Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.successGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Suggestions',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.successGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (project.concertDate != null && project.daysUntilConcert != null && project.daysUntilConcert! <= 7)
                        Text(
                          '🎯 Concert in ${project.daysUntilConcert} days - Focus on performance readiness',
                          style: const TextStyle(fontSize: 12),
                        )
                      else if (sortedPieces.first.criticalSpots.isNotEmpty)
                        Text(
                          '🔥 Work on "${sortedPieces.first.title}" - ${sortedPieces.first.criticalSpots.length} critical spots need attention',
                          style: const TextStyle(fontSize: 12),
                        )
                      else
                        Text(
                          '✨ Great progress! Focus on maintaining muscle memory',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Piece Selection
                Text(
                  'Choose piece to practice:',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                
                ...sortedPieces.take(3).map((piece) {
                  final isSelected = selectedPiece?.id == piece.id;
                  final criticalCount = piece.criticalSpots.length;
                  final practiceCount = piece.practiceSpots.length;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedPiece = piece;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryPurple.withOpacity(0.1) : null,
                          border: Border.all(
                            color: isSelected ? AppColors.primaryPurple : AppColors.borderLight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // Priority indicator
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: criticalCount > 0 
                                    ? AppColors.errorRed 
                                    : practiceCount > 0 
                                        ? AppColors.warningOrange 
                                        : AppColors.successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    piece.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    piece.composer,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (criticalCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$criticalCount urgent',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (practiceCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warningOrange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$practiceCount practice',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 16),

                // Time Selection
                Row(
                  children: [
                    Text(
                      'Practice time: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [15, 30, 45, 60].map((minutes) {
                          final isSelected = selectedDuration == minutes;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedDuration = minutes;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryPurple : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryPurple : AppColors.borderLight,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${minutes}m',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Advanced Options
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Microbreaks',
                          style: TextStyle(fontSize: 12),
                        ),
                        subtitle: const Text(
                          '2-min breaks every 15 min',
                          style: TextStyle(fontSize: 10),
                        ),
                        value: microbreakEnabled,
                        onChanged: (value) {
                          setState(() {
                            microbreakEnabled = value ?? false;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Interleave',
                          style: TextStyle(fontSize: 12),
                        ),
                        subtitle: const Text(
                          'Mix practice spots',
                          style: TextStyle(fontSize: 10),
                        ),
                        value: interleaveEnabled,
                        onChanged: (value) {
                          setState(() {
                            interleaveEnabled = value ?? false;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedPiece == null ? null : () {
                Navigator.of(context).pop();
                _startActualPractice(project, selectedPiece!, selectedDuration, microbreakEnabled, interleaveEnabled);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Practice'),
            ),
          ],
        ),
      ),
    );
  }

  void _startActualPractice(Project project, Piece selectedPiece, int duration, bool microbreaks, bool interleave) async {
    try {
      await ref.read(activePracticeSessionProvider.notifier).startProjectPracticeSession(
        project.name,
        SessionType.smart,
      );

      // Check if a session was actually created
      final practiceState = ref.read(activePracticeSessionProvider);
      
      if (practiceState.session == null || !practiceState.isActive) {
        // No session was created - likely no spots available
        if (mounted) {
          SnackBarUtils.showWarning(
            context, 
            'No practice spots available! Please open your pieces in the score viewer and create practice spots first.'
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ActivePracticeSessionScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start practice: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _navigateToPieceManagement(Project project) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PieceManagementScreen(project: project),
      ),
    );
    
    // If pieces were updated, refresh the projects list
    if (result == true) {
      ref.read(projectsProvider.notifier).refresh();
    }
  }

  /// Get difficulty label text
  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Easy';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Intermediate';
    }
  }

  /// Get color based on piece difficulty level (1-5)
  Color _getDifficultyColor(int difficulty) {
    final colorblindMode = ref.watch(colorblindModeProvider);
    
    if (colorblindMode) {
      // Use colorblind-friendly color scheme
      switch (difficulty) {
        case 1:
          return AppColors.colorblindBlue; // Beginner - Blue
        case 2:
          return AppColors.colorblindPattern1; // Easy - Sea Green
        case 3:
          return AppColors.colorblindPattern3; // Intermediate - Indigo  
        case 4:
          return AppColors.colorblindOrange; // Advanced - Orange
        case 5:
          return AppColors.colorblindRed; // Expert - Dark Red
        default:
          return AppColors.colorblindPattern3; // Default to indigo
      }
    } else {
      // Use standard color scheme
      switch (difficulty) {
        case 1:
          return AppColors.successGreen; // Beginner - Green
        case 2:
          return AppColors.lightPurple; // Easy - Light Purple
        case 3:
          return AppColors.accentPurple; // Intermediate - Medium Purple  
        case 4:
          return AppColors.warningOrange; // Advanced - Orange
        case 5:
          return AppColors.errorRed; // Expert - Red
        default:
          return AppColors.accentPurple; // Default to intermediate
      }
    }
  }
}
