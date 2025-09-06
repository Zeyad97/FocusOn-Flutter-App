import 'package:flutter/material.dart';
import '../models/annotation.dart' as AppAnnotation;

/// A panel for managing annotation layers
class LayerPanel extends StatelessWidget {
  final List<AppAnnotation.AnnotationLayer> layers;
  final String selectedLayerId;
  final Function(String) onLayerChanged;
  final Function(String, bool) onLayerVisibilityChanged;
  final Function(AppAnnotation.AnnotationLayer) onLayerCreated;
  final Function(AppAnnotation.AnnotationLayer) onLayerUpdated;
  final Function(String) onLayerDeleted;
  final Function(AppAnnotation.AnnotationLayer) onLayerCreate;
  final Function(AppAnnotation.AnnotationLayer) onLayerUpdate;
  final Function(String, bool) onLayerToggle;
  final Function(String) onLayerDelete;

  const LayerPanel({
    Key? key,
    required this.layers,
    required this.selectedLayerId,
    required this.onLayerChanged,
    required this.onLayerVisibilityChanged,
    required this.onLayerCreated,
    required this.onLayerUpdated,
    required this.onLayerDeleted,
    required this.onLayerCreate,
    required this.onLayerUpdate,
    required this.onLayerToggle,
    required this.onLayerDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Layers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: layers.length,
              itemBuilder: (context, index) {
                final layer = layers[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: _getColorForTag(layer.colorTag),
                  ),
                  title: Text(layer.name, style: const TextStyle(fontSize: 14)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          layer.isVisible ? Icons.visibility : Icons.visibility_off,
                          size: 16,
                        ),
                        onPressed: () => onLayerToggle(layer.id, !layer.isVisible),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 16),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: const Row(
                              children: [
                                Icon(Icons.delete, size: 16),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (action) {
                          if (action == 'edit') {
                            // Handle edit
                          } else if (action == 'delete') {
                            onLayerDelete(layer.id);
                          }
                        },
                      ),
                    ],
                  ),
                  selected: layer.id == selectedLayerId,
                  onTap: () => onLayerChanged(layer.id),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Create new layer
                final newLayer = AppAnnotation.AnnotationLayer(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: 'Layer ${layers.length + 1}',
                  colorTag: AppAnnotation.ColorTag.blue,
                  isVisible: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                onLayerCreate(newLayer);
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Layer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForTag(AppAnnotation.ColorTag tag) {
    switch (tag) {
      case AppAnnotation.ColorTag.red:
        return Colors.red;
      case AppAnnotation.ColorTag.blue:
        return Colors.blue;
      case AppAnnotation.ColorTag.green:
        return Colors.green;
      case AppAnnotation.ColorTag.yellow:
        return Colors.yellow;
      case AppAnnotation.ColorTag.purple:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
