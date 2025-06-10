import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';

/// Element bounds helper class
class ElementBounds {
  final double x, y, width, height;

  ElementBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  double get area => width * height;
  double get bottom => y + height;
  double get left => x;
  double get right => x + width;

  double get top => y;

  bool intersects(ElementBounds other) {
    return !(right < other.left ||
        left > other.right ||
        bottom < other.top ||
        top > other.bottom);
  }
}

/// Element memory information
class ElementMemoryInfo {
  final String elementId;
  final String elementType;
  final int estimatedSize;
  final DateTime registrationTime;
  final Map<String, dynamic> properties;

  ElementMemoryInfo({
    required this.elementId,
    required this.elementType,
    required this.estimatedSize,
    required this.registrationTime,
    required this.properties,
  });
}

/// Image resource tracking information
class ImageResource {
  final ui.Image image;
  final String source;
  final int estimatedSize;
  final DateTime loadTime;
  bool _isDisposed = false;

  ImageResource({
    required this.image,
    required this.source,
    required this.estimatedSize,
    required this.loadTime,
  });

  bool get isDisposed => _isDisposed;

  void dispose() {
    if (!_isDisposed) {
      image.dispose();
      _isDisposed = true;
    }
  }
}

/// Memory-efficient element representation
class MemoryEfficientElement {
  final String id;
  final String type;
  final ElementBounds bounds;
  final int estimatedSize;
  final bool isLarge;
  final Map<String, dynamic> essentialProperties;
  final Future<Map<String, dynamic>> Function() fullPropertiesLoader;

  MemoryEfficientElement({
    required this.id,
    required this.type,
    required this.bounds,
    required this.estimatedSize,
    required this.isLarge,
    required this.essentialProperties,
    required this.fullPropertiesLoader,
  });

  /// Check if element intersects with viewport
  bool intersectsViewport(ElementBounds viewport) {
    return bounds.intersects(viewport);
  }

  /// Load full properties on-demand
  Future<Map<String, dynamic>> loadFullProperties() async {
    return await fullPropertiesLoader();
  }
}

/// Comprehensive memory management system for the M3 Canvas
/// Handles resource disposal, memory tracking, and large element optimization
class MemoryManager extends ChangeNotifier {
  static const int _defaultMaxMemory = 256 * 1024 * 1024; // 256MB default
  static const int _largeElementThreshold =
      1024 * 1024; // 1MB threshold for large elements
  static const double _memoryPressureThreshold =
      0.8; // 80% memory usage threshold

  final Map<String, ImageResource> _imageResources = {};
  final Map<String, ElementMemoryInfo> _elementMemoryInfo = {};
  final Set<String> _largeElements = {};
  final Map<String, DateTime> _lastAccessTimes = {};

  int _maxMemoryBytes = _defaultMaxMemory;
  int _currentMemoryUsage = 0;
  int _peakMemoryUsage = 0;
  int _totalImagesLoaded = 0;
  int _totalImagesDisposed = 0;
  Timer? _memoryCleanupTimer;

  // 🚀 性能优化：节流通知机制
  DateTime _lastNotificationTime = DateTime.now();
  static const Duration _notificationThrottle = Duration(milliseconds: 1000); // 最多每1秒通知一次

  /// Memory pressure callback
  VoidCallback? onMemoryPressure;

  /// Low memory callback
  VoidCallback? onLowMemory;

  MemoryManager({int? maxMemoryBytes}) {
    _maxMemoryBytes = maxMemoryBytes ?? _defaultMaxMemory;
    _startMemoryMonitoring();
  }

  /// Get max memory bytes (for API compatibility)
  int get maxMemoryBytes => _maxMemoryBytes;

  /// Get current memory statistics
  MemoryStats get memoryStats => MemoryStats(
    currentUsage: _currentMemoryUsage,
    peakUsage: _peakMemoryUsage,
    maxLimit: _maxMemoryBytes,
    pressureRatio: _currentMemoryUsage / _maxMemoryBytes,
    totalImagesLoaded: _totalImagesLoaded,
    totalImagesDisposed: _totalImagesDisposed,
    activeImageCount: _imageResources.length,
    largeElementCount: _largeElements.length,
    trackedElementCount: _elementMemoryInfo.length,
  );

