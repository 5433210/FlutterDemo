import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'character_position.dart';
import 'global_image_cache.dart';
import 'texture_config.dart';

/// 集字绘制器 - 实现CustomPainter，负责字符和纹理的绘制
class CollectionPainter extends CustomPainter {
  // 基本属性
  final List<String> characters;
  final List<CharacterPosition> positions;
  final double fontSize;
  final dynamic characterImages;
  final TextureConfig textureConfig;
  final dynamic ref;

  // 内部状态变量
  final Set<String> _loadingTextures = {};
  bool _needsRepaint = false;
  VoidCallback? _repaintCallback;
  String? _cacheKey;

  /// 构造函数
  CollectionPainter({
    required this.characters,
    required this.positions,
    required this.fontSize,
    required this.characterImages,
    required this.textureConfig,
    this.ref,
  });

  /// 设置重绘回调函数
  void setRepaintCallback(VoidCallback callback) {
    _repaintCallback = callback;
  }

  @override
  bool shouldRepaint(covariant CollectionPainter oldDelegate) {
    // 如果纹理配置变化，需要重绘
    if (oldDelegate.textureConfig != textureConfig) {
      return true;
    }

    // 如果有明确标记需要重绘，返回true
    if (_needsRepaint) {
      _needsRepaint = false; // 重置标志
      return true;
    }

    // 其他情况下，使用默认比较逻辑
    return oldDelegate.characters != characters ||
        oldDelegate.positions != positions ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.characterImages != characterImages;
  }

  /// 主绘制方法
  @override
  void paint(Canvas canvas, Size size) {
    try {
      // 1. 首先绘制整体背景（如果需要）
      if (textureConfig.enabled &&
          textureConfig.data != null &&
          textureConfig.applicationMode == 'background') {
        final rect = Offset.zero & size;
        _paintTexture(canvas, rect, mode: 'background');
      }

      // 2. 遍历所有字符位置，绘制字符
      for (int i = 0; i < positions.length; i++) {
        final position = positions[i];

        // 跳过换行符
        if (i < characters.length && characters[i] == '\n') continue;

        // 创建绘制区域
        final rect = Rect.fromLTWH(
          position.x,
          position.y,
          position.size,
          position.size,
        );

        // 3. 绘制字符背景
        // 根据纹理配置，决定绘制普通背景还是纹理背景
        if (textureConfig.enabled &&
            textureConfig.data != null &&
            textureConfig.applicationMode == 'characterBackground') {
          _paintTexture(canvas, rect, mode: 'characterBackground');
        } else {
          _drawFallbackBackground(canvas, rect, position);
        }

        // 4. 获取字符图片并绘制
        final charImage = _findCharacterImage(position.char, position.index);
        if (charImage != null) {
          // 如果有图片，绘制图片
          _drawCharacterImage(canvas, rect, position, charImage);
        } else {
          // 如果没有图片，绘制文本
          _drawFallbackText(canvas, position, rect);
        }
      }
    } catch (e) {
      debugPrint('绘制异常：$e');
    }
  }

