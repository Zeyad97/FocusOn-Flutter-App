import 'package:flutter/material.dart';
import '../../../models/annotation.dart';
import '../../../theme/app_theme.dart';

/// Annotation toolbar for PDF viewer
class AnnotationToolbar extends StatelessWidget {
  final AnnotationTool currentTool;
  final ColorTag currentColorTag;
  final bool isAnnotationMode;
  final Function(AnnotationTool) onToolChanged;
  final Function(ColorTag) onColorChanged;
  final VoidCallback onAnnotationModeToggle;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;

  const AnnotationToolbar({
    super.key,
    required this.currentTool,
    required this.currentColorTag,
    required this.isAnnotationMode,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onAnnotationModeToggle,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main toolbar
          Row(
            children: [
              // Annotation mode toggle
              IconButton(
                onPressed: onAnnotationModeToggle,
                icon: Icon(
                  isAnnotationMode ? Icons.edit : Icons.edit_outlined,
                  color: isAnnotationMode ? AppColors.primaryBlue : Colors.grey,
                ),
                tooltip: 'Toggle Annotation Mode',
              ),
              
              const SizedBox(width: 8),
              
              if (isAnnotationMode) ...[
                // Tool selection
                _ToolButton(
                  tool: AnnotationTool.pen,
                  currentTool: currentTool,
                  onPressed: () => onToolChanged(AnnotationTool.pen),
                  icon: Icons.edit,
                  tooltip: 'Pen',
                ),
                _ToolButton(
                  tool: AnnotationTool.highlighter,
                  currentTool: currentTool,
                  onPressed: () => onToolChanged(AnnotationTool.highlighter),
                  icon: Icons.highlight,
                  tooltip: 'Highlighter',
                ),
                _ToolButton(
                  tool: AnnotationTool.text,
                  currentTool: currentTool,
                  onPressed: () => onToolChanged(AnnotationTool.text),
                  icon: Icons.text_fields,
                  tooltip: 'Text',
                ),
                
                const SizedBox(width: 16),
                
                // Color selection
                Row(
                  children: [
                    _ColorButton(
                      color: ColorTag.yellow,
                      currentColor: currentColorTag,
                      onPressed: () => onColorChanged(ColorTag.yellow),
                    ),
                    const SizedBox(width: 4),
                    _ColorButton(
                      color: ColorTag.blue,
                      currentColor: currentColorTag,
                      onPressed: () => onColorChanged(ColorTag.blue),
                    ),
                    const SizedBox(width: 4),
                    _ColorButton(
                      color: ColorTag.purple,
                      currentColor: currentColorTag,
                      onPressed: () => onColorChanged(ColorTag.purple),
                    ),
                    const SizedBox(width: 4),
                    _ColorButton(
                      color: ColorTag.red,
                      currentColor: currentColorTag,
                      onPressed: () => onColorChanged(ColorTag.red),
                    ),
                    const SizedBox(width: 4),
                    _ColorButton(
                      color: ColorTag.green,
                      currentColor: currentColorTag,
                      onPressed: () => onColorChanged(ColorTag.green),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Action buttons
                IconButton(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo',
                  iconSize: 20,
                ),
                IconButton(
                  onPressed: onRedo,
                  icon: const Icon(Icons.redo),
                  tooltip: 'Redo',
                  iconSize: 20,
                ),
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_all),
                  tooltip: 'Clear All',
                  iconSize: 20,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Tool button widget
class _ToolButton extends StatelessWidget {
  final AnnotationTool tool;
  final AnnotationTool currentTool;
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  const _ToolButton({
    required this.tool,
    required this.currentTool,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = tool == currentTool;
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? AppColors.primaryBlue : Colors.grey.shade600,
        ),
      ),
    );
  }
}

/// Color button widget
class _ColorButton extends StatelessWidget {
  final ColorTag color;
  final ColorTag currentColor;
  final VoidCallback onPressed;

  const _ColorButton({
    required this.color,
    required this.currentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = color == currentColor;
    final colorValue = _getColorValue(color);
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: colorValue,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  Color _getColorValue(ColorTag tag) {
    switch (tag) {
      case ColorTag.yellow:
        return Colors.yellow.shade600;
      case ColorTag.blue:
        return Colors.blue.shade600;
      case ColorTag.purple:
        return Colors.purple.shade600;
      case ColorTag.red:
        return Colors.red.shade600;
      case ColorTag.green:
        return Colors.green.shade600;
    }
  }
}
