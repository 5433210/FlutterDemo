import 'dart:io';

import 'package:flutter/foundation.dart';

/// Cache for file paths to avoid redundant file system operations
class PathCache {
  // Cache for thumbnail paths
  static final Map<String, String> _thumbnailPaths = {};

  // Cache for file existence checks
  static final Map<String, bool> _fileExistsCache = {};

  // Cache for file size checks
  static final Map<String, int> _fileSizeCache = {};

  // Time-to-live for cache entries in milliseconds
  static const int cacheTtlMs = 5000; // 5 seconds

  // Timestamps for cache invalidation
  static final Map<String, int> _cacheTimestamps = {};

  /// Stores a thumbnail path in cache
  static void cacheThumbnailPath(String characterId, String path) {
    _thumbnailPaths[characterId] = path;
    _setCacheTimestamp(characterId);
  }

  /// Clear all caches
  static void clearAll() {
    _thumbnailPaths.clear();
    _fileExistsCache.clear();
    _fileSizeCache.clear();
    _cacheTimestamps.clear();
  }

  /// Checks if a file exists with caching
  static Future<bool> fileExists(String path) async {
    final cacheKey = 'exists:$path';

    if (_isCacheValid(cacheKey) && _fileExistsCache.containsKey(cacheKey)) {
      return _fileExistsCache[cacheKey]!;
    }

    try {
      final exists = await File(path).exists();
      _fileExistsCache[cacheKey] = exists;
      _setCacheTimestamp(cacheKey);
      return exists;
    } catch (e) {
      debugPrint('Error checking file existence: $e');
      return false;
    }
  }

  /// Gets file size with caching
  static Future<int> fileSize(String path) async {
    final cacheKey = 'size:$path';

    if (_isCacheValid(cacheKey) && _fileSizeCache.containsKey(cacheKey)) {
      return _fileSizeCache[cacheKey]!;
    }

    try {
      final size = await File(path).length();
      _fileSizeCache[cacheKey] = size;
      _setCacheTimestamp(cacheKey);
      return size;
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0;
    }
  }

  /// Gets a cached thumbnail path if available
  static String? getCachedThumbnailPath(String characterId) {
    if (_isCacheValid(characterId) &&
        _thumbnailPaths.containsKey(characterId)) {
      return _thumbnailPaths[characterId];
    }
    return null;
  }

  /// Invalidates cache for a specific character
  static void invalidate(String characterId) {
    _thumbnailPaths.remove(characterId);
    _cacheTimestamps.remove(characterId);

    // Also remove associated file checks
    final thumbnailPath = _thumbnailPaths[characterId];
    if (thumbnailPath != null) {
      _fileExistsCache.remove('exists:$thumbnailPath');
      _fileSizeCache.remove('size:$thumbnailPath');
    }
  }

  // Private helper to check if cache entry is still valid
  static bool _isCacheValid(String key) {
    if (!_cacheTimestamps.containsKey(key)) return false;

    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - timestamp) < cacheTtlMs;
  }

  // Private helper to set cache timestamp
  static void _setCacheTimestamp(String key) {
    _cacheTimestamps[key] = DateTime.now().millisecondsSinceEpoch;
  }
}
