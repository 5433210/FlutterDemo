import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../infrastructure/logging/logger.dart';

/// Utility class for working with Flutter's image cache
class ImageCacheUtil {
  /// Clear the entire image cache
  static void clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    AppLogger.debug('已清除所有图像缓存');
  }

  /// Evict a specific image from cache
  static void evictImage(String path) {
    try {
      final provider = FileImage(File(path));
      PaintingBinding.instance.imageCache.evict(provider);
      AppLogger.debug('已从缓存移除图像', data: {'path': path});
    } catch (e) {
      AppLogger.error('从缓存移除图像失败', error: e, data: {'path': path});
    }
  }

  /// Evict a specific memory image from cache
  static void evictMemoryImage(Uint8List bytes) {
    try {
      final provider = MemoryImage(bytes);
      PaintingBinding.instance.imageCache.evict(provider);
      AppLogger.debug('已从缓存移除内存图像', data: {'bytesLength': bytes.length});
    } catch (e) {
      AppLogger.error('从缓存移除内存图像失败', error: e);
    }
  }
}
