import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../models/piece.dart';
import '../../../providers/unified_library_provider.dart';

class PieceSettingsDialog extends ConsumerStatefulWidget {
  final Piece piece;

  const PieceSettingsDialog({
    super.key,
    required this.piece,
  });

  @override
  ConsumerState<PieceSettingsDialog> createState() => _PieceSettingsDialogState();
}

class _PieceSettingsDialogState extends ConsumerState<PieceSettingsDialog> {
  late TextEditingController _titleController;
  late TextEditingController _composerController;
  late TextEditingController _keyController;
  late int _difficulty;
  late int _duration; // Practice duration in minutes
  late double? _targetTempo;
  late double? _currentTempo;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.piece.title);
    _composerController = TextEditingController(text: widget.piece.composer);
    _keyController = TextEditingController(text: widget.piece.keySignature ?? '');
    _difficulty = widget.piece.difficulty;
    _duration = widget.piece.duration ?? 30; // Default to 30 minutes if not set
    _targetTempo = widget.piece.targetTempo;
    _currentTempo = widget.piece.currentTempo;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Piece Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter piece title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Composer
                    TextField(
                      controller: _composerController,
                      decoration: const InputDecoration(
                        labelText: 'Composer',
                        hintText: 'Enter composer name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Key Signature
                    TextField(
                      controller: _keyController,
                      decoration: const InputDecoration(
                        labelText: 'Key Signature',
                        hintText: 'e.g., C major, A minor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Practice Duration
                    Text(
                      'Practice Duration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryPurple.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target practice time per session: $_duration minutes',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Slider(
                            value: _duration.toDouble(),
                            min: 5,
                            max: 120,
                            divisions: 23,
                            activeColor: AppColors.primaryPurple,
                            label: '$_duration min',
                            onChanged: (value) {
                              setState(() {
                                _duration = value.round();
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '5 min',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '120 min',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Difficulty
                    Text(
                      'Difficulty Level',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final isSelected = index < _difficulty;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _difficulty = index + 1;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Icon(
                              isSelected ? Icons.star : Icons.star_border,
                              color: AppColors.warningOrange,
                              size: 28,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Tempo Settings (if applicable)
                    if (widget.piece.targetTempo != null || widget.piece.currentTempo != null) ...[
                      Text(
                        'Tempo Settings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Target Tempo (BPM)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _targetTempo = double.tryParse(value);
                              },
                              controller: TextEditingController(
                                text: _targetTempo?.toString() ?? '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Current Tempo (BPM)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _currentTempo = double.tryParse(value);
                              },
                              controller: TextEditingController(
                                text: _currentTempo?.toString() ?? '',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Quick Duration Presets
                    Text(
                      'Quick Presets',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [15, 30, 45, 60, 90].map((minutes) {
                        final isSelected = _duration == minutes;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _duration = minutes;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryPurple
                                  : AppColors.primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryPurple.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '${minutes}m',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
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
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    try {
      // Create updated piece with new values
      final updatedPiece = widget.piece.copyWith(
        title: _titleController.text.trim(),
        composer: _composerController.text.trim(),
        keySignature: _keyController.text.trim().isEmpty ? null : _keyController.text.trim(),
        difficulty: _difficulty,
        duration: _duration,
        targetTempo: _targetTempo,
        currentTempo: _currentTempo,
        updatedAt: DateTime.now(),
      );

      // Update the piece in the provider
      await ref.read(unifiedLibraryProvider.notifier).updatePiece(updatedPiece);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate changes were saved
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved for "${updatedPiece.title}"'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}
