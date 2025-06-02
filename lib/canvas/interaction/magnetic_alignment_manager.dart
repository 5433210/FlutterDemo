import 'dart:math';
import 'dart:ui';

import '../core/canvas_state_manager.dart';

/// Visual guide for alignment
class AlignmentGuide {
  final Offset start;
  final Offset end;
  final GuideType type;
  final double strength; // 0.0 to 1.0

  const AlignmentGuide({
    required this.start,
    required this.end,
    required this.type,
    required this.strength,
  });

  @override
  int get hashCode => start.hashCode ^ end.hashCode ^ type.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlignmentGuide &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          type == other.type;
}

/// Alignment modes for multiple elements
enum AlignmentMode {
  independent, // Each element aligns independently
  grouped, // Elements align as a group
  chain, // Elements align in sequence
}

/// Performance statistics for alignment operations
class AlignmentPerformanceStats {
  final int totalOperations;
  final double averageProcessingTime;
  final double totalProcessingTime;

  const AlignmentPerformanceStats({
    required this.totalOperations,
    required this.averageProcessingTime,
    required this.totalProcessingTime,
  });
}

/// Result of position alignment
class AlignmentResult {
  final Offset originalPosition;
  final Offset alignedPosition;
  final List<SnapResult> appliedSnaps;
  final Set<AlignmentGuide> guides;
  final double processingTimeMs;

  const AlignmentResult({
    required this.originalPosition,
    required this.alignedPosition,
    required this.appliedSnaps,
    required this.guides,
    required this.processingTimeMs,
  });

  Offset get offset => alignedPosition - originalPosition;
  bool get wasAligned => appliedSnaps.isNotEmpty;
}

/// Result of group alignment
class GroupAlignmentResult {
  final Map<String, AlignmentResult> results;
  final Set<AlignmentGuide> guides;
  final Offset groupOffset;

  const GroupAlignmentResult({
    required this.results,
    required this.guides,
    required this.groupOffset,
  });
}

/// Types of alignment guides
enum GuideType {
  horizontal,
  vertical,
}

/// Manages magnetic alignment features for canvas elements
/// Provides snap-to-grid and element-to-element alignment
class MagneticAlignmentManager {
  final CanvasStateManager _stateManager;

  // Configuration
  double _gridSnapDistance = 10.0;
  double _elementSnapDistance = 8.0;
  bool _snapToGridEnabled = true;
  bool _snapToElementsEnabled = true;

  // Grid settings
  double _gridSize = 20.0;
  Offset _gridOffset = Offset.zero;

  // Performance monitoring
  int _snapOperations = 0;
  double _totalSnapTime = 0.0;

  // Alignment guides
  final Set<AlignmentGuide> _activeGuides = {};

  MagneticAlignmentManager(this._stateManager);

  /// Aligns multiple elements simultaneously
  MultiElementAlignmentResult alignMultipleElements(
    Map<String, Offset> elementPositions, {
    AlignmentMode mode = AlignmentMode.independent,
  }) {
    final results = <String, AlignmentResult>{};
    final allGuides = <AlignmentGuide>{};

    switch (mode) {
      case AlignmentMode.independent:
        // Align each element independently
        for (final entry in elementPositions.entries) {
          final excludeIds =
              elementPositions.keys.where((id) => id != entry.key).toList();

          final result = alignPosition(entry.value, excludeIds);
          results[entry.key] = result;
          allGuides.addAll(result.guides);
        }
        break;

      case AlignmentMode.grouped:
        // Align elements as a group
        final groupResult = _alignElementGroup(elementPositions);
        results.addAll(groupResult.results);
        allGuides.addAll(groupResult.guides);
        break;

      case AlignmentMode.chain:
        // Align elements in sequence, considering previous alignments
        final sortedEntries = elementPositions.entries.toList()
          ..sort((a, b) => a.value.dx.compareTo(b.value.dx));

        final processedPositions = <String, Offset>{};

        for (final entry in sortedEntries) {
          final excludeIds = [
            ...processedPositions.keys,
            ...elementPositions.keys.where((id) => id != entry.key),
          ];

          final result = alignPosition(entry.value, excludeIds);
          results[entry.key] = result;
          allGuides.addAll(result.guides);
          processedPositions[entry.key] = result.alignedPosition;
        }
        break;
    }

    return MultiElementAlignmentResult(
      results: results,
      guides: allGuides,
      mode: mode,
    );
  }

