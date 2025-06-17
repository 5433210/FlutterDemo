import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'enhanced_ondemand_resource_loader.dart';
import 'memory_manager.dart';

/// Element metadata for memory tracking
class ElementMetadata {
  final int originalSize;
  final int optimizedSize;
  final double compressionRatio;
  final DateTime generationTime;

  ElementMetadata({
    required this.originalSize,
    required this.optimizedSize,
    required this.compressionRatio,
    required this.generationTime,
  });

  int get savedBytes => originalSize - optimizedSize;
  double get savingsRatio => savedBytes / originalSize;
}

/// Element representation data
class ElementRepresentation {
  final String elementId;
  final ElementRepresentationMode mode;
  final Widget widget;
  final ElementMetadata metadata;

  ElementRepresentation({
    required this.elementId,
    required this.mode,
    required this.widget,
    required this.metadata,
  });
}

/// Element representation modes
enum ElementRepresentationMode {
  full, // Full quality, no optimization
  preview, // Thumbnail/preview version
  compressed, // Compressed version with quality loss
  proxy, // Placeholder that loads on demand
  adaptive, // Adapts to current conditions
}

/// Enhanced memory-efficient element representation system
class MemoryEfficientElementRepresentation with ChangeNotifier {
  static const int _largeElementThreshold = 1024 * 1024; // 1MB
  static const int _previewDimension = 128; // 128x128 preview thumbnails
  static const double _compressionQuality =
      0.7; // 70% quality for compressed representations

  final MemoryManager _memoryManager;
  final EnhancedOnDemandResourceLoader _resourceLoader;

  final Map<String, ElementRepresentation> _representations = {};
  final Map<String, Uint8List> _compressedData = {};
  final Set<String> _loadingElements = {};

  // 优化配置
  final int _maxCachedRepresentations;

  // 性能统计
  int _totalRepresentations = 0;
  int _memoryOptimizedCount = 0;
  int _previewGeneratedCount = 0;
  int _compressionSavedBytes = 0;

  // 🚀 节流通知相关
  Timer? _notificationTimer;
  bool _hasPendingUpdate = false;
  DateTime _lastNotificationTime = DateTime.now();
  static const Duration _notificationThrottle =
      Duration(milliseconds: 16); // 60 FPS

  MemoryEfficientElementRepresentation({
    required MemoryManager memoryManager,
    required EnhancedOnDemandResourceLoader resourceLoader,
    int maxCachedRepresentations = 10,
  })  : _memoryManager = memoryManager,
        _resourceLoader = resourceLoader,
        _maxCachedRepresentations = maxCachedRepresentations {
    _initializeRepresentationSystem();
  }

  /// Current representation statistics
  RepresentationStats get stats => RepresentationStats(
        totalRepresentations: _totalRepresentations,
        memoryOptimizedCount: _memoryOptimizedCount,
        previewGeneratedCount: _previewGeneratedCount,
        compressionSavedBytes: _compressionSavedBytes,
        activeRepresentations: _representations.length,
        loadingElements: _loadingElements.length,
      );

  /// Clear all representations
  void clearAllRepresentations() {
    _representations.clear();
    _compressedData.clear();
    _loadingElements.clear();

    // 🚀 使用节流通知替代直接notifyListeners
    _throttledNotifyListeners(
      operation: 'clear_all_representations',
      data: {
        'clearedRepresentations': _representations.length,
        'clearedCompressedData': _compressedData.length,
        'clearedLoadingElements': _loadingElements.length,
      },
    );

    if (kDebugMode) {
      debugPrint(
          '💾 MemoryEfficientElementRepresentation: Cleared all representations');
    }
  }

