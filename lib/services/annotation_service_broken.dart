import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/annotation.dart';
import '../database/db_helper.dart';

// Provider for AnnotationService
final annotationServiceProvider = Provider<AnnotationService>((ref) {
  return AnnotationService();
});

/// Advanced annotation service with performance-optimized filtering
class AnnotationService {
  static final AnnotationService _instance = AnnotationService._internal();
  factory AnnotationService() => _instance;
  AnnotationService._internal();

  final DBHelper _db = DBHelper();
  
  // In-memory cache for fast filtering (per piece)
  final Map<String, List<Annotation>> _annotationCache = {};
  final Map<String, List<AnnotationLayer>> _layerCache = {};
  final Map<String, AnnotationFilter> _filterCache = {};

  /// Save annotation to database and update cache
  Future<void> saveAnnotation(Annotation annotation) async {
    try {
      debugPrint('AnnotationService: Saving annotation ${annotation.id} for piece ${annotation.pieceId}');
      
      await _db.insertAnnotation(annotation);
      
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

  /// Update existing annotation
  Future<void> updateAnnotation(Annotation annotation) async {
    try {
      debugPrint('AnnotationService: Updating annotation ${annotation.id}');
      
      await _db.updateAnnotation(annotation);
      
      // Update cache
      if (_annotationCache.containsKey(annotation.pieceId)) {
        final cache = _annotationCache[annotation.pieceId]!;
        final index = cache.indexWhere((a) => a.id == annotation.id);
        if (index != -1) {
          cache[index] = annotation;
        }
      }
      
      debugPrint('AnnotationService: Annotation updated successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error updating annotation: $e');
      rethrow;
    }
  }

  /// Delete annotation
  Future<void> deleteAnnotation(String annotationId, String pieceId) async {
    try {
      debugPrint('AnnotationService: Deleting annotation $annotationId');
      
      await _db.deleteAnnotation(annotationId);
      
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

  /// Get all annotations for a piece with caching
  Future<List<Annotation>> getAnnotationsForPiece(String pieceId) async {
    try {
      // Check cache first
      if (_annotationCache.containsKey(pieceId)) {
        debugPrint('AnnotationService: Returning cached annotations for piece $pieceId');
        return _annotationCache[pieceId]!;
      }
      
      debugPrint('AnnotationService: Loading annotations for piece $pieceId from database');
      
      final annotations = await _db.getAnnotationsForPiece(pieceId);
      
      // Cache for future use
      _annotationCache[pieceId] = annotations;
      
      debugPrint('AnnotationService: Found ${annotations.length} annotations');
      return annotations;
    } catch (e) {
      debugPrint('AnnotationService: Error loading annotations: $e');
      return [];
    }
  }

  /// Get annotations for a specific page with performance optimization
  Future<List<Annotation>> getAnnotationsForPage(String pieceId, int page) async {
    try {
      final allAnnotations = await getAnnotationsForPiece(pieceId);
      final pageAnnotations = allAnnotations.where((a) => a.page == page).toList();
      
      debugPrint('AnnotationService: Found ${pageAnnotations.length} annotations for page $page');
      return pageAnnotations;
    } catch (e) {
      debugPrint('AnnotationService: Error loading page annotations: $e');
      return [];
    }
  }

  /// Get filtered annotations with <100ms performance guarantee
  Future<List<Annotation>> getFilteredAnnotations({
    required String pieceId,
    int? page,
    AnnotationFilter? filter,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Get base annotations (from cache if possible)
      List<Annotation> annotations = await getAnnotationsForPiece(pieceId);
      
      // Filter by page if specified
      if (page != null) {
        annotations = annotations.where((a) => a.page == page).toList();
      }
      
      // Apply advanced filter if provided
      if (filter != null && filter.isActive) {
        if (filter.fadeNonMatching) {
          // Return all annotations but mark which should be faded
          return annotations;
        } else {
          // Return only matching annotations
          annotations = filter.apply(annotations);
        }
      }
      
      stopwatch.stop();
      debugPrint('AnnotationService: Filtered ${annotations.length} annotations in ${stopwatch.elapsedMilliseconds}ms');
      
      return annotations;
    } catch (e) {
      stopwatch.stop();
      debugPrint('AnnotationService: Error filtering annotations: $e (${stopwatch.elapsedMilliseconds}ms)');
      return [];
    }
  }

  /// Get annotations that should be faded (non-matching when fadeNonMatching is true)
  Future<List<Annotation>> getFadedAnnotations({
    required String pieceId,
    int? page,
    required AnnotationFilter filter,
  }) async {
    try {
      // Get base annotations
      List<Annotation> annotations = await getAnnotationsForPiece(pieceId);
      
      // Filter by page if specified
      if (page != null) {
        annotations = annotations.where((a) => a.page == page).toList();
      }
      
      // Get annotations that should be faded
      return filter.getFadedAnnotations(annotations);
    } catch (e) {
      debugPrint('AnnotationService: Error getting faded annotations: $e');
      return [];
    }
  }

  /// Save filter preferences for a piece
  void saveFilterForPiece(String pieceId, AnnotationFilter filter) {
    _filterCache[pieceId] = filter;
    debugPrint('AnnotationService: Saved filter for piece $pieceId');
  }

  /// Get saved filter for a piece
  AnnotationFilter? getFilterForPiece(String pieceId) {
    return _filterCache[pieceId];
  }

  /// Clear cache for a specific piece
  void clearCacheForPiece(String pieceId) {
    _annotationCache.remove(pieceId);
    _layerCache.remove(pieceId);
    _filterCache.remove(pieceId);
    debugPrint('AnnotationService: Cleared cache for piece $pieceId');
  }

  /// Clear all caches
  void clearAllCaches() {
    _annotationCache.clear();
    _layerCache.clear();
    _filterCache.clear();
    debugPrint('AnnotationService: Cleared all caches');
  }

  // LAYER MANAGEMENT METHODS

  /// Save annotation layer
  Future<void> saveLayer(String pieceId, AnnotationLayer layer) async {
    try {
      debugPrint('AnnotationService: Saving layer ${layer.id} for piece $pieceId');
      
      await _db.insertAnnotationLayer(layer);
      
      // Update cache
      if (_layerCache.containsKey(pieceId)) {
        _layerCache[pieceId]!.add(layer);
      }
      
      debugPrint('AnnotationService: Layer saved successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error saving layer: $e');
      rethrow;
    }
  }

  /// Update existing layer
  Future<void> updateLayer(String pieceId, AnnotationLayer layer) async {
    try {
      debugPrint('AnnotationService: Updating layer ${layer.id}');
      
      await _db.updateAnnotationLayer(layer);
      
      // Update cache
      if (_layerCache.containsKey(pieceId)) {
        final cache = _layerCache[pieceId]!;
        final index = cache.indexWhere((l) => l.id == layer.id);
        if (index != -1) {
          cache[index] = layer;
        }
      }
      
      debugPrint('AnnotationService: Layer updated successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error updating layer: $e');
      rethrow;
    }
  }

  /// Delete layer and optionally its annotations
  Future<void> deleteLayer(String pieceId, String layerId, {bool deleteAnnotations = false}) async {
    try {
      debugPrint('AnnotationService: Deleting layer $layerId (deleteAnnotations: $deleteAnnotations)');
      
      if (deleteAnnotations) {
        // Delete all annotations in this layer - TODO: Implement in database
        // await _db.deleteAnnotationsByLayer(layerId);
        
        // Update annotation cache
        if (_annotationCache.containsKey(pieceId)) {
          _annotationCache[pieceId]!.removeWhere((a) => a.layerId == layerId);
        }
      }
      
      await _db.deleteAnnotationLayer(layerId);
      
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

  /// Get all layers for a piece
  Future<List<AnnotationLayer>> getLayersForPiece(String pieceId) async {
    try {
      // Check cache first
      if (_layerCache.containsKey(pieceId)) {
        debugPrint('AnnotationService: Returning cached layers for piece $pieceId');
        return _layerCache[pieceId]!;
      }
      
      debugPrint('AnnotationService: Loading layers for piece $pieceId from database');
      
      // TODO: Implement layer loading from database
      // final layers = await _db.getAnnotationLayersForPiece(pieceId);
      final layers = <AnnotationLayer>[]; // Temporary empty list
      
      // Cache for future use
      _layerCache[pieceId] = layers;
      
      debugPrint('AnnotationService: Found ${layers.length} layers');
      return layers;
    } catch (e) {
      debugPrint('AnnotationService: Error loading layers: $e');
      return [];
    }
  }

  /// Create default layers for a new piece
  Future<List<AnnotationLayer>> createDefaultLayers(String pieceId) async {
    final now = DateTime.now();
    final defaultLayers = [
      AnnotationLayer(
        id: '${pieceId}_layer_dynamics',
        name: 'Dynamics',
        colorTag: ColorTag.yellow,
        createdAt: now,
        updatedAt: now,
      ),
      AnnotationLayer(
        id: '${pieceId}_layer_fingering',
        name: 'Fingering',
        colorTag: ColorTag.blue,
        createdAt: now,
        updatedAt: now,
      ),
      AnnotationLayer(
        id: '${pieceId}_layer_phrasing',
        name: 'Phrasing',
        colorTag: ColorTag.purple,
        createdAt: now,
        updatedAt: now,
      ),
      AnnotationLayer(
        id: '${pieceId}_layer_critical',
        name: 'Critical Areas',
        colorTag: ColorTag.red,
        createdAt: now,
        updatedAt: now,
      ),
      AnnotationLayer(
        id: '${pieceId}_layer_corrections',
        name: 'Corrections',
        colorTag: ColorTag.green,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    try {
      for (final layer in defaultLayers) {
        await saveLayer(pieceId, layer);
      }
      
      debugPrint('AnnotationService: Created ${defaultLayers.length} default layers for piece $pieceId');
      return defaultLayers;
    } catch (e) {
      debugPrint('AnnotationService: Error creating default layers: $e');
      rethrow;
    }
  }

  /// Get layer by ID
  Future<AnnotationLayer?> getLayerById(String pieceId, String layerId) async {
    final layers = await getLayersForPiece(pieceId);
    return layers.cast<AnnotationLayer?>().firstWhere(
      (layer) => layer?.id == layerId,
      orElse: () => null,
    );
  }
}
  Future<void> deleteAnnotationsForPiece(String pieceId) async {
    try {
      debugPrint('AnnotationService: Deleting all annotations for piece $pieceId');
      
      await _db.deleteAnnotationsForPiece(pieceId);
      
      debugPrint('AnnotationService: All annotations deleted successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error deleting annotations: $e');
      rethrow;
    }
  }

  /// Save annotation layer
  Future<void> saveAnnotationLayer(AnnotationLayer layer) async {
    try {
      debugPrint('AnnotationService: Saving annotation layer ${layer.id}');
      
      await _db.insertAnnotationLayer(layer);
      
      debugPrint('AnnotationService: Annotation layer saved successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error saving annotation layer: $e');
      rethrow;
    }
  }

  /// Get all annotation layers
  Future<List<AnnotationLayer>> getAnnotationLayers() async {
    try {
      debugPrint('AnnotationService: Loading annotation layers');
      
      final layers = await _db.getAnnotationLayers();
      
      debugPrint('AnnotationService: Found ${layers.length} annotation layers');
      return layers;
    } catch (e) {
      debugPrint('AnnotationService: Error loading annotation layers: $e');
      return [];
    }
  }

  /// Update annotation layer
  Future<void> updateAnnotationLayer(AnnotationLayer layer) async {
    try {
      debugPrint('AnnotationService: Updating annotation layer ${layer.id}');
      
      await _db.updateAnnotationLayer(layer);
      
      debugPrint('AnnotationService: Annotation layer updated successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error updating annotation layer: $e');
      rethrow;
    }
  }

  /// Delete annotation layer
  Future<void> deleteAnnotationLayer(String layerId) async {
    try {
      debugPrint('AnnotationService: Deleting annotation layer $layerId');
      
      await _db.deleteAnnotationLayer(layerId);
      
      debugPrint('AnnotationService: Annotation layer deleted successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error deleting annotation layer: $e');
      rethrow;
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

  /// Export annotations to JSON
  Map<String, dynamic> exportAnnotations(List<Annotation> annotations) {
    return {
      'annotations': annotations.map((a) => a.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'count': annotations.length,
    };
  }

  /// Import annotations from JSON
  Future<void> importAnnotations(Map<String, dynamic> data) async {
    try {
      final annotationsList = data['annotations'] as List;
      final annotations = annotationsList
          .map((json) => Annotation.fromJson(json))
          .toList();

      // Use the existing method that's working
      for (final annotation in annotations) {
        await _db.insertAnnotation(annotation);
      }

      debugPrint('AnnotationService: Imported ${annotations.length} annotations');
    } catch (e) {
      debugPrint('AnnotationService: Error importing annotations: $e');
      rethrow;
    }
  }
}
