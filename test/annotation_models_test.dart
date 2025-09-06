import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/models/annotation.dart' as AppAnnotation;

void main() {
  group('Comprehensive Annotation System - Model Tests', () {
    
    group('AnnotationLayer Model', () {
      test('should create annotation layer with all properties', () {
        const layer = AppAnnotation.AnnotationLayer(
          id: 'layer-1',
          name: 'Test Layer',
          colorTag: AppAnnotation.ColorTag.red,
          isVisible: true,
          createdAt: null,
        );
        
        expect(layer.id, 'layer-1');
        expect(layer.name, 'Test Layer');
        expect(layer.colorTag, AppAnnotation.ColorTag.red);
        expect(layer.isVisible, true);
      });

      test('should support visibility toggle', () {
        const layer1 = AppAnnotation.AnnotationLayer(
          id: 'layer-1',
          name: 'Test Layer',
          colorTag: AppAnnotation.ColorTag.blue,
          isVisible: true,
          createdAt: null,
        );
        
        const layer2 = AppAnnotation.AnnotationLayer(
          id: 'layer-1',
          name: 'Test Layer',
          colorTag: AppAnnotation.ColorTag.blue,
          isVisible: false,
          createdAt: null,
        );
        
        expect(layer1.isVisible, true);
        expect(layer2.isVisible, false);
      });
    });

    group('VectorPath Model', () {
      test('should create vector path with points', () {
        final path = AppAnnotation.VectorPath(
          points: const [
            AppAnnotation.Point(x: 100, y: 150, pressure: 1.0),
            AppAnnotation.Point(x: 200, y: 250, pressure: 0.8),
          ],
          strokeWidth: 2.0,
        );
        
        expect(path.points.length, 2);
        expect(path.points[0].x, 100);
        expect(path.points[0].y, 150);
        expect(path.points[1].pressure, 0.8);
        expect(path.strokeWidth, 2.0);
      });
    });

    group('TextData Model', () {
      test('should create text annotation data', () {
        const textData = AppAnnotation.TextData(
          text: 'Practice slowly here',
          position: AppAnnotation.Point(x: 100, y: 200, pressure: 0),
          fontSize: 14.0,
          fontWeight: AppAnnotation.FontWeight.normal,
        );
        
        expect(textData.text, 'Practice slowly here');
        expect(textData.position.x, 100);
        expect(textData.position.y, 200);
        expect(textData.fontSize, 14.0);
      });
    });

    group('StampData Model', () {
      test('should create stamp annotation data', () {
        const stampData = AppAnnotation.StampData(
          type: AppAnnotation.StampType.accent,
          position: AppAnnotation.Point(x: 150, y: 100, pressure: 0),
          scale: 1.2,
          rotation: 45.0,
        );
        
        expect(stampData.type, AppAnnotation.StampType.accent);
        expect(stampData.position.x, 150);
        expect(stampData.scale, 1.2);
        expect(stampData.rotation, 45.0);
      });
    });

    group('Annotation Model', () {
      test('should create annotation with vector data', () {
        final annotation = AppAnnotation.Annotation(
          id: 'ann-1',
          pieceId: 'piece-1',
          layerId: 'layer-1',
          page: 1,
          tool: AppAnnotation.AnnotationTool.pen,
          colorTag: AppAnnotation.ColorTag.blue,
          createdAt: DateTime.now(),
          data: AppAnnotation.VectorPath(
            points: const [
              AppAnnotation.Point(x: 50, y: 75, pressure: 1.0),
            ],
            strokeWidth: 2.0,
          ),
        );
        
        expect(annotation.tool, AppAnnotation.AnnotationTool.pen);
        expect(annotation.data, isA<AppAnnotation.VectorPath>());
        expect((annotation.data as AppAnnotation.VectorPath).points.length, 1);
      });

      test('should create annotation with text data', () {
        final annotation = AppAnnotation.Annotation(
          id: 'ann-2',
          pieceId: 'piece-1',
          layerId: 'layer-1',
          page: 1,
          tool: AppAnnotation.AnnotationTool.text,
          colorTag: AppAnnotation.ColorTag.green,
          createdAt: DateTime.now(),
          data: const AppAnnotation.TextData(
            text: 'Important section',
            position: AppAnnotation.Point(x: 100, y: 100, pressure: 0),
            fontSize: 12.0,
            fontWeight: AppAnnotation.FontWeight.bold,
          ),
        );
        
        expect(annotation.tool, AppAnnotation.AnnotationTool.text);
        expect(annotation.data, isA<AppAnnotation.TextData>());
        expect((annotation.data as AppAnnotation.TextData).text, 'Important section');
      });

      test('should create annotation with stamp data', () {
        final annotation = AppAnnotation.Annotation(
          id: 'ann-3',
          pieceId: 'piece-1',
          layerId: 'layer-1',
          page: 2,
          tool: AppAnnotation.AnnotationTool.stamp,
          colorTag: AppAnnotation.ColorTag.red,
          createdAt: DateTime.now(),
          data: const AppAnnotation.StampData(
            type: AppAnnotation.StampType.crescendo,
            position: AppAnnotation.Point(x: 200, y: 150, pressure: 0),
            scale: 0.8,
            rotation: 0.0,
          ),
        );
        
        expect(annotation.tool, AppAnnotation.AnnotationTool.stamp);
        expect(annotation.data, isA<AppAnnotation.StampData>());
        expect((annotation.data as AppAnnotation.StampData).type, AppAnnotation.StampType.crescendo);
      });
    });

    group('AnnotationFilter Model', () {
      test('should create filter with color tags', () {
        const filter = AppAnnotation.AnnotationFilter(
          colorTags: {AppAnnotation.ColorTag.red, AppAnnotation.ColorTag.blue},
          tools: {},
          visualMode: AppAnnotation.FilterVisualMode.hide,
        );
        
        expect(filter.colorTags.length, 2);
        expect(filter.colorTags.contains(AppAnnotation.ColorTag.red), true);
        expect(filter.colorTags.contains(AppAnnotation.ColorTag.blue), true);
        expect(filter.visualMode, AppAnnotation.FilterVisualMode.hide);
      });

      test('should create filter with tools', () {
        const filter = AppAnnotation.AnnotationFilter(
          colorTags: {},
          tools: {AppAnnotation.AnnotationTool.pen, AppAnnotation.AnnotationTool.highlighter},
          visualMode: AppAnnotation.FilterVisualMode.fade,
        );
        
        expect(filter.tools.length, 2);
        expect(filter.tools.contains(AppAnnotation.AnnotationTool.pen), true);
        expect(filter.tools.contains(AppAnnotation.AnnotationTool.highlighter), true);
        expect(filter.visualMode, AppAnnotation.FilterVisualMode.fade);
      });
    });

    group('Enum Tests', () {
      test('should have all annotation tools', () {
        final tools = AppAnnotation.AnnotationTool.values;
        expect(tools.contains(AppAnnotation.AnnotationTool.pen), true);
        expect(tools.contains(AppAnnotation.AnnotationTool.highlighter), true);
        expect(tools.contains(AppAnnotation.AnnotationTool.text), true);
        expect(tools.contains(AppAnnotation.AnnotationTool.stamp), true);
        expect(tools.contains(AppAnnotation.AnnotationTool.eraser), true);
      });

      test('should have all color tags', () {
        final colors = AppAnnotation.ColorTag.values;
        expect(colors.contains(AppAnnotation.ColorTag.red), true);
        expect(colors.contains(AppAnnotation.ColorTag.blue), true);
        expect(colors.contains(AppAnnotation.ColorTag.green), true);
        expect(colors.contains(AppAnnotation.ColorTag.yellow), true);
        expect(colors.contains(AppAnnotation.ColorTag.purple), true);
        expect(colors.contains(AppAnnotation.ColorTag.black), true);
      });

      test('should have all stamp types', () {
        final stamps = AppAnnotation.StampType.values;
        expect(stamps.contains(AppAnnotation.StampType.accent), true);
        expect(stamps.contains(AppAnnotation.StampType.staccato), true);
        expect(stamps.contains(AppAnnotation.StampType.tenuto), true);
        expect(stamps.contains(AppAnnotation.StampType.fermata), true);
        expect(stamps.contains(AppAnnotation.StampType.crescendo), true);
        expect(stamps.contains(AppAnnotation.StampType.diminuendo), true);
      });

      test('should have filter visual modes', () {
        final modes = AppAnnotation.FilterVisualMode.values;
        expect(modes.contains(AppAnnotation.FilterVisualMode.hide), true);
        expect(modes.contains(AppAnnotation.FilterVisualMode.fade), true);
      });
    });

    group('Integration Tests', () {
      test('should handle complex annotation hierarchy', () {
        // Create a layer
        const layer = AppAnnotation.AnnotationLayer(
          id: 'layer-main',
          name: 'Main Annotations',
          colorTag: AppAnnotation.ColorTag.blue,
          isVisible: true,
          createdAt: null,
        );

        // Create multiple annotations in the layer
        final annotations = [
          AppAnnotation.Annotation(
            id: 'ann-1',
            pieceId: 'piece-1',
            layerId: layer.id,
            page: 1,
            tool: AppAnnotation.AnnotationTool.pen,
            colorTag: AppAnnotation.ColorTag.red,
            createdAt: DateTime.now(),
            data: AppAnnotation.VectorPath(
              points: const [AppAnnotation.Point(x: 10, y: 10, pressure: 1.0)],
              strokeWidth: 2.0,
            ),
          ),
          AppAnnotation.Annotation(
            id: 'ann-2',
            pieceId: 'piece-1',
            layerId: layer.id,
            page: 1,
            tool: AppAnnotation.AnnotationTool.text,
            colorTag: AppAnnotation.ColorTag.blue,
            createdAt: DateTime.now(),
            data: const AppAnnotation.TextData(
              text: 'Key change here',
              position: AppAnnotation.Point(x: 100, y: 50, pressure: 0),
              fontSize: 10.0,
              fontWeight: AppAnnotation.FontWeight.normal,
            ),
          ),
        ];

        // Create a filter
        const filter = AppAnnotation.AnnotationFilter(
          colorTags: {AppAnnotation.ColorTag.red},
          tools: {},
          visualMode: AppAnnotation.FilterVisualMode.hide,
        );

        // Test filtering logic
        final filteredAnnotations = annotations.where((annotation) {
          return filter.colorTags.isEmpty || filter.colorTags.contains(annotation.colorTag);
        }).toList();

        expect(annotations.length, 2);
        expect(filteredAnnotations.length, 1);
        expect(filteredAnnotations.first.colorTag, AppAnnotation.ColorTag.red);
        expect(filteredAnnotations.first.tool, AppAnnotation.AnnotationTool.pen);
      });

      test('should handle layer visibility filtering', () {
        // Create layers with different visibility
        const visibleLayer = AppAnnotation.AnnotationLayer(
          id: 'visible',
          name: 'Visible Layer',
          colorTag: AppAnnotation.ColorTag.green,
          isVisible: true,
          createdAt: null,
        );

        const hiddenLayer = AppAnnotation.AnnotationLayer(
          id: 'hidden',
          name: 'Hidden Layer',
          colorTag: AppAnnotation.ColorTag.red,
          isVisible: false,
          createdAt: null,
        );

        final layers = [visibleLayer, hiddenLayer];

        // Filter visible layers
        final visibleLayers = layers.where((layer) => layer.isVisible).toList();
        
        expect(visibleLayers.length, 1);
        expect(visibleLayers.first.id, 'visible');
        expect(visibleLayers.first.isVisible, true);
      });
    });
  });
}