  /// Create memory-efficient representation for an element
  Future<ElementRepresentation?> createRepresentation(
    String elementId,
    Map<String, dynamic> elementData, {
    ElementRepresentationMode? mode,
    bool forceRegenerate = false,
  }) async {
    if (_loadingElements.contains(elementId)) {
      // Already loading, wait for completion
      return await _waitForLoadingCompletion(elementId);
    }

    if (!forceRegenerate && _representations.containsKey(elementId)) {
      // Return existing representation
      return _representations[elementId];
    }

    _loadingElements.add(elementId);
    _totalRepresentations++;

    try {
      final representation =
          await _generateRepresentation(elementId, elementData, mode);
      if (representation != null) {
        _representations[elementId] = representation;

        // 🚀 使用节流通知替代直接notifyListeners
        _throttledNotifyListeners(
          operation: 'create_representation',
          data: {
            'elementId': elementId,
            'mode': representation.mode.toString(),
            'totalRepresentations': _representations.length,
          },
        );
      }
      return representation;
    } finally {
      _loadingElements.remove(elementId);
    }
  }

  @override
  void dispose() {
    _memoryManager.removeListener(_onMemoryStateChanged);
    clearAllRepresentations();
    super.dispose();
  }

  /// Get representation for element
  ElementRepresentation? getRepresentation(String elementId) {
    return _representations[elementId];
  }

  /// Get detailed representation information
  Map<String, dynamic> getRepresentationInfo() {
    final totalOriginalSize = _representations.values
        .map((rep) => rep.metadata.originalSize)
        .fold(0, (sum, size) => sum + size);

    final totalOptimizedSize = _representations.values
        .map((rep) => rep.metadata.optimizedSize)
        .fold(0, (sum, size) => sum + size);

    return {
      'totalRepresentations': _representations.length,
      'loadingElements': _loadingElements.length,
      'totalOriginalSize': totalOriginalSize,
      'totalOptimizedSize': totalOptimizedSize,
      'totalSavedBytes': totalOriginalSize - totalOptimizedSize,
      'averageCompressionRatio': _representations.isNotEmpty
          ? _representations.values
                  .map((rep) => rep.metadata.compressionRatio)
                  .reduce((a, b) => a + b) /
              _representations.length
          : 0.0,
      'stats': stats.toMap(),
    };
  }

  /// Remove representation
  void removeRepresentation(String elementId) {
    final representation = _representations.remove(elementId);
    if (representation != null) {
      _compressedData.remove(elementId);

      // 🚀 使用节流通知替代直接notifyListeners
      _throttledNotifyListeners(
        operation: 'remove_representation',
        data: {
          'elementId': elementId,
          'remainingRepresentations': _representations.length,
        },
      );
    }
  }

  /// Create adaptive representation that changes based on conditions
  Future<ElementRepresentation?> _createAdaptiveRepresentation(
    String elementId,
    Map<String, dynamic> elementData,
  ) async {
    // Start with a basic representation and upgrade as needed
    final memoryStats = _memoryManager.memoryStats;

    if (memoryStats.pressureRatio > 0.7) {
      return await _createPreviewRepresentation(elementId, elementData);
    } else {
      return await _createFullRepresentation(elementId, elementData);
    }
  }

