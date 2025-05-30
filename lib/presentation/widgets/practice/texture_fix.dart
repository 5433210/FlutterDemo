import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/providers/storage_providers.dart';

/// 纹理加载和显示修复工具
class TextureFix {
  /// 加载纹理图像
  static Future<ui.Image?> loadTexture(String path, WidgetRef? ref) async {
    debugPrint('🔄 TextureFix: 开始加载纹理: $path');

    // 提取文件ID
    String fileId = _extractFileId(path);

    // 检查缓存
    if (TextureCache.instance.hasTexture(fileId)) {
      debugPrint('✅ TextureFix: 从缓存加载纹理: $fileId');
      return TextureCache.instance.getTexture(fileId);
    }

    // 直接从文件系统加载
    if (path.contains('C:\\Users')) {
      try {
        File file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          final image = frame.image;

          // 缓存图像
          TextureCache.instance.putTexture(fileId, image);
          debugPrint(
              '✅ TextureFix: 成功从文件系统加载纹理: ${image.width}x${image.height}');
          return image;
        }
      } catch (e) {
        debugPrint('❌ TextureFix: 直接加载文件失败: $e');
      }
    }

    // 使用存储服务加载
    if (ref != null) {
      try {
        final storage = ref.read(initializedStorageProvider);

        // 尝试多种路径格式
        final List<String> pathsToTry = [
          path,
          path.startsWith('/') ? path : '/$path',
          '${storage.getAppDataPath()}/$path',
          '${storage.getAppDataPath()}/library/${path.split('/').last}',
        ];

        for (final tryPath in pathsToTry) {
          final exists = await storage.fileExists(tryPath);
          if (exists) {
            final bytes = await storage.readFile(tryPath);
            if (bytes.isNotEmpty) {
              final codec =
                  await ui.instantiateImageCodec(Uint8List.fromList(bytes));
              final frame = await codec.getNextFrame();
              final image = frame.image;

              // 缓存图像
              TextureCache.instance.putTexture(fileId, image);
              debugPrint(
                  '✅ TextureFix: 成功从存储服务加载纹理: ${image.width}x${image.height}');
              return image;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ TextureFix: 存储服务加载失败: $e');
      }
    }

    debugPrint('❌ TextureFix: 无法加载纹理: $path');
    return null;
  }

  /// 绘制纹理
  static void drawTexture(Canvas canvas, Rect rect, ui.Image image,
      String fillMode, double opacity) {
    canvas.save();
    canvas.clipRect(rect);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..filterQuality = FilterQuality.high;

    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    if (fillMode == 'cover') {
      _drawCoverTexture(canvas, rect, srcRect, image, paint);
    } else if (fillMode == 'contain') {
      _drawContainTexture(canvas, rect, srcRect, image, paint);
    } else if (fillMode == 'repeat') {
      _drawRepeatedTexture(canvas, rect, image, paint, ImageRepeat.repeat);
    } else if (fillMode == 'repeatX') {
      _drawRepeatedTexture(canvas, rect, image, paint, ImageRepeat.repeatX);
    } else if (fillMode == 'repeatY') {
      _drawRepeatedTexture(canvas, rect, image, paint, ImageRepeat.repeatY);
    } else {
      // noRepeat - 默认居中显示
      _drawContainTexture(canvas, rect, srcRect, image, paint);
    }

    canvas.restore();
  }

  /// 绘制占位纹理
  static void drawPlaceholder(Canvas canvas, Size size) {
    canvas.save();

    // 绘制背景
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 绘制点阵
    final dotPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    const spacing = 10.0;
    const dotRadius = 1.5;

    final horizontalDots = (size.width / spacing).ceil();
    final verticalDots = (size.height / spacing).ceil();

    for (var i = 0; i < horizontalDots; i++) {
      for (var j = 0; j < verticalDots; j++) {
        canvas.drawCircle(
          Offset(i * spacing, j * spacing),
          dotRadius,
          dotPaint,
        );
      }
    }

    // 绘制文本
    final textSpan = TextSpan(
      text: '纹理加载中...',
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey.withValues(alpha: 0.7),
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // 绘制文本背景
    final textBgRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: textPainter.width + 10,
      height: textPainter.height + 6,
    );
    canvas.drawRect(
      textBgRect,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    // 绘制文本
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    canvas.restore();
  }

  // 提取文件ID
  static String _extractFileId(String path) {
    String fileName;

    if (path.contains('\\')) {
      final parts = path.split('\\');
      fileName = parts.last;
    } else {
      fileName = path.split('/').last;
    }

    return fileName.split('.').first;
  }

  // 绘制覆盖模式纹理
  static void _drawCoverTexture(
      Canvas canvas, Rect rect, Rect srcRect, ui.Image image, Paint paint) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    final scale = math.max(rect.width / imageWidth, rect.height / imageHeight);

    final scaledWidth = imageWidth * scale;
    final scaledHeight = imageHeight * scale;

    final dx = (rect.width - scaledWidth) / 2;
    final dy = (rect.height - scaledHeight) / 2;

    final destRect = Rect.fromLTWH(
      rect.left + dx,
      rect.top + dy,
      scaledWidth,
      scaledHeight,
    );

    canvas.drawImageRect(image, srcRect, destRect, paint);
  }

  // 绘制包含模式纹理
  static void _drawContainTexture(
      Canvas canvas, Rect rect, Rect srcRect, ui.Image image, Paint paint) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    final scale = math.min(rect.width / imageWidth, rect.height / imageHeight);

    final scaledWidth = imageWidth * scale;
    final scaledHeight = imageHeight * scale;

    final dx = (rect.width - scaledWidth) / 2;
    final dy = (rect.height - scaledHeight) / 2;

    final destRect = Rect.fromLTWH(
      rect.left + dx,
      rect.top + dy,
      scaledWidth,
      scaledHeight,
    );

    canvas.drawImageRect(image, srcRect, destRect, paint);
  }

  // 绘制重复模式纹理
  static void _drawRepeatedTexture(Canvas canvas, Rect rect, ui.Image image,
      Paint paint, ImageRepeat repeat) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    int horizontalCount = 1;
    int verticalCount = 1;

    if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatX) {
      horizontalCount = (rect.width / imageWidth).ceil() + 1;
    }
    if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatY) {
      verticalCount = (rect.height / imageHeight).ceil() + 1;
    }

    final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);

    for (int y = 0; y < verticalCount; y++) {
      for (int x = 0; x < horizontalCount; x++) {
        final destRect = Rect.fromLTWH(
          rect.left + x * imageWidth,
          rect.top + y * imageHeight,
          imageWidth,
          imageHeight,
        );

        canvas.drawImageRect(image, srcRect, destRect, paint);
      }
    }
  }
}

