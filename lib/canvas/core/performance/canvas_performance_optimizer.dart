// filepath: lib/canvas/core/performance/canvas_performance_optimizer.dart

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Cache entry for LRU management
class CacheEntry {
  final dynamic data;
  final int size;
  final int priority;
  final DateTime timestamp;

  CacheEntry({
    required this.data,
    required this.size,
    this.priority = 0,
    required this.timestamp,
  });
}

/// Comprehensive performance optimization system for Canvas components
///
/// This system provides unified performance monitoring, caching strategies,
/// memory management, and rendering optimizations for all Canvas subsystems.
class CanvasPerformanceOptimizer {
  static final CanvasPerformanceOptimizer _instance =
      CanvasPerformanceOptimizer._internal();
  static const Duration defaultThrottleDuration =
      Duration(milliseconds: 16); // 60fps
  static const Duration defaultDebounceDuration = Duration(milliseconds: 100);

  // Performance monitoring
  final Map<String, PerformanceMetrics> _metrics = {};
  final LinkedHashMap<String, CacheEntry> _renderCache = LinkedHashMap();
  final LinkedHashMap<String, CacheEntry> _computationCache = LinkedHashMap();

  // Memory management
  int _maxCacheSize = 50 * 1024 * 1024; // 50MB default
  int _currentCacheSize = 0;
  Timer? _memoryCheckTimer;
  final List<WeakReference<ui.Image>> _imageReferences = [];

  // Rendering optimization
  final Map<String, ui.Picture> _pictureCache = {};
  final Map<String, DirtyRegion> _dirtyRegions = {};
  bool _isDirtyRegionEnabled = true;

  // Throttling and debouncing
  final Map<String, Timer> _throttleTimers = {};
  final Map<String, Timer> _debounceTimers = {};
  // Performance settings
  PerformanceProfile _currentProfile = PerformanceProfile.balanced;
  final bool _isPerformanceMonitoringEnabled = kDebugMode;

  factory CanvasPerformanceOptimizer() => _instance;
  CanvasPerformanceOptimizer._internal() {
    _initializePerformanceMonitoring();
  }

