import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/annotation.dart';
import '../database/db_helper.dart';

// Provider for AnnotationService
final annotationServiceProvider = Provider<AnnotationService>((ref) {
  return AnnotationService();
});

/// Simple annotation service for basic functionality
class AnnotationService {

  // In-memory cache for fast filtering (per piece)
  final Map<String, List<Annotation>> _annotationCache = {};
  final Map<String, AnnotationFilter> _filterCache = {};
  final Map<String, List<AnnotationLayer>> _layerCache = {};

  /// Save annotation to database and update cache
  Future<void> saveAnnotation(Annotation annotation) async {
    try {
      debugPrint('AnnotationService: Saving annotation ${annotation.id} for piece ${annotation.pieceId}');
      
      await DBHelper.insertAnnotation(annotation);
      
      // Update cache
      if (_annotationCache.containsKey(annotation.pieceId)) {
        _annotationCache[annotation.pieceId]!.add(annotation);
      }
      
      debugPrint('AnnotationService: Annotation saved successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error saving annotation: $e');
      rethrow;
    }
  }

  /// Get annotations for a piece from cache or database
  Future<List<Annotation>> getAnnotationsForPiece(String pieceId) async {
    try {
      // Return from cache if available
      if (_annotationCache.containsKey(pieceId)) {
        debugPrint('AnnotationService: Returning ${_annotationCache[pieceId]!.length} annotations from cache');
        return _annotationCache[pieceId]!;
      }

      // Load from database
      debugPrint('AnnotationService: Loading annotations for piece $pieceId from database');
      final annotations = await DBHelper.getAnnotationsForPiece(pieceId);
      
      // Update cache
      _annotationCache[pieceId] = annotations;
      
      debugPrint('AnnotationService: Loaded ${annotations.length} annotations');
      return annotations;
    } catch (e) {
      debugPrint('AnnotationService: Error loading annotations: $e');
      return [];
    }
  }

