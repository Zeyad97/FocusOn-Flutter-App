import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/models/annotation.dart' as AppAnnotation;
import 'package:music_app/services/annotation_service.dart';
import 'package:music_app/database/db_helper.dart';

void main() {
  group('Comprehensive Annotation System Tests', () {
    late AnnotationService annotationService;
    late DBHelper dbHelper;

    setUp(() async {
      // Initialize test database
      dbHelper = DBHelper.instance;
      await dbHelper.database;
      
      // Initialize annotation service
      annotationService = AnnotationService();
    });

    tearDown(() async {
      // Clean up test data
      final db = await dbHelper.database;
      await db.delete('annotations');
      await db.delete('annotation_layers');
    });

    group('Layer Management', () {
      test('should create a new annotation layer', () async {
        const pieceId = 'test-piece-1';
        final layer = AppAnnotation.AnnotationLayer(
          id: '1',
          name: 'Test Layer',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.red,
          isVisible: true,
          createdAt: DateTime.now(),
        );

        final createdLayer = await annotationService.createLayer(layer);
        
        expect(createdLayer.id, isNotEmpty);
        expect(createdLayer.name, 'Test Layer');
        expect(createdLayer.pieceId, pieceId);
        expect(createdLayer.colorTag, AppAnnotation.ColorTag.red);
        expect(createdLayer.isVisible, true);
      });

      test('should get layers for a piece', () async {
        const pieceId = 'test-piece-2';
        
        // Create multiple layers
        await annotationService.createLayer(AppAnnotation.AnnotationLayer(
          id: '1',
          name: 'Layer 1',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.blue,
          isVisible: true,
          createdAt: DateTime.now(),
        ));

        await annotationService.createLayer(AppAnnotation.AnnotationLayer(
          id: '2',
          name: 'Layer 2',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.green,
          isVisible: false,
          createdAt: DateTime.now(),
        ));

        final layers = await annotationService.getLayersForPiece(pieceId);
        
        expect(layers.length, 2);
        expect(layers.any((l) => l.name == 'Layer 1'), true);
        expect(layers.any((l) => l.name == 'Layer 2'), true);
      });

      test('should update layer visibility', () async {
        const pieceId = 'test-piece-3';
        final layer = await annotationService.createLayer(AppAnnotation.AnnotationLayer(
          id: '1',
          name: 'Test Layer',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.orange,
          isVisible: true,
          createdAt: DateTime.now(),
        ));

        final updatedLayer = layer.copyWith(isVisible: false);
        await annotationService.updateLayer(updatedLayer);

        final layers = await annotationService.getLayersForPiece(pieceId);
        final retrievedLayer = layers.firstWhere((l) => l.id == layer.id);
        
        expect(retrievedLayer.isVisible, false);
      });

      test('should delete a layer', () async {
        const pieceId = 'test-piece-4';
        final layer = await annotationService.createLayer(AppAnnotation.AnnotationLayer(
          id: '1',
          name: 'Test Layer',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.purple,
          isVisible: true,
          createdAt: DateTime.now(),
        ));

        await annotationService.deleteLayer(layer.id);

        final layers = await annotationService.getLayersForPiece(pieceId);
        expect(layers.isEmpty, true);
      });
    });

    group('Enhanced Annotation Management', () {
      test('should create annotation with layer support', () async {
        const pieceId = 'test-piece-5';
        
        // First create a layer
        final layer = await annotationService.createLayer(AppAnnotation.AnnotationLayer(
          id: '1',
          name: 'Drawing Layer',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.blue,
          isVisible: true,
          createdAt: DateTime.now(),
        ));

        // Create annotation with layer
        final annotation = AppAnnotation.Annotation(
          id: '1',
          pieceId: pieceId,
          layerId: layer.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.pen,
          colorTag: AppAnnotation.ColorTag.blue,
          createdAt: DateTime.now(),
          data: AppAnnotation.VectorPath(points: [
            AppAnnotation.PathPoint(x: 100, y: 100, pressure: 1.0),
            AppAnnotation.PathPoint(x: 200, y: 200, pressure: 0.8),
          ]),
        );

        final createdAnnotation = await annotationService.createAnnotation(annotation);
        
        expect(createdAnnotation.layerId, layer.id);
        expect(createdAnnotation.tool, AppAnnotation.AnnotationTool.pen);
        expect(createdAnnotation.data, isA<AppAnnotation.VectorPath>());
      });

      test('should support different annotation types', () async {
        const pieceId = 'test-piece-6';
        final layer = await annotationService.createLayer(AppAnnotation.AnnotationLayer(
          id: '1',
          name: 'Mixed Layer',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.green,
          isVisible: true,
          createdAt: DateTime.now(),
        ));

        // Vector annotation
        final vectorAnnotation = AppAnnotation.Annotation(
          id: '1',
          pieceId: pieceId,
          layerId: layer.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.pen,
          colorTag: AppAnnotation.ColorTag.green,
          createdAt: DateTime.now(),
          data: AppAnnotation.VectorPath(points: [
            AppAnnotation.PathPoint(x: 50, y: 50, pressure: 1.0),
          ]),
        );

        // Text annotation
        final textAnnotation = AppAnnotation.Annotation(
          id: '2',
          pieceId: pieceId,
          layerId: layer.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.text,
          colorTag: AppAnnotation.ColorTag.green,
          createdAt: DateTime.now(),
          data: AppAnnotation.TextData(
            text: 'Practice this section slowly',
            x: 100,
            y: 100,
            fontSize: 14,
          ),
        );

        // Stamp annotation
        final stampAnnotation = AppAnnotation.Annotation(
          id: '3',
          pieceId: pieceId,
          layerId: layer.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.stamp,
          colorTag: AppAnnotation.ColorTag.green,
          createdAt: DateTime.now(),
          data: AppAnnotation.StampData(
            stampType: AppAnnotation.StampType.forte,
            x: 150,
            y: 150,
            scale: 1.0,
            rotation: 0.0,
          ),
        );

        await annotationService.createAnnotation(vectorAnnotation);
        await annotationService.createAnnotation(textAnnotation);
        await annotationService.createAnnotation(stampAnnotation);

        final annotations = await annotationService.getAnnotationsForPiece(pieceId);
        
        expect(annotations.length, 3);
        expect(annotations.any((a) => a.data is AppAnnotation.VectorPath), true);
        expect(annotations.any((a) => a.data is AppAnnotation.TextData), true);
        expect(annotations.any((a) => a.data is AppAnnotation.StampData), true);
      });
    });

    group('Advanced Filtering', () {
      test('should filter annotations by color', () async {
        const pieceId = 'test-piece-7';
        final layer = await annotationService.createLayer(AppAnnotation.AnnotationLayer(
          id: '1',
          name: 'Test Layer',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.blue,
          isVisible: true,
          createdAt: DateTime.now(),
        ));

        // Create annotations with different colors
        await annotationService.createAnnotation(AppAnnotation.Annotation(
          id: '1',
          pieceId: pieceId,
          layerId: layer.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.pen,
          colorTag: AppAnnotation.ColorTag.red,
          createdAt: DateTime.now(),
          data: AppAnnotation.VectorPath(points: []),
        ));

        await annotationService.createAnnotation(AppAnnotation.Annotation(
          id: '2',
          pieceId: pieceId,
          layerId: layer.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.pen,
          colorTag: AppAnnotation.ColorTag.blue,
          createdAt: DateTime.now(),
          data: AppAnnotation.VectorPath(points: []),
        ));

        final filter = AppAnnotation.AnnotationFilter(
          colorTags: {AppAnnotation.ColorTag.red},
        );

        final filteredAnnotations = await annotationService.getFilteredAnnotations(
          pieceId, 
          filter,
        );

        expect(filteredAnnotations.length, 1);
        expect(filteredAnnotations.first.colorTag, AppAnnotation.ColorTag.red);
      });

      test('should filter annotations by tool', () async {
        const pieceId = 'test-piece-8';
        final layer = await annotationService.createLayer(AppAnnotation.AnnotationLayer(
          id: '1',
          name: 'Test Layer',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.blue,
          isVisible: true,
          createdAt: DateTime.now(),
        ));

        // Create annotations with different tools
        await annotationService.createAnnotation(AppAnnotation.Annotation(
          id: '1',
          pieceId: pieceId,
          layerId: layer.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.pen,
          colorTag: AppAnnotation.ColorTag.blue,
          createdAt: DateTime.now(),
          data: AppAnnotation.VectorPath(points: []),
        ));

        await annotationService.createAnnotation(AppAnnotation.Annotation(
          id: '2',
          pieceId: pieceId,
          layerId: layer.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.highlighter,
          colorTag: AppAnnotation.ColorTag.blue,
          createdAt: DateTime.now(),
          data: AppAnnotation.VectorPath(points: []),
        ));

        final filter = AppAnnotation.AnnotationFilter(
          tools: {AppAnnotation.AnnotationTool.highlighter},
        );

        final filteredAnnotations = await annotationService.getFilteredAnnotations(
          pieceId, 
          filter,
        );

        expect(filteredAnnotations.length, 1);
        expect(filteredAnnotations.first.tool, AppAnnotation.AnnotationTool.highlighter);
      });

      test('should filter annotations by date range', () async {
        const pieceId = 'test-piece-9';
        final layer = await annotationService.createLayer(AppAnnotation.AnnotationLayer(
          id: '1',
          name: 'Test Layer',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.blue,
          isVisible: true,
          createdAt: DateTime.now(),
        ));

        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final tomorrow = now.add(const Duration(days: 1));

        // Create annotation from yesterday
        await annotationService.createAnnotation(AppAnnotation.Annotation(
          id: '1',
          pieceId: pieceId,
          layerId: layer.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.pen,
          colorTag: AppAnnotation.ColorTag.blue,
          createdAt: yesterday,
          data: AppAnnotation.VectorPath(points: []),
        ));

        // Create annotation from today
        await annotationService.createAnnotation(AppAnnotation.Annotation(
          id: '2',
          pieceId: pieceId,
          layerId: layer.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.pen,
          colorTag: AppAnnotation.ColorTag.blue,
          createdAt: now,
          data: AppAnnotation.VectorPath(points: []),
        ));

        final filter = AppAnnotation.AnnotationFilter(
          dateRange: DateTimeRange(
            start: now.subtract(const Duration(hours: 1)),
            end: tomorrow,
          ),
        );

        final filteredAnnotations = await annotationService.getFilteredAnnotations(
          pieceId, 
          filter,
        );

        expect(filteredAnnotations.length, 1);
        expect(filteredAnnotations.first.id, '2');
      });
    });

    group('Integration Tests', () {
      test('should handle complex layer and filter combinations', () async {
        const pieceId = 'test-piece-10';
        
        // Create multiple layers
        final layer1 = await annotationService.createLayer(AppAnnotation.AnnotationLayer(
          id: '1',
          name: 'Visible Layer',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.red,
          isVisible: true,
          createdAt: DateTime.now(),
        ));

        final layer2 = await annotationService.createLayer(AppAnnotation.AnnotationLayer(
          id: '2',
          name: 'Hidden Layer',
          pieceId: pieceId,
          colorTag: AppAnnotation.ColorTag.blue,
          isVisible: false,
          createdAt: DateTime.now(),
        ));

        // Create annotations in different layers
        await annotationService.createAnnotation(AppAnnotation.Annotation(
          id: '1',
          pieceId: pieceId,
          layerId: layer1.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.pen,
          colorTag: AppAnnotation.ColorTag.red,
          createdAt: DateTime.now(),
          data: AppAnnotation.VectorPath(points: []),
        ));

        await annotationService.createAnnotation(AppAnnotation.Annotation(
          id: '2',
          pieceId: pieceId,
          layerId: layer2.id,
          page: 1,
          tool: AppAnnotation.AnnotationTool.pen,
          colorTag: AppAnnotation.ColorTag.blue,
          createdAt: DateTime.now(),
          data: AppAnnotation.VectorPath(points: []),
        ));

        // Get only visible annotations
        final visibleAnnotations = await annotationService.getVisibleAnnotationsForPiece(pieceId);
        
        expect(visibleAnnotations.length, 1);
        expect(visibleAnnotations.first.layerId, layer1.id);
        expect(visibleAnnotations.first.colorTag, AppAnnotation.ColorTag.red);

        // Test layer visibility toggle
        await annotationService.updateLayer(layer2.copyWith(isVisible: true));
        
        final nowVisibleAnnotations = await annotationService.getVisibleAnnotationsForPiece(pieceId);
        expect(nowVisibleAnnotations.length, 2);
      });
    });
  });
}

// Helper extension for AnnotationLayer copyWith
extension AnnotationLayerCopyWith on AppAnnotation.AnnotationLayer {
  AppAnnotation.AnnotationLayer copyWith({
    String? id,
    String? name,
    String? pieceId,
    AppAnnotation.ColorTag? colorTag,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppAnnotation.AnnotationLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      pieceId: pieceId ?? this.pieceId,
      colorTag: colorTag ?? this.colorTag,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Helper class for DateTimeRange (if not available in the project)
class DateTimeRange {
  final DateTime start;
  final DateTime end;
  
  DateTimeRange({required this.start, required this.end});
}
