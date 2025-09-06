import 'package:flutter/material.dart';
import '../../../models/annotation.dart' as AppAnnotation;
import '../../../theme/app_theme.dart';

/// Enhanced annotation toolbar for PDF viewer
class AnnotationToolbar extends StatefulWidget {
  final AppAnnotation.AnnotationTool currentTool;
  final AppAnnotation.ColorTag currentColorTag;
  final String? selectedLayerId;
  final AppAnnotation.StampType? selectedStamp;
  final bool isAnnotationMode;
  final Function(AppAnnotation.AnnotationTool) onToolChanged;
  final Function(AppAnnotation.ColorTag) onColorChanged;
  final Function(String) onLayerChanged;
  final Function(AppAnnotation.StampType) onStampSelected;
  final VoidCallback onAnnotationModeToggle;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final Function(String, Offset)? onTextInput; // For text input
  final VoidCallback? onShowFilters; // For showing filters
  final VoidCallback? onShowLayers; // For showing layers

  const AnnotationToolbar({
    super.key,
    required this.currentTool,
    required this.currentColorTag,
    required this.selectedLayerId,
    required this.selectedStamp,
    required this.isAnnotationMode,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onLayerChanged,
    required this.onStampSelected,
    required this.onAnnotationModeToggle,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    this.onTextInput,
    this.onShowFilters,
    this.onShowLayers,
  });

  @override
  State<AnnotationToolbar> createState() => _AnnotationToolbarState();
}

class _AnnotationToolbarState extends State<AnnotationToolbar> {
  bool _showStampSelector = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main toolbar
          _buildMainToolbar(),
          
