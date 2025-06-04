import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Specialized handler for large elements that require special memory management
class LargeElementHandler extends ChangeNotifier {
  static const int _largeElementThreshold = 1024 * 1024; // 1MB
  static const int _veryLargeElementThreshold = 10 * 1024 * 1024; // 10MB
  static const int _maxConcurrentLargeElements =
      3; // Limit concurrent large elements

  final Map<String, LargeElementInfo> _largeElements = {};
  final Map<String, LargeElementProxy> _elementProxies = {};
  final Queue<String> _loadingQueue = Queue<String>();
  final Set<String> _currentlyLoading = {};

  int _totalLargeElementMemory = 0;

  /// Get statistics about large elements
  LargeElementStats get stats => LargeElementStats(
        totalLargeElements: _largeElements.length,
        totalMemoryUsage: _totalLargeElementMemory,
        veryLargeElements:
            _largeElements.values.where((info) => info.isVeryLarge).length,
        currentlyLoading: _currentlyLoading.length,
        queuedForLoading: _loadingQueue.length,
      );

  /// Create memory-efficient representation for a large element
  MemoryEfficientLargeElement createMemoryEfficientRepresentation(
      String elementId, Map<String, dynamic> element) {
    final info = _largeElements[elementId];
    if (info == null) {
      throw ArgumentError(
          'Element $elementId is not registered as large element');
    }

    return MemoryEfficientLargeElement(
      elementId: elementId,
      elementType: info.elementType,
      estimatedSize: info.estimatedSize,
      isVeryLarge: info.isVeryLarge,
      // Store only essential properties for large elements
      essentialProperties: _extractEssentialProperties(element),
      // Lazy loading function for full properties
      fullElementLoader: () => _loadFullElementData(elementId, element),
      // Preview generator for placeholder rendering
      previewGenerator: () => _generateElementPreview(element),
    );
  }

  @override
  void dispose() {
    _largeElements.clear();
    _elementProxies.clear();
    _loadingQueue.clear();
    _currentlyLoading.clear();
    super.dispose();
  }

  /// Get proxy for large element (lazy loading wrapper)
  LargeElementProxy? getElementProxy(String elementId) {
    return _elementProxies[elementId];
  }

  /// Handle memory pressure by unloading large elements
  Future<int> handleMemoryPressure({required bool aggressive}) async {
    int freedMemory = 0;
    final now = DateTime.now();

    // Sort large elements by priority for unloading
    final sortedElements = _largeElements.entries.toList()
      ..sort((a, b) {
        final aInfo = a.value;
        final bInfo = b.value;

        // Prioritize unloading: very large > old > less recently used
        if (aInfo.isVeryLarge && !bInfo.isVeryLarge) return -1;
        if (!aInfo.isVeryLarge && bInfo.isVeryLarge) return 1;

        return aInfo.registrationTime.compareTo(bInfo.registrationTime);
      });

    final maxToUnload =
        aggressive ? sortedElements.length : math.min(2, sortedElements.length);

    for (int i = 0; i < maxToUnload; i++) {
      final entry = sortedElements[i];
      final elementId = entry.key;
      final info = entry.value;

      if (_unloadLargeElement(elementId)) {
        freedMemory += info.estimatedSize;

        if (kDebugMode) {
          print(
              '💾 LargeElementHandler: Unloaded large element $elementId to free memory');
        }
      }
    }

    return freedMemory;
  }

  /// Optimize large element for rendering
  Widget optimizeLargeElementRendering(
      String elementId, Map<String, dynamic> element, Widget fallbackWidget) {
    final info = _largeElements[elementId];
    if (info == null) return fallbackWidget;

    return LargeElementOptimizedWidget(
      elementId: elementId,
      element: element,
      estimatedSize: info.estimatedSize,
      isVeryLarge: info.isVeryLarge,
      fallbackWidget: fallbackWidget,
      handler: this,
    );
  }

  /// Preload large elements that are likely to be needed soon
  Future<void> preloadVisibleElements(List<String> visibleElementIds) async {
    final largeVisibleElements = visibleElementIds
        .where((id) => _largeElements.containsKey(id))
        .toList();

    // Prioritize loading of visible large elements
    for (final elementId in largeVisibleElements) {
      if (!_currentlyLoading.contains(elementId) &&
          _currentlyLoading.length < _maxConcurrentLargeElements) {
        _queueForLoading(elementId);
      }
    }

    await _processLoadingQueue();
  }

