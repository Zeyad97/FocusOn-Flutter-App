import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../models/project.dart';
import '../../../models/piece.dart';
import '../../../services/data_service.dart';

class ProjectPiecesManager extends ConsumerStatefulWidget {
  final Project project;

  const ProjectPiecesManager({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<ProjectPiecesManager> createState() => _ProjectPiecesManagerState();
}

class _ProjectPiecesManagerState extends ConsumerState<ProjectPiecesManager> {
  late List<String> _selectedPieceIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPieceIds = List.from(widget.project.pieceIds);
  }

  @override
  Widget build(BuildContext context) {
    final piecesAsync = ref.watch(piecesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Pieces - ${widget.project.name}'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _hasChanges() ? _saveChanges : null,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _hasChanges() ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: piecesAsync.when(
        data: (pieces) {
          if (pieces.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pieces in your library',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add pieces to your library first',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Stats header
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryPurple.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.library_music,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Pieces',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                          Text(
                            '${_selectedPieceIds.length} of ${pieces.length} pieces selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_hasChanges())
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Unsaved',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Selection controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedPieceIds = pieces.map((p) => p.id).toList();
                        });
                      },
                      icon: const Icon(Icons.select_all),
                      label: const Text('Select All'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedPieceIds.clear();
                        });
                      },
                      icon: const Icon(Icons.deselect),
                      label: const Text('Clear All'),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedPieceIds.length} selected',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Pieces list
              Expanded(
                child: ListView.builder(
                  itemCount: pieces.length,
                  itemBuilder: (context, index) {
                    final piece = pieces[index];
                    final isSelected = _selectedPieceIds.contains(piece.id);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      elevation: isSelected ? 4 : 1,
                      color: isSelected 
                          ? AppColors.primaryPurple.withOpacity(0.05)
                          : null,
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedPieceIds.add(piece.id);
                            } else {
                              _selectedPieceIds.remove(piece.id);
                            }
                          });
                        },
                        title: Text(
                          piece.title,
                          style: TextStyle(
                            fontWeight: isSelected 
                                ? FontWeight.w600 
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(piece.composer),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getReadinessColor(piece.readinessPercentage),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${(piece.readinessPercentage * 100).toInt()}% ready',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${piece.spots.length} spots',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        activeColor: AppColors.primaryPurple,
                        dense: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading pieces',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasChanges() {
    return !_listsEqual(_selectedPieceIds, widget.project.pieceIds);
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (!list2.contains(list1[i])) return false;
    }
    for (int i = 0; i < list2.length; i++) {
      if (!list1.contains(list2[i])) return false;
    }
    return true;
  }

  Color _getReadinessColor(double readiness) {
    if (readiness >= 0.8) return AppColors.successGreen;
    if (readiness >= 0.6) return AppColors.warningOrange;
    return AppColors.errorRed;
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProject = widget.project.copyWith(
        pieceIds: _selectedPieceIds,
        updatedAt: DateTime.now(),
      );

      await ref.read(projectsProvider.notifier).updateProject(updatedProject);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated "${widget.project.name}" with ${_selectedPieceIds.length} pieces'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changes were saved
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update project: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
