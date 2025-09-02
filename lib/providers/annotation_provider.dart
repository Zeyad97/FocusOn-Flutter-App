import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/annotation.dart';
import '../services/annotation_service.dart';

// ====================================================================
// ANNOTATION STATE PROVIDERS
// ====================================================================

/// Current annotations for the active piece
final annotationsProvider = StateNotifierProvider.family<AnnotationsNotifier, AsyncValue<List<Annotation>>, String>(
  (ref, pieceId) => AnnotationsNotifier(ref, pieceId),
);

/// Current annotation layers
final layersProvider = StateNotifierProvider<LayersNotifier, AsyncValue<List<AnnotationLayer>>>(
  (ref) => LayersNotifier(ref),
);

/// Current annotation filter for piece
final annotationFilterProvider = StateNotifierProvider.family<AnnotationFilterNotifier, AnnotationFilter, String>(
  (ref, pieceId) => AnnotationFilterNotifier(ref, pieceId),
);

/// Current annotation tool and settings
final annotationToolProvider = StateNotifierProvider<AnnotationToolNotifier, AnnotationToolState>(
  (ref) => AnnotationToolNotifier(),
);

/// Filtered annotations based on current filter
final filteredAnnotationsProvider = Provider.family<List<Annotation>, String>((ref, pieceId) {
  final annotationsAsync = ref.watch(annotationsProvider(pieceId));
  final filter = ref.watch(annotationFilterProvider(pieceId));
  
  return annotationsAsync.when(
    data: (annotations) {
      if (filter.isActive) {
        return filter.apply(annotations);
      }
      return annotations;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Faded annotations for opacity rendering
final fadedAnnotationsProvider = Provider.family<List<Annotation>, String>((ref, pieceId) {
  final annotationsAsync = ref.watch(annotationsProvider(pieceId));
  final filter = ref.watch(annotationFilterProvider(pieceId));
  
  return annotationsAsync.when(
    data: (annotations) {
      if (filter.isActive && filter.fadeNonMatching) {
        return filter.getFadedAnnotations(annotations);
      }
      return [];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Visible layers only
final visibleLayersProvider = Provider<List<AnnotationLayer>>((ref) {
  final layersAsync = ref.watch(layersProvider);
  return layersAsync.when(
    data: (layers) => layers.where((layer) => layer.isVisible).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ====================================================================
// STATE NOTIFIERS
// ====================================================================

/// Manages annotations for a specific piece
class AnnotationsNotifier extends StateNotifier<AsyncValue<List<Annotation>>> {
  final Ref ref;
  final String pieceId;
  late final AnnotationService _service;

  AnnotationsNotifier(this.ref, this.pieceId) : super(const AsyncValue.loading()) {
    _service = ref.read(annotationServiceProvider);
    _loadAnnotations();
  }

  /// Load annotations from service
  Future<void> _loadAnnotations() async {
    try {
      final annotations = await _service.getAnnotationsForPiece(pieceId);
      if (mounted) {
        state = AsyncValue.data(annotations);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// Add new annotation
  Future<void> addAnnotation(Annotation annotation) async {
    try {
      await _service.saveAnnotation(annotation);
      
      // Update state immediately for responsive UI
      state.whenData((annotations) {
        if (mounted) {
          state = AsyncValue.data([...annotations, annotation]);
        }
      });
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// Update existing annotation
  Future<void> updateAnnotation(Annotation annotation) async {
    try {
      await _service.updateAnnotation(annotation);
      
      // Update state immediately
      state.whenData((annotations) {
        if (mounted) {
          final updatedList = annotations.map((a) => 
            a.id == annotation.id ? annotation : a
          ).toList();
          state = AsyncValue.data(updatedList);
        }
      });
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// Remove annotation
  Future<void> removeAnnotation(String annotationId) async {
    try {
      await _service.deleteAnnotation(annotationId, pieceId);
      
      // Update state immediately
      state.whenData((annotations) {
        if (mounted) {
          final updatedList = annotations.where((a) => a.id != annotationId).toList();
          state = AsyncValue.data(updatedList);
        }
      });
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// Refresh annotations from database
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadAnnotations();
  }

  /// Clear all annotations for piece
  Future<void> clearAll() async {
    try {
      final currentAnnotations = state.value ?? [];
      for (final annotation in currentAnnotations) {
        await _service.deleteAnnotation(annotation.id, pieceId);
      }
      
      if (mounted) {
        state = const AsyncValue.data([]);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }
}

/// Manages annotation layers
class LayersNotifier extends StateNotifier<AsyncValue<List<AnnotationLayer>>> {
  final Ref ref;
  late final AnnotationService _service;

  LayersNotifier(this.ref) : super(const AsyncValue.loading()) {
    _service = ref.read(annotationServiceProvider);
    _loadLayers();
  }

  /// Load layers from service
  Future<void> _loadLayers() async {
    try {
      final layers = await _service.getLayers();
      if (mounted) {
        state = AsyncValue.data(layers);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// Add new layer
  Future<void> addLayer(AnnotationLayer layer) async {
    try {
      await _service.saveLayer(layer);
      
      state.whenData((layers) {
        if (mounted) {
          state = AsyncValue.data([...layers, layer]);
        }
      });
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// Update existing layer
  Future<void> updateLayer(AnnotationLayer layer) async {
    try {
      await _service.updateLayer(layer);
      
      state.whenData((layers) {
        if (mounted) {
          final updatedList = layers.map((l) => 
            l.id == layer.id ? layer : l
          ).toList();
          state = AsyncValue.data(updatedList);
        }
      });
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// Delete layer
  Future<void> deleteLayer(String layerId, {bool deleteAnnotations = false}) async {
    try {
      await _service.deleteLayer(layerId);
      
      state.whenData((layers) {
        if (mounted) {
          final updatedList = layers.where((l) => l.id != layerId).toList();
          state = AsyncValue.data(updatedList);
        }
      });
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// Toggle layer visibility
  Future<void> toggleVisibility(String layerId) async {
    try {
      await _service.toggleLayerVisibility(layerId);
      
      state.whenData((layers) {
        if (mounted) {
          final updatedList = layers.map((layer) {
            if (layer.id == layerId) {
              return layer.copyWith(isVisible: !layer.isVisible);
            }
            return layer;
          }).toList();
          state = AsyncValue.data(updatedList);
        }
      });
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// Refresh layers from database
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadLayers();
  }
}

/// Manages annotation filter for a specific piece
class AnnotationFilterNotifier extends StateNotifier<AnnotationFilter> {
  final Ref ref;
  final String pieceId;
  late final AnnotationService _service;

  AnnotationFilterNotifier(this.ref, this.pieceId) : super(const AnnotationFilter()) {
    _service = ref.read(annotationServiceProvider);
    _loadSavedFilter();
  }

  /// Load saved filter for piece
  void _loadSavedFilter() {
    final savedFilter = _service.getFilterForPiece(pieceId);
    if (savedFilter != null) {
      state = savedFilter;
    } else {
      state = _service.getDefaultFilter();
    }
  }

  /// Update color tag filter
  void setColorTags(Set<ColorTag>? colorTags) {
    final newFilter = state.copyWith(colorTags: colorTags);
    state = newFilter;
    _service.saveFilterForPiece(pieceId, newFilter);
  }

  /// Update tool filter
  void setTools(Set<AnnotationTool>? tools) {
    final newFilter = state.copyWith(tools: tools);
    state = newFilter;
    _service.saveFilterForPiece(pieceId, newFilter);
  }

  /// Set date filter to today only
  void setShowToday() {
    final newFilter = state.copyWith(
      showToday: true,
      showLast7Days: false,
      showAll: false,
      customStart: null,
      customEnd: null,
    );
    state = newFilter;
    _service.saveFilterForPiece(pieceId, newFilter);
  }

  /// Set date filter to last 7 days
  void setShowLast7Days() {
    final newFilter = state.copyWith(
      showToday: false,
      showLast7Days: true,
      showAll: false,
      customStart: null,
      customEnd: null,
    );
    state = newFilter;
    _service.saveFilterForPiece(pieceId, newFilter);
  }

  /// Set date filter to show all
  void setShowAll() {
    final newFilter = state.copyWith(
      showToday: false,
      showLast7Days: false,
      showAll: true,
      customStart: null,
      customEnd: null,
    );
    state = newFilter;
    _service.saveFilterForPiece(pieceId, newFilter);
  }

  /// Set custom date range
  void setCustomDateRange(DateTime? start, DateTime? end) {
    final newFilter = state.copyWith(
      showToday: false,
      showLast7Days: false,
      showAll: false,
      customStart: start,
      customEnd: end,
    );
    state = newFilter;
    _service.saveFilterForPiece(pieceId, newFilter);
  }

  /// Toggle fade non-matching vs hide completely
  void toggleFadeMode() {
    final newFilter = state.copyWith(fadeNonMatching: !state.fadeNonMatching);
    state = newFilter;
    _service.saveFilterForPiece(pieceId, newFilter);
  }

  /// Reset filter to default
  void reset() {
    final defaultFilter = _service.getDefaultFilter();
    state = defaultFilter;
    _service.saveFilterForPiece(pieceId, defaultFilter);
  }

  /// Quick filter presets
  void applyQuickFilter(QuickFilter quickFilter) {
    switch (quickFilter) {
      case QuickFilter.todayOnly:
        setShowToday();
        break;
      case QuickFilter.last7Days:
        setShowLast7Days();
        break;
      case QuickFilter.dynamicsOnly:
        setColorTags({ColorTag.yellow});
        break;
      case QuickFilter.fingeringOnly:
        setColorTags({ColorTag.blue});
        break;
      case QuickFilter.errorsOnly:
        setColorTags({ColorTag.red});
        break;
      case QuickFilter.textOnly:
        setTools({AnnotationTool.text});
        break;
      case QuickFilter.stampsOnly:
        setTools({AnnotationTool.stamp});
        break;
      case QuickFilter.clear:
        reset();
        break;
    }
  }

  /// Add a color to the current filter
  void addColor(ColorTag color) {
    final currentColors = state.colorTags ?? <ColorTag>{};
    final newColors = {...currentColors, color};
    setColorTags(newColors);
  }

  /// Remove a color from the current filter
  void removeColor(ColorTag color) {
    final currentColors = state.colorTags ?? <ColorTag>{};
    final newColors = {...currentColors};
    newColors.remove(color);
    setColorTags(newColors.isEmpty ? null : newColors);
  }

  /// Add a tool to the current filter
  void addTool(AnnotationTool tool) {
    final currentTools = state.tools ?? <AnnotationTool>{};
    final newTools = {...currentTools, tool};
    setTools(newTools);
  }

  /// Remove a tool from the current filter
  void removeTool(AnnotationTool tool) {
    final currentTools = state.tools ?? <AnnotationTool>{};
    final newTools = {...currentTools};
    newTools.remove(tool);
    setTools(newTools.isEmpty ? null : newTools);
  }

  /// Set date range filter
  void setDateRange(DateTimeRange range) {
    final newFilter = state.copyWith(
      showToday: false,
      showLast7Days: false,
      showAll: false,
      customStart: range.start,
      customEnd: range.end,
    );
    state = newFilter;
    _service.saveFilterForPiece(pieceId, newFilter);
  }

  /// Set whether to show filtered annotations with reduced opacity
  void setShowFiltered(bool showFiltered) {
    final newFilter = state.copyWith(fadeNonMatching: showFiltered);
    state = newFilter;
    _service.saveFilterForPiece(pieceId, newFilter);
  }

  /// Set the opacity level for filtered annotations
  void setFilteredOpacity(double opacity) {
    final newFilter = state.copyWith(fadeNonMatching: opacity > 0);
    state = newFilter;
    _service.saveFilterForPiece(pieceId, newFilter);
  }
}

/// Current annotation tool and settings
class AnnotationToolState {
  final AnnotationTool currentTool;
  final ColorTag currentColorTag;
  final String currentLayerId;
  final double strokeWidth;
  final double fontSize;
  final StampType currentStampType;
  final bool isDrawing;

  const AnnotationToolState({
    this.currentTool = AnnotationTool.pen,
    this.currentColorTag = ColorTag.blue,
    this.currentLayerId = 'default',
    this.strokeWidth = 2.0,
    this.fontSize = 14.0,
    this.currentStampType = StampType.fingering1,
    this.isDrawing = false,
  });

  AnnotationToolState copyWith({
    AnnotationTool? currentTool,
    ColorTag? currentColorTag,
    String? currentLayerId,
    double? strokeWidth,
    double? fontSize,
    StampType? currentStampType,
    bool? isDrawing,
  }) {
    return AnnotationToolState(
      currentTool: currentTool ?? this.currentTool,
      currentColorTag: currentColorTag ?? this.currentColorTag,
      currentLayerId: currentLayerId ?? this.currentLayerId,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      fontSize: fontSize ?? this.fontSize,
      currentStampType: currentStampType ?? this.currentStampType,
      isDrawing: isDrawing ?? this.isDrawing,
    );
  }
}

/// Manages annotation tool state
class AnnotationToolNotifier extends StateNotifier<AnnotationToolState> {
  AnnotationToolNotifier() : super(const AnnotationToolState());

  void setTool(AnnotationTool tool) {
    state = state.copyWith(currentTool: tool);
  }

  void setColorTag(ColorTag colorTag) {
    state = state.copyWith(currentColorTag: colorTag);
  }

  void setLayer(String layerId) {
    state = state.copyWith(currentLayerId: layerId);
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
  }

  void setStampType(StampType stampType) {
    state = state.copyWith(currentStampType: stampType);
  }

  void setDrawing(bool isDrawing) {
    state = state.copyWith(isDrawing: isDrawing);
  }
}

/// Quick filter presets for easy access
enum QuickFilter {
  todayOnly,
  last7Days,
  dynamicsOnly,
  fingeringOnly,
  errorsOnly,
  textOnly,
  stampsOnly,
  clear,
}

extension QuickFilterExtension on QuickFilter {
  String get displayName {
    switch (this) {
      case QuickFilter.todayOnly:
        return 'Today Only';
      case QuickFilter.last7Days:
        return 'Last 7 Days';
      case QuickFilter.dynamicsOnly:
        return 'Dynamics Only';
      case QuickFilter.fingeringOnly:
        return 'Fingering Only';
      case QuickFilter.errorsOnly:
        return 'Errors Only';
      case QuickFilter.textOnly:
        return 'Text Only';
      case QuickFilter.stampsOnly:
        return 'Stamps Only';
      case QuickFilter.clear:
        return 'Clear Filters';
    }
  }

  String get description {
    switch (this) {
      case QuickFilter.todayOnly:
        return 'Show only annotations added today';
      case QuickFilter.last7Days:
        return 'Show annotations from the last week';
      case QuickFilter.dynamicsOnly:
        return 'Show only yellow (dynamics) annotations';
      case QuickFilter.fingeringOnly:
        return 'Show only blue (fingering) annotations';
      case QuickFilter.errorsOnly:
        return 'Show only red (error) annotations';
      case QuickFilter.textOnly:
        return 'Show only text annotations';
      case QuickFilter.stampsOnly:
        return 'Show only stamp annotations';
      case QuickFilter.clear:
        return 'Remove all filters';
    }
  }
}
