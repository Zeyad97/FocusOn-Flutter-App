import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/annotation.dart' as AppAnnotation;
import '../../../theme/app_theme.dart';

/// Enhanced annotation toolbar with comprehensive tools and layer support
class AnnotationToolbar extends StatefulWidget {
  final AppAnnotation.AnnotationTool currentTool;
  final AppAnnotation.ColorTag currentColorTag;
  final bool isAnnotationMode;
  final Function(AppAnnotation.AnnotationTool) onToolChanged;
  final Function(AppAnnotation.ColorTag) onColorChanged;
  final VoidCallback onAnnotationModeToggle;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final List<AppAnnotation.AnnotationLayer>? layers;
  final AppAnnotation.AnnotationLayer? selectedLayer;
  final String? selectedLayerId;
  final AppAnnotation.StampType? selectedStamp;
  final Function(AppAnnotation.AnnotationLayer)? onLayerSelected;
  final Function(String)? onLayerChanged;
  final Function(AppAnnotation.StampType)? onStampSelected;

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
    this.layers,
    this.selectedLayer,
    this.selectedLayerId,
    this.selectedStamp,
    this.onLayerSelected,
    this.onLayerChanged,
    this.onStampSelected,
  });

  @override
  State<AnnotationToolbar> createState() => _AnnotationToolbarState();
}

class _AnnotationToolbarState extends State<AnnotationToolbar> {
  bool _showStampPalette = false;
  bool _showLayerSelector = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Annotation mode toggle
                _buildModeToggle(),
                
