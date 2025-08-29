import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/project.dart';
import '../../models/piece.dart';
import '../../services/data_service.dart';
import '../../providers/unified_library_provider.dart';
import '../library/widgets/import_pdf_dialog.dart';
import 'widgets/project_import_pdf_dialog.dart';
import '../../utils/snackbar_utils.dart';

class PieceManagementScreen extends ConsumerStatefulWidget {
  final Project project;

  const PieceManagementScreen({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<PieceManagementScreen> createState() => _PieceManagementScreenState();
}

class _PieceManagementScreenState extends ConsumerState<PieceManagementScreen> {
  late Set<String> selectedPieces;
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    selectedPieces = Set<String>.from(widget.project.pieceIds);
    print('PieceManagement: Initial selected pieces: ${selectedPieces.toList()}');
  }

  @override
  Widget build(BuildContext context) {
    final piecesAsync = ref.watch(unifiedLibraryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('Manage Pieces'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryPurple,
                  AppColors.accentPurple,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.project.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${selectedPieces.length} pieces selected',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                if (widget.project.concertDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Concert: ${widget.project.concertDate!.day}/${widget.project.concertDate!.month}/${widget.project.concertDate!.year}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Search and Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search pieces...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    onChanged: (value) {
                      // TODO: Implement search
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showAddPieceDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Piece'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPurple,
                    side: BorderSide(color: AppColors.primaryPurple),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedPieces.clear();
                      hasChanges = !_setsEqual(selectedPieces, Set.from(widget.project.pieceIds));
                      print('Cleared all selections');
                      print('Has changes: $hasChanges');
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  tooltip: 'Clear all selections',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pieces List
          Expanded(
            child: piecesAsync.when(
              data: (pieces) {
                if (pieces.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pieces in your library',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add pieces to your library first',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Selection controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                selectedPieces = pieces.map((p) => p.id).toSet();
                                hasChanges = !_setsEqual(selectedPieces, Set.from(widget.project.pieceIds));
                                print('Selected all pieces: ${selectedPieces.toList()}');
                                print('Has changes: $hasChanges');
                              });
                            },
                            icon: const Icon(Icons.select_all, size: 18),
                            label: const Text('Select All'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryPurple,
                              side: BorderSide(color: AppColors.primaryPurple),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${selectedPieces.length} of ${pieces.length} selected',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pieces list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100), // Extra padding for FAB
                        itemCount: pieces.length,
                        itemBuilder: (context, index) {
                          final piece = pieces[index];
                          final isSelected = selectedPieces.contains(piece.id);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedPieces.add(piece.id);
                                  } else {
                                    selectedPieces.remove(piece.id);
                                  }
                                  hasChanges = !_setsEqual(selectedPieces, Set.from(widget.project.pieceIds));
                                  print('Piece ${piece.title} ${value == true ? 'selected' : 'deselected'}');
                                  print('Selected pieces: ${selectedPieces.toList()}');
                                  print('Has changes: $hasChanges');
                                });
                              },
                        title: Text(
                          piece.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'by ${piece.composer}',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${piece.spots.length} spots • ${piece.readinessPercentage.toInt()}% ready',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                        activeColor: AppColors.primaryPurple,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        controlAffinity: ListTileControlAffinity.leading,
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
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading pieces',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: hasChanges
          ? FloatingActionButton.extended(
              onPressed: _saveChanges,
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  bool _setsEqual(Set<String> set1, Set<String> set2) {
    return set1.length == set2.length && set1.containsAll(set2);
  }

  Future<void> _saveChanges() async {
    try {
      print('Saving changes: ${selectedPieces.length} pieces selected');
      print('Selected piece IDs: ${selectedPieces.toList()}');
      print('Original project piece IDs: ${widget.project.pieceIds}');
      
      final updatedProject = widget.project.copyWith(
        pieceIds: selectedPieces.toList(),
        updatedAt: DateTime.now(),
      );

      print('Updating project with piece IDs: ${updatedProject.pieceIds}');
      await ref.read(projectsProvider.notifier).updateProject(updatedProject);
      print('Project updated successfully');

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Project updated with ${selectedPieces.length} pieces');
        Navigator.pop(context, true); // Return true to indicate changes were saved
      }
    } catch (e) {
      print('Error saving changes: $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to save changes: $e');
      }
    }
  }

  Future<void> _showAddPieceDialog() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Piece to Project'),
        content: const Text('How would you like to add a piece?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'library'),
            child: const Text('From Library'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'file'),
            child: const Text('Import PDF'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: const Text('Manual Entry'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    switch (choice) {
      case 'library':
        await _showLibraryPieceSelector();
        break;
      case 'file':
        await _showImportPDFDialog();
        break;
      case 'manual':
        await _createManualPiece();
        break;
    }
  }

  Future<void> _showLibraryPieceSelector() async {
    final libraryState = ref.read(unifiedLibraryProvider);
    if (!libraryState.hasValue) return;
    
    final allPieces = libraryState.value!;
    final availablePieces = allPieces.where(
      (piece) => !selectedPieces.contains(piece.id)
    ).toList();

    if (availablePieces.isEmpty) {
      if (mounted) {
        SnackBarUtils.showWarning(context, 'All library pieces are already in this project');
      }
      return;
    }

    final selectedPiece = await showDialog<Piece>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select from Library'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availablePieces.length,
            itemBuilder: (context, index) {
              final piece = availablePieces[index];
              return ListTile(
                title: Text(piece.title),
                subtitle: Text(piece.composer),
                onTap: () => Navigator.pop(context, piece),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedPiece != null) {
      setState(() {
        selectedPieces.add(selectedPiece.id);
        hasChanges = !_setsEqual(selectedPieces, Set.from(widget.project.pieceIds));
      });

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Added "${selectedPiece.title}" to project');
      }
    }
  }

  Future<void> _showImportPDFDialog() async {
    final newPiece = await showDialog<Piece>(
      context: context,
      builder: (context) => ProjectImportPDFDialog(projectId: widget.project.id),
    );

    if (newPiece != null) {
      try {
        // Update piece with project context (inherit project details)
        final updatedPiece = newPiece.copyWith(
          projectId: widget.project.id,
          // Inherit project metadata if available
          // duration: widget.project.duration,
          // genre: widget.project.genre,
          // concertDate: widget.project.concertDate,
        );
        
        await ref.read(unifiedLibraryProvider.notifier).addPiece(updatedPiece);
        
        setState(() {
          selectedPieces.add(updatedPiece.id);
          hasChanges = !_setsEqual(selectedPieces, Set.from(widget.project.pieceIds));
        });

        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Imported "${updatedPiece.title}" and added to project');
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Failed to import piece: $e');
        }
      }
    }
  }

  Future<void> _createManualPiece() async {
    final pieceDetails = await _showPieceDetailsDialog();
    if (pieceDetails == null) return;

    final now = DateTime.now();
    final newPiece = Piece(
      id: 'manual_${now.millisecondsSinceEpoch}',
      title: pieceDetails['title'],
      composer: pieceDetails['composer'] ?? 'Unknown Composer',
      keySignature: pieceDetails['keySignature'],
      difficulty: pieceDetails['difficulty'],
      pdfFilePath: '', // No PDF file for manual pieces
      spots: [],
      createdAt: now,
      updatedAt: now,
      totalPages: 0,
    );
    
    print('Creating new piece with ID: ${newPiece.id}');
    print('Selected pieces before adding: ${selectedPieces.toList()}');
    
    try {
      await ref.read(unifiedLibraryProvider.notifier).addPiece(newPiece);
      print('Piece added to library successfully');
      
      // Auto-select the newly created piece for this project
      setState(() {
        selectedPieces.add(newPiece.id);
        hasChanges = !_setsEqual(selectedPieces, Set.from(widget.project.pieceIds));
        print('Selected pieces after adding: ${selectedPieces.toList()}');
        print('Has changes: $hasChanges');
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Piece "${newPiece.title}" created and selected!'),
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
                    hintText: 'e.g., Bach Invention No. 8',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: composerController,
                  decoration: InputDecoration(
                    labelText: 'Composer',
                    hintText: 'e.g., Johann Sebastian Bach',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(
                    labelText: 'Key Signature',
                    hintText: 'e.g., F major',
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
