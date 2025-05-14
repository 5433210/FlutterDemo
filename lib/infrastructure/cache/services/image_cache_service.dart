import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../../infrastructure/logging/logger.dart';
import '../interfaces/i_cache.dart';

/// 统一图像缓存服务
///
/// 提供对二进制图像数据和UI图像对象的缓存操作，以及Flutter内置缓存的操作
class ImageCacheService {
  /// 二进制图像数据缓存
  final ICache<String, Uint8List> _binaryCache;

  /// UI图像对象缓存
  final ICache<String, ui.Image> _uiImageCache;

  /// Flutter内置缓存的引用
  final ImageCache _flutterImageCache;

  /// 构造函数
  ///
  /// [binaryCache] 二进制图像数据缓存
  /// [uiImageCache] UI图像对象缓存
  ImageCacheService({
    required ICache<String, Uint8List> binaryCache,
    required ICache<String, ui.Image> uiImageCache,
  })  : _binaryCache = binaryCache,
        _uiImageCache = uiImageCache,
        _flutterImageCache = PaintingBinding.instance.imageCache;

  /// 缓存二进制图像数据
  Future<void> cacheBinaryImage(String key, Uint8List data) async {
    await _binaryCache.put(key, data);
  }

  /// 缓存UI图像对象
  Future<void> cacheUiImage(String key, ui.Image image) async {
    // 同时存入内存缓存和持久化缓存
    _inMemoryUiImageCache[key] = image;
    await _uiImageCache.put(key, image);
    debugPrint('图像已缓存: $key');
  }

  /// 清除所有图像缓存
  Future<void> clearAll() async {
    await _binaryCache.clear();
    await _uiImageCache.clear();
    _flutterImageCache.clear();
    _flutterImageCache.clearLiveImages();

    AppLogger.debug('已清除所有图像缓存');
  }

  /// 从二进制数据解码UI图像
  Future<ui.Image?> decodeImageFromBytes(Uint8List bytes) async {
    try {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image image) {
        completer.complete(image);
      });
      return await completer.future;
    } catch (e) {
      debugPrint('解码图像失败: $e');
      return null;
    }
  }

  /// 从Flutter缓存中移除图像
  void evictFromFlutterCache(ImageProvider provider) {
    _flutterImageCache.evict(provider);
  }

  /// 从缓存中移除特定文件图像
  void evictImage(String path) {
    try {
      // 从Flutter缓存中移除
      final provider = FileImage(File(path));
      _flutterImageCache.evict(provider);

      AppLogger.debug('已从缓存移除图像', data: {'path': path});
    } catch (e) {
      AppLogger.error('从缓存移除图像失败', error: e, data: {'path': path});
    }
  }

  /// 从缓存中移除特定内存图像
  void evictMemoryImage(Uint8List bytes) {
    try {
      // 从Flutter缓存中移除
      final provider = MemoryImage(bytes);
      _flutterImageCache.evict(provider);

      AppLogger.debug('已从缓存移除内存图像', data: {'bytesLength': bytes.length});
    } catch (e) {
      AppLogger.error('从缓存移除内存图像失败', error: e);
    }
  }

  /// 生成缓存键
  String generateCacheKey(
      String id, String type, Map<String, dynamic> transform) {
    final transformString = jsonEncode(transform);
    final transformHash = md5.convert(utf8.encode(transformString)).toString();
    return '$id-$type-$transformHash';
  }

  /// 生成缩略图
  Future<Uint8List?> generateThumbnail(Uint8List data) async {
    try {
      // 解码图片
      final image = img.decodeImage(data);
      if (image == null) return null;

      // 计算缩略图尺寸
      const maxSize = 200;
      final width = image.width;
      final height = image.height;
      var newWidth = width;
      var newHeight = height;

      if (width > height) {
        if (width > maxSize) {
          newWidth = maxSize;
          newHeight = (height * maxSize / width).round();
        }
      } else {
        if (height > maxSize) {
          newHeight = maxSize;
          newWidth = (width * maxSize / height).round();
        }
      }

      // 生成缩略图
      final thumbnail = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // 编码为 JPEG
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));
    } catch (e) {
      AppLogger.error('生成缩略图失败', error: e);
      return null;
    }
  }

  /// 获取二进制图像数据
  Future<Uint8List?> getBinaryImage(String key) async {
    return await _binaryCache.get(key);
  }

  /// 获取处理后的图像
  ///
  /// 如果缓存中存在，则返回缓存的图像
  /// 否则，使用提供的处理函数处理图像并缓存结果
  Future<Uint8List?> getProcessedImage(
    String key,
    Future<Uint8List?> Function() imageLoader,
    Future<Uint8List?> Function(Uint8List) imageProcessor,
  ) async {
    // 尝试从缓存获取
    final cachedImage = await _binaryCache.get(key);
    if (cachedImage != null) {
      return cachedImage;
    }

    // 加载原始图像
    final originalImage = await imageLoader();
    if (originalImage == null) {
      return null;
    }

    // 处理图像
    final processedImage = await imageProcessor(originalImage);
    if (processedImage == null) {
      return null;
    }

    // 缓存处理结果
    await _binaryCache.put(key, processedImage);

    return processedImage;
  }

  /// 获取UI图像对象 - 异步方式
  Future<ui.Image?> getUiImage(String key) async {
    return await _uiImageCache.get(key);
  }
  
  // 内存中的UI图像缓存
  final Map<String, ui.Image> _inMemoryUiImageCache = {};

  /// 同步检查缓存中是否存在指定的UI图像
  /// 
  /// [key] 缓存键
  /// 返回是否存在该缓存项
  bool hasCachedUiImage(String key) {
    try {
      // 首先检查内存缓存
      if (_inMemoryUiImageCache.containsKey(key)) {
        return true;
      }
      
      // 然后检查缓存文件是否存在
      final cacheDir = Directory('${Directory.systemTemp.path}/cache/images');
      final cacheFile = File('${cacheDir.path}/$key');
      
      if (!cacheFile.existsSync()) {
        debugPrint('缓存文件不存在: ${cacheFile.path}');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('检查缓存异常: $e');
      return false;
    }
  }
  
  /// 尝试同步获取UI图像对象
  /// 
  /// [key] 缓存键
  /// 如果存在于内存缓存中，返回缓存的图像，否则返回null
  ui.Image? tryGetUiImageSync(String key) {
    try {
      // 首先检查内存缓存
      if (_inMemoryUiImageCache.containsKey(key)) {
        debugPrint('从内存缓存中找到图像: $key');
        return _inMemoryUiImageCache[key];
      }
      
      debugPrint('图像不在内存缓存中: $key');
      return null;
    } catch (e) {
      debugPrint('尝试同步获取图像异常: $e');
      return null;
    }
  }
  
  /// 检查缓存文件是否存在
  /// 
  /// [key] 缓存键
  /// 返回文件是否存在
  bool cacheFileExists(String key) {
    try {
      final cacheDir = Directory('${Directory.systemTemp.path}/cache/images');
      final cacheFile = File('${cacheDir.path}/$key');
      return cacheFile.existsSync();
    } catch (e) {
      debugPrint('检查缓存文件存在性失败: $e');
      return false;
    }
  }
}