  /// Create collection preview
  Widget _createCollectionPreview(Map<String, dynamic> elementData) {
    final itemCount = (elementData['items'] as List?)?.length ?? 0;

    return Container(
      width: _previewDimension.toDouble(),
      height: _previewDimension.toDouble(),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
        color: Colors.green.withOpacity(0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections,
            size: 32,
            color: Colors.green.withOpacity(0.7),
          ),
          const SizedBox(height: 4),
          Text(
            '$itemCount items',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Create compressed representation
  Future<ElementRepresentation?> _createCompressedRepresentation(
    String elementId,
    Map<String, dynamic> elementData,
  ) async {
    final widget = await _createElementWidget(elementData, compressed: true);
    if (widget == null) return null;

    _memoryOptimizedCount++;
    final originalSize = _estimateElementSize(elementData);
    final optimizedSize = (originalSize * _compressionQuality).round();
    _compressionSavedBytes += (originalSize - optimizedSize);

    return ElementRepresentation(
      elementId: elementId,
      mode: ElementRepresentationMode.compressed,
      widget: widget,
      metadata: ElementMetadata(
        originalSize: originalSize,
        optimizedSize: optimizedSize,
        compressionRatio: _compressionQuality,
        generationTime: DateTime.now(),
      ),
    );
  }

  /// Create element widget with optional compression
  Future<Widget?> _createElementWidget(Map<String, dynamic> elementData,
      {bool compressed = false}) async {
    // This would typically delegate to existing element rendering logic
    // For now, return a placeholder
    return Container(
      width: 100,
      height: 100,
      color: Colors.blue.withOpacity(0.1),
      child: const Center(
        child: Text('Element'),
      ),
    );
  }

  /// Create full representation (no optimization)
  Future<ElementRepresentation?> _createFullRepresentation(
    String elementId,
    Map<String, dynamic> elementData,
  ) async {
    final widget = await _createElementWidget(elementData);
    if (widget == null) return null;

    return ElementRepresentation(
      elementId: elementId,
      mode: ElementRepresentationMode.full,
      widget: widget,
      metadata: ElementMetadata(
        originalSize: _estimateElementSize(elementData),
        optimizedSize: _estimateElementSize(elementData),
        compressionRatio: 1.0,
        generationTime: DateTime.now(),
      ),
    );
  }

  /// Create generic preview for unknown element types
  Widget _createGenericPreview(Map<String, dynamic> elementData) {
    final elementType = elementData['type'] as String? ?? 'Element';

    return Container(
      width: _previewDimension.toDouble(),
      height: _previewDimension.toDouble(),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey.withOpacity(0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.widgets,
            size: 32,
            color: Colors.grey.withOpacity(0.7),
          ),
          const SizedBox(height: 4),
          Text(
            elementType,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Create image preview
  Future<Widget?> _createImagePreview(Map<String, dynamic> elementData) async {
    final imagePath = elementData['imagePath'] as String?;
    if (imagePath == null) return null;

    try {
      final image = await _resourceLoader.loadImage(
        imagePath,
        priority: LoadPriority.background,
        strategy: LoadingStrategy.memoryOptimized,
      );

      if (image == null) return null;

      return Container(
        width: _previewDimension.toDouble(),
        height: _previewDimension.toDouble(),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: RawImage(
            image: image,
            fit: BoxFit.cover,
            width: _previewDimension.toDouble(),
            height: _previewDimension.toDouble(),
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to create image preview: $e');
      }
      return _createGenericPreview(elementData);
    }
  }

  /// Create preview representation (thumbnail/simplified version)
  Future<ElementRepresentation?> _createPreviewRepresentation(
    String elementId,
    Map<String, dynamic> elementData,
  ) async {
    final elementType = elementData['type'] as String? ?? 'unknown';

    Widget? previewWidget;

    switch (elementType) {
      case 'image':
        previewWidget = await _createImagePreview(elementData);
        break;
      case 'text':
        previewWidget = _createTextPreview(elementData);
        break;
      case 'collection':
        previewWidget = _createCollectionPreview(elementData);
        break;
      default:
        previewWidget = _createGenericPreview(elementData);
        break;
    }

    if (previewWidget == null) return null;

    _previewGeneratedCount++;
    final originalSize = _estimateElementSize(elementData);
    final optimizedSize =
        originalSize ~/ 4; // Assume 4x size reduction for previews

    return ElementRepresentation(
      elementId: elementId,
      mode: ElementRepresentationMode.preview,
      widget: previewWidget,
      metadata: ElementMetadata(
        originalSize: originalSize,
        optimizedSize: optimizedSize,
        compressionRatio: optimizedSize / originalSize,
        generationTime: DateTime.now(),
      ),
    );
  }

  /// Create proxy representation (placeholder that loads on demand)
  Future<ElementRepresentation?> _createProxyRepresentation(
    String elementId,
    Map<String, dynamic> elementData,
  ) async {
    final proxyWidget = _createProxyWidget(elementId, elementData);

    final originalSize = _estimateElementSize(elementData);
    const proxySize = 1024; // Small proxy size

    return ElementRepresentation(
      elementId: elementId,
      mode: ElementRepresentationMode.proxy,
      widget: proxyWidget,
      metadata: ElementMetadata(
        originalSize: originalSize,
        optimizedSize: proxySize,
        compressionRatio: proxySize / originalSize,
        generationTime: DateTime.now(),
      ),
    );
  }

  /// Create proxy widget that loads content on demand
  Widget _createProxyWidget(
      String elementId, Map<String, dynamic> elementData) {
    return GestureDetector(
      onTap: () => _loadFullRepresentation(elementId, elementData),
      child: Container(
        width: _previewDimension.toDouble(),
        height: _previewDimension.toDouble(),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
          color: Colors.orange.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_download,
              size: 32,
              color: Colors.orange.withOpacity(0.7),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to load',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create text preview
  Widget _createTextPreview(Map<String, dynamic> elementData) {
    final text = elementData['text'] as String? ?? 'Text Element';
    final truncatedText =
        text.length > 50 ? '${text.substring(0, 50)}...' : text;

    return Container(
      width: _previewDimension.toDouble(),
      height: (_previewDimension / 2).toDouble(),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
        color: Colors.blue.withOpacity(0.1),
      ),
      child: Text(
        truncatedText,
        style: const TextStyle(fontSize: 10),
        overflow: TextOverflow.ellipsis,
        maxLines: 3,
      ),
    );
  }

  /// Determine optimal representation mode
  ElementRepresentationMode _determineOptimalRepresentationMode(
    String elementType,
    Map<String, dynamic> elementData,
    MemoryStats memoryStats,
  ) {
    final estimatedSize = _estimateElementSize(elementData);
    final memoryPressure = memoryStats.pressureRatio;

    // High memory pressure - use most efficient representation
    if (memoryPressure > 0.8) {
      return estimatedSize > _largeElementThreshold
          ? ElementRepresentationMode.proxy
          : ElementRepresentationMode.compressed;
    }

    // Medium memory pressure - balance efficiency and quality
    if (memoryPressure > 0.6) {
      return estimatedSize > _largeElementThreshold
          ? ElementRepresentationMode.compressed
          : ElementRepresentationMode.preview;
    }

    // Low memory pressure - prefer quality
    if (estimatedSize > _largeElementThreshold * 2) {
      return ElementRepresentationMode.compressed;
    }

    return ElementRepresentationMode.full;
  }

  /// Estimate element size in bytes
  int _estimateElementSize(Map<String, dynamic> elementData) {
    final elementType = elementData['type'] as String? ?? 'unknown';

    switch (elementType) {
      case 'image':
        final width = (elementData['width'] as num?)?.toDouble() ?? 100;
        final height = (elementData['height'] as num?)?.toDouble() ?? 100;
        return (width * height * 4).round(); // 4 bytes per pixel (RGBA)
      case 'text':
        final text = elementData['text'] as String? ?? '';
        return text.length * 2; // 2 bytes per character (UTF-16)
      case 'collection':
        final items = elementData['items'] as List? ?? [];
        return items.length * 1024; // Estimate 1KB per item
      default:
        return 1024; // Default 1KB estimation
    }
  }

  /// Generate appropriate representation based on element type and memory constraints
  Future<ElementRepresentation?> _generateRepresentation(
    String elementId,
    Map<String, dynamic> elementData,
    ElementRepresentationMode? mode,
  ) async {
    final elementType = elementData['type'] as String? ?? 'unknown';
    final memoryStats = _memoryManager.memoryStats;

    // Determine representation mode based on memory pressure and element type
    final representationMode = mode ??
        _determineOptimalRepresentationMode(
          elementType,
          elementData,
          memoryStats,
        );

    switch (representationMode) {
      case ElementRepresentationMode.full:
        return await _createFullRepresentation(elementId, elementData);
      case ElementRepresentationMode.preview:
        return await _createPreviewRepresentation(elementId, elementData);
      case ElementRepresentationMode.compressed:
        return await _createCompressedRepresentation(elementId, elementData);
      case ElementRepresentationMode.proxy:
        return await _createProxyRepresentation(elementId, elementData);
      case ElementRepresentationMode.adaptive:
        return await _createAdaptiveRepresentation(elementId, elementData);
    }
  }

  /// Initialize the representation system
  void _initializeRepresentationSystem() {
    _memoryManager.addListener(_onMemoryStateChanged);

    if (kDebugMode) {
      debugPrint('💾 MemoryEfficientElementRepresentation: Initialized');
    }
  }

  /// Load full representation for a proxy element
  Future<void> _loadFullRepresentation(
      String elementId, Map<String, dynamic> elementData) async {
    await createRepresentation(
      elementId,
      elementData,
      mode: ElementRepresentationMode.full,
      forceRegenerate: true,
    );
  }

  /// React to memory state changes
  void _onMemoryStateChanged() {
    final memoryStats = _memoryManager.memoryStats;

    // If under high memory pressure, convert some representations to more efficient modes
    if (memoryStats.pressureRatio > 0.8) {
      _optimizeExistingRepresentations();
    }
  }

  /// Optimize existing representations under memory pressure
  void _optimizeExistingRepresentations() {
    final representationsToOptimize = _representations.entries
        .where((entry) => entry.value.mode == ElementRepresentationMode.full)
        .take(5) // Optimize up to 5 at a time
        .toList();
    for (final entry in representationsToOptimize) {
      final elementId = entry.key;

      // Convert to preview mode asynchronously
      Future(() async {
        // Remove current full representation to free memory
        _representations.remove(elementId);
        // This would re-create the representation in preview mode
        // Implementation depends on how element data is stored
      });
    }
  }

  /// Wait for loading completion
  Future<ElementRepresentation?> _waitForLoadingCompletion(
      String elementId) async {
    while (_loadingElements.contains(elementId)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return _representations[elementId];
  }

  /// 🚀 节流通知方法 - 避免内存高效表示管理器过于频繁地触发UI更新
  void _throttledNotifyListeners({
    required String operation,
    Map<String, dynamic>? data,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastNotificationTime) >= _notificationThrottle) {
      _lastNotificationTime = now;

      EditPageLogger.performanceInfo(
        '内存高效表示管理器通知',
        data: {
          'operation': operation,
          'representationCount': _representations.length,
          'optimization': 'throttled_memory_efficient_notification',
          ...?data,
        },
      );

      super.notifyListeners();
    } else {
      // 缓存待处理的更新
      if (!_hasPendingUpdate) {
        _hasPendingUpdate = true;
        _notificationTimer?.cancel();
        _notificationTimer = Timer(_notificationThrottle, () {
          _hasPendingUpdate = false;

          EditPageLogger.performanceInfo(
            '内存高效表示管理器延迟通知',
            data: {
              'operation': operation,
              'representationCount': _representations.length,
              'optimization': 'throttled_delayed_memory_efficient_notification',
              ...?data,
            },
          );

          super.notifyListeners();
        });
      }
    }
  }
}

/// Representation statistics
class RepresentationStats {
  final int totalRepresentations;
  final int memoryOptimizedCount;
  final int previewGeneratedCount;
  final int compressionSavedBytes;
  final int activeRepresentations;
  final int loadingElements;

  RepresentationStats({
    required this.totalRepresentations,
    required this.memoryOptimizedCount,
    required this.previewGeneratedCount,
    required this.compressionSavedBytes,
    required this.activeRepresentations,
    required this.loadingElements,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalRepresentations': totalRepresentations,
      'memoryOptimizedCount': memoryOptimizedCount,
      'previewGeneratedCount': previewGeneratedCount,
      'compressionSavedBytes': compressionSavedBytes,
      'activeRepresentations': activeRepresentations,
      'loadingElements': loadingElements,
    };
  }

  @override
  String toString() {
    return 'RepresentationStats(total: $totalRepresentations, optimized: $memoryOptimizedCount, '
        'previews: $previewGeneratedCount, saved: ${compressionSavedBytes}B)';
  }
}
