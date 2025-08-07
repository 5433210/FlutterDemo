import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../infrastructure/logging/logger.dart';

/// Information about a managed image resource
class ImageResourceInfo {
  final String resourceId;
  final String elementId;
  final String source;
  final DateTime registrationTime;
  final Map<String, dynamic> metadata;
  bool isDisposed;
  DateTime? disposalTime;

  ImageResourceInfo({
    required this.resourceId,
    required this.elementId,
    required this.source,
    required this.registrationTime,
    required this.metadata,
    this.isDisposed = false,
    this.disposalTime,
  });

  Duration get lifetime {
    final endTime = disposalTime ?? DateTime.now();
    return endTime.difference(registrationTime);
  }
}

/// Wrapper for ui.Image with disposal tracking
class ManagedImage {
  final ui.Image _image;
  bool _isDisposed = false;

  ManagedImage(this._image);

  int get height => _image.height;
  ui.Image get image => _image;
  bool get isDisposed => _isDisposed;
  int get width => _image.width;

  void dispose() {
    if (!_isDisposed) {
      _image.dispose();
      _isDisposed = true;
    }
  }
}

/// Service for on-demand resource loading
class OnDemandResourceLoader {
  final Map<String, Future<ui.Image>> _loadingTasks = {};
  final Map<String, ManagedImage> _cache = {};

  /// Clear the image cache
  void clearCache() {
    for (final managedImage in _cache.values) {
      if (!managedImage.isDisposed) {
        managedImage.dispose();
      }
    }
    _cache.clear();
  }

  /// Dispose the loader
  void dispose() {
    clearCache();
    _loadingTasks.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final validImages = _cache.values.where((img) => !img.isDisposed).length;
    return {
      'totalCached': _cache.length,
      'validImages': validImages,
      'loadingTasks': _loadingTasks.length,
    };
  }

  /// Load an image resource on-demand
  Future<ui.Image?> loadImage(
    String source, {
    bool useCache = true,
    Map<String, dynamic>? loadOptions,
  }) async {
    // Check cache first
    if (useCache && _cache.containsKey(source)) {
      final cachedImage = _cache[source];
      if (cachedImage != null && !cachedImage.isDisposed) {
        return cachedImage.image;
      } else {
        _cache.remove(source);
      }
    }

    // Check if already loading
    if (_loadingTasks.containsKey(source)) {
      final image = await _loadingTasks[source];
      return image;
    }

    // Start loading
    final loadingTask = _loadImageFromSource(source, loadOptions);
    _loadingTasks[source] = loadingTask;

    try {
      final image = await loadingTask;

      if (useCache) {
        _cache[source] = ManagedImage(image);
      }

      return image;
    } finally {
      _loadingTasks.remove(source);
    }
  }

  /// Load image from source (placeholder implementation)
  Future<ui.Image> _loadImageFromSource(
      String source, Map<String, dynamic>? options) async {
    // This is a placeholder - in real implementation, this would:
    // 1. Load from file system for local images
    // 2. Load from network for remote images
    // 3. Load from assets for asset images
    // 4. Handle different image formats and transformations

    if (source.startsWith('file://')) {
      // Load from file system
      throw UnimplementedError('File loading not implemented in this example');
    } else if (source.startsWith('http://') || source.startsWith('https://')) {
      // Load from network
      throw UnimplementedError(
          'Network loading not implemented in this example');
    } else {
      // Load from assets
      final data = await rootBundle.load(source);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    }
  }
}

/// Service for proper disposal of image resources
/// Handles the lifecycle of images to prevent memory leaks
class ResourceDisposalService extends ChangeNotifier {
  static const Duration _disposalDelay =
      Duration(seconds: 30); // 30 second delay before disposal
  final Map<String, ManagedImage> _managedImages = {};
  final Map<String, ImageResourceInfo> _imageInfo = {};
  final Set<String> _pendingDisposal = {};

  Timer? _disposalTimer;

  /// Get statistics about managed resources
  ResourceStats get stats => ResourceStats(
        totalImages: _managedImages.length,
        pendingDisposal: _pendingDisposal.length,
        totalRegistered: _imageInfo.length,
        totalDisposed:
            _imageInfo.values.where((info) => info.isDisposed).length,
      );

  /// Cancel scheduled disposal for an image
  void cancelImageDisposal(String resourceId) {
    _pendingDisposal.remove(resourceId);

    if (kDebugMode) {
      print(
          '❌ ResourceDisposalService: Cancelled disposal for image $resourceId');
    }
  }

  /// Force cleanup of all disposed images from tracking
  void cleanupDisposedImages() {
    final toRemove = <String>[];

    for (final entry in _imageInfo.entries) {
      if (entry.value.isDisposed) {
        final timeSinceDisposal = DateTime.now()
            .difference(entry.value.disposalTime ?? DateTime.now());
        if (timeSinceDisposal.inMinutes > 5) {
          // Keep disposed info for 5 minutes for debugging
          toRemove.add(entry.key);
        }
      }
    }

    for (final resourceId in toRemove) {
      _imageInfo.remove(resourceId);
    }

    if (toRemove.isNotEmpty) {
      AppLogger.debug(
        'ResourceDisposalService: Cleaned up info for disposed images',
        tag: 'ResourceDisposal',
        data: {
          'cleanedCount': toRemove.length,
          'operation': 'cleanup_info',
        },
      );
    }
  }

  @override
  void dispose() {
    _disposalTimer?.cancel();

    // Dispose all managed images
    for (final managedImage in _managedImages.values) {
      if (!managedImage.isDisposed) {
        managedImage.dispose();
      }
    }

    _managedImages.clear();
    _imageInfo.clear();
    _pendingDisposal.clear();

    super.dispose();
  }