  /// Filter annotations by criteria
  List<Annotation> filterAnnotations(
    List<Annotation> annotations, {
    Set<ColorTag>? colorTags,
    Set<AnnotationTool>? tools,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return annotations.where((annotation) {
      return annotation.matchesFilter(
        colorTags: colorTags,
        tools: tools,
        startDate: startDate,
        endDate: endDate,
      );
    }).toList();
  }

  /// Save filter for a piece
  void saveFilterForPiece(String pieceId, AnnotationFilter filter) {
    _filterCache[pieceId] = filter;
    debugPrint('AnnotationService: Filter saved for piece $pieceId');
  }

  /// Get saved filter for a piece
  AnnotationFilter? getFilterForPiece(String pieceId) {
    return _filterCache[pieceId];
  }

  /// Clear annotations cache for a piece
  void clearCacheForPiece(String pieceId) {
    _annotationCache.remove(pieceId);
    _filterCache.remove(pieceId);
    debugPrint('AnnotationService: Cache cleared for piece $pieceId');
  }

  /// Clear all cache
  void clearAllCache() {
    _annotationCache.clear();
    _filterCache.clear();
    debugPrint('AnnotationService: All cache cleared');
  }

  /// Advanced layer management for organizing annotations
  Future<void> createLayer(String pieceId, AnnotationLayer layer) async {
    try {
      debugPrint('AnnotationService: Creating layer ${layer.id} for piece $pieceId');
      
      await DBHelper.insertAnnotationLayer(pieceId, layer);
      
      // Update cache
      if (_layerCache.containsKey(pieceId)) {
        _layerCache[pieceId]!.add(layer);
      }
      
      debugPrint('AnnotationService: Layer created successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error creating layer: $e');
      rethrow;
    }
  }

  Future<void> updateLayer(String pieceId, AnnotationLayer layer) async {
    try {
      debugPrint('AnnotationService: Updating layer ${layer.id} for piece $pieceId');
      
      await DBHelper.updateAnnotationLayer(pieceId, layer);
      
      // Update cache
      if (_layerCache.containsKey(pieceId)) {
        final layers = _layerCache[pieceId]!;
        final index = layers.indexWhere((l) => l.id == layer.id);
        if (index != -1) {
          layers[index] = layer;
        }
      }
      
      debugPrint('AnnotationService: Layer updated successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error updating layer: $e');
      rethrow;
    }
  }

  Future<void> deleteLayer(String pieceId, String layerId, {bool deleteAnnotations = false}) async {
    try {
      debugPrint('AnnotationService: Deleting layer $layerId for piece $pieceId');
      
      if (deleteAnnotations) {
        // Delete all annotations in this layer
        await DBHelper.deleteAnnotationsByLayer(pieceId, layerId);
        
        // Remove from annotation cache
        if (_annotationCache.containsKey(pieceId)) {
          _annotationCache[pieceId]!.removeWhere((a) => a.layerId == layerId);
        }
      } else {
        // Move annotations to default layer
        await DBHelper.moveAnnotationsToDefaultLayer(pieceId, layerId);
        
        // Update annotation cache
        if (_annotationCache.containsKey(pieceId)) {
          for (var annotation in _annotationCache[pieceId]!) {
            if (annotation.layerId == layerId) {
              // Update annotation in cache to use default layer
              final index = _annotationCache[pieceId]!.indexOf(annotation);
              _annotationCache[pieceId]![index] = annotation.copyWith(layerId: 'default');
            }
          }
        }
      }
      
      await DBHelper.deleteAnnotationLayer(pieceId, layerId);
      
      // Update layer cache
      if (_layerCache.containsKey(pieceId)) {
        _layerCache[pieceId]!.removeWhere((l) => l.id == layerId);
      }
      
      debugPrint('AnnotationService: Layer deleted successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error deleting layer: $e');
      rethrow;
    }
  }

  Future<List<AnnotationLayer>> getLayersForPiece(String pieceId) async {
    try {
      // Return from cache if available
      if (_layerCache.containsKey(pieceId)) {
        debugPrint('AnnotationService: Returning ${_layerCache[pieceId]!.length} layers from cache');
        return _layerCache[pieceId]!;
      }

      // Load from database
      debugPrint('AnnotationService: Loading layers for piece $pieceId from database');
      final layers = await DBHelper.getAnnotationLayersForPiece(pieceId);
      
      // Ensure default layer exists
      if (layers.isEmpty || !layers.any((l) => l.id == 'default')) {
        final defaultLayer = AnnotationLayer(
          id: 'default',
          name: 'Default Layer',
          colorTag: ColorTag.blue,
          isVisible: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await createLayer(pieceId, defaultLayer);
        layers.insert(0, defaultLayer);
      }
      
      // Update cache
      _layerCache[pieceId] = layers;
      
      debugPrint('AnnotationService: Loaded ${layers.length} layers');
      return layers;
    } catch (e) {
      debugPrint('AnnotationService: Error loading layers: $e');
      // Return default layer on error
      final defaultLayer = AnnotationLayer(
        id: 'default',
        name: 'Default Layer',
        colorTag: ColorTag.blue,
        isVisible: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return [defaultLayer];
    }
  }

  /// Advanced filtering with layer visibility and annotation fade
  List<Annotation> filterAnnotationsAdvanced(
    List<Annotation> annotations,
    List<AnnotationLayer> layers,
    AnnotationFilter filter,
  ) {
    // First filter by layer visibility
    final visibleLayers = layers.where((layer) => layer.isVisible).map((layer) => layer.id).toSet();
    final layerFilteredAnnotations = annotations.where((annotation) => visibleLayers.contains(annotation.layerId)).toList();
    
    // Then apply annotation filter
    return filter.apply(layerFilteredAnnotations);
  }

  /// Get annotations that should be faded (for UI visual feedback)
  List<Annotation> getFadedAnnotations(
    List<Annotation> annotations,
    List<AnnotationLayer> layers,
    AnnotationFilter filter,
  ) {
    // First filter by layer visibility
    final visibleLayers = layers.where((layer) => layer.isVisible).map((layer) => layer.id).toSet();
    final layerFilteredAnnotations = annotations.where((annotation) => visibleLayers.contains(annotation.layerId)).toList();
    
    // Get faded annotations from filter
    return filter.getFadedAnnotations(layerFilteredAnnotations);
  }

  /// Bulk operations for performance
  Future<void> saveAnnotations(List<Annotation> annotations) async {
    try {
      debugPrint('AnnotationService: Bulk saving ${annotations.length} annotations');
      
      await DBHelper.insertAnnotations(annotations);
      
      // Update cache for each piece
      for (final annotation in annotations) {
        if (_annotationCache.containsKey(annotation.pieceId)) {
          _annotationCache[annotation.pieceId]!.add(annotation);
        }
      }
      
      debugPrint('AnnotationService: Bulk save completed');
    } catch (e) {
      debugPrint('AnnotationService: Error in bulk save: $e');
      rethrow;
    }
  }

  /// Delete annotation by ID
  Future<void> deleteAnnotation(String annotationId, String pieceId) async {
    try {
      debugPrint('AnnotationService: Deleting annotation $annotationId');
      
      await DBHelper.deleteAnnotation(annotationId);
      
      // Update cache
      if (_annotationCache.containsKey(pieceId)) {
        _annotationCache[pieceId]!.removeWhere((a) => a.id == annotationId);
      }
      
      debugPrint('AnnotationService: Annotation deleted successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error deleting annotation: $e');
      rethrow;
    }
  }

  /// Create annotation - alias for saveAnnotation for consistency
  Future<Annotation> createAnnotation(Annotation annotation) async {
    await saveAnnotation(annotation);
    return annotation;
  }

  /// Get filtered annotations for a piece
  Future<List<Annotation>> getFilteredAnnotations(String pieceId, AnnotationFilter filter) async {
    final annotations = await getAnnotationsForPiece(pieceId);
    final layers = await getLayersForPiece(pieceId);
    return filterAnnotationsAdvanced(annotations, layers, filter);
  }

  /// Get visible annotations for a piece (based on layer visibility)
  Future<List<Annotation>> getVisibleAnnotationsForPiece(String pieceId) async {
    final annotations = await getAnnotationsForPiece(pieceId);
    final layers = await getLayersForPiece(pieceId);
    final visibleLayers = layers.where((layer) => layer.isVisible).map((layer) => layer.id).toSet();
    return annotations.where((annotation) => visibleLayers.contains(annotation.layerId)).toList();
  }

  /// Get visible layers for a piece
  Future<List<AnnotationLayer>> getVisibleLayers(String pieceId) async {
    final layers = await getLayersForPiece(pieceId);
    return layers.where((layer) => layer.isVisible).toList();
  }
}
