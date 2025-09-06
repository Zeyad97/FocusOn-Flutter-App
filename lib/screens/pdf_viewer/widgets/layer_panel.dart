import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/annotation.dart';
import '../../../theme/app_theme.dart';

/// Comprehensive layer management panel for annotation organization
class LayerPanel extends ConsumerStatefulWidget {
  final String pieceId;
  final List<AnnotationLayer> layers;
  final Function(AnnotationLayer) onLayerToggle;
  final Function(AnnotationLayer) onLayerCreate;
  final Function(AnnotationLayer) onLayerUpdate;
  final Function(String, {bool deleteAnnotations}) onLayerDelete;
  final Function(AnnotationLayer) onLayerSelected;
  final AnnotationLayer? selectedLayer;

  const LayerPanel({
    super.key,
    required this.pieceId,
    required this.layers,
    required this.onLayerToggle,
    required this.onLayerCreate,
    required this.onLayerUpdate,
    required this.onLayerDelete,
    required this.onLayerSelected,
    this.selectedLayer,
  });

  @override
  ConsumerState<LayerPanel> createState() => _LayerPanelState();
}

class _LayerPanelState extends ConsumerState<LayerPanel> {
  bool _isExpanded = false;
  
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
          // Header with expand/collapse
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
                    Icons.layers,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Annotation Layers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.layers.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.text.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded layer list
          if (_isExpanded) ...[
            const Divider(height: 1),
            
            // Add layer button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateLayerDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Layer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            
            // Layer list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.layers.length,
                itemBuilder: (context, index) {
                  final layer = widget.layers[index];
                  final isSelected = widget.selectedLayer?.id == layer.id;
                  
                  return LayerListItem(
                    layer: layer,
                    isSelected: isSelected,
                    onToggle: () => widget.onLayerToggle(layer),
                    onSelect: () => widget.onLayerSelected(layer),
                    onEdit: () => _showEditLayerDialog(layer),
                    onDelete: () => _showDeleteLayerDialog(layer),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _showCreateLayerDialog() {
    showDialog(
      context: context,
      builder: (context) => LayerCreationDialog(
        pieceId: widget.pieceId,
        existingLayers: widget.layers,
        onLayerCreated: widget.onLayerCreate,
      ),
    );
  }

  void _showEditLayerDialog(AnnotationLayer layer) {
    showDialog(
      context: context,
      builder: (context) => LayerEditDialog(
        layer: layer,
        existingLayers: widget.layers,
        onLayerUpdated: widget.onLayerUpdate,
      ),
    );
  }

  void _showDeleteLayerDialog(AnnotationLayer layer) {
    if (layer.id == 'default') {
      // Cannot delete default layer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the default layer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Layer "${layer.name}"?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose what to do with annotations in this layer:'),
            const SizedBox(height: 16),
            
            ListTile(
              leading: Icon(Icons.move_to_inbox, color: AppColors.primaryBlue),
              title: const Text('Move to Default Layer'),
              subtitle: const Text('Keep annotations, move to default layer'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onLayerDelete(layer.id, deleteAnnotations: false);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete All Annotations'),
              subtitle: const Text('Permanently delete layer and all annotations'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onLayerDelete(layer.id, deleteAnnotations: true);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Individual layer list item with controls
class LayerListItem extends StatelessWidget {
  final AnnotationLayer layer;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LayerListItem({
    super.key,
    required this.layer,
    required this.isSelected,
    required this.onToggle,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: AppColors.primaryBlue, width: 1) : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        
        // Layer color indicator
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: layer.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
        ),
        
        // Layer name
        title: Text(
          layer.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: AppColors.text,
          ),
        ),
        
        // Layer info
        subtitle: Text(
          '${layer.colorTag.name.toUpperCase()} • ${layer.isVisible ? "Visible" : "Hidden"}',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.text.withOpacity(0.6),
          ),
        ),
        
        // Controls
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Visibility toggle
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  layer.isVisible ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                  color: layer.isVisible ? AppColors.primaryBlue : AppColors.text.withOpacity(0.5),
                ),
              ),
            ),
            
            // Edit button
            if (layer.id != 'default') ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.text.withOpacity(0.7),
                  ),
                ),
              ),
              
              // Delete button
              const SizedBox(width: 8),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
        
        onTap: onSelect,
      ),
    );
  }
}