  /// Performs magnetic alignment for a position
  AlignmentResult alignPosition(
    Offset position,
    List<String> excludeElementIds, {
    bool includeGrid = true,
    bool includeElements = true,
  }) {
    final stopwatch = Stopwatch()..start();

    var alignedPosition = position;
    final appliedSnaps = <SnapResult>[];
    _activeGuides.clear();

    // Grid snapping
    if (includeGrid && _snapToGridEnabled) {
      final gridSnap = _snapToGrid(position);
      if (gridSnap.applied) {
        alignedPosition = gridSnap.position;
        appliedSnaps.add(gridSnap);
      }
    }

    // Element snapping (only if grid snap wasn't applied or is disabled)
    if (includeElements && _snapToElementsEnabled && appliedSnaps.isEmpty) {
      final elementSnap = _snapToElements(position, excludeElementIds);
      if (elementSnap.applied) {
        alignedPosition = elementSnap.position;
        appliedSnaps.add(elementSnap);

        // Add alignment guides
        _activeGuides.addAll(elementSnap.guides);
      }
    }

    stopwatch.stop();
    _snapOperations++;
    _totalSnapTime += stopwatch.elapsedMicroseconds / 1000.0;

    return AlignmentResult(
      originalPosition: position,
      alignedPosition: alignedPosition,
      appliedSnaps: appliedSnaps,
      guides: Set.from(_activeGuides),
      processingTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
    );
  }

  /// Clears all active guides
  void clearGuides() => _activeGuides.clear();

  void configureElementSnap({
    double? snapDistance,
    bool? enabled,
  }) {
    if (snapDistance != null) _elementSnapDistance = snapDistance;
    if (enabled != null) _snapToElementsEnabled = enabled;
  }

  // Configuration methods
  void configureGrid({
    double? size,
    Offset? offset,
    double? snapDistance,
    bool? enabled,
  }) {
    if (size != null) _gridSize = size;
    if (offset != null) _gridOffset = offset;
    if (snapDistance != null) _gridSnapDistance = snapDistance;
    if (enabled != null) _snapToGridEnabled = enabled;
  }

  /// Gets current active alignment guides
  Set<AlignmentGuide> getActiveGuides() => Set.from(_activeGuides);

  /// Gets performance statistics
  AlignmentPerformanceStats getPerformanceStats() {
    return AlignmentPerformanceStats(
      totalOperations: _snapOperations,
      averageProcessingTime:
          _snapOperations > 0 ? _totalSnapTime / _snapOperations : 0.0,
      totalProcessingTime: _totalSnapTime,
    );
  }

  /// Resets performance statistics
  void resetPerformanceStats() {
    _snapOperations = 0;
    _totalSnapTime = 0.0;
  }

  /// Aligns a group of elements together
  GroupAlignmentResult _alignElementGroup(
      Map<String, Offset> elementPositions) {
    final results = <String, AlignmentResult>{};
    final allGuides = <AlignmentGuide>{};

    // Calculate group bounds
    final positions = elementPositions.values.toList();
    final minX = positions.map((p) => p.dx).reduce(min);
    final maxX = positions.map((p) => p.dx).reduce(max);
    final minY = positions.map((p) => p.dy).reduce(min);
    final maxY = positions.map((p) => p.dy).reduce(max);

    final groupCenter = Offset(
      (minX + maxX) / 2,
      (minY + maxY) / 2,
    );

    // Try to align the group center to grid or other elements
    final centerAlignment =
        alignPosition(groupCenter, elementPositions.keys.toList());
    final offset = centerAlignment.alignedPosition - groupCenter;

    // Apply the offset to all elements
    for (final entry in elementPositions.entries) {
      final alignedPosition = entry.value + offset;
      results[entry.key] = AlignmentResult(
        originalPosition: entry.value,
        alignedPosition: alignedPosition,
        appliedSnaps: centerAlignment.appliedSnaps,
        guides: centerAlignment.guides,
        processingTimeMs: centerAlignment.processingTimeMs,
      );
    }

    allGuides.addAll(centerAlignment.guides);

    return GroupAlignmentResult(
      results: results,
      guides: allGuides,
      groupOffset: offset,
    );
  }