          // Stamp selector (shown when stamp tool is selected)
          if (_showStampSelector) ...[
            const SizedBox(height: 8),
            _buildStampSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildMainToolbar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle annotation mode
        _buildToolButton(
          icon: widget.isAnnotationMode ? Icons.check_circle : Icons.edit_off,
          isSelected: widget.isAnnotationMode,
          tooltip: 'Toggle Annotation Mode',
          onPressed: widget.onAnnotationModeToggle,
          color: widget.isAnnotationMode ? AppColors.primaryPurple : Colors.grey,
        ),
        
        const SizedBox(width: 8),
        
        // Scrollable tools section
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(), // Always allow scrolling
            child: Row(
              children: [
                // Drawing tools
                _buildToolButton(
                  icon: Icons.edit,
                  isSelected: widget.currentTool == AppAnnotation.AnnotationTool.pen,
                  tooltip: 'Pen',
                  onPressed: () {
                    setState(() => _showStampSelector = false);
                    widget.onToolChanged(AppAnnotation.AnnotationTool.pen);
                  },
                ),
                const SizedBox(width: 4),
                
                _buildToolButton(
                  icon: Icons.highlight,
                  isSelected: widget.currentTool == AppAnnotation.AnnotationTool.highlighter,
                  tooltip: 'Highlighter',
                  onPressed: () {
                    setState(() => _showStampSelector = false);
                    widget.onToolChanged(AppAnnotation.AnnotationTool.highlighter);
                  },
                ),
                const SizedBox(width: 4),
                
                _buildToolButton(
                  icon: Icons.cleaning_services,
                  isSelected: widget.currentTool == AppAnnotation.AnnotationTool.eraser,
                  tooltip: 'Eraser',
                  onPressed: () {
                    setState(() => _showStampSelector = false);
                    widget.onToolChanged(AppAnnotation.AnnotationTool.eraser);
                  },
                ),
                const SizedBox(width: 4),
                
                _buildToolButton(
                  icon: Icons.text_fields,
                  isSelected: widget.currentTool == AppAnnotation.AnnotationTool.text,
                  tooltip: 'Text',
                  onPressed: () {
                    setState(() => _showStampSelector = false);
                    widget.onToolChanged(AppAnnotation.AnnotationTool.text);
                    // Remove automatic text dialog - wait for user to tap on PDF
                  },
                ),
                const SizedBox(width: 4),
                
                _buildToolButton(
                  icon: Icons.push_pin,
                  isSelected: widget.currentTool == AppAnnotation.AnnotationTool.stamp,
                  tooltip: 'Stamp',
                  onPressed: () {
                    widget.onToolChanged(AppAnnotation.AnnotationTool.stamp);
                    setState(() => _showStampSelector = !_showStampSelector);
                  },
                ),
                const SizedBox(width: 12),
                
                // Color picker
                ...AppAnnotation.ColorTag.values.map((colorTag) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _buildColorButton(colorTag),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Action buttons
                _buildActionButton(
                  icon: Icons.undo,
                  tooltip: 'Undo',
                  onPressed: widget.onUndo,
                ),
                const SizedBox(width: 4),
                
                _buildActionButton(
                  icon: Icons.redo,
                  tooltip: 'Redo',
                  onPressed: widget.onRedo,
                ),
                const SizedBox(width: 4),
                
                _buildActionButton(
                  icon: Icons.clear_all,
                  tooltip: 'Clear All',
                  onPressed: widget.onClear,
                  color: AppColors.errorRed,
                ),
                const SizedBox(width: 8),
                
                // Filter and layer buttons
                if (widget.onShowFilters != null) ...[
                  _buildActionButton(
                    icon: Icons.filter_list,
                    tooltip: 'Show Filters',
                    onPressed: widget.onShowFilters!,
                  ),
                  const SizedBox(width: 4),
                ],
                
                if (widget.onShowLayers != null) ...[
                  _buildActionButton(
                    icon: Icons.layers,
                    tooltip: 'Show Layers',
                    onPressed: widget.onShowLayers!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStampSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Stamps:',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 8),
          ...AppAnnotation.StampType.values.map((stamp) => 
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildStampButton(stamp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected 
                ? (color ?? AppColors.primaryPurple).withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? (color ?? AppColors.primaryPurple)
                  : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected 
                ? (color ?? AppColors.primaryPurple)
                : Colors.white.withOpacity(0.8),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color ?? Colors.white.withOpacity(0.8),
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(AppAnnotation.ColorTag colorTag) {
    final color = _getColorFromTag(colorTag);
    final isSelected = widget.currentColorTag == colorTag;
    
    return Tooltip(
      message: colorTag.name.toUpperCase(),
      child: GestureDetector(
        onTap: () => widget.onColorChanged(colorTag),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  color: _getContrastColor(color),
                  size: 16,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStampButton(AppAnnotation.StampType stamp) {
    final isSelected = widget.selectedStamp == stamp;
    
    return Tooltip(
      message: stamp.name,
      child: GestureDetector(
        onTap: () => widget.onStampSelected(stamp),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPurple.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.primaryPurple : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              _getStampSymbol(stamp),
              style: TextStyle(
                color: isSelected ? AppColors.primaryPurple : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTextInputDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String text = '';
        return AlertDialog(
          title: const Text('Add Text Annotation'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter your text...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => text = value,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (text.isNotEmpty && widget.onTextInput != null) {
                  // Use center of screen as default position
                  final size = MediaQuery.of(context).size;
                  widget.onTextInput!(text, Offset(size.width / 2, size.height / 2));
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Color _getColorFromTag(AppAnnotation.ColorTag colorTag) {
    switch (colorTag) {
      case AppAnnotation.ColorTag.yellow:
        return Colors.yellow;
      case AppAnnotation.ColorTag.blue:
        return Colors.blue;
      case AppAnnotation.ColorTag.purple:
        return Colors.purple;
      case AppAnnotation.ColorTag.red:
        return Colors.red;
      case AppAnnotation.ColorTag.green:
        return Colors.green;
    }
  }

  Color _getContrastColor(Color color) {
    // Calculate if we need white or black text on this color
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  String _getStampSymbol(AppAnnotation.StampType stamp) {
    switch (stamp) {
      case AppAnnotation.StampType.fingering1:
        return '1';
      case AppAnnotation.StampType.fingering2:
        return '2';
      case AppAnnotation.StampType.fingering3:
        return '3';
      case AppAnnotation.StampType.fingering4:
        return '4';
      case AppAnnotation.StampType.fingering5:
        return '5';
      case AppAnnotation.StampType.pedal:
        return 'P';
      case AppAnnotation.StampType.bowingUp:
        return '↑';
      case AppAnnotation.StampType.bowingDown:
        return '↓';
      case AppAnnotation.StampType.accent:
        return '>';
      case AppAnnotation.StampType.rehearsalLetter:
        return 'A';
    }
  }
}