/// Dialog for creating a new annotation layer
class LayerCreationDialog extends StatefulWidget {
  final String pieceId;
  final List<AnnotationLayer> existingLayers;
  final Function(AnnotationLayer) onLayerCreated;

  const LayerCreationDialog({
    super.key,
    required this.pieceId,
    required this.existingLayers,
    required this.onLayerCreated,
  });

  @override
  State<LayerCreationDialog> createState() => _LayerCreationDialogState();
}

class _LayerCreationDialogState extends State<LayerCreationDialog> {
  final TextEditingController _nameController = TextEditingController();
  ColorTag _selectedColorTag = ColorTag.blue;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Layer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layer name
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Layer Name',
              hintText: 'e.g., Dynamics, Fingering, Notes',
              errorText: _nameError,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _nameError = null),
          ),
          
          const SizedBox(height: 16),
          
          // Color tag selection
          Text(
            'Color Tag',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ColorTag.values.map((tag) {
              final isSelected = tag == _selectedColorTag;
              final color = _getColorFromTag(tag);
              
              return InkWell(
                onTap: () => setState(() => _selectedColorTag = tag),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
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
                        width: 16,
                        height: 16,
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
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Color meanings helper
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Usage:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ..._getColorMeanings().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: entry.key,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.value,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createLayer,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createLayer() {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter a layer name');
      return;
    }
    
    if (widget.existingLayers.any((layer) => layer.name.toLowerCase() == name.toLowerCase())) {
      setState(() => _nameError = 'A layer with this name already exists');
      return;
    }
    
    final layer = AnnotationLayer(
      id: '${widget.pieceId}_layer_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      colorTag: _selectedColorTag,
      isVisible: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    widget.onLayerCreated(layer);
    Navigator.of(context).pop();
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

  Map<Color, String> _getColorMeanings() {
    return {
      Colors.red: 'Critical areas, mistakes',
      Colors.blue: 'Fingering, technique',
      Colors.yellow.shade700: 'Dynamics, expression',
      Colors.green: 'Corrections, improvements',
      Colors.purple: 'Phrasing, articulation',
    };
  }
}

/// Dialog for editing an existing layer
class LayerEditDialog extends StatefulWidget {
  final AnnotationLayer layer;
  final List<AnnotationLayer> existingLayers;
  final Function(AnnotationLayer) onLayerUpdated;

  const LayerEditDialog({
    super.key,
    required this.layer,
    required this.existingLayers,
    required this.onLayerUpdated,
  });

  @override
  State<LayerEditDialog> createState() => _LayerEditDialogState();
}

class _LayerEditDialogState extends State<LayerEditDialog> {
  late TextEditingController _nameController;
  late ColorTag _selectedColorTag;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.layer.name);
    _selectedColorTag = widget.layer.colorTag;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Layer "${widget.layer.name}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layer name
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Layer Name',
              errorText: _nameError,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _nameError = null),
          ),
          
          const SizedBox(height: 16),
          
          // Color tag selection
          Text(
            'Color Tag',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ColorTag.values.map((tag) {
              final isSelected = tag == _selectedColorTag;
              final color = _getColorFromTag(tag);
              
              return InkWell(
                onTap: () => setState(() => _selectedColorTag = tag),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
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
                        width: 16,
                        height: 16,
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
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateLayer,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _updateLayer() {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter a layer name');
      return;
    }
    
    if (name.toLowerCase() != widget.layer.name.toLowerCase() &&
        widget.existingLayers.any((layer) => layer.name.toLowerCase() == name.toLowerCase())) {
      setState(() => _nameError = 'A layer with this name already exists');
      return;
    }
    
    final updatedLayer = widget.layer.copyWith(
      name: name,
      colorTag: _selectedColorTag,
      updatedAt: DateTime.now(),
    );
    
    widget.onLayerUpdated(updatedLayer);
    Navigator.of(context).pop();
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
}
