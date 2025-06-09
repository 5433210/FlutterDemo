import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../pages/practices/widgets/element_change_types.dart';
import 'dirty_tracker.dart';
import 'element_cache_manager.dart';

/// Strategies for rebuilding elements based on change type
enum RebuildStrategy {
  /// Only update content within existing widget structure
  contentUpdate,

  /// Minimal rebuild with optimized widget reuse
  minimalRebuild,

  /// Update layout positioning without rebuilding widget
  layoutUpdate,

  /// Update transform properties (rotation, scale)
  transformUpdate,

  /// Full widget rebuild required
  fullRebuild,
}

/// Manages selective rebuilding of elements based on dirty tracking
class SelectiveRebuildManager extends ChangeNotifier {
  final DirtyTracker _dirtyTracker;

  /// Map of element ID to widget build version
  final Map<String, int> _widgetVersions = <String, int>{};

  /// Map of element ID to last rebuild timestamp for performance tracking
  final Map<String, DateTime> _lastRebuildTimes = <String, DateTime>{};

  /// Set of elements currently being rebuilt to prevent circular rebuilds
  final Set<String> _rebuilding = <String>{};

  /// Performance metrics
  int _totalRebuilds = 0;
  int _skippedRebuilds = 0;
  Duration _totalRebuildTime = Duration.zero;

  SelectiveRebuildManager({
    required DirtyTracker dirtyTracker,
    required ElementCacheManager
        cacheManager, // Used for initialization/coordination
  }) : _dirtyTracker = dirtyTracker {
    // Listen to dirty tracker changes
    _dirtyTracker.addListener(_onDirtyTrackerChanged);
  }

  /// Complete element rebuild and update tracking
  void completeElementRebuild(String elementId, Widget widget) {
    _rebuilding.remove(elementId);

    // Update widget version
    _widgetVersions[elementId] = _dirtyTracker.globalVersion;

    // Update rebuild timestamp
    _lastRebuildTimes[elementId] = DateTime.now();

    // Mark element as clean in dirty tracker
    _dirtyTracker.markElementClean(elementId);

    // Update performance metrics
    _totalRebuilds++;
  }

  @override
  void dispose() {
    _dirtyTracker.removeListener(_onDirtyTrackerChanged);
    _rebuilding.clear();
    _widgetVersions.clear();
    _lastRebuildTimes.clear();
    super.dispose();
  }

  /// Get performance metrics
  SelectiveRebuildMetrics getMetrics() {
    return SelectiveRebuildMetrics(
      totalRebuilds: _totalRebuilds,
      skippedRebuilds: _skippedRebuilds,
      totalRebuildTime: _totalRebuildTime,
      averageRebuildTime: _totalRebuilds > 0
          ? Duration(
              microseconds: _totalRebuildTime.inMicroseconds ~/ _totalRebuilds)
          : Duration.zero,
      currentlyRebuilding: _rebuilding.length,
      trackedElements: _widgetVersions.length,
      rebuildEfficiency: _totalRebuilds + _skippedRebuilds > 0
          ? _skippedRebuilds / (_totalRebuilds + _skippedRebuilds)
          : 0.0,
    );
  }

  /// Get rebuild strategy for an element based on change type
  RebuildStrategy getRebuildStrategy(
      String elementId, ElementChangeType changeType) {
    switch (changeType) {
      case ElementChangeType.contentOnly:
        // Content-only changes might be handled by updating existing widget
        return RebuildStrategy.contentUpdate;

      case ElementChangeType.opacity:
        // Opacity changes can be handled with minimal rebuild
        return RebuildStrategy.minimalRebuild;

      case ElementChangeType.positionOnly:
        // Position changes only need layout update, not widget rebuild
        return RebuildStrategy.layoutUpdate;

      case ElementChangeType.sizeOnly:
      case ElementChangeType.sizeAndPosition:
        // Size changes require widget rebuild but cache might be reusable
        return RebuildStrategy.fullRebuild;

      case ElementChangeType.rotation:
        // Rotation needs transform update
        return RebuildStrategy.transformUpdate;

      case ElementChangeType.visibility:
      case ElementChangeType.created:
      case ElementChangeType.deleted:
        // These need full handling
        return RebuildStrategy.fullRebuild;
      case ElementChangeType.multiple:
        // Multiple changes require full rebuild
        return RebuildStrategy.fullRebuild;
    }
  }

