import 'package:flutter/material.dart';
import '../models/annotation.dart';

/// Advanced filter panel for annotations with date presets
class AnnotationFilterPanel extends StatefulWidget {
  final AnnotationFilter currentFilter;
  final Function(AnnotationFilter) onFilterChanged;
  final VoidCallback onClose;

  const AnnotationFilterPanel({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.onClose,
  });

  @override
  State<AnnotationFilterPanel> createState() => _AnnotationFilterPanelState();
}

class _AnnotationFilterPanelState extends State<AnnotationFilterPanel> {
  late Set<ColorTag> selectedColorTags;
  late Set<AnnotationTool> selectedTools;
  late bool showToday;
  late bool showLast7Days;
  late bool showAll;
  late bool fadeNonMatching;
  DateTime? customStart;
  DateTime? customEnd;

  @override
  void initState() {
    super.initState();
    selectedColorTags = widget.currentFilter.colorTags?.toSet() ?? {};
    selectedTools = widget.currentFilter.tools?.toSet() ?? {};
    showToday = widget.currentFilter.showToday;
    showLast7Days = widget.currentFilter.showLast7Days;
    showAll = widget.currentFilter.showAll;
    fadeNonMatching = widget.currentFilter.fadeNonMatching;
    customStart = widget.currentFilter.customStart;
    customEnd = widget.currentFilter.customEnd;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Filter Annotations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Filter content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color Tags Section
                  _buildSectionTitle('Color Tags'),
                  const SizedBox(height: 8),
                  _buildColorTagsFilter(),
                  
                  const SizedBox(height: 24),
                  
                  // Tools Section
                  _buildSectionTitle('Tools'),
                  const SizedBox(height: 8),
                  _buildToolsFilter(),
                  
                  const SizedBox(height: 24),
                  
                  // Date Range Section
                  _buildSectionTitle('Date Range'),
                  const SizedBox(height: 8),
                  _buildDateFilter(),
                  
                  const SizedBox(height: 24),
                  
                  // Visual Mode Section
                  _buildSectionTitle('Visual Mode'),
                  const SizedBox(height: 8),
                  _buildVisualModeToggle(),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  _buildQuickActions(),
                ],
              ),
            ),
          ),

          // Apply/Reset buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildColorTagsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick toggle buttons
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => setState(() => selectedColorTags.addAll(ColorTag.values)),
              icon: const Icon(Icons.select_all, size: 16),
              label: const Text('All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.black87,
                minimumSize: const Size(60, 32),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => setState(() => selectedColorTags.clear()),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('None'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.black87,
                minimumSize: const Size(60, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Color filter chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ColorTag.values.map((tag) {
            final isSelected = selectedColorTags.contains(tag);
            final color = _getColorFromTag(tag);
            
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(_getColorTagName(tag)),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedColorTags.add(tag);
                  } else {
                    selectedColorTags.remove(tag);
                  }
                });
              },
              selectedColor: color.withOpacity(0.2),
              checkmarkColor: color,
              backgroundColor: Colors.grey[50],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildToolsFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AnnotationTool.values.map((tool) {
        final isSelected = selectedTools.contains(tool);
        
        return FilterChip(
          label: Text(_getToolName(tool)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedTools.add(tool);
              } else {
                selectedTools.remove(tool);
              }
            });
          },
          avatar: Icon(_getToolIcon(tool), size: 16),
        );
      }).toList(),
    );
  }

  Widget _buildDateFilter() {
    return Column(
      children: [
        // Preset options
        RadioListTile<String>(
          title: const Text('All annotations'),
          value: 'all',
          groupValue: _getSelectedDateOption(),
          onChanged: (value) => setState(() {
            showAll = true;
            showToday = false;
            showLast7Days = false;
          }),
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text('Today only'),
          value: 'today',
          groupValue: _getSelectedDateOption(),
          onChanged: (value) => setState(() {
            showToday = true;
            showAll = false;
            showLast7Days = false;
          }),
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text('Last 7 days'),
          value: 'last7days',
          groupValue: _getSelectedDateOption(),
          onChanged: (value) => setState(() {
            showLast7Days = true;
            showAll = false;
            showToday = false;
          }),
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text('Custom range'),
          value: 'custom',
          groupValue: _getSelectedDateOption(),
          onChanged: (value) => setState(() {
            showAll = false;
            showToday = false;
            showLast7Days = false;
          }),
          dense: true,
        ),
        
        // Custom date range inputs
        if (!showAll && !showToday && !showLast7Days) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'From',
                  date: customStart,
                  onChanged: (date) => setState(() => customStart = date),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateField(
                  label: 'To',
                  date: customEnd,
                  onChanged: (date) => setState(() => customEnd = date),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onChanged,
  }) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Select date',
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      controller: TextEditingController(
        text: date != null 
            ? '${date.day}/${date.month}/${date.year}'
            : '',
      ),
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
    );
  }

  Widget _buildVisualModeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Non-matching annotations:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Hide completely'),
                  subtitle: const Text('Remove from view'),
                  value: false,
                  groupValue: fadeNonMatching,
                  onChanged: (value) => setState(() => fadeNonMatching = value!),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Fade to 20%'),
                  subtitle: const Text('Keep visible but dimmed'),
                  value: true,
                  groupValue: fadeNonMatching,
                  onChanged: (value) => setState(() => fadeNonMatching = value!),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quick Actions'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  selectedColorTags.clear();
                  selectedColorTags.add(ColorTag.red);
                  selectedTools.clear();
                  showAll = false;
                  showToday = true;
                  showLast7Days = false;
                });
              },
              icon: const Icon(Icons.warning, color: Colors.red),
              label: const Text('Today\'s Critical'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  selectedColorTags.clear();
                  selectedColorTags.addAll([ColorTag.yellow, ColorTag.blue]);
                  selectedTools.clear();
                  showAll = true;
                });
              },
              icon: const Icon(Icons.music_note),
              label: const Text('Practice Notes'),
            ),
          ],
        ),
      ],
    );
  }

  String _getSelectedDateOption() {
    if (showAll) return 'all';
    if (showToday) return 'today';
    if (showLast7Days) return 'last7days';
    return 'custom';
  }

  void _resetFilters() {
    setState(() {
      selectedColorTags.clear();
      selectedTools.clear();
      showAll = true;
      showToday = false;
      showLast7Days = false;
      fadeNonMatching = false;
      customStart = null;
      customEnd = null;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final filter = AnnotationFilter(
      colorTags: selectedColorTags.isEmpty ? null : selectedColorTags,
      tools: selectedTools.isEmpty ? null : selectedTools,
      showToday: showToday,
      showLast7Days: showLast7Days,
      showAll: showAll,
      customStart: customStart,
      customEnd: customEnd,
      fadeNonMatching: fadeNonMatching,
    );

    widget.onFilterChanged(filter);
    widget.onClose();
  }

  String _getColorTagName(ColorTag tag) {
    switch (tag) {
      case ColorTag.yellow:
        return 'Dynamics';
      case ColorTag.blue:
        return 'Fingering';
      case ColorTag.purple:
        return 'Phrasing';
      case ColorTag.red:
        return 'Critical';
      case ColorTag.green:
        return 'Corrections';
    }
  }

  String _getToolName(AnnotationTool tool) {
    switch (tool) {
      case AnnotationTool.pen:
        return 'Pen';
      case AnnotationTool.highlighter:
        return 'Highlighter';
      case AnnotationTool.eraser:
        return 'Eraser';
      case AnnotationTool.text:
        return 'Text';
      case AnnotationTool.stamp:
        return 'Stamps';
    }
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
