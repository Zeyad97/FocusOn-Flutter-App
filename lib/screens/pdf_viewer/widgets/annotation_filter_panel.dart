import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/annotation.dart';
import '../../../theme/app_theme.dart';

/// Advanced filter panel for annotations with comprehensive filtering options
class AnnotationFilterPanel extends ConsumerStatefulWidget {
  final AnnotationFilter currentFilter;
  final Function(AnnotationFilter) onFilterChanged;
  final int totalAnnotations;
  final int filteredAnnotations;

  const AnnotationFilterPanel({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.totalAnnotations,
    required this.filteredAnnotations,
  });

  @override
  ConsumerState<AnnotationFilterPanel> createState() => _AnnotationFilterPanelState();
}

class _AnnotationFilterPanelState extends ConsumerState<AnnotationFilterPanel> {
  bool _isExpanded = false;
  late AnnotationFilter _workingFilter;

  @override
  void initState() {
    super.initState();
    _workingFilter = widget.currentFilter;
  }

  @override
  void didUpdateWidget(AnnotationFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentFilter != widget.currentFilter) {
      _workingFilter = widget.currentFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with filter status
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: _workingFilter.isActive ? AppColors.primaryBlue : AppColors.text.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filter Annotations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Filter count badge
                  if (_workingFilter.isActive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.filteredAnnotations}/${widget.totalAnnotations}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.totalAnnotations}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Clear filters button
                  if (_workingFilter.isActive) ...[
                    InkWell(
                      onTap: _clearFilters,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.clear,
                          size: 18,
                          color: AppColors.text.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.text.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded filter controls
          if (_isExpanded) ...[
            const Divider(height: 1),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color tag filters
                  _buildColorTagFilters(),
                  
                  const SizedBox(height: 16),
                  
                  // Tool type filters
                  _buildToolFilters(),
                  
                  const SizedBox(height: 16),
                  
                  // Date range filters
                  _buildDateFilters(),
                  
                  const SizedBox(height: 16),
                  
                  // Visual mode toggle
                  _buildVisualModeToggle(),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorTagFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette, size: 16, color: AppColors.text.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              'Color Tags',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ColorTag.values.map((tag) {
            final isSelected = _workingFilter.colorTags?.contains(tag) ?? false;
            final color = _getColorFromTag(tag);
            
            return InkWell(
              onTap: () => _toggleColorTag(tag),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tag.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        // Color meanings
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meanings:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              ..._getColorMeanings().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: entry.key,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.text.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.build, size: 16, color: AppColors.text.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              'Tools',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AnnotationTool.values.map((tool) {
            final isSelected = _workingFilter.tools?.contains(tool) ?? false;
            
            return InkWell(
              onTap: () => _toggleTool(tool),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getToolIcon(tool),
                      size: 14,
                      color: isSelected ? AppColors.primaryBlue : AppColors.text.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tool.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: AppColors.text.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              'Date Range',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Date preset buttons
        Row(
          children: [
            Expanded(
              child: _buildDateButton('Today', _workingFilter.showToday, () {
                setState(() {
                  _workingFilter = _workingFilter.copyWith(
                    showToday: !_workingFilter.showToday,
                    showLast7Days: false,
                    showAll: false,
                  );
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateButton('Last 7 Days', _workingFilter.showLast7Days, () {
                setState(() {
                  _workingFilter = _workingFilter.copyWith(
                    showToday: false,
                    showLast7Days: !_workingFilter.showLast7Days,
                    showAll: false,
                  );
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateButton('All Time', _workingFilter.showAll, () {
                setState(() {
                  _workingFilter = _workingFilter.copyWith(
                    showToday: false,
                    showLast7Days: false,
                    showAll: true,
                  );
                });
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primaryBlue : AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildVisualModeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.visibility, size: 16, color: AppColors.text.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              'Non-Matching Annotations',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _workingFilter = _workingFilter.copyWith(fadeNonMatching: false);
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: !_workingFilter.fadeNonMatching 
                        ? AppColors.primaryBlue.withOpacity(0.1) 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: !_workingFilter.fadeNonMatching 
                          ? AppColors.primaryBlue 
                          : Colors.grey.shade300,
                      width: !_workingFilter.fadeNonMatching ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_off,
                        size: 16,
                        color: !_workingFilter.fadeNonMatching 
                            ? AppColors.primaryBlue 
                            : AppColors.text.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hide',
                        style: TextStyle(
                          fontWeight: !_workingFilter.fadeNonMatching 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _workingFilter = _workingFilter.copyWith(fadeNonMatching: true);
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _workingFilter.fadeNonMatching 
                        ? AppColors.primaryBlue.withOpacity(0.1) 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _workingFilter.fadeNonMatching 
                          ? AppColors.primaryBlue 
                          : Colors.grey.shade300,
                      width: _workingFilter.fadeNonMatching ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.opacity,
                        size: 16,
                        color: _workingFilter.fadeNonMatching 
                            ? AppColors.primaryBlue 
                            : AppColors.text.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fade',
                        style: TextStyle(
                          fontWeight: _workingFilter.fadeNonMatching 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleColorTag(ColorTag tag) {
    setState(() {
      final currentTags = _workingFilter.colorTags ?? <ColorTag>{};
      final newTags = Set<ColorTag>.from(currentTags);
      
      if (newTags.contains(tag)) {
        newTags.remove(tag);
      } else {
        newTags.add(tag);
      }
      
      _workingFilter = _workingFilter.copyWith(
        colorTags: newTags.isEmpty ? null : newTags,
      );
    });
  }

  void _toggleTool(AnnotationTool tool) {
    setState(() {
      final currentTools = _workingFilter.tools ?? <AnnotationTool>{};
      final newTools = Set<AnnotationTool>.from(currentTools);
      
      if (newTools.contains(tool)) {
        newTools.remove(tool);
      } else {
        newTools.add(tool);
      }
      
      _workingFilter = _workingFilter.copyWith(
        tools: newTools.isEmpty ? null : newTools,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _workingFilter = const AnnotationFilter();
    });
    widget.onFilterChanged(_workingFilter);
  }

  void _applyFilters() {
    widget.onFilterChanged(_workingFilter);
  }

  Color _getColorFromTag(ColorTag tag) {
    switch (tag) {
      case ColorTag.red: return Colors.red;
      case ColorTag.blue: return Colors.blue;
      case ColorTag.yellow: return Colors.yellow.shade700;
      case ColorTag.green: return Colors.green;
      case ColorTag.purple: return Colors.purple;
    }
  }

  IconData _getToolIcon(AnnotationTool tool) {
    switch (tool) {
      case AnnotationTool.pen: return Icons.edit;
      case AnnotationTool.highlighter: return Icons.highlight;
      case AnnotationTool.eraser: return Icons.cleaning_services;
      case AnnotationTool.text: return Icons.text_fields;
      case AnnotationTool.stamp: return Icons.label;
    }
  }

  Map<Color, String> _getColorMeanings() {
    return {
      Colors.red: 'Critical, mistakes',
      Colors.blue: 'Fingering, technique',
      Colors.yellow.shade700: 'Dynamics, expression',
      Colors.green: 'Corrections',
      Colors.purple: 'Phrasing, articulation',
    };
  }
}