  /// Register a large element
  void registerLargeElement(
      String elementId, Map<String, dynamic> element, int estimatedSize) {
    if (estimatedSize < _largeElementThreshold) return;

    final info = LargeElementInfo(
      elementId: elementId,
      elementType: element['type'] as String? ?? 'unknown',
      estimatedSize: estimatedSize,
      registrationTime: DateTime.now(),
      isVeryLarge: estimatedSize > _veryLargeElementThreshold,
    );

    _largeElements[elementId] = info;
    _totalLargeElementMemory += estimatedSize;

    // Create a proxy for lazy loading
    _elementProxies[elementId] = LargeElementProxy(
      elementId: elementId,
      element: element,
      estimatedSize: estimatedSize,
      loadCallback: () => _loadLargeElement(elementId),
      unloadCallback: () => _unloadLargeElement(elementId),
    );

    if (kDebugMode) {
      print('🐘 LargeElementHandler: Registered large element $elementId '
          '(${element['type']}, ${_formatBytes(estimatedSize)})');
    }

    notifyListeners();
  }

  /// Unregister a large element
  void unregisterLargeElement(String elementId) {
    final info = _largeElements.remove(elementId);
    if (info != null) {
      _totalLargeElementMemory -= info.estimatedSize;
      _elementProxies.remove(elementId);
      _currentlyLoading.remove(elementId);

      if (kDebugMode) {
        print('🗑️ LargeElementHandler: Unregistered large element $elementId');
      }

      notifyListeners();
    }
  }

  /// Extract essential properties for memory efficiency
  Map<String, dynamic> _extractEssentialProperties(
      Map<String, dynamic> element) {
    return {
      'id': element['id'],
      'type': element['type'],
      'x': element['x'],
      'y': element['y'],
      'width': element['width'],
      'height': element['height'],
      'layerId': element['layerId'],
    };
  }

