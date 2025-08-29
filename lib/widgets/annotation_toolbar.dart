import 'package:flutter/material.dart';
import '../models/annotation.dart';

/// Advanced annotation toolbar with pencil-first approach
class AnnotationToolbar extends StatefulWidget {
  final AnnotationTool selectedTool;
  final ColorTag selectedColorTag;
  final String? selectedLayerId;
  final List<AnnotationLayer> availableLayers;
  final AnnotationFilter currentFilter;
  final Function(AnnotationTool) onToolChanged;
  final Function(ColorTag) onColorTagChanged;
  final Function(String) onLayerChanged;
  final Function(AnnotationFilter) onFilterChanged;
  final VoidCallback onLayerManager;
  final VoidCallback onFilterPanel;

  const AnnotationToolbar({
    super.key,
    required this.selectedTool,
    required this.selectedColorTag,
    required this.selectedLayerId,
    required this.availableLayers,
    required this.currentFilter,
    required this.onToolChanged,
    required this.onColorTagChanged,
    required this.onLayerChanged,
    required this.onFilterChanged,
    required this.onLayerManager,
    required this.onFilterPanel,
  });

  @override
  State<AnnotationToolbar> createState() => _AnnotationToolbarState();
}

class _AnnotationToolbarState extends State<AnnotationToolbar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isExpanded ? _buildExpandedToolbar() : _buildCompactToolbar(),
    );
  }

  Widget _buildCompactToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current tool indicator
          _buildToolButton(widget.selectedTool, isSelected: true),
          const SizedBox(width: 8),
          
          // Color tag indicator
          _buildColorTagIndicator(),
          const SizedBox(width: 8),
          
          // Expand button
          IconButton(
            icon: const Icon(Icons.expand_more, color: Colors.white),
            onPressed: () => setState(() => _isExpanded = true),
            tooltip: 'Expand toolbar',
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedToolbar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with collapse button
          Row(
            children: [
              const Text(
                'Annotation Tools',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.expand_less, color: Colors.white),
                onPressed: () => setState(() => _isExpanded = false),
                tooltip: 'Collapse toolbar',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Tools row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToolButton(AnnotationTool.pen),
              const SizedBox(width: 4),
              _buildToolButton(AnnotationTool.highlighter),
              const SizedBox(width: 4),
              _buildToolButton(AnnotationTool.eraser),
              const SizedBox(width: 4),
              _buildToolButton(AnnotationTool.text),
              const SizedBox(width: 4),
              _buildToolButton(AnnotationTool.stamp),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Color tags row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: ColorTag.values.map((tag) => 
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _buildColorTagButton(tag),
              ),
            ).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // Layer and filter controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick filter chips
              _buildQuickFilterChips(),
              const SizedBox(width: 8),
              
              // Layer selector
              _buildLayerSelector(),
              const SizedBox(width: 8),
              
              // Layer manager
              IconButton(
                icon: const Icon(Icons.layers, color: Colors.white),
                onPressed: widget.onLayerManager,
                tooltip: 'Manage layers',
              ),
              
              // Filter indicator and button
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: widget.onFilterPanel,
                    tooltip: 'Filter annotations',
                  ),
                  if (widget.currentFilter.isActive)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(AnnotationTool tool, {bool? isSelected}) {
    final selected = isSelected ?? (widget.selectedTool == tool);
    return Container(
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? Colors.blue : Colors.white30,
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(_getToolIcon(tool), color: Colors.white),
        onPressed: () => widget.onToolChanged(tool),
        tooltip: _getToolTooltip(tool),
      ),
    );
  }

  Widget _buildColorTagButton(ColorTag colorTag) {
    final selected = widget.selectedColorTag == colorTag;
    final color = _getColorFromTag(colorTag);
    
    return GestureDetector(
      onTap: () => widget.onColorTagChanged(colorTag),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.white30,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  Widget _buildColorTagIndicator() {
    final color = _getColorFromTag(widget.selectedColorTag);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30),
      ),
    );
  }

  Widget _buildQuickFilterChips() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Today chip
        _buildQuickFilterChip(
          'Today',
          Icons.today,
          widget.currentFilter.showToday,
          () {
            final newFilter = widget.currentFilter.copyWith(
              showToday: !widget.currentFilter.showToday,
              showLast7Days: false,
              showAll: false,
            );
            widget.onFilterChanged(newFilter);
          },
        ),
        const SizedBox(width: 4),
        
        // Critical color chip
        _buildQuickFilterChip(
          'Critical',
          Icons.warning,
          widget.currentFilter.colorTags?.contains(ColorTag.red) ?? false,
          () {
            final currentColors = widget.currentFilter.colorTags?.toSet() ?? <ColorTag>{};
            if (currentColors.contains(ColorTag.red)) {
              currentColors.remove(ColorTag.red);
            } else {
              currentColors.add(ColorTag.red);
            }
            final newFilter = widget.currentFilter.copyWith(
              colorTags: currentColors.isEmpty ? null : currentColors,
            );
            widget.onFilterChanged(newFilter);
          },
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildQuickFilterChip(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? (color ?? Colors.blue) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? (color ?? Colors.blue) : Colors.white30,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerSelector() {
    final selectedLayer = widget.availableLayers
        .cast<AnnotationLayer?>()
        .firstWhere(
          (layer) => layer?.id == widget.selectedLayerId,
          orElse: () => null,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white30),
      ),
      child: DropdownButton<String>(
        value: widget.selectedLayerId,
        hint: const Text('Layer', style: TextStyle(color: Colors.white70)),
        dropdownColor: Colors.black87,
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white),
        items: widget.availableLayers.map((layer) {
          return DropdownMenuItem<String>(
            value: layer.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: layer.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(layer.name),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            widget.onLayerChanged(value);
          }
        },
      ),
    );
  }

  IconData _getToolIcon(AnnotationTool tool) {
    switch (tool) {
      case AnnotationTool.pen:
        return Icons.edit;
      case AnnotationTool.highlighter:
        return Icons.highlight;
      case AnnotationTool.eraser:
        return Icons.cleaning_services;
      case AnnotationTool.text:
        return Icons.text_fields;
      case AnnotationTool.stamp:
        return Icons.push_pin;
    }
  }

  String _getToolTooltip(AnnotationTool tool) {
    switch (tool) {
      case AnnotationTool.pen:
        return 'Pen - Draw freehand';
      case AnnotationTool.highlighter:
        return 'Highlighter - Highlight text';
      case AnnotationTool.eraser:
        return 'Eraser - Remove annotations';
      case AnnotationTool.text:
        return 'Text - Add text notes';
      case AnnotationTool.stamp:
        return 'Stamp - Add musical symbols';
    }
  }

  Color _getColorFromTag(ColorTag colorTag) {
    switch (colorTag) {
      case ColorTag.yellow:
        return Colors.yellow;
      case ColorTag.blue:
        return Colors.blue;
      case ColorTag.purple:
        return Colors.purple;
      case ColorTag.red:
        return Colors.red;
      case ColorTag.green:
        return Colors.green;
    }
  }
}
