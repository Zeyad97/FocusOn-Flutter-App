import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../services/piece_service.dart';
import '../../../services/database_service.dart';
import '../../../models/piece.dart';

/// Simplified dialog for importing PDF files in project context
class ProjectImportPDFDialog extends StatefulWidget {
  final String? projectId;
  
  const ProjectImportPDFDialog({
    super.key,
    this.projectId,
  });

  @override
  State<ProjectImportPDFDialog> createState() => _ProjectImportPDFDialogState();
}

class _ProjectImportPDFDialogState extends State<ProjectImportPDFDialog> {
  final _titleController = TextEditingController();
  final _composerController = TextEditingController();
  int _difficulty = 3;
  String? _selectedFilePath;
  bool _isImporting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFilePath = result.files.first.path;
          
          // Try to extract title from filename
          if (_titleController.text.isEmpty) {
            final fileName = result.files.first.name;
            final titleFromFile = fileName
                .replaceAll('.pdf', '')
                .replaceAll('_', ' ')
                .replaceAll('-', ' ');
            _titleController.text = titleFromFile;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _import() async {
    if (_selectedFilePath == null || _titleController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      // Simulate processing the PDF
      await Future.delayed(const Duration(seconds: 1));

      final newPiece = Piece(
        id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        composer: _composerController.text.trim().isEmpty 
            ? 'Unknown Composer' 
            : _composerController.text.trim(),
        difficulty: _difficulty,
        pdfFilePath: _selectedFilePath!,
        projectId: widget.projectId,
        spots: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        Navigator.of(context).pop(newPiece); // Return the new piece
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canImport = _selectedFilePath != null && 
                     _titleController.text.trim().isNotEmpty &&
                     !_isImporting;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 450,
          maxHeight: 600, // Limit height to prevent overflow
        ),
        child: SingleChildScrollView( // Make it scrollable
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.library_add,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Import PDF Score',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // File selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFilePath != null 
                          ? AppColors.successGreen 
                          : AppColors.textSecondary.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFilePath != null ? Icons.check_circle : Icons.upload_file,
                        size: 48,
                        color: _selectedFilePath != null 
                            ? AppColors.successGreen 
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFilePath != null 
                            ? 'PDF selected' 
                            : 'Select PDF file',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_selectedFilePath != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _selectedFilePath!.split('\\').last.split('/').last,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isImporting ? null : _selectFile,
                        icon: const Icon(Icons.folder_open),
                        label: Text(_selectedFilePath != null ? 'Change File' : 'Browse Files'),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title field
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Chopin Nocturne Op. 9 No. 2',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isImporting,
                ),
                
                const SizedBox(height: 16),
                
                // Composer field
                TextField(
                  controller: _composerController,
                  decoration: const InputDecoration(
                    labelText: 'Composer',
                    hintText: 'e.g., Frédéric Chopin',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isImporting,
                ),
                
                const SizedBox(height: 16),
                
                // Difficulty slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Difficulty:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _difficulty.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: '$_difficulty',
                            onChanged: _isImporting ? null : (value) {
                              setState(() {
                                _difficulty = value.round();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < _difficulty ? Icons.star : Icons.star_border,
                              size: 16,
                              color: AppColors.warningOrange,
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Note about project context
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This piece will inherit duration, genre, and concert date from the project.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: canImport ? _import : null,
                        child: _isImporting 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Import'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
