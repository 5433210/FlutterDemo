import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// 图像转换工具类
class ImageConverter {
  /// 缓存已转换的图像，避免重复转换
  static final Map<String, ui.Image> _imageCache = {};

  /// 将图像字节数据转换为ui.Image
  static Future<ui.Image?> bytesToImage(Uint8List bytes) async {
    try {
      // 使用bytes的hashCode作为缓存key
      final key = bytes.hashCode.toString();
      if (_imageCache.containsKey(key)) {
        return _imageCache[key];
      }

      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (result) {
        _imageCache[key] = result;
        completer.complete(result);
      });
      return await completer.future;
    } catch (e) {
      debugPrint('图像转换失败: $e');
      return null;
    }
  }

  /// 清除图像缓存
  static void clearCache() {
    _imageCache.clear();
  }

  /// 将ui.Image转换为图像字节数据
  static Future<Uint8List?> imageToBytes(ui.Image image) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('图像转换失败: $e');
      return null;
    }
  }

  /// 从缓存中移除指定图像
  static void removeFromCache(String key) {
    _imageCache.remove(key);
  }
}