  /// Adjust memory limits based on system capabilities
  void adjustMemoryLimits({int? newMaxMemory}) {
    if (newMaxMemory != null && newMaxMemory > 0) {
      _maxMemoryBytes = newMaxMemory;
      EditPageLogger.editPageDebug(
        '内存管理器限制调整',
        data: {
          'newMaxMemory': _formatBytes(_maxMemoryBytes),
          'oldUsage': _formatBytes(_currentMemoryUsage),
          'pressureRatio': _currentMemoryUsage / _maxMemoryBytes,
        },
      );
      _checkMemoryPressure();
    }
  }

  /// 🚀 节流通知方法 - 避免内存管理操作过于频繁地触发UI更新
  void _throttledNotifyListeners({
    required String operation,
    Map<String, dynamic>? data,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastNotificationTime) >= _notificationThrottle) {
      _lastNotificationTime = now;
      
      EditPageLogger.performanceInfo(
        '内存管理通知',
        data: {
          'operation': operation,
          'currentUsage': _formatBytes(_currentMemoryUsage),
          'peakUsage': _formatBytes(_peakMemoryUsage),
          'pressureRatio': _currentMemoryUsage / _maxMemoryBytes,
          'activeImages': _imageResources.length,
          'largeElements': _largeElements.length,
          'optimization': 'throttled_memory_notification',
          ...?data,
        },
      );
      
      notifyListeners();
    }
  }

  /// Get memory-efficient representation of an element
  MemoryEfficientElement createMemoryEfficientElement(
    Map<String, dynamic> element,
  ) {
    final elementType = element['type'] as String? ?? 'unknown';
    final estimatedSize = _estimateElementMemorySize(element);

    return MemoryEfficientElement(
      id: element['id'] as String,
      type: elementType,
      bounds: ElementBounds(
        x: (element['x'] as num?)?.toDouble() ?? 0.0,
        y: (element['y'] as num?)?.toDouble() ?? 0.0,
        width: (element['width'] as num?)?.toDouble() ?? 0.0,
        height: (element['height'] as num?)?.toDouble() ?? 0.0,
      ),
      estimatedSize: estimatedSize,
      isLarge: estimatedSize > _largeElementThreshold,
      // Store only essential properties, load full data on-demand
      essentialProperties: _extractEssentialProperties(element),
      fullPropertiesLoader: () => Future.value(element),
    );
  }

  @override
  void dispose() {
    _memoryCleanupTimer?.cancel();
    // Dispose all image resources
    for (final resource in _imageResources.values) {
      if (!resource.isDisposed) {
        resource.dispose();
      }
    }

    _imageResources.clear();
    _elementMemoryInfo.clear();
    _largeElements.clear();
    _lastAccessTimes.clear();

    super.dispose();
  }

  /// Dispose image resource for an element
  bool disposeImageResource(String elementId) {
    final resource = _imageResources.remove(elementId);
    if (resource != null) {
      _updateMemoryUsage(-resource.estimatedSize);
      _totalImagesDisposed++;
      _lastAccessTimes.remove(elementId);
      // Dispose the image if it's still valid
      if (!resource.isDisposed) {
        resource.dispose();
      }

      EditPageLogger.editPageDebug(
        '释放图片资源',
        data: {
          'elementId': elementId,
          'resourceSize': _formatBytes(resource.estimatedSize),
          'totalMemoryUsage': _formatBytes(_currentMemoryUsage),
        },
      );

      // 🚀 使用节流通知替代直接notifyListeners
      _throttledNotifyListeners(
        operation: 'dispose_image_resource',
        data: {
          'elementId': elementId,
          'resourceSize': resource.estimatedSize,
        },
      );
      return true;
    }
    return false;
  }

  /// Get list of large elements
  List<String> getLargeElements() {
    return List.from(_largeElements);
  }

  /// Check if memory is critically low
  bool isLowMemory() {
    return _currentMemoryUsage / _maxMemoryBytes > 0.95;
  }

  /// Check if memory is under pressure
  bool isMemoryPressure() {
    return _currentMemoryUsage / _maxMemoryBytes > _memoryPressureThreshold;
  }

  /// Update element access time (for LRU cleanup)
  void markElementAccessed(String elementId) {
    _lastAccessTimes[elementId] = DateTime.now();
  }

  /// Force memory cleanup
  Future<int> performMemoryCleanup({bool aggressive = false}) async {
    final startUsage = _currentMemoryUsage;

    EditPageLogger.editPageDebug(
      '开始内存清理',
      data: {
        'aggressive': aggressive,
        'currentUsage': _formatBytes(_currentMemoryUsage),
        'maxLimit': _formatBytes(_maxMemoryBytes),
        'pressureRatio': _currentMemoryUsage / _maxMemoryBytes,
      },
    );

    // 1. Clean up old unused image resources
    _cleanupUnusedImageResources(aggressive);

    // 2. Clean up old element memory info
    _cleanupOldElementMemory(aggressive);

    // 3. If still under pressure and aggressive, dispose large elements
    if (aggressive && isMemoryPressure()) {
      _cleanupLargeElements();
    }

    final finalUsage = _currentMemoryUsage;
    final actualFreed = startUsage - finalUsage;

    EditPageLogger.editPageDebug(
      '内存清理完成',
      data: {
        'freedMemory': _formatBytes(actualFreed),
        'finalUsage': _formatBytes(finalUsage),
        'maxLimit': _formatBytes(_maxMemoryBytes),
        'newPressureRatio': finalUsage / _maxMemoryBytes,
      },
    );

    // 🚀 使用节流通知替代直接notifyListeners
    _throttledNotifyListeners(
      operation: 'memory_cleanup',
      data: {
        'freedMemory': actualFreed,
        'aggressive': aggressive,
      },
    );
    return actualFreed;
  }

  /// Register element memory information
  void registerElementMemory(String elementId, Map<String, dynamic> element) {
    final estimatedSize = _estimateElementMemorySize(element);
    final elementType = element['type'] as String? ?? 'unknown';

    final memoryInfo = ElementMemoryInfo(
      elementId: elementId,
      elementType: elementType,
      estimatedSize: estimatedSize,
      registrationTime: DateTime.now(),
      properties: Map<String, dynamic>.from(element),
    );

    // Remove old memory info if present
    final oldInfo = _elementMemoryInfo.remove(elementId);
    if (oldInfo != null) {
      _updateMemoryUsage(-oldInfo.estimatedSize);
      _largeElements.remove(elementId);
    }

    _elementMemoryInfo[elementId] = memoryInfo;
    _updateMemoryUsage(estimatedSize);
    _lastAccessTimes[elementId] = DateTime.now();

    // Track large elements
    if (estimatedSize > _largeElementThreshold) {
      _largeElements.add(elementId);
      EditPageLogger.editPageWarning(
        '检测到大型元素',
        data: {
          'elementId': elementId,
          'elementType': elementType,
          'elementSize': _formatBytes(estimatedSize),
          'threshold': _formatBytes(_largeElementThreshold),
          'totalLargeElements': _largeElements.length,
        },
      );
    }

    _checkMemoryPressure();
  }

  /// Register an image resource for tracking
  void registerImageResource(String elementId, ui.Image image, String source) {
    // Dispose existing resource if present
    disposeImageResource(elementId);

    final estimatedSize = _estimateImageSize(image);
    final resource = ImageResource(
      image: image,
      source: source,
      estimatedSize: estimatedSize,
      loadTime: DateTime.now(),
    );

    _imageResources[elementId] = resource;
    _updateMemoryUsage(estimatedSize);
    _totalImagesLoaded++;
    _lastAccessTimes[elementId] = DateTime.now();

    if (kDebugMode) {
      print(
        '📷 MemoryManager: Registered image resource for $elementId (${_formatBytes(estimatedSize)})',
      );
    }

    _checkMemoryPressure();
  }

  /// Unregister element memory
  bool unregisterElementMemory(String elementId) {
    final memoryInfo = _elementMemoryInfo.remove(elementId);
    if (memoryInfo != null) {
      _updateMemoryUsage(-memoryInfo.estimatedSize);
      _largeElements.remove(elementId);
      _lastAccessTimes.remove(elementId);

      if (kDebugMode) {
        print(
          '🗑️ MemoryManager: Unregistered element memory for $elementId (${_formatBytes(memoryInfo.estimatedSize)})',
        );
      }

      // 🚀 使用节流通知替代直接notifyListeners
      _throttledNotifyListeners(
        operation: 'unregister_element_memory',
        data: {
          'elementId': elementId,
          'elementSize': memoryInfo.estimatedSize,
        },
      );
      return true;
    }
    return false;
  }

  /// Update memory limits (for adaptive cache manager compatibility)
  void updateMemoryLimits({
    int? maxMemoryBytes,
    bool enableAggressiveCleanup = false,
  }) {
    if (maxMemoryBytes != null && maxMemoryBytes > 0) {
      _maxMemoryBytes = maxMemoryBytes;
      if (kDebugMode) {
        print(
          '📏 MemoryManager: Memory limit updated to ${_formatBytes(_maxMemoryBytes)}',
        );
      }

      // Trigger cleanup if we're now over the limit
      if (_currentMemoryUsage > _maxMemoryBytes) {
        performMemoryCleanup(aggressive: enableAggressiveCleanup);
      }
    }
  }

  /// Check memory pressure and trigger callbacks
  void _checkMemoryPressure() {
    if (isLowMemory()) {
      onLowMemory?.call();
      // Automatically trigger aggressive cleanup
      Future.microtask(() => performMemoryCleanup(aggressive: true));
    } else if (isMemoryPressure()) {
      onMemoryPressure?.call();
      // Trigger normal cleanup
      Future.microtask(() => performMemoryCleanup());
    }
  }

  /// Clean up large elements during memory pressure
  int _cleanupLargeElements() {
    final now = DateTime.now();
    final cutoffTime = now.subtract(const Duration(minutes: 1));

    final toRemove = <String>[];
    int freedMemory = 0;

    for (final elementId in _largeElements) {
      final lastAccess = _lastAccessTimes[elementId];
      if (lastAccess != null && lastAccess.isBefore(cutoffTime)) {
        toRemove.add(elementId);
        final memoryInfo = _elementMemoryInfo[elementId];
        if (memoryInfo != null) {
          freedMemory += memoryInfo.estimatedSize;
        }
      }
    }

    for (final elementId in toRemove) {
      disposeImageResource(elementId);
      unregisterElementMemory(elementId);
    }

    return freedMemory;
  }

  /// Clean up old element memory info
  int _cleanupOldElementMemory(bool aggressive) {
    final now = DateTime.now();
    final cutoffTime = now.subtract(Duration(minutes: aggressive ? 2 : 10));

    final toRemove = <String>[];
    int freedMemory = 0;

    for (final entry in _elementMemoryInfo.entries) {
      final elementId = entry.key;
      final memoryInfo = entry.value;
      final lastAccess =
          _lastAccessTimes[elementId] ?? memoryInfo.registrationTime;

      if (lastAccess.isBefore(cutoffTime)) {
        toRemove.add(elementId);
        freedMemory += memoryInfo.estimatedSize;
      }
    }

    for (final elementId in toRemove) {
      unregisterElementMemory(elementId);
    }

    return freedMemory;
  }

  /// Clean up unused image resources
  int _cleanupUnusedImageResources(bool aggressive) {
    final now = DateTime.now();
    final cutoffTime = now.subtract(Duration(minutes: aggressive ? 1 : 5));

    final toRemove = <String>[];
    int freedMemory = 0;

    for (final entry in _imageResources.entries) {
      final elementId = entry.key;
      final resource = entry.value;
      final lastAccess = _lastAccessTimes[elementId] ?? resource.loadTime;

      if (lastAccess.isBefore(cutoffTime)) {
        toRemove.add(elementId);
        freedMemory += resource.estimatedSize;
      }
    }

    for (final elementId in toRemove) {
      disposeImageResource(elementId);
    }

    return freedMemory;
  }

  /// Estimate memory size of an element
  int _estimateElementMemorySize(Map<String, dynamic> element) {
    final elementType = element['type'] as String? ?? 'unknown';
    final width = (element['width'] as num?)?.toDouble() ?? 100.0;
    final height = (element['height'] as num?)?.toDouble() ?? 100.0;

    // Base size for element metadata
    int baseSize = 2048; // ~2KB for element properties and widget overhead

    switch (elementType) {
      case 'text':
        final text = element['text'] as String? ?? '';
        return baseSize + (text.length * 4) + 1024; // Text + styling overhead

      case 'collection':
        final content = element['content'] as Map<String, dynamic>?;
        final characters = content?['characters'] as String? ?? '';
        final characterImages = content?['characterImages'] as Map? ?? {};
        // Each character image can be substantial
        return baseSize +
            (characters.length * 50 * 1024) +
            (characterImages.length * 20 * 1024);

      case 'image':
        // Estimate based on dimensions - assume compressed but decoded in memory
        final pixelCount = width * height;
        return baseSize + (pixelCount * 4).toInt(); // RGBA

      case 'group':
        final content = element['content'] as Map<String, dynamic>?;
        final children = content?['children'] as List? ?? [];
        // Recursively estimate children
        int childrenSize = 0;
        for (final child in children) {
          if (child is Map<String, dynamic>) {
            childrenSize += _estimateElementMemorySize(child);
          }
        }
        return baseSize + childrenSize;

      default:
        // Default estimation for unknown element types
        final area = width * height;
        return baseSize + (area * 0.5).toInt(); // Conservative estimate
    }
  }

  /// Estimate memory size of an image
  int _estimateImageSize(ui.Image image) {
    // RGBA = 4 bytes per pixel
    return image.width * image.height * 4;
  }

  /// Extract essential properties for memory-efficient storage
  Map<String, dynamic> _extractEssentialProperties(
    Map<String, dynamic> element,
  ) {
    return {
      'id': element['id'],
      'type': element['type'],
      'x': element['x'],
      'y': element['y'],
      'width': element['width'],
      'height': element['height'],
      'layerId': element['layerId'],
      'opacity': element['opacity'] ?? 1.0,
      'rotation': element['rotation'] ?? 0.0,
    };
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Start periodic memory monitoring
  void _startMemoryMonitoring() {
    _memoryCleanupTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (isMemoryPressure()) {
        performMemoryCleanup();
      }
    });
  }

  /// Update memory usage and track peak
  void _updateMemoryUsage(int delta) {
    _currentMemoryUsage = math.max(0, _currentMemoryUsage + delta);
    
    // 更新峰值使用量并记录日志
    if (_currentMemoryUsage > _peakMemoryUsage) {
      final previousPeak = _peakMemoryUsage;
      _peakMemoryUsage = _currentMemoryUsage;
      
      EditPageLogger.performanceInfo(
        '内存使用峰值更新',
        data: {
          'newPeakUsage': _formatBytes(_peakMemoryUsage),
          'previousPeak': _formatBytes(previousPeak),
          'currentUsage': _formatBytes(_currentMemoryUsage),
          'maxLimit': _formatBytes(_maxMemoryBytes),
          'peakUtilization': (_peakMemoryUsage / _maxMemoryBytes * 100).toStringAsFixed(1) + '%',
          'delta': _formatBytes(delta),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      // 检查是否接近内存限制
      final utilizationPercent = _peakMemoryUsage / _maxMemoryBytes;
      if (utilizationPercent > 0.9) {
        EditPageLogger.performanceWarning(
          '内存使用接近限制',
          data: {
            'peakUsage': _formatBytes(_peakMemoryUsage),
            'maxLimit': _formatBytes(_maxMemoryBytes),
            'utilizationPercent': (utilizationPercent * 100).toStringAsFixed(1),
            'availableMemory': _formatBytes(_maxMemoryBytes - _peakMemoryUsage),
            'suggestion': '建议及时清理不需要的资源',
          },
        );
      }
    }
  }
}

/// Memory statistics
class MemoryStats {
  final int currentUsage;
  final int peakUsage;
  final int maxLimit;
  final double pressureRatio;
  final int totalImagesLoaded;
  final int totalImagesDisposed;
  final int activeImageCount;
  final int largeElementCount;
  final int trackedElementCount;

  MemoryStats({
    required this.currentUsage,
    required this.peakUsage,
    required this.maxLimit,
    required this.pressureRatio,
    required this.totalImagesLoaded,
    required this.totalImagesDisposed,
    required this.activeImageCount,
    required this.largeElementCount,
    required this.trackedElementCount,
  });

  bool get isLowMemory => pressureRatio > 0.95;
  bool get isUnderPressure => pressureRatio > 0.8;

  @override
  String toString() {
    return 'MemoryStats(usage: ${_formatBytes(currentUsage)}/${_formatBytes(maxLimit)}, '
        'pressure: ${(pressureRatio * 100).toStringAsFixed(1)}%, '
        'images: $activeImageCount, large: $largeElementCount)';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
