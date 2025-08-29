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
  // Database helper
  final DBHelper _db = DBHelper();

  // In-memory cache for fast filtering (per piece)
  final Map<String, List<Annotation>> _annotationCache = {};
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
      final annotations = await _db.getAnnotationsForPiece(pieceId);
      
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

  /// Placeholder methods for annotation layers (not implemented yet)
  Future<void> saveLayer(String pieceId, Map<String, dynamic> layer) async {
    debugPrint('AnnotationService: Layer operations not yet implemented');
  }

  Future<void> updateLayer(String pieceId, Map<String, dynamic> layer) async {
    debugPrint('AnnotationService: Layer operations not yet implemented');
  }

  Future<void> deleteLayer(String pieceId, String layerId, {bool deleteAnnotations = false}) async {
    debugPrint('AnnotationService: Layer operations not yet implemented');
  }

  Future<List<Map<String, dynamic>>> getLayers() async {
    debugPrint('AnnotationService: Layer operations not yet implemented');
    return [];
  }
}