  /// Format bytes to readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Generate preview for large element
  Widget _generateElementPreview(Map<String, dynamic> element) {
    final elementType = element['type'] as String? ?? 'unknown';
    final width = (element['width'] as num?)?.toDouble() ?? 100.0;
    final height = (element['height'] as num?)?.toDouble() ?? 100.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
        borderRadius: BorderRadius.circular(4),
        color: const Color(0xFFF5F5F5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForElementType(elementType),
              size: math.min(width, height) * 0.3,
              color: const Color(0xFF757575),
            ),
            const SizedBox(height: 4),
            Text(
              'Loading $elementType...',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Get icon for element type
  IconData _getIconForElementType(String elementType) {
    switch (elementType) {
      case 'image':
        return Icons.image;
      case 'collection':
        return Icons.text_fields;
      case 'group':
        return Icons.group_work;
      default:
        return Icons.widgets;
    }
  }

  /// Load full element data
  Future<Map<String, dynamic>> _loadFullElementData(
      String elementId, Map<String, dynamic> element) async {
    // In a real implementation, this might load from a database or file
    await Future.delayed(
        const Duration(milliseconds: 50)); // Simulate loading time
    return Map<String, dynamic>.from(element);
  }

  /// Load a large element
  Future<bool> _loadLargeElement(String elementId) async {
    if (_currentlyLoading.contains(elementId)) return true;

    _currentlyLoading.add(elementId);

    try {
      // Simulate loading time for very large elements
      final info = _largeElements[elementId];
      if (info != null && info.isVeryLarge) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (kDebugMode) {
        print('📥 LargeElementHandler: Loaded large element $elementId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ LargeElementHandler: Failed to load large element $elementId: $e');
      }
      return false;
    } finally {
      _currentlyLoading.remove(elementId);
    }
  }

  /// Process the loading queue
  Future<void> _processLoadingQueue() async {
    while (_loadingQueue.isNotEmpty &&
        _currentlyLoading.length < _maxConcurrentLargeElements) {
      final elementId = _loadingQueue.removeFirst();
      await _loadLargeElement(elementId);
    }
  }

  /// Queue element for loading
  void _queueForLoading(String elementId) {
    if (!_loadingQueue.contains(elementId) &&
        !_currentlyLoading.contains(elementId)) {
      _loadingQueue.add(elementId);
    }
  }

  /// Unload a large element
  bool _unloadLargeElement(String elementId) {
    _currentlyLoading.remove(elementId);
    // Additional unloading logic would go here
    return true;
  }
}

/// Information about a large element
class LargeElementInfo {
  final String elementId;
  final String elementType;
  final int estimatedSize;
  final DateTime registrationTime;
  final bool isVeryLarge;

  LargeElementInfo({
    required this.elementId,
    required this.elementType,
    required this.estimatedSize,
    required this.registrationTime,
    required this.isVeryLarge,
  });
}

/// Optimized widget for rendering large elements
class LargeElementOptimizedWidget extends StatefulWidget {
  final String elementId;
  final Map<String, dynamic> element;
  final int estimatedSize;
  final bool isVeryLarge;
  final Widget fallbackWidget;
  final LargeElementHandler handler;

  const LargeElementOptimizedWidget({
    Key? key,
    required this.elementId,
    required this.element,
    required this.estimatedSize,
    required this.isVeryLarge,
    required this.fallbackWidget,
    required this.handler,
  }) : super(key: key);

  @override
  State<LargeElementOptimizedWidget> createState() =>
      _LargeElementOptimizedWidgetState();
}

/// Proxy for lazy loading of large elements
class LargeElementProxy {
  final String elementId;
  final Map<String, dynamic> element;
  final int estimatedSize;
  final Future<bool> Function() loadCallback;
  final bool Function() unloadCallback;

  bool _isLoaded = false;
  bool _isLoading = false;

  LargeElementProxy({
    required this.elementId,
    required this.element,
    required this.estimatedSize,
    required this.loadCallback,
    required this.unloadCallback,
  });

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  Future<bool> load() async {
    if (_isLoaded || _isLoading) return _isLoaded;

    _isLoading = true;
    try {
      _isLoaded = await loadCallback();
      return _isLoaded;
    } finally {
      _isLoading = false;
    }
  }

  bool unload() {
    if (!_isLoaded) return true;

    final result = unloadCallback();
    if (result) {
      _isLoaded = false;
    }
    return result;
  }
}

/// Statistics for large element handling
class LargeElementStats {
  final int totalLargeElements;
  final int totalMemoryUsage;
  final int veryLargeElements;
  final int currentlyLoading;
  final int queuedForLoading;

  LargeElementStats({
    required this.totalLargeElements,
    required this.totalMemoryUsage,
    required this.veryLargeElements,
    required this.currentlyLoading,
    required this.queuedForLoading,
  });

  @override
  String toString() {
    return 'LargeElementStats(total: $totalLargeElements, '
        'memory: ${_formatBytes(totalMemoryUsage)}, '
        'veryLarge: $veryLargeElements, loading: $currentlyLoading)';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Memory-efficient representation of a large element
class MemoryEfficientLargeElement {
  final String elementId;
  final String elementType;
  final int estimatedSize;
  final bool isVeryLarge;
  final Map<String, dynamic> essentialProperties;
  final Future<Map<String, dynamic>> Function() fullElementLoader;
  final Widget Function() previewGenerator;

  MemoryEfficientLargeElement({
    required this.elementId,
    required this.elementType,
    required this.estimatedSize,
    required this.isVeryLarge,
    required this.essentialProperties,
    required this.fullElementLoader,
    required this.previewGenerator,
  });

  /// Generate preview widget
  Widget generatePreview() {
    return previewGenerator();
  }

  /// Load full element properties
  Future<Map<String, dynamic>> loadFullElement() async {
    return await fullElementLoader();
  }
}

/// Simple queue implementation
class Queue<T> {
  final List<T> _items = [];

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;
  void add(T item) => _items.add(item);
  void clear() => _items.clear();
  bool contains(T item) => _items.contains(item);
  T removeFirst() => _items.removeAt(0);
}

class _LargeElementOptimizedWidgetState
    extends State<LargeElementOptimizedWidget> {
  bool _isVisible = false;
  bool _isLoaded = false;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      // Return a placeholder for off-screen large elements
      return const SizedBox.shrink();
    }

    if (widget.isVeryLarge && !_isLoaded) {
      // Show loading preview for very large elements
      return widget.handler._generateElementPreview(widget.element);
    }

    // Return the actual widget
    return widget.fallbackWidget;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    // Use a simple heuristic to determine if the element is likely visible
    // In a real implementation, this would check viewport intersection
    setState(() {
      _isVisible = true;
    });

    if (_isVisible && !_isLoaded) {
      _loadElement();
    }
  }

  Future<void> _loadElement() async {
    final proxy = widget.handler.getElementProxy(widget.elementId);
    if (proxy != null) {
      final success = await proxy.load();
      if (mounted) {
        setState(() {
          _isLoaded = success;
        });
      }
    }
  }
}
