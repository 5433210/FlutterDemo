import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../infrastructure/logging/logger.dart';
import 'memory_manager.dart';
import 'resource_disposal_service.dart';

/// Cached resource data
class CachedResource {
  final ManagedImage _managedImage;
  final String source;
  final DateTime loadTime;
  DateTime lastAccess;
  final Map<String, dynamic> options;

  CachedResource({
    required ui.Image image,
    required this.source,
    required this.loadTime,
    required this.lastAccess,
    required this.options,
  }) : _managedImage = ManagedImage(image);

  ui.Image get image => _managedImage.image;
  bool get isValid => !_managedImage.isDisposed;

  void dispose() {
    _managedImage.dispose();
  }

  void updateAccessTime() {
    lastAccess = DateTime.now();
  }
}

/// Enhanced on-demand resource loader with sophisticated loading strategies
class EnhancedOnDemandResourceLoader extends ChangeNotifier {
  static const int _maxConcurrentLoads = 3;
  static const int _maxCacheSize = 50;
  static const Duration _loadTimeout = Duration(seconds: 30);

  final MemoryManager _memoryManager;
  final Map<String, CachedResource> _resourceCache = {};
  final Map<String, Future<ui.Image?>> _loadingTasks = {};
  final Set<String> _highPriorityRequests = {};
  final List<LoadRequest> _loadQueue = [];

  int _currentConcurrentLoads = 0;
  Timer? _cleanupTimer;

  /// Loading strategies
  LoadingStrategy _currentStrategy = LoadingStrategy.adaptive;

  /// Performance metrics
  int _totalLoadRequests = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _loadFailures = 0;

  EnhancedOnDemandResourceLoader({
    required MemoryManager memoryManager,
  }) : _memoryManager = memoryManager {
    _initializeLoader();
  }

  /// Current loading statistics
  LoadingStats get stats => LoadingStats(
        totalRequests: _totalLoadRequests,
        cacheHits: _cacheHits,
        cacheMisses: _cacheMisses,
        loadFailures: _loadFailures,
        cacheSize: _resourceCache.length,
        queueSize: _loadQueue.length,
        currentLoads: _currentConcurrentLoads,
        hitRate: _totalLoadRequests > 0 ? _cacheHits / _totalLoadRequests : 0.0,
      );