  /// Batch operations for better performance
  Future<void> batchOperations(List<Future<void> Function()> operations) async {
    const batchSize = 5;

    for (int i = 0; i < operations.length; i += batchSize) {
      final end = math.min(i + batchSize, operations.length);
      final batch = operations.sublist(i, end);

      await Future.wait(batch.map((op) => op()));

      // Allow UI to update between batches
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  /// Cache computation result
  void cacheComputation<T>(String key, T result, {int priority = 0}) {
    final size = _estimateObjectSize(result);

    while (_currentCacheSize + size > _maxCacheSize &&
        _computationCache.isNotEmpty) {
      _evictLRUComputationEntry();
    }

    final entry = CacheEntry(
      data: result,
      size: size,
      priority: priority,
      timestamp: DateTime.now(),
    );

    _computationCache[key] = entry;
    _currentCacheSize += size;
  }

  /// Cache rendered picture with LRU eviction
  void cachePicture(String key, ui.Picture picture, {int priority = 0}) {
    final size = _estimatePictureSize(picture);

    // Check if we need to make space
    while (
        _currentCacheSize + size > _maxCacheSize && _renderCache.isNotEmpty) {
      _evictLRUEntry();
    }

    final entry = CacheEntry(
      data: picture,
      size: size,
      priority: priority,
      timestamp: DateTime.now(),
    );

    _renderCache[key] = entry;
    _currentCacheSize += size;
  }

  /// Clear all caches
  void clearAllCaches() {
    _renderCache.clear();
    _computationCache.clear();
    _pictureCache.clear();
    _dirtyRegions.clear();
    _currentCacheSize = 0;
    debugPrint('🧹 Cleared all Canvas performance caches');
  }

  /// Clear dirty region
  void clearDirtyRegion(String layerId) {
    _dirtyRegions.remove(layerId);
  }

  /// Debounce function execution
  void debounce(String key, VoidCallback callback, {Duration? duration}) {
    final debounceDuration = duration ?? defaultDebounceDuration;

    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(debounceDuration, () {
      callback();
      _debounceTimers.remove(key);
    });
  }

  /// Dispose resources
  void dispose() {
    _memoryCheckTimer?.cancel();
    for (var timer in _throttleTimers.values) {
      timer.cancel();
    }
    for (var timer in _debounceTimers.values) {
      timer.cancel();
    }
    clearAllCaches();
  }

  /// Get cached computation result
  T? getCachedComputation<T>(String key) {
    final entry = _computationCache[key];
    if (entry != null) {
      // Move to end for LRU
      _computationCache.remove(key);
      _computationCache[key] = entry;
      return entry.data as T;
    }
    return null;
  }

  /// Get cached picture
  ui.Picture? getCachedPicture(String key) {
    final entry = _renderCache[key];
    if (entry != null) {
      // Move to end for LRU
      _renderCache.remove(key);
      _renderCache[key] = entry;
      return entry.data as ui.Picture;
    }
    return null;
  }

  /// Get dirty region for layer
  Rect? getDirtyRegion(String layerId) {
    return _dirtyRegions[layerId]?.bounds;
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    return {
      'cacheSize': _currentCacheSize,
      'maxCacheSize': _maxCacheSize,
      'renderCacheEntries': _renderCache.length,
      'computationCacheEntries': _computationCache.length,
      'dirtyRegions': _dirtyRegions.length,
      'profile': _currentProfile.toString(),
      'metrics': _metrics.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  /// Optimize canvas drawing with dirty regions
  void optimizedDraw(
    Canvas canvas,
    String layerId,
    VoidCallback drawCallback, {
    bool force = false,
  }) {
    if (!_isDirtyRegionEnabled || force) {
      drawCallback();
      return;
    }

    final dirtyRegion = getDirtyRegion(layerId);
    if (dirtyRegion != null) {
      canvas.save();
      canvas.clipRect(dirtyRegion);
      drawCallback();
      canvas.restore();
      clearDirtyRegion(layerId);
    }
  }

  /// Optimize image loading with weak references
  Future<ui.Image?> optimizedLoadImage(String path) async {
    // Check for existing weak references
    for (int i = _imageReferences.length - 1; i >= 0; i--) {
      final ref = _imageReferences[i];
      final image = ref.target;
      if (image == null) {
        _imageReferences.removeAt(i);
      }
    }

    try {
      final bytes = await _loadImageBytes(path);
      if (bytes != null) {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();

        // Store weak reference
        _imageReferences.add(WeakReference(frame.image));

        return frame.image;
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }

    return null;
  }

  /// Register dirty region for optimized rendering
  void registerDirtyRegion(String layerId, Rect region) {
    if (!_isDirtyRegionEnabled) return;

    final existing = _dirtyRegions[layerId];
    if (existing != null) {
      existing.expand(region);
    } else {
      _dirtyRegions[layerId] = DirtyRegion(region);
    }
  }

  /// Set performance profile
  void setPerformanceProfile(PerformanceProfile profile) {
    _currentProfile = profile;
    _applyPerformanceProfile();
  }

  /// Track operation performance
  PerformanceTracker startTracking(String operationName) {
    return PerformanceTracker(operationName, this);
  }

  /// Throttle function execution
  void throttle(String key, VoidCallback callback, {Duration? duration}) {
    final throttleDuration = duration ?? defaultThrottleDuration;

    if (_throttleTimers.containsKey(key)) {
      return; // Already throttled
    }

    callback();
    _throttleTimers[key] = Timer(throttleDuration, () {
      _throttleTimers.remove(key);
    });
  }

  /// Apply performance profile settings
  void _applyPerformanceProfile() {
    switch (_currentProfile) {
      case PerformanceProfile.performance:
        _maxCacheSize = 100 * 1024 * 1024; // 100MB
        _isDirtyRegionEnabled = true;
        break;
      case PerformanceProfile.balanced:
        _maxCacheSize = 50 * 1024 * 1024; // 50MB
        _isDirtyRegionEnabled = true;
        break;
      case PerformanceProfile.memory:
        _maxCacheSize = 20 * 1024 * 1024; // 20MB
        _isDirtyRegionEnabled = false;
        break;
    }
    _trimCacheIfNeeded();
  }

  /// Memory management
  void _checkMemoryUsage() {
    if (_currentCacheSize > _maxCacheSize * 0.8) {
      debugPrint(
          '🔄 Memory usage high: ${_currentCacheSize ~/ (1024 * 1024)}MB, trimming cache');
      _trimCacheIfNeeded();
    }
  }

  /// Estimate object size for cache management
  int _estimateObjectSize(dynamic object) {
    if (object is String) {
      return object.length * 2; // UTF-16
    } else if (object is List) {
      return object.length * 100; // Rough estimate
    } else if (object is Map) {
      return object.length * 200; // Rough estimate
    }
    return 100; // Default small object size
  }

  /// Estimate picture size for cache management
  int _estimatePictureSize(ui.Picture picture) {
    // Rough estimation based on typical picture complexity
    return 1024 * 1024; // 1MB default estimate
  }

  void _evictLRUComputationEntry() {
    if (_computationCache.isNotEmpty) {
      final key = _computationCache.keys.first;
      final entry = _computationCache.remove(key)!;
      _currentCacheSize -= entry.size;
    }
  }

  void _evictLRUEntry() {
    if (_renderCache.isNotEmpty) {
      final key = _renderCache.keys.first;
      final entry = _renderCache.remove(key)!;
      _currentCacheSize -= entry.size;
      _pictureCache.remove(key);
    }
  }

  /// Initialize performance monitoring
  void _initializePerformanceMonitoring() {
    if (!_isPerformanceMonitoringEnabled) return;

    // Start memory monitoring
    _memoryCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkMemoryUsage();
    });

    // Register frame callback for performance tracking
    SchedulerBinding.instance
        .addPersistentFrameCallback(_trackFramePerformance);
  }

  /// Load image bytes (platform-specific implementation would go here)
  Future<Uint8List?> _loadImageBytes(String path) async {
    // This would be implemented based on the platform
    // For now, return null as placeholder
    return null;
  }

  /// Record performance metrics
  void _recordMetrics(String operationName, Duration duration, int memoryUsed) {
    if (!_isPerformanceMonitoringEnabled) return;

    final metrics = _metrics.putIfAbsent(
        operationName, () => PerformanceMetrics(operationName));
    metrics.addMeasurement(duration, memoryUsed);

    // Log performance issues
    if (duration.inMilliseconds > 16) {
      // More than one frame
      debugPrint(
          '⚠️ Performance: $operationName took ${duration.inMilliseconds}ms (> 16ms)');
    }
  }

  /// Track frame performance
  void _trackFramePerformance(Duration timestamp) {
    if (!_isPerformanceMonitoringEnabled) return;

    // This could track frame times and detect jank
    // Implementation would depend on specific requirements
  }

  void _trimCacheIfNeeded() {
    while (_currentCacheSize > _maxCacheSize &&
        (_renderCache.isNotEmpty || _computationCache.isNotEmpty)) {
      if (_renderCache.isNotEmpty && _computationCache.isNotEmpty) {
        // Evict from cache with older timestamps first
        final renderEntry = _renderCache.values.first;
        final computationEntry = _computationCache.values.first;

        if (renderEntry.timestamp.isBefore(computationEntry.timestamp)) {
          _evictLRUEntry();
        } else {
          _evictLRUComputationEntry();
        }
      } else if (_renderCache.isNotEmpty) {
        _evictLRUEntry();
      } else {
        _evictLRUComputationEntry();
      }
    }
  }
}

/// Dirty region tracking for optimized rendering
class DirtyRegion {
  Rect bounds;

  DirtyRegion(this.bounds);

  void expand(Rect newRegion) {
    bounds = bounds.expandToInclude(newRegion);
  }
}

/// Performance metrics tracking
class PerformanceMetrics {
  final String operationName;
  final List<Duration> _durations = [];
  final List<int> _memoryUsages = [];

  PerformanceMetrics(this.operationName);

  Duration get averageDuration {
    if (_durations.isEmpty) return Duration.zero;
    final total = _durations.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: total ~/ _durations.length);
  }

  Duration get maxDuration {
    if (_durations.isEmpty) return Duration.zero;
    return _durations.reduce((a, b) => a > b ? a : b);
  }

  void addMeasurement(Duration duration, int memoryUsed) {
    _durations.add(duration);
    _memoryUsages.add(memoryUsed);

    // Keep only last 100 measurements
    if (_durations.length > 100) {
      _durations.removeAt(0);
      _memoryUsages.removeAt(0);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'operationName': operationName,
      'measurementCount': _durations.length,
      'averageDurationMs': averageDuration.inMilliseconds,
      'maxDurationMs': maxDuration.inMilliseconds,
    };
  }
}

/// Performance profile settings
enum PerformanceProfile {
  performance, // High memory usage, maximum performance
  balanced, // Balanced memory and performance
  memory, // Low memory usage, reduced performance
}

/// Performance tracking helper
class PerformanceTracker {
  final String operationName;
  final CanvasPerformanceOptimizer optimizer;
  final Stopwatch _stopwatch = Stopwatch();
  final int _initialMemory;

  PerformanceTracker(this.operationName, this.optimizer)
      : _initialMemory = 0 // Would get actual memory usage
  {
    _stopwatch.start();
  }

  void finish() {
    _stopwatch.stop();
    final duration = _stopwatch.elapsed;
    const memoryUsed = 0; // Would calculate actual memory delta
    optimizer._recordMetrics(operationName, duration, memoryUsed);
  }
}