  /// Snaps position to nearby elements
  SnapResult _snapToElements(Offset position, List<String> excludeElementIds) {
    final elements = _stateManager.selectableElements
        .where((element) => !excludeElementIds.contains(element.id))
        .toList();

    double minDistance = double.infinity;
    Offset? bestPosition;
    SnapType bestSnapType = SnapType.none;
    final guides = <AlignmentGuide>{};

    for (final element in elements) {
      final elementBounds = element.bounds;

      // Check horizontal alignment (snapping to vertical lines)
      final horizontalSnaps = [
        elementBounds.left, // Left edge
        elementBounds.center.dx, // Center
        elementBounds.right, // Right edge
      ];

      for (final snapX in horizontalSnaps) {
        final distance = (position.dx - snapX).abs();
        if (distance <= _elementSnapDistance && distance < minDistance) {
          minDistance = distance;
          bestPosition = Offset(snapX, position.dy);
          bestSnapType = SnapType.elementVertical;

          guides.clear();
          guides.add(AlignmentGuide(
            start: Offset(snapX, elementBounds.top - 20),
            end: Offset(snapX, elementBounds.bottom + 20),
            type: GuideType.vertical,
            strength: 1.0 - (distance / _elementSnapDistance),
          ));
        }
      }

      // Check vertical alignment (snapping to horizontal lines)
      final verticalSnaps = [
        elementBounds.top, // Top edge
        elementBounds.center.dy, // Center
        elementBounds.bottom, // Bottom edge
      ];

      for (final snapY in verticalSnaps) {
        final distance = (position.dy - snapY).abs();
        if (distance <= _elementSnapDistance && distance < minDistance) {
          minDistance = distance;
          bestPosition = Offset(position.dx, snapY);
          bestSnapType = SnapType.elementHorizontal;

          guides.clear();
          guides.add(AlignmentGuide(
            start: Offset(elementBounds.left - 20, snapY),
            end: Offset(elementBounds.right + 20, snapY),
            type: GuideType.horizontal,
            strength: 1.0 - (distance / _elementSnapDistance),
          ));
        }
      }
    }

    if (bestPosition != null) {
      return SnapResult(
        position: bestPosition,
        snapType: bestSnapType,
        distance: minDistance,
        applied: true,
        guides: guides,
      );
    }

    return SnapResult(
      position: position,
      snapType: SnapType.none,
      distance: 0,
      applied: false,
      guides: {},
    );
  }

  /// Snaps position to grid
  SnapResult _snapToGrid(Offset position) {
    final adjustedPosition = position - _gridOffset;
    final gridX = (adjustedPosition.dx / _gridSize).round() * _gridSize;
    final gridY = (adjustedPosition.dy / _gridSize).round() * _gridSize;
    final gridPosition = Offset(gridX, gridY) + _gridOffset;

    final distance = (position - gridPosition).distance;

    if (distance <= _gridSnapDistance) {
      return SnapResult(
        position: gridPosition,
        snapType: SnapType.grid,
        distance: distance,
        applied: true,
        guides: {},
      );
    }

    return SnapResult(
      position: position,
      snapType: SnapType.none,
      distance: 0,
      applied: false,
      guides: {},
    );
  }
}

/// Result of multiple element alignment
class MultiElementAlignmentResult {
  final Map<String, AlignmentResult> results;
  final Set<AlignmentGuide> guides;
  final AlignmentMode mode;

  const MultiElementAlignmentResult({
    required this.results,
    required this.guides,
    required this.mode,
  });
}

/// Result of a snap operation
class SnapResult {
  final Offset position;
  final SnapType snapType;
  final double distance;
  final bool applied;
  final Set<AlignmentGuide> guides;

  const SnapResult({
    required this.position,
    required this.snapType,
    required this.distance,
    required this.applied,
    required this.guides,
  });
}

/// Types of snapping
enum SnapType {
  none,
  grid,
  elementVertical,
  elementHorizontal,
}