  /// Clear all cached resources
  void clearCache() {
    for (final cached in _resourceCache.values) {
      _memoryManager.disposeImageResource(cached.source);
      cached.dispose();
    }
    _resourceCache.clear();

    if (kDebugMode) {
      print('🧹 EnhancedOnDemandResourceLoader: Cleared all cache');
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _memoryManager.removeListener(_onMemoryStateChanged);
    clearCache();
    super.dispose();
  }

  /// Get cache information
  Map<String, dynamic> getCacheInfo() {
    final cacheSize = _resourceCache.length;
    final totalMemory = _resourceCache.values
        .map((cached) => cached.image.width * cached.image.height * 4)
        .fold(0, (sum, size) => sum + size);

    return {
      'cacheSize': cacheSize,
      'maxCacheSize': _maxCacheSize,
      'totalMemoryUsage': totalMemory,
      'loadingTasks': _loadingTasks.length,
      'queueSize': _loadQueue.length,
      'stats': stats.toMap(),
    };
  }

  /// Load an image resource with enhanced strategies
  Future<ui.Image?> loadImage(
    String source, {
    LoadPriority priority = LoadPriority.normal,
    LoadingStrategy? strategy,
    Map<String, dynamic>? options,
    bool useCache = true,
  }) async {
    _totalLoadRequests++;

    // Check cache first
    if (useCache) {
      final cached = _getCachedResource(source);
      if (cached != null) {
        _cacheHits++;
        return cached;
      }
    }

    _cacheMisses++;

    // Check if already loading
    if (_loadingTasks.containsKey(source)) {
      return await _loadingTasks[source];
    }

    // Create load request
    final request = LoadRequest(
      source: source,
      priority: priority,
      strategy: strategy ?? _currentStrategy,
      options: options ?? {},
      timestamp: DateTime.now(),
    );

    // Handle based on priority and current load capacity
    if (priority == LoadPriority.immediate ||
        _currentConcurrentLoads < _maxConcurrentLoads) {
      return await _executeLoad(request);
    } else {
      return await _queueLoad(request);
    }
  }

  /// Load multiple images with optimized batching
  Future<Map<String, ui.Image?>> loadImageBatch(
    List<String> sources, {
    LoadPriority priority = LoadPriority.normal,
    LoadingStrategy? strategy,
    bool useCache = true,
  }) async {
    final results = <String, ui.Image?>{};
    final loadTasks = <Future<void>>[];

    // Check cache for all sources first
    final uncachedSources = <String>[];
    for (final source in sources) {
      if (useCache) {
        final cached = _getCachedResource(source);
        if (cached != null) {
          results[source] = cached;
          _cacheHits++;
          continue;
        }
      }
      uncachedSources.add(source);
      _cacheMisses++;
    }

    // Load uncached resources in batches
    final batchSize = math.min(_maxConcurrentLoads, uncachedSources.length);
    for (int i = 0; i < uncachedSources.length; i += batchSize) {
      final batch = uncachedSources.skip(i).take(batchSize).toList();

      for (final source in batch) {
        loadTasks.add(_loadImageAsync(source, priority, strategy).then((image) {
          results[source] = image;
        }));
      }

      // Wait for current batch to complete before starting next
      await Future.wait(loadTasks);
      loadTasks.clear();
    }

    return results;
  }

  /// Preload images for upcoming use
  Future<void> preloadImages(
    List<String> sources, {
    LoadPriority priority = LoadPriority.background,
  }) async {
    for (final source in sources) {
      // Only preload if not already cached or loading
      if (!_resourceCache.containsKey(source) &&
          !_loadingTasks.containsKey(source)) {
        // Queue for background loading
        _queueLoad(LoadRequest(
          source: source,
          priority: priority,
          strategy: LoadingStrategy.backgroundOptimized,
          options: {},
          timestamp: DateTime.now(),
        ));
      }
    }

    _processLoadQueue();
  }

  /// Cache a loaded resource
  void _cacheResource(
      String source, ui.Image image, Map<String, dynamic> options) {
    // Remove old cache entry if exists
    final oldCached = _resourceCache.remove(source);
    if (oldCached != null && !oldCached.isValid) {
      oldCached.dispose();
    }

    // Add new cache entry
    _resourceCache[source] = CachedResource(
      image: image,
      source: source,
      loadTime: DateTime.now(),
      lastAccess: DateTime.now(),
      options: options,
    );

    // Register with memory manager
    _memoryManager.registerImageResource(source, image, source);

    // Clean cache if necessary
    _cleanupCacheIfNeeded();
  }

  /// Clean up cache entries
  void _cleanupCache({bool aggressive = false}) {
    final entriesToRemove = <String>[];

    // Sort by last access time (LRU)
    final sortedEntries = _resourceCache.entries.toList()
      ..sort((a, b) => a.value.lastAccess.compareTo(b.value.lastAccess));

    final targetSize = aggressive
        ? (_maxCacheSize * 0.5).toInt()
        : (_maxCacheSize * 0.8).toInt();
    final toRemove = math.max(0, _resourceCache.length - targetSize);

    for (int i = 0; i < toRemove && i < sortedEntries.length; i++) {
      entriesToRemove.add(sortedEntries[i].key);
    } // Remove old entries
    for (final key in entriesToRemove) {
      final cached = _resourceCache.remove(key);
      if (cached != null) {
        _memoryManager.disposeImageResource(key);
        cached.dispose();
      }
    }

    if (kDebugMode && entriesToRemove.isNotEmpty) {
      AppLogger.debug(
          'EnhancedOnDemandResourceLoader: 清理了 ${entriesToRemove.length} 个缓存条目',
          tag: 'ResourceLoader');
    }
  }

  /// Clean cache if needed
  void _cleanupCacheIfNeeded() {
    if (_resourceCache.length > _maxCacheSize) {
      _cleanupCache();
    }
  }

  /// Execute load request immediately
  Future<ui.Image?> _executeLoad(LoadRequest request) async {
    if (request.priority == LoadPriority.immediate) {
      _highPriorityRequests.add(request.source);
    }

    final loadingTask = _loadImageWithStrategy(request);
    _loadingTasks[request.source] = loadingTask;

    _currentConcurrentLoads++;

    try {
      final image = await loadingTask;

      // Cache the result if successful
      if (image != null) {
        _cacheResource(request.source, image, request.options);
      } else {
        _loadFailures++;
      }

      return image;
    } catch (e) {
      _loadFailures++;
      if (kDebugMode) {
        print(
            '❌ EnhancedOnDemandResourceLoader: Failed to load ${request.source}: $e');
      }
      return null;
    } finally {
      _loadingTasks.remove(request.source);
      _highPriorityRequests.remove(request.source);
      _currentConcurrentLoads--;

      // Process any queued loads
      _processLoadQueue();
    }
  }

  /// Get cached resource if available and valid
  ui.Image? _getCachedResource(String source) {
    final cached = _resourceCache[source];
    if (cached != null && cached.isValid) {
      cached.updateAccessTime();
      return cached.image;
    } else if (cached != null) {
      // Remove invalid cache entry
      _resourceCache.remove(source);
    }
    return null;
  }

  /// Initialize the loader
  void _initializeLoader() {
    _startCleanupTimer();
    _memoryManager.addListener(_onMemoryStateChanged);
  }

  /// Adaptive strategy - adjust based on current conditions
  Future<ui.Image?> _loadAdaptiveStrategy(LoadRequest request) async {
    final memoryStats = _memoryManager.memoryStats;

    // Choose sub-strategy based on conditions
    if (memoryStats.pressureRatio > 0.8) {
      return await _loadMemoryOptimizedStrategy(request);
    } else if (_currentConcurrentLoads >= _maxConcurrentLoads * 0.8) {
      return await _loadBackgroundOptimizedStrategy(request);
    } else {
      return await _loadImmediateStrategy(request);
    }
  }

  /// Background optimized strategy - lower priority, yield to other tasks
  Future<ui.Image?> _loadBackgroundOptimizedStrategy(
      LoadRequest request) async {
    // Yield to other tasks periodically during background loading
    await Future.delayed(const Duration(milliseconds: 10));
    return await _loadImageFromSource(request.source, request.options);
  }

  /// Load image from assets
  Future<ui.Image?> _loadFromAssets(
      String assetPath, Map<String, dynamic> options) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ EnhancedOnDemandResourceLoader: Failed to load asset $assetPath: $e');
      }
      return null;
    }
  }

  /// Load image from file
  Future<ui.Image?> _loadFromFile(
      String path, Map<String, dynamic> options) async {
    // Placeholder implementation
    throw UnimplementedError('File loading not implemented in this example');
  }

  /// Load image from network
  Future<ui.Image?> _loadFromNetwork(
      String url, Map<String, dynamic> options) async {
    // Placeholder implementation
    throw UnimplementedError('Network loading not implemented in this example');
  }

  /// Async helper for loading
  Future<ui.Image?> _loadImageAsync(
      String source, LoadPriority priority, LoadingStrategy? strategy) async {
    return await loadImage(source, priority: priority, strategy: strategy);
  }

  /// Load image from source with timeout
  Future<ui.Image?> _loadImageFromSource(
      String source, Map<String, dynamic> options) async {
    try {
      return await _loadImageFromSourceImpl(source, options)
          .timeout(_loadTimeout);
    } on TimeoutException {
      if (kDebugMode) {
        print('⏰ EnhancedOnDemandResourceLoader: Load timeout for $source');
      }
      return null;
    }
  }

  /// Implementation of image loading from source
  Future<ui.Image?> _loadImageFromSourceImpl(
      String source, Map<String, dynamic> options) async {
    if (source.startsWith('file://')) {
      return await _loadFromFile(source.substring(7), options);
    } else if (source.startsWith('http://') || source.startsWith('https://')) {
      return await _loadFromNetwork(source, options);
    } else if (source.startsWith('assets://')) {
      return await _loadFromAssets(source.substring(9), options);
    } else {
      // Treat as asset path by default
      return await _loadFromAssets(source, options);
    }
  }

  /// Load image with specific strategy
  Future<ui.Image?> _loadImageWithStrategy(LoadRequest request) async {
    switch (request.strategy) {
      case LoadingStrategy.immediate:
        return await _loadImmediateStrategy(request);
      case LoadingStrategy.backgroundOptimized:
        return await _loadBackgroundOptimizedStrategy(request);
      case LoadingStrategy.memoryOptimized:
        return await _loadMemoryOptimizedStrategy(request);
      case LoadingStrategy.adaptive:
        return await _loadAdaptiveStrategy(request);
    }
  }

  /// Immediate loading strategy - no optimization, load as fast as possible
  Future<ui.Image?> _loadImmediateStrategy(LoadRequest request) async {
    return await _loadImageFromSource(request.source, request.options);
  }

  /// Memory optimized strategy - check memory pressure before loading
  Future<ui.Image?> _loadMemoryOptimizedStrategy(LoadRequest request) async {
    final memoryStats = _memoryManager.memoryStats;

    // If under memory pressure, clean cache first
    if (memoryStats.pressureRatio > 0.8) {
      _cleanupCache(aggressive: true);
    }

    return await _loadImageFromSource(request.source, request.options);
  }

  /// React to memory state changes
  void _onMemoryStateChanged() {
    final memoryStats = _memoryManager.memoryStats;

    // Adjust loading strategy based on memory pressure
    if (memoryStats.pressureRatio > 0.9) {
      _currentStrategy = LoadingStrategy.memoryOptimized;
      _cleanupCache(aggressive: true);
    } else if (memoryStats.pressureRatio > 0.7) {
      _currentStrategy = LoadingStrategy.adaptive;
    } else {
      _currentStrategy = LoadingStrategy.adaptive;
    }
  }

  /// Process the load queue
  void _processLoadQueue() {
    while (_loadQueue.isNotEmpty &&
        _currentConcurrentLoads < _maxConcurrentLoads) {
      final request = _loadQueue.removeAt(0);
      _executeLoad(request);
    }
  }

  /// Queue load request for later execution
  Future<ui.Image?> _queueLoad(LoadRequest request) async {
    _loadQueue.add(request);
    _loadQueue.sort((a, b) {
      // Sort by priority first, then by timestamp
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      return a.timestamp.compareTo(b.timestamp);
    });

    // Create a completer for this request
    final completer = Completer<ui.Image?>();

    // Wait for the request to be processed
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Check if the image is now loaded
      final cached = _getCachedResource(request.source);
      if (cached != null) {
        timer.cancel();
        completer.complete(cached);
        return;
      }

      // Check if the request failed
      if (_loadQueue.where((r) => r.source == request.source).isEmpty &&
          !_loadingTasks.containsKey(request.source)) {
        timer.cancel();
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// Start cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupCache();
    });
  }
}