                if (widget.isAnnotationMode) ...[
                  const SizedBox(width: 16),
                  _buildDivider(),
                  const SizedBox(width: 16),
                  
                  // Tool selection
                  _buildToolButtons(),
                  
                  const SizedBox(width: 16),
                  _buildDivider(),
                  const SizedBox(width: 16),
                  
                  // Color selection
                  _buildColorPalette(),
                  
                  const SizedBox(width: 16),
                  _buildDivider(),
                  const SizedBox(width: 16),
                  
                  // Layer selection (if layers are provided)
                  if (widget.layers != null) ...[
                    _buildLayerSelector(),
                    const SizedBox(width: 16),
                    _buildDivider(),
                    const SizedBox(width: 16),
                  ],
                  
                  // Action buttons
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
          
          // Floating stamp palette
          if (_showStampPalette && widget.currentTool == AppAnnotation.AnnotationTool.stamp) 
            Positioned(
              bottom: 70,
              left: 16,
              child: StampPalette(
                onStampSelected: (stamp) {
                  widget.onStampSelected?.call(stamp);
                  setState(() {
                    _showStampPalette = false;
                  });
                },
                onClose: () {
                  setState(() {
                    _showStampPalette = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isAnnotationMode ? AppColors.primaryBlue.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isAnnotationMode ? AppColors.primaryBlue : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onAnnotationModeToggle();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit,
                size: 18,
                color: widget.isAnnotationMode ? AppColors.primaryBlue : AppColors.text.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                widget.isAnnotationMode ? 'Exit Annotations' : 'Annotate',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.isAnnotationMode ? AppColors.primaryBlue : AppColors.text.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButtons() {
    return Row(
      children: AppAnnotation.AnnotationTool.values.map((tool) {
        final isSelected = tool == widget.currentTool;
        
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              if (tool == AppAnnotation.AnnotationTool.stamp) {
                setState(() {
                  _showStampPalette = !_showStampPalette;
                });
              } else {
                setState(() {
                  _showStampPalette = false;
                });
              }
              widget.onToolChanged(tool);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getToolIcon(tool),
                    size: 18,
                    color: isSelected ? AppColors.primaryBlue : AppColors.text.withOpacity(0.7),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getToolName(tool),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryBlue : AppColors.text.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPalette() {
    return Row(
      children: AppAnnotation.ColorTag.values.map((colorTag) {
        final isSelected = colorTag == widget.currentColorTag;
        final color = _getColorFromTag(colorTag);
        
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onColorChanged(colorTag);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  colorTag.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getContrastColor(color),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLayerSelector() {
    return InkWell(
      onTap: () {
        setState(() {
          _showLayerSelector = !_showLayerSelector;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.layers,
              size: 16,
              color: AppColors.text.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              widget.selectedLayer?.name ?? 'Layer',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showLayerSelector ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: AppColors.text.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Undo
        _buildActionButton(
          icon: Icons.undo,
          label: 'Undo',
          onTap: widget.onUndo,
        ),
        
        const SizedBox(width: 8),
        
        // Redo
        _buildActionButton(
          icon: Icons.redo,
          label: 'Redo',
          onTap: widget.onRedo,
        ),
        
        const SizedBox(width: 8),
        
        // Clear all
        _buildActionButton(
          icon: Icons.clear_all,
          label: 'Clear',
          onTap: () {
            HapticFeedback.mediumImpact();
            _showClearConfirmation();
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDestructive ? Colors.red.shade600 : AppColors.text.withOpacity(0.7),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDestructive ? Colors.red.shade600 : AppColors.text.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey.shade300,
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Annotations?'),
        content: const Text('This action cannot be undone. All annotations on the current page will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onClear();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getToolIcon(AppAnnotation.AnnotationTool tool) {
    switch (tool) {
      case AppAnnotation.AnnotationTool.pen:
        return Icons.edit;
      case AppAnnotation.AnnotationTool.highlighter:
        return Icons.highlight;
      case AppAnnotation.AnnotationTool.eraser:
        return Icons.cleaning_services;
      case AppAnnotation.AnnotationTool.text:
        return Icons.text_fields;
      case AppAnnotation.AnnotationTool.stamp:
        return Icons.label;
    }
  }

  String _getToolName(AppAnnotation.AnnotationTool tool) {
    switch (tool) {
      case AppAnnotation.AnnotationTool.pen:
        return 'Pen';
      case AppAnnotation.AnnotationTool.highlighter:
        return 'Highlight';
      case AppAnnotation.AnnotationTool.eraser:
        return 'Eraser';
      case AppAnnotation.AnnotationTool.text:
        return 'Text';
      case AppAnnotation.AnnotationTool.stamp:
        return 'Stamp';
    }
  }

  Color _getColorFromTag(AppAnnotation.ColorTag tag) {
    switch (tag) {
      case AppAnnotation.ColorTag.red:
        return Colors.red;
      case AppAnnotation.ColorTag.blue:
        return Colors.blue;
      case AppAnnotation.ColorTag.yellow:
        return Colors.yellow.shade700;
      case AppAnnotation.ColorTag.green:
        return Colors.green;
      case AppAnnotation.ColorTag.purple:
        return Colors.purple;
    }
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if we need dark or light text
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Floating stamp palette for stamp tool selection
class StampPalette extends StatelessWidget {
  final Function(AppAnnotation.StampType) onStampSelected;
  final VoidCallback onClose;

  const StampPalette({
    super.key,
    required this.onStampSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Stamp',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.text.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Stamp grid
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: AppAnnotation.StampType.values.map((stampType) {
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onStampSelected(stampType);
                  onClose();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getStampIcon(stampType),
                        size: 24,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStampName(stampType),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getStampIcon(AppAnnotation.StampType stampType) {
    switch (stampType) {
      case AppAnnotation.StampType.fingering1:
      case AppAnnotation.StampType.fingering2:
      case AppAnnotation.StampType.fingering3:
      case AppAnnotation.StampType.fingering4:
      case AppAnnotation.StampType.fingering5:
        return Icons.touch_app;
      case AppAnnotation.StampType.pedal:
        return Icons.horizontal_rule;
      case AppAnnotation.StampType.bowingUp:
        return Icons.keyboard_arrow_up;
      case AppAnnotation.StampType.bowingDown:
        return Icons.keyboard_arrow_down;
      case AppAnnotation.StampType.accent:
        return Icons.keyboard_arrow_up;
      case AppAnnotation.StampType.rehearsalLetter:
        return Icons.font_download;
    }
  }

  String _getStampName(AppAnnotation.StampType stampType) {
    switch (stampType) {
      case AppAnnotation.StampType.fingering1: return '1';
      case AppAnnotation.StampType.fingering2: return '2';
      case AppAnnotation.StampType.fingering3: return '3';
      case AppAnnotation.StampType.fingering4: return '4';
      case AppAnnotation.StampType.fingering5: return '5';
      case AppAnnotation.StampType.pedal: return 'Pedal';
      case AppAnnotation.StampType.bowingUp: return 'Up Bow';
      case AppAnnotation.StampType.bowingDown: return 'Down';
      case AppAnnotation.StampType.accent: return 'Accent';
      case AppAnnotation.StampType.rehearsalLetter: return 'Letter';
    }
  }
}