  /// Process a batch of element rebuilds efficiently
  List<String> processBatchRebuild(List<String> elementIds) {
    final startTime = DateTime.now();
    final rebuiltElements = <String>[];

    _dirtyTracker.startBatch();

    try {
      for (final elementId in elementIds) {
        if (shouldRebuildElement(elementId)) {
          rebuiltElements.add(elementId);
          startElementRebuild(elementId);
        } else {
          skipElementRebuild(elementId, 'Not dirty or already up-to-date');
        }
      }
    } finally {
      _dirtyTracker.endBatch();
    }

    final batchTime = DateTime.now().difference(startTime);
    _totalRebuildTime += batchTime;

    EditPageLogger.performanceInfo('批量重建处理完成', data: {
      'totalElements': elementIds.length,
      'rebuiltElements': rebuiltElements.length,
      'batchTimeMs': batchTime.inMilliseconds
    });

    return rebuiltElements;
  }

  /// Clear rebuild tracking for an element
  void removeElement(String elementId) {
    _rebuilding.remove(elementId);
    _widgetVersions.remove(elementId);
    _lastRebuildTimes.remove(elementId);
    _dirtyTracker.removeElement(elementId);
  }

  /// Reset performance metrics
  void resetMetrics() {
    _totalRebuilds = 0;
    _skippedRebuilds = 0;
    _totalRebuildTime = Duration.zero;
  }

  /// Check if an element needs rebuilding
  bool shouldRebuildElement(String elementId) {
    // If element is currently being rebuilt, don't rebuild again
    if (_rebuilding.contains(elementId)) {
      return false;
    }

    // If element is dirty, it needs rebuilding
    if (_dirtyTracker.isElementDirty(elementId)) {
      return true;
    }

    // If element widget version is outdated, it needs rebuilding
    final currentVersion = _dirtyTracker.getElementVersion(elementId);
    final widgetVersion = _widgetVersions[elementId] ?? 0;

    return widgetVersion < currentVersion;
  }

  /// Skip rebuild for an element (used when reusing cached widget)
  void skipElementRebuild(String elementId, String reason) {
    _skippedRebuilds++;
    EditPageLogger.performanceInfo('跳过元素重建', data: {
      'elementId': elementId,
      'reason': reason
    });
  }

  /// Mark that an element is starting rebuild
  void startElementRebuild(String elementId) {
    _rebuilding.add(elementId);
  }

  /// Handle dirty tracker changes
  void _onDirtyTrackerChanged() {
    // Notify listeners when dirty state changes
    notifyListeners();
  }
}

/// Performance metrics for selective rebuilding
class SelectiveRebuildMetrics {
  final int totalRebuilds;
  final int skippedRebuilds;
  final Duration totalRebuildTime;
  final Duration averageRebuildTime;
  final int currentlyRebuilding;
  final int trackedElements;
  final double rebuildEfficiency;

  const SelectiveRebuildMetrics({
    required this.totalRebuilds,
    required this.skippedRebuilds,
    required this.totalRebuildTime,
    required this.averageRebuildTime,
    required this.currentlyRebuilding,
    required this.trackedElements,
    required this.rebuildEfficiency,
  });

  /// Get a compact report for performance monitoring
  String getCompactReport() {
    return 'Rebuilds: $totalRebuilds, Skipped: $skippedRebuilds, '
        'Efficiency: ${(rebuildEfficiency * 100).toStringAsFixed(1)}%, '
        'Avg: ${averageRebuildTime.inMilliseconds}ms';
  }

  @override
  String toString() {
    return 'SelectiveRebuildMetrics(\n'
        '  totalRebuilds: $totalRebuilds,\n'
        '  skippedRebuilds: $skippedRebuilds,\n'
        '  rebuildEfficiency: ${(rebuildEfficiency * 100).toStringAsFixed(1)}%,\n'
        '  averageRebuildTime: ${averageRebuildTime.inMilliseconds}ms,\n'
        '  currentlyRebuilding: $currentlyRebuilding,\n'
        '  trackedElements: $trackedElements\n'
        ')';
  }
}
