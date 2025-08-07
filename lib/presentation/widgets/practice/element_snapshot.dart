import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';

/// Element snapshot system for optimizing drag operations
///
/// This system creates lightweight snapshots of elements at the start of drag operations,
/// which can be used for preview rendering without repeatedly querying element data.
class ElementSnapshot {
  /// Unique identifier for the element
  final String elementId;

  /// Original position of the element when snapshot was created
  final Offset originalPosition;

  /// Element properties at snapshot time
  final Map<String, dynamic> properties;

  /// Optional cached widget representation for fastest preview rendering
  final Widget? cachedWidget;

  /// Optional cached image for ultra-lightweight rendering
  final ui.Image? cachedImage;

  /// Timestamp when snapshot was created
  final DateTime createdAt;

  /// Element type for optimized rendering strategy
  final String elementType;

  ElementSnapshot({
    required this.elementId,
    required this.originalPosition,
    required this.properties,
    required this.elementType,
    this.cachedWidget,
    this.cachedImage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a snapshot from element data
  factory ElementSnapshot.fromElement(Map<String, dynamic> element) {
    final elementId = element['id'] as String;
    final x = (element['x'] as num?)?.toDouble() ?? 0.0;
    final y = (element['y'] as num?)?.toDouble() ?? 0.0;
    final elementType = element['type'] as String? ?? 'unknown';

    return ElementSnapshot(
      elementId: elementId,
      originalPosition: Offset(x, y),
      properties: Map<String, dynamic>.from(element),
      elementType: elementType,
    );
  }

  /// Check if the snapshot is still fresh (for cache invalidation)
  bool get isFresh {
    const maxAge = Duration(minutes: 5);
    return DateTime.now().difference(createdAt) < maxAge;
  }

  /// Get the rotation of the element
  double get rotation {
    return (properties['rotation'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get the dimensions of the element
  Size get size {
    final width = (properties['width'] as num?)?.toDouble() ?? 0.0;
    final height = (properties['height'] as num?)?.toDouble() ?? 0.0;
    return Size(width, height);
  }

  /// Create a copy with cached image
  ElementSnapshot copyWithCachedImage(ui.Image image) {
    return ElementSnapshot(
      elementId: elementId,
      originalPosition: originalPosition,
      properties: properties,
      elementType: elementType,
      cachedWidget: cachedWidget,
      cachedImage: image,
      createdAt: createdAt,
    );
  }

  /// Create a copy with cached widget
  ElementSnapshot copyWithCachedWidget(Widget widget) {
    return ElementSnapshot(
      elementId: elementId,
      originalPosition: originalPosition,
      properties: properties,
      elementType: elementType,
      cachedWidget: widget,
      cachedImage: cachedImage,
      createdAt: createdAt,
    );
  }

  /// Create a copy with updated position
  ElementSnapshot copyWithPosition(Offset newPosition) {
    final updatedProperties = Map<String, dynamic>.from(properties);
    updatedProperties['x'] = newPosition.dx;
    updatedProperties['y'] = newPosition.dy;

    return ElementSnapshot(
      elementId: elementId,
      originalPosition: newPosition,
      properties: updatedProperties,
      elementType: elementType,
      cachedWidget: cachedWidget,
      cachedImage: cachedImage,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'ElementSnapshot(id: $elementId, type: $elementType, '
        'position: $originalPosition, size: $size, '
        'hasWidget: ${cachedWidget != null}, hasImage: ${cachedImage != null})';
  }
}

/// Configuration for element snapshot behavior
class ElementSnapshotConfig {
  /// Whether to enable widget caching for faster rendering
  final bool enableWidgetCaching;

  /// Whether to enable image caching for ultra-lightweight rendering
  final bool enableImageCaching;

  /// Maximum number of snapshots to cache
  final int maxCacheSize;

  /// How long snapshots remain fresh
  final Duration snapshotLifetime;

  const ElementSnapshotConfig({
    this.enableWidgetCaching = true,
    this.enableImageCaching = false, // Disabled by default due to complexity
    this.maxCacheSize = 100,
    this.snapshotLifetime = const Duration(minutes: 5),
  });
}

/// Manager for element snapshots during drag operations
class ElementSnapshotManager {
  /// Map of element ID to snapshot
  final Map<String, ElementSnapshot> _snapshots = {};

  /// Map of element ID to cached widgets for ultra-fast rendering
  final Map<String, Widget> _widgetCache = {};

  /// Configuration for snapshot behavior
  final ElementSnapshotConfig config;

  ElementSnapshotManager({
    ElementSnapshotConfig? config,
  }) : config = config ?? const ElementSnapshotConfig();

  /// Clear snapshot for specific element
  void clearSnapshot(String elementId) {
    _snapshots.remove(elementId);
    _widgetCache.remove(elementId);
  }

  /// Clear all snapshots
  void clearSnapshots() {
    _snapshots.clear();
    _widgetCache.clear();
    EditPageLogger.editPageDebug('ElementSnapshotManager清除所有快照');
  }

  /// Create snapshots for a list of elements
  Future<Map<String, ElementSnapshot>> createSnapshots(
    List<Map<String, dynamic>> elements,
  ) async {
    final snapshots = <String, ElementSnapshot>{};

    for (final element in elements) {
      final elementId = element['id'] as String;
      final snapshot = ElementSnapshot.fromElement(element);

      // Store the snapshot
      snapshots[elementId] = snapshot;
      _snapshots[elementId] = snapshot;

      // Optionally create cached widget for performance
      if (config.enableWidgetCaching) {
        await _createCachedWidget(snapshot);
      }

      // Optionally create cached image for ultra-lightweight rendering
      if (config.enableImageCaching) {
        await _createCachedImage(snapshot);
      }
    }

    EditPageLogger.editPageDebug('ElementSnapshotManager创建快照', 
      data: {'snapshotCount': snapshots.length});
    return snapshots;
  }

  /// Dispose and cleanup
  void dispose() {
    clearSnapshots();
    EditPageLogger.editPageDebug('ElementSnapshotManager已释放');
  }

  /// Get all current snapshots
  Map<String, ElementSnapshot> getAllSnapshots() {
    // Clean up stale snapshots
    _cleanupStaleSnapshots();
    return Map.unmodifiable(_snapshots);
  }

  /// Get cached widget for element if available
  Widget? getCachedWidget(String elementId) {
    return _widgetCache[elementId];
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    int widgetCacheCount = _widgetCache.length;
    int snapshotCount = _snapshots.length;
    int imageCacheCount =
        _snapshots.values.where((s) => s.cachedImage != null).length;

    return {
      'snapshotCount': snapshotCount,
      'widgetCacheCount': widgetCacheCount,
      'imageCacheCount': imageCacheCount,
      'memoryEstimateKB': _estimateMemoryUsage(),
    };
  }

  /// Get snapshot for an element
  ElementSnapshot? getSnapshot(String elementId) {
    final snapshot = _snapshots[elementId];

    // Check if snapshot is fresh
    if (snapshot != null && !snapshot.isFresh) {
      _snapshots.remove(elementId);
      _widgetCache.remove(elementId);
      return null;
    }

    return snapshot;
  }

  /// Update snapshot position (for drag operations)
  void updateSnapshotPosition(String elementId, Offset newPosition) {
    final snapshot = _snapshots[elementId];
    if (snapshot != null) {
      _snapshots[elementId] = snapshot.copyWithPosition(newPosition);
    }
  }

  /// Clean up stale snapshots
  void _cleanupStaleSnapshots() {
    final staleIds = <String>[];

    for (final entry in _snapshots.entries) {
      if (!entry.value.isFresh) {
        staleIds.add(entry.key);
      }
    }

    for (final id in staleIds) {
      _snapshots.remove(id);
      _widgetCache.remove(id);
    }

    if (staleIds.isNotEmpty) {
      EditPageLogger.editPageDebug('清理过期快照', 
        data: {'staleCount': staleIds.length});
    }
  }

  /// Create cached image for snapshot (for ultra-lightweight rendering)
  Future<void> _createCachedImage(ElementSnapshot snapshot) async {
    if (!config.enableImageCaching) return;

    try {
      // This would be implemented to capture element as image
      // For now, we'll skip this complex implementation
      EditPageLogger.editPageDebug('图片缓存功能尚未实现', 
        data: {'elementId': snapshot.elementId});
    } catch (e) {
      EditPageLogger.editPageError('创建缓存图片失败', 
        data: {'elementId': snapshot.elementId}, error: e);
    }
  }

  /// Create cached widget for snapshot
  Future<void> _createCachedWidget(ElementSnapshot snapshot) async {
    try {
      Widget? cachedWidget;

      switch (snapshot.elementType) {
        case 'text':
          cachedWidget = _createTextPreviewWidget(snapshot);
          break;
        case 'image':
          cachedWidget = _createImagePreviewWidget(snapshot);
          break;
        case 'collection':
          cachedWidget = _createCollectionPreviewWidget(snapshot);
          break;
        default:
          cachedWidget = _createGenericPreviewWidget(snapshot);
      }

      _widgetCache[snapshot.elementId] = cachedWidget;

      // Update snapshot with cached widget
      _snapshots[snapshot.elementId] =
          snapshot.copyWithCachedWidget(cachedWidget);
    } catch (e) {
      EditPageLogger.editPageError('创建缓存组件失败', 
        data: {'elementId': snapshot.elementId}, error: e);
    }
  }

  /// Create collection preview widget
  Widget _createCollectionPreviewWidget(ElementSnapshot snapshot) {
    return Container(
      width: snapshot.size.width,
      height: snapshot.size.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1),
        color: Colors.orange.withValues(alpha: 0.1),
      ),
      child: const Center(
        child: Icon(
          Icons.grid_on,
          color: Colors.orange,
          size: 24,
        ),
      ),
    );
  }

  /// Create generic preview widget
  Widget _createGenericPreviewWidget(ElementSnapshot snapshot) {
    return Container(
      width: snapshot.size.width,
      height: snapshot.size.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple.withValues(alpha: 0.5), width: 1),
        color: Colors.purple.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          snapshot.elementType,
          style: const TextStyle(
            color: Colors.purple,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// Create image preview widget
  Widget _createImagePreviewWidget(ElementSnapshot snapshot) {
    return Container(
      width: snapshot.size.width,
      height: snapshot.size.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 1),
        color: Colors.green.withValues(alpha: 0.1),
      ),
      child: const Center(
        child: Icon(
          Icons.image,
          color: Colors.green,
          size: 24,
        ),
      ),
    );
  }

  /// Create text preview widget
  Widget _createTextPreviewWidget(ElementSnapshot snapshot) {
    final properties = snapshot.properties;
    final text = properties['text'] as String? ?? '';
    final fontSize = (properties['fontSize'] as num?)?.toDouble() ?? 14.0;

    return Container(
      width: snapshot.size.width,
      height: snapshot.size.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 1),
        color: Colors.blue.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          text.length > 20 ? '${text.substring(0, 20)}...' : text,
          style: TextStyle(
            fontSize: fontSize * 0.8, // Slightly smaller for preview
            color: Colors.blue,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Estimate memory usage in KB
  int _estimateMemoryUsage() {
    // Rough estimation: each snapshot ~1KB, each cached widget ~2KB
    return (_snapshots.length * 1) + (_widgetCache.length * 2);
  }
}

/// Extension methods for easier snapshot operations
extension ElementSnapshotExtensions on Map<String, dynamic> {
  /// Create a snapshot from this element data
  ElementSnapshot toSnapshot() {
    return ElementSnapshot.fromElement(this);
  }
}