  /// 绘制背景纹理
  void _paintTexture(Canvas canvas, Rect rect, {required String mode}) {
    if (!textureConfig.enabled || textureConfig.data == null) return;

    final data = textureConfig.data!;
    final texturePath = data['path'] as String?;
    if (texturePath == null || texturePath.isEmpty) return;

    // 处理纹理模式，只有在当前模式匹配时才绘制
    if (mode != textureConfig.applicationMode) return;

    try {
      // 获取图像
      final image = GlobalImageCache.get(texturePath);

      if (image != null) {
        // 有纹理图片，绘制纹理
        _drawTextureWithImage(canvas, rect, image);
      } else {
        // 纹理加载中，显示占位符
        _drawFallbackTexture(canvas, rect);

        // 异步加载纹理图片
        if (!_loadingTextures.contains(texturePath)) {
          _loadingTextures.add(texturePath);
          _loadAndCacheTexture(texturePath).then((loadedImage) {
            _loadingTextures.remove(texturePath);
            if (loadedImage != null && _repaintCallback != null) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                _repaintCallback!();
              });
            }
          });
        }
      }
    } catch (e, stack) {
      debugPrint('❌ 纹理绘制错误: $e\n$stack');
    }
  }

  /// 使用图像绘制纹理
  void _drawTextureWithImage(Canvas canvas, Rect rect, ui.Image image) {
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Colors.white.withOpacity(textureConfig.opacity);

    if (textureConfig.fillMode == 'repeat') {
      // 平铺模式
      final shader = ImageShader(
        image,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );
      paint.shader = shader;
      canvas.drawRect(rect, paint);
    } else if (textureConfig.fillMode == 'cover') {
      // 覆盖模式 - 调整图像大小以覆盖整个区域，可能会被裁剪
      final imageRatio = image.width / image.height;
      final targetRatio = rect.width / rect.height;

      double scaledWidth, scaledHeight;
      if (imageRatio > targetRatio) {
        // 图像相对更宽，以高度为基准
        scaledHeight = rect.height;
        scaledWidth = scaledHeight * imageRatio;
      } else {
        // 图像相对更高，以宽度为基准
        scaledWidth = rect.width;
        scaledHeight = scaledWidth / imageRatio;
      }

      final srcRect =
          Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble());
      final destRect = Rect.fromCenter(
        center: rect.center,
        width: scaledWidth,
        height: scaledHeight,
      );

      canvas.drawImageRect(image, srcRect, destRect, paint);
    } else if (textureConfig.fillMode == 'contain') {
      // 包含模式 - 调整图像大小以完全显示，可能会有空白
      final imageRatio = image.width / image.height;
      final targetRatio = rect.width / rect.height;

      double scaledWidth, scaledHeight;
      if (imageRatio > targetRatio) {
        // 图像相对更宽，以宽度为基准
        scaledWidth = rect.width;
        scaledHeight = scaledWidth / imageRatio;
      } else {
        // 图像相对更高，以高度为基准
        scaledHeight = rect.height;
        scaledWidth = scaledHeight * imageRatio;
      }

      final srcRect =
          Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble());
      final destRect = Rect.fromCenter(
        center: rect.center,
        width: scaledWidth,
        height: scaledHeight,
      );

      canvas.drawImageRect(image, srcRect, destRect, paint);
    } else if (textureConfig.fillMode == 'stretch') {
      // 拉伸模式 - 图像被拉伸以适应目标大小
      final srcRect =
          Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble());
      final destRect = rect;
      canvas.drawImageRect(image, srcRect, destRect, paint);
    }
  }

  /// 绘制默认纹理占位符
  void _drawFallbackTexture(Canvas canvas, Rect rect) {
    // 绘制简单的灰色占位符
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
  }

  /// 绘制普通背景
  void _drawFallbackBackground(
      Canvas canvas, Rect rect, CharacterPosition position) {
    if (position.backgroundColor != Colors.transparent) {
      final bgPaint = Paint()
        ..color = position.backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, bgPaint);
    } else {
      // 绘制默认占位符背景
      final paint = Paint()
        ..color = Colors.grey.withAlpha(26) // 约等于 0.1 不透明度
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
    }
  }

  /// 绘制普通文本
  void _drawFallbackText(Canvas canvas, CharacterPosition position, Rect rect) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: position.char,
        style: TextStyle(
          fontSize: position.size * 0.7,
          color: position.fontColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final textOffset = Offset(
      position.x + (position.size - textPainter.width) / 2,
      position.y + (position.size - textPainter.height) / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  /// 绘制字符图像
  void _drawCharacterImage(
      Canvas canvas, Rect rect, CharacterPosition position, ui.Image image) {
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    // 获取图像源矩形
    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    // 检查是否需要应用颜色处理
    final bool needsColorProcessing = position.fontColor != Colors.black;

    // 如果不需要任何颜色处理，直接绘制原始图像
    if (!needsColorProcessing) {
      canvas.drawImageRect(image, srcRect, rect, paint);
      return;
    }

    // 需要进行颜色处理
    canvas.saveLayer(rect, Paint());

    // 创建基础绘制配置
    final basePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(image, srcRect, rect, basePaint);
    canvas.drawRect(
        rect,
        Paint()
          ..color = position.fontColor
          ..blendMode = BlendMode.srcIn);

    // 完成绘制
    canvas.restore();
  }

  /// 查找字符图片
  ui.Image? _findCharacterImage(String char, int index) {
    try {
      // 如果characterImages是Map类型
      if (characterImages is Map) {
        final key = char;
        if ((characterImages as Map).containsKey(key)) {
          final imageData = characterImages[key];
          // 根据imageData的类型处理
          if (imageData is ui.Image) {
            return imageData;
          } else if (imageData is String) {
            // 如果是路径，检查缓存
            _cacheKey = imageData;
            return GlobalImageCache.get(_cacheKey!);
          }
        }
      }
      // 如果是列表，使用索引查找
      else if (characterImages is List &&
          index < (characterImages as List).length) {
        final imageData = characterImages[index];
        if (imageData is ui.Image) {
          return imageData;
        } else if (imageData is String) {
          _cacheKey = imageData;
          return GlobalImageCache.get(_cacheKey!);
        }
      }
      return null;
    } catch (e) {
      debugPrint('获取字符图像失败: $e');
      return null;
    }
  }

  /// 加载并缓存纹理
  Future<ui.Image?> _loadAndCacheTexture(String path) async {
    // 检查是否已经缓存
    if (GlobalImageCache.contains(path)) {
      return GlobalImageCache.get(path);
    }

    try {
      if (path.startsWith('assets/') || path.startsWith('asset/')) {
        // 从资源加载
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        GlobalImageCache.put(path, frame.image);
        return frame.image;
      } else if (path.startsWith('http://') || path.startsWith('https://')) {
        // 从网络加载
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(path));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        GlobalImageCache.put(path, frame.image);
        return frame.image;
      } else if (path.startsWith('file://')) {
        // 从文件加载
        final file = File(path.substring(7));
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        GlobalImageCache.put(path, frame.image);
        return frame.image;
      }
    } catch (e) {
      debugPrint('加载纹理失败: $e, 路径: $path');
    }

    return null;
  }
}

/// 用于HTTP响应处理的工具函数
Future<Uint8List> consolidateHttpClientResponseBytes(
  HttpClientResponse response,
) {
  final completer = Completer<Uint8List>();
  BytesBuilder builder = BytesBuilder(copy: true);
  response.listen(
    builder.add,
    onError: completer.completeError,
    onDone: () {
      completer.complete(builder.takeBytes());
    },
    cancelOnError: true,
  );

  return completer.future;
}
