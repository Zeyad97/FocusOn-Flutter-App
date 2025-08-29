import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../services/piece_service.dart';
import '../../../services/database_service.dart';
import '../../../models/piece.dart';

/// Dialog for importing PDF files
class ImportPDFDialog extends StatefulWidget {
  const ImportPDFDialog({super.key});

  @override
  State<ImportPDFDialog> createState() => _ImportPDFDialogState();
}

class _ImportPDFDialogState extends State<ImportPDFDialog> {final _titleController = TextEditingController();
  final _composerController = TextEditingController();
  final _durationController = TextEditingController();
  final _genreController = TextEditingController();
  int _difficulty = 3;
  DateTime? _concertDate;
  String? _selectedFilePath;
  bool _isImporting = false;
  String? _selectedMusicStyle; // Removed music styles

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();_durationController.dispose();
    _genreController.dispose();
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
      await Future.delayed(const Duration(seconds: 2));// Import piece with song info like Lovable
      final databaseService = DatabaseService();
      final pieceService = PieceService(databaseService);// Show import confirmation dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Piece Imported'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: ${_titleController.text.trim()}'),
              Text('Composer: ${_composerController.text.trim()}'),
              Text('Duration: ${_durationController.text.trim() + ' mins'}'),
              Text('Difficulty: $_difficulty/5'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      final newPiece = Piece(
        id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        composer: _composerController.text.trim(),
        difficulty: _difficulty,
        duration: int.tryParse(_durationController.text.trim()) ?? 0,
        genre: _genreController.text.trim(),
        pdfFilePath: _selectedFilePath!,
        concertDate: _concertDate,
        spots: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await pieceService.savePiece(newPiece);

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PDF imported successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_titleController.text} is now in your library',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Navigate to the newly imported piece
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Import failed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Error: $e',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
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

  Future<void> _selectConcertDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _concertDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _concertDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canImport = _selectedFilePath != null && 
                     _titleController.text.trim().isNotEmpty &&
                     !_isImporting;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
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
                Text(
                  'Import PDF Score',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
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
                      _selectedFilePath!.split('/').last,
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
            
            // Genre field
            TextField(
              controller: _genreController,
              decoration: const InputDecoration(
                labelText: 'Genre',
                hintText: 'e.g., Classical, Jazz',
                border: OutlineInputBorder(),
              ),
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
            
            // Duration field
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duration',
                hintText: 'e.g., 5 minutes',
                border: OutlineInputBorder(),
              ),
              enabled: !_isImporting,
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 16),
            
            // Difficulty slider
            Row(
              children: [
                Text(
                  'Difficulty:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 16),
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
                ...List.generate(5, (index) {
                  return Icon(
                    index < _difficulty ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppColors.warningOrange,
                  );
                }),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Concert date
            InkWell(
              onTap: _isImporting ? null : _selectConcertDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.textSecondary.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: _concertDate != null 
                          ? AppColors.primaryBlue 
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _concertDate != null 
                            ? 'Concert: ${_formatDate(_concertDate!)}'
                            : 'Set concert date (optional)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _concertDate != null 
                              ? null 
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (_concertDate != null)
                      IconButton(
                        onPressed: _isImporting ? null : () {
                          setState(() {
                            _concertDate = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        iconSize: 16,
                      ),
                  ],
                ),
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
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