  /// Immediately dispose an image resource
  bool disposeImage(String resourceId) {
    final managedImage = _managedImages.remove(resourceId);
    final info = _imageInfo.remove(resourceId);
    _pendingDisposal.remove(resourceId);

    if (managedImage != null && !managedImage.isDisposed) {
      managedImage.dispose();

      if (info != null) {
        info.isDisposed = true;
        info.disposalTime = DateTime.now();
      }

      if (kDebugMode) {
        print('🗑️ ResourceDisposalService: Disposed image $resourceId');
      }

      notifyListeners();
      return true;
    }

    return false;
  }

  /// Dispose all images for a specific element
  void disposeImagesForElement(String elementId) {
    final toDispose = <String>[];

    for (final entry in _imageInfo.entries) {
      if (entry.value.elementId == elementId) {
        toDispose.add(entry.key);
      }
    }

    for (final resourceId in toDispose) {
      disposeImage(resourceId);
    }

    if (toDispose.isNotEmpty) {
      AppLogger.debug(
        'ResourceDisposalService: Disposed images for element',
        tag: 'ResourceDisposal',
        data: {
          'elementId': elementId,
          'disposedCount': toDispose.length,
          'operation': 'dispose_element_images',
        },
      );
    }
  }

  /// Get an image if it's still available
  ui.Image? getImage(String resourceId) {
    final managedImage = _managedImages[resourceId];
    if (managedImage != null && !managedImage.isDisposed) {
      // Cancel any pending disposal since the image is being used
      cancelImageDisposal(resourceId);
      return managedImage.image;
    }
    return null;
  }

  /// Get resource information
  ImageResourceInfo? getImageInfo(String resourceId) {
    return _imageInfo[resourceId];
  }

  /// Handle memory pressure by disposing unused images
  Future<void> handleMemoryPressure({bool aggressive = false}) async {
    final toDispose = <String>[];
    final now = DateTime.now();

    // Dispose pending images immediately
    toDispose.addAll(_pendingDisposal);

    if (aggressive) {
      // In aggressive mode, dispose images that haven't been accessed recently
      for (final entry in _imageInfo.entries) {
        final resourceId = entry.key;
        final info = entry.value;

        if (!info.isDisposed && !_pendingDisposal.contains(resourceId)) {
          final timeSinceRegistration = now.difference(info.registrationTime);
          if (timeSinceRegistration.inMinutes > 2) {
            toDispose.add(resourceId);
          }
        }
      }
    }

    for (final resourceId in toDispose) {
      disposeImage(resourceId);
    }

    if (toDispose.isNotEmpty) {
      AppLogger.debug(
        'ResourceDisposalService: Disposed images due to memory pressure',
        tag: 'ResourceDisposal',
        data: {
          'disposedCount': toDispose.length,
          'operation': 'memory_pressure_cleanup',
        },
      );
    }
  }

  /// Check if an image resource exists and is not disposed
  bool hasImage(String resourceId) {
    final managedImage = _managedImages[resourceId];
    return managedImage != null && !managedImage.isDisposed;
  }

  /// Register an image for managed disposal
  void registerImage(
    String resourceId,
    ui.Image image, {
    String? source,
    required String elementId,
    Map<String, dynamic>? metadata,
  }) {
    // Dispose existing image if present
    disposeImage(resourceId);

    _managedImages[resourceId] = ManagedImage(image);
    _imageInfo[resourceId] = ImageResourceInfo(
      resourceId: resourceId,
      elementId: elementId,
      source: source ?? 'unknown',
      registrationTime: DateTime.now(),
      metadata: metadata ?? {},
      isDisposed: false,
    );

    if (kDebugMode) {
      print(
          '📷 ResourceDisposalService: Registered image $resourceId for element $elementId');
    }
  }

  /// Schedule an image for delayed disposal
  void scheduleImageDisposal(String resourceId) {
    if (!_managedImages.containsKey(resourceId)) return;

    _pendingDisposal.add(resourceId);

    if (kDebugMode) {
      print(
          '⏰ ResourceDisposalService: Scheduled image $resourceId for disposal');
    }

    _startDisposalTimer();
  }

  /// Process pending image disposals
  void _processPendingDisposals() {
    final toDispose = List<String>.from(_pendingDisposal);
    _pendingDisposal.clear();

    for (final resourceId in toDispose) {
      disposeImage(resourceId);
    }
  }

  /// Start the disposal timer if not already running
  void _startDisposalTimer() {
    if (_disposalTimer?.isActive == true) return;

    _disposalTimer = Timer.periodic(_disposalDelay, (timer) {
      _processPendingDisposals();

      // Stop timer if no pending disposals
      if (_pendingDisposal.isEmpty) {
        timer.cancel();
      }
    });
  }

  /// Create an image resource ID from element information
  static String createResourceId(String elementId, String imageSource) {
    return '${elementId}_${imageSource.hashCode}';
  }
}

/// Statistics about resource disposal
class ResourceStats {
  final int totalImages;
  final int pendingDisposal;
  final int totalRegistered;
  final int totalDisposed;

  ResourceStats({
    required this.totalImages,
    required this.pendingDisposal,
    required this.totalRegistered,
    required this.totalDisposed,
  });

  int get activeImages => totalImages;
  double get disposalRate =>
      totalRegistered > 0 ? totalDisposed / totalRegistered : 0.0;

  @override
  String toString() {
    return 'ResourceStats(active: $activeImages, pending: $pendingDisposal, '
        'disposed: $totalDisposed/$totalRegistered, rate: ${(disposalRate * 100).toStringAsFixed(1)}%)';
  }
}
