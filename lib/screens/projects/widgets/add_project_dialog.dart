import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../services/data_service.dart';
import '../../../models/piece.dart';
import '../../../providers/unified_library_provider.dart';

class AddProjectDialog extends ConsumerStatefulWidget {
  const AddProjectDialog({super.key});

  @override
  ConsumerState<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends ConsumerState<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _concertDate;
  Duration _dailyGoal = const Duration(minutes: 30);
  final List<String> _selectedTags = [];
  final List<String> _selectedPieceIds = [];

  final List<String> _availableTags = [
    'Classical',
    'Jazz',
    'Pop',
    'Folk',
    'Recital',
    'Competition',
    'Audition',
    'Wedding',
    'Church',
    'School',
    'Professional',
    'Personal',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.create_new_folder, 
                       color: AppColors.primaryPurple, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create New Project',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Project Title *',
                          hintText: 'e.g., Spring Recital 2025',
                          prefixIcon: Icon(Icons.music_note),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a project title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Describe your project goals...',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Concert Date
                      InkWell(
                        onTap: _selectConcertDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event, color: AppColors.primaryPurple),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Concert/Performance Date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _concertDate != null 
                                        ? '${_concertDate!.day}/${_concertDate!.month}/${_concertDate!.year}'
                                        : 'Select date (Optional)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _concertDate != null 
                                          ? Colors.black 
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_forward_ios, 
                                   color: Colors.grey.shade400, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Daily Practice Goal
                      Text(
                        'Daily Practice Goal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer, color: AppColors.primaryPurple),
                            const SizedBox(width: 12),
                            Text(
                              '${_dailyGoal.inMinutes} minutes per day',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (_dailyGoal.inMinutes > 15) {
                                      setState(() {
                                        _dailyGoal = Duration(minutes: _dailyGoal.inMinutes - 15);
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: AppColors.primaryPurple,
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _dailyGoal = Duration(minutes: _dailyGoal.inMinutes + 15);
                                    });
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: AppColors.primaryPurple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      Text(
                        'Project Tags',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(
                              tag,
                              style: TextStyle(
                                color: isSelected 
                                    ? AppColors.primaryPurple
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                            selectedColor: AppColors.primaryPurple.withOpacity(0.15),
                            backgroundColor: Theme.of(context).chipTheme.backgroundColor ?? 
                                            Theme.of(context).colorScheme.surfaceContainerHighest,
                            checkmarkColor: AppColors.primaryPurple,
                            side: BorderSide(
                              color: isSelected 
                                  ? AppColors.primaryPurple 
                                  : Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Pieces Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Pieces',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _showAddPieceDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add New Piece'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryPurple,
                              side: BorderSide(color: AppColors.primaryPurple),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          final piecesAsync = ref.watch(unifiedLibraryProvider);
                          
                          return piecesAsync.when(
                            data: (pieces) {
                              if (pieces.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'No pieces available. Add pieces to your library first.',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: pieces.length,
                                  itemBuilder: (context, index) {
                                    final piece = pieces[index];
                                    final isSelected = _selectedPieceIds.contains(piece.id);
                                    
                                    return CheckboxListTile(
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
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Text(piece.composer),
                                      activeColor: AppColors.primaryPurple,
                                      dense: true,
                                    );
                                  },
                                ),
                              );
                            },
                            loading: () => Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Loading pieces...'),
                                ],
                              ),
                            ),
                            error: (error, _) => Container(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Error loading pieces: $error',
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            // Fixed Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _createProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Create Project'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectConcertDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _concertDate = date;
      });
    }
  }

  void _createProject() {
    if (_formKey.currentState!.validate()) {
      final projectData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'concertDate': _concertDate,
        'dailyGoal': _dailyGoal,
        'tags': _selectedTags,
        'pieceIds': _selectedPieceIds,
      };

      Navigator.pop(context, projectData);
    }
  }

  Future<void> _showAddPieceDialog() async {
    final pieceDetails = await _showPieceDetailsDialog();
    if (pieceDetails == null) return;

    final now = DateTime.now();
    final newPiece = Piece(
      id: 'manual_${now.millisecondsSinceEpoch}',
      title: pieceDetails['title'],
      composer: pieceDetails['composer'] ?? 'Unknown Composer',
      keySignature: pieceDetails['keySignature'],
      difficulty: pieceDetails['difficulty'],
      tags: ['Manual'],
      pdfFilePath: '', // No PDF file for manual pieces
      spots: [],
      createdAt: now,
      updatedAt: now,
      totalPages: 0,
    );
    
    try {
      await ref.read(unifiedLibraryProvider.notifier).addPiece(newPiece);
      
      // Auto-select the newly created piece
      setState(() {
        _selectedPieceIds.add(newPiece.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Piece "${newPiece.title}" created and added to project!'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create piece: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showPieceDetailsDialog() async {
    final titleController = TextEditingController();
    final composerController = TextEditingController();
    final keyController = TextEditingController();
    int difficulty = 3;
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Piece'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Chopin Nocturne Op. 9 No. 2',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: composerController,
                  decoration: InputDecoration(
                    labelText: 'Composer',
                    hintText: 'e.g., Frédéric Chopin',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(
                    labelText: 'Key Signature',
                    hintText: 'e.g., E♭ major',
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Difficulty: '),
                    Expanded(
                      child: Slider(
                        value: difficulty.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '$difficulty ${_getDifficultyLabel(difficulty)}',
                        onChanged: (value) {
                          setState(() {
                            difficulty = value.round();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'title': titleController.text.trim(),
                    'composer': composerController.text.trim().isEmpty 
                        ? null : composerController.text.trim(),
                    'keySignature': keyController.text.trim().isEmpty 
                        ? null : keyController.text.trim(),
                    'difficulty': difficulty,
                  });
                }
              },
              child: Text('Add Piece'),
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1: return '(Beginner)';
      case 2: return '(Easy)';
      case 3: return '(Intermediate)';
      case 4: return '(Advanced)';
      case 5: return '(Expert)';
      default: return '';
    }
  }
}
