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
  final DBHelper _db = DBHelper();

  /// Save annotation to database
  Future<void> saveAnnotation(Annotation annotation) async {
    try {
      debugPrint('AnnotationService: Saving annotation ${annotation.id}');
      await _db.insertAnnotation(annotation);
      debugPrint('AnnotationService: Annotation saved successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error saving annotation: $e');
      rethrow;
    }
  }

  /// Update annotation
  Future<void> updateAnnotation(Annotation annotation) async {
    try {
      debugPrint('AnnotationService: Updating annotation ${annotation.id}');
      await _db.updateAnnotation(annotation);
      debugPrint('AnnotationService: Annotation updated successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error updating annotation: $e');
      rethrow;
    }
  }

  /// Delete annotation
  Future<void> deleteAnnotation(String annotationId) async {
    try {
      debugPrint('AnnotationService: Deleting annotation $annotationId');
      await _db.deleteAnnotation(annotationId);
      debugPrint('AnnotationService: Annotation deleted successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error deleting annotation: $e');
      rethrow;
    }
  }

  /// Get annotations for a piece
  Future<List<Annotation>> getAnnotationsForPiece(String pieceId) async {
    try {
      debugPrint('AnnotationService: Loading annotations for piece $pieceId');
      final annotations = await _db.getAnnotationsForPiece(pieceId);
      debugPrint('AnnotationService: Loaded ${annotations.length} annotations');
      return annotations;
    } catch (e) {
      debugPrint('AnnotationService: Error loading annotations: $e');
      return [];
    }
  }

  /// Filter annotations by criteria
  List<Annotation> filterAnnotations(
    List<Annotation> annotations,
    AnnotationFilter filter,
  ) {
    if (!filter.isActive) return annotations;
    
    return annotations.where((annotation) => filter.matches(annotation)).toList();
  }

  /// Save layer to database
  Future<void> saveLayer(AnnotationLayer layer) async {
    try {
      debugPrint('AnnotationService: Saving layer ${layer.id}');
      await _db.insertLayer(layer);
      debugPrint('AnnotationService: Layer saved successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error saving layer: $e');
      rethrow;
    }
  }

  /// Get all layers
  Future<List<AnnotationLayer>> getLayers() async {
    try {
      debugPrint('AnnotationService: Loading layers');
      final layers = await _db.getLayers();
      debugPrint('AnnotationService: Loaded ${layers.length} layers');
      return layers;
    } catch (e) {
      debugPrint('AnnotationService: Error loading layers: $e');
      return [];
    }
  }

  /// Update layer
  Future<void> updateLayer(AnnotationLayer layer) async {
    try {
      debugPrint('AnnotationService: Updating layer ${layer.id}');
      await _db.updateLayer(layer);
      debugPrint('AnnotationService: Layer updated successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error updating layer: $e');
      rethrow;
    }
  }

  /// Delete layer
  Future<void> deleteLayer(String layerId) async {
    try {
      debugPrint('AnnotationService: Deleting layer $layerId');
      await _db.deleteLayer(layerId);
      debugPrint('AnnotationService: Layer deleted successfully');
    } catch (e) {
      debugPrint('AnnotationService: Error deleting layer: $e');
      rethrow;
    }
  }
}
