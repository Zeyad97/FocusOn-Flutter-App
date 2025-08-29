import 'package:flutter/material.dart';
import '../models/annotation.dart';

/// Layer manager for organizing annotations with deletion confirmation
class LayerManagerDialog extends StatefulWidget {
  final List<AnnotationLayer> layers;
  final Function(AnnotationLayer) onLayerCreated;
  final Function(AnnotationLayer) onLayerUpdated;
  final Function(String, bool) onLayerDeleted; // layerId, deleteAnnotations
  final VoidCallback onClose;

  const LayerManagerDialog({
    super.key,
    required this.layers,
    required this.onLayerCreated,
    required this.onLayerUpdated,
    required this.onLayerDeleted,
    required this.onClose,
  });

  @override
  State<LayerManagerDialog> createState() => _LayerManagerDialogState();
}

class _LayerManagerDialogState extends State<LayerManagerDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                  const Icon(Icons.layers, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Manage Layers',
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

            // Layers list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.layers.length,
                itemBuilder: (context, index) {
                  final layer = widget.layers[index];
                  return _buildLayerTile(layer);
                },
              ),
            ),

            // Add layer button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateLayerDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Layer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerTile(AnnotationLayer layer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: layer.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
        title: Text(
          layer.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: layer.isVisible ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Text(
          _getColorTagName(layer.colorTag),
          style: TextStyle(
            color: layer.isVisible ? Colors.black54 : Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Visibility toggle
            IconButton(
              icon: Icon(
                layer.isVisible ? Icons.visibility : Icons.visibility_off,
                color: layer.isVisible ? Colors.blue : Colors.grey,
              ),
              onPressed: () => _toggleLayerVisibility(layer),
              tooltip: layer.isVisible ? 'Hide layer' : 'Show layer',
            ),
            
            // Edit layer
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showEditLayerDialog(layer),
              tooltip: 'Edit layer',
            ),
            
            // Delete layer
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteLayerDialog(layer),
              tooltip: 'Delete layer',
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLayerVisibility(AnnotationLayer layer) {
    final updatedLayer = layer.copyWith(
      isVisible: !layer.isVisible,
    );
    widget.onLayerUpdated(updatedLayer);
  }

  void _showCreateLayerDialog() {
    showDialog(
      context: context,
      builder: (context) => _LayerEditDialog(
        title: 'Create New Layer',
        onSave: (name, colorTag) {
          final newLayer = AnnotationLayer(
            id: 'layer_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            colorTag: colorTag,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          widget.onLayerCreated(newLayer);
        },
      ),
    );
  }

  void _showEditLayerDialog(AnnotationLayer layer) {
    showDialog(
      context: context,
      builder: (context) => _LayerEditDialog(
        title: 'Edit Layer',
        initialName: layer.name,
        initialColorTag: layer.colorTag,
        onSave: (name, colorTag) {
          final updatedLayer = layer.copyWith(
            name: name,
            colorTag: colorTag,
          );
          widget.onLayerUpdated(updatedLayer);
        },
      ),
    );
  }

  void _showDeleteLayerDialog(AnnotationLayer layer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Layer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${layer.name}"?'),
            const SizedBox(height: 16),
            const Text(
              'What should happen to annotations in this layer?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onLayerDeleted(layer.id, false);
            },
            child: const Text('Keep Annotations'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onLayerDeleted(layer.id, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
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
}

/// Dialog for creating/editing layers
class _LayerEditDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final ColorTag? initialColorTag;
  final Function(String name, ColorTag colorTag) onSave;

  const _LayerEditDialog({
    required this.title,
    this.initialName,
    this.initialColorTag,
    required this.onSave,
  });

  @override
  State<_LayerEditDialog> createState() => _LayerEditDialogState();
}

class _LayerEditDialogState extends State<_LayerEditDialog> {
  late TextEditingController _nameController;
  late ColorTag _selectedColorTag;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedColorTag = widget.initialColorTag ?? ColorTag.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layer name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Layer Name',
              hintText: 'Enter layer name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          
          const SizedBox(height: 16),
          
          // Color tag selection
          const Text(
            'Color Tag',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            children: ColorTag.values.map((tag) {
              final isSelected = _selectedColorTag == tag;
              final color = _getColorFromTag(tag);
              
              return GestureDetector(
                onTap: () => setState(() => _selectedColorTag = tag),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
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
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () {
                  widget.onSave(_nameController.text.trim(), _selectedColorTag);
                  Navigator.of(context).pop();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
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