/// 纹理缓存
class TextureCache {
  static final TextureCache instance = TextureCache._();
  final Map<String, ui.Image> _cache = {};

  TextureCache._();

  // 清除缓存
  void clearCache() {
    debugPrint('🧹 TextureCache: 清空缓存 (${_cache.length} 个)');
    _cache.clear();
  }

  // 获取纹理
  ui.Image? getTexture(String key) {
    return _cache[key];
  }

  // 检查纹理是否存在
  bool hasTexture(String key) {
    return _cache.containsKey(key);
  }

  // 存储纹理
  void putTexture(String key, ui.Image image) {
    debugPrint('⭐ TextureCache: 存储纹理 $key => ${image.width}x${image.height}');
    _cache[key] = image;
  }

  // 打印缓存统计
  void printStats() {
    debugPrint('📊 TextureCache: 缓存状态 - ${_cache.length} 个纹理');
    _cache.forEach((key, image) {
      debugPrint('  - $key: ${image.width}x${image.height}');
    });
  }
}

/// 纹理管理器
class TextureManager {
  /// 清除纹理缓存
  static void clearTextureCache() {
    debugPrint('🧹 TextureManager: 清除纹理缓存');
    TextureCache.instance.clearCache();
  }

  /// 加载纹理并返回图像
  static Future<ui.Image?> loadTexture(String path, WidgetRef? ref) {
    return TextureFix.loadTexture(path, ref);
  }
}