/// Loading statistics
class LoadingStats {
  final int totalRequests;
  final int cacheHits;
  final int cacheMisses;
  final int loadFailures;
  final int cacheSize;
  final int queueSize;
  final int currentLoads;
  final double hitRate;

  LoadingStats({
    required this.totalRequests,
    required this.cacheHits,
    required this.cacheMisses,
    required this.loadFailures,
    required this.cacheSize,
    required this.queueSize,
    required this.currentLoads,
    required this.hitRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalRequests': totalRequests,
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'loadFailures': loadFailures,
      'cacheSize': cacheSize,
      'queueSize': queueSize,
      'currentLoads': currentLoads,
      'hitRate': hitRate,
    };
  }

  @override
  String toString() {
    return 'LoadingStats(requests: $totalRequests, hit rate: ${(hitRate * 100).toStringAsFixed(1)}%, '
        'cache: $cacheSize, queue: $queueSize, loading: $currentLoads)';
  }
}

/// Loading strategies
enum LoadingStrategy {
  immediate, // Load as fast as possible
  backgroundOptimized, // Optimized for background loading
  memoryOptimized, // Prioritize memory conservation
  adaptive, // Adapt to current conditions
}

/// Loading priority levels
enum LoadPriority {
  immediate,
  high,
  normal,
  low,
  background,
}

/// Load request data
class LoadRequest {
  final String source;
  final LoadPriority priority;
  final LoadingStrategy strategy;
  final Map<String, dynamic> options;
  final DateTime timestamp;

  LoadRequest({
    required this.source,
    required this.priority,
    required this.strategy,
    required this.options,
    required this.timestamp,
  });
}
