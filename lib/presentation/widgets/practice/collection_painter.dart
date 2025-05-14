import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../infrastructure/cache/services/image_cache_service.dart';
import '../../../infrastructure/providers/cache_providers.dart'
    as cache_providers;
import '../../../infrastructure/services/character_image_service.dart';
import 'character_position.dart';
import 'texture_config.dart';

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

/// 集字绘制器 - 实现CustomPainter，负责字符和纹理的绘制
class CollectionPainter extends CustomPainter {
  // 基本属性
  final List<String> characters;
  final List<CharacterPosition> positions;
  final double fontSize;
  final dynamic characterImages;
  final TextureConfig textureConfig;
  final WidgetRef ref;

  // 内部状态变量
  final Set<String> _loadingTextures = {};
  final bool _needsRepaint = false;
  VoidCallback? _repaintCallback;

  // 服务
  late ImageCacheService _imageCacheService;
  late CharacterImageService _characterImageService;

  /// 构造函数
  CollectionPainter({
    required this.characters,
    required this.positions,
    required this.fontSize,
    required this.characterImages,
    required this.textureConfig,
    required this.ref,
  }) {
    _imageCacheService = ref.read(cache_providers.imageCacheServiceProvider);
    _characterImageService = ref.read(characterImageServiceProvider);
  }

  /// 主绘制方法
  @override
  void paint(Canvas canvas, Size size) {
    try {
      // 1. 首先绘制整体背景（如果需要）
      if (textureConfig.enabled &&
          textureConfig.data != null &&
          textureConfig.textureApplicationRange == 'background') {
        final rect = Offset.zero & size;
        _paintTexture(canvas, rect, mode: 'background');
      }

      // 2. 遍历所有字符位置，绘制字符
      for (int i = 0; i < positions.length; i++) {
        final position = positions[i];

        // 如果是换行符，直接跳过，不做任何绘制
        if (position.char == '\n') continue;

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
            textureConfig.textureApplicationRange == 'characterBackground') {
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

    // 如果字符列表变化，需要重绘
    if (oldDelegate.characters.length != characters.length) {
      return true;
    }

    // 如果字体大小变化，需要重绘
    if (oldDelegate.fontSize != fontSize) {
      return true;
    }

    // 如果字符图片变化，需要重绘
    if (oldDelegate.characterImages != characterImages) {
      return true;
    }

    // 如果内部状态标记为需要重绘，则重绘
    return _needsRepaint;
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

  /// 绘制默认纹理占位符
  void _drawFallbackTexture(Canvas canvas, Rect rect) {
    // 绘制简单的灰色占位符
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
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

  /// 查找字符图片 - 同步方法
  ui.Image? _findCharacterImage(String char, int index) {
    try {
      // 如果字符图片为空，返回null
      if (characterImages == null) {
        debugPrint('没有字符图像数据');
        return null;
      }

      // 如果是图像对象，直接返回
      if (characterImages is ui.Image) {
        return characterImages;
      }

      debugPrint(
          '字符图像类型: ${characterImages.runtimeType}, 当前字符: $char, 索引: $index');

      // 如果是映射形式，先尝试根据索引获取
      if (characterImages is Map) {
        // 尝试查找索引键
        debugPrint('尝试查找索引键1: $index');

        // 检查是否有子键字典
        if (characterImages.containsKey('characterImages')) {
          final subMap = characterImages['characterImages'];
          if (subMap is Map && subMap.containsKey(index.toString())) {
            return _processCharacterImageData(
                subMap[index.toString()], char, index);
          }
        }

        // 直接检查索引键
        if (characterImages.containsKey(index.toString())) {
          return _processCharacterImageData(
              characterImages[index.toString()], char, index);
        }

        // 直接检查数字索引
        if (characterImages.containsKey(index)) {
          return _processCharacterImageData(
              characterImages[index], char, index);
        }

        // 检查字符键
        if (characterImages.containsKey(char)) {
          return _processCharacterImageData(characterImages[char], char, index);
        }

        // 输出子键信息便于调试
        debugPrint('找到characterImages子键: $characterImages');
      }

      // 如果是列表形式，根据索引获取
      if (characterImages is List && index < characterImages.length) {
        final imageData = characterImages[index];
        return _processCharacterImageData(imageData, char, index);
      }

      debugPrint('没有找到字符 "$char" (索引: $index) 的图像');
      return null;
    } catch (e) {
      debugPrint('获取字符图像失败: $e');
      return null;
    }
  }

  /// 加载并缓存纹理
  Future<ui.Image?> _loadAndCacheTexture(String path) async {
    // 检查是否已经缓存
    final cachedImage = await _imageCacheService.getUiImage(path);
    if (cachedImage != null) {
      return cachedImage;
    }

    try {
      if (path.startsWith('assets/') || path.startsWith('asset/')) {
        // 从资源加载
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        await _imageCacheService.cacheUiImage(path, frame.image);
        return frame.image;
      } else if (path.startsWith('http://') || path.startsWith('https://')) {
        // 从网络加载
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(path));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        await _imageCacheService.cacheUiImage(path, frame.image);
        return frame.image;
      } else if (path.startsWith('file://')) {
        // 从文件加载
        final file = File(path.substring(7));
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        await _imageCacheService.cacheUiImage(path, frame.image);
        return frame.image;
      }
    } catch (e) {
      debugPrint('加载纹理失败: $e, 路径: $path');
    }

    return null;
  }

  /// 加载字符图像
  Future<bool> _loadCharacterImage(String imageData, String cacheKey) async {
    try {
      // 防止重复加载
      if (_loadingTextures.contains(cacheKey)) {
        return false;
      }
      _loadingTextures.add(cacheKey);

      ui.Image? image;
      if (imageData.contains('/')) {
        // 如果是路径，使用ImageCacheService加载
        image = await _imageCacheService.getUiImage(imageData);
      } else {
        // 如果是字符ID，使用CharacterImageService加载
        final imageBytes = await _characterImageService.getCharacterImage(
            imageData, 'default', 'png');

        if (imageBytes != null) {
          // 将字节数据转换为UI图像
          final completer = Completer<ui.Image>();
          ui.decodeImageFromList(imageBytes, (ui.Image img) {
            completer.complete(img);
          });
          image = await completer.future;

          // 缓存图像
          await _imageCacheService.cacheUiImage(cacheKey, image);
        }
      }

      _loadingTextures.remove(cacheKey);

      // 触发重绘
      if (image != null && _repaintCallback != null) {
        scheduleMicrotask(() {
          _repaintCallback!();
        });
      }

      return image != null;
    } catch (e) {
      debugPrint('加载字符图像失败: $e');
      _loadingTextures.remove(cacheKey);
      return false;
    }
  }

  /// 绘制背景纹理
  void _paintTexture(Canvas canvas, Rect rect, {required String mode}) {
    if (!textureConfig.enabled || textureConfig.data == null) return;

    final data = textureConfig.data!;
    final texturePath = data['path'] as String?;
    if (texturePath == null || texturePath.isEmpty) return;

    // 处理纹理模式，只有在当前模式匹配时才绘制
    if (mode != textureConfig.textureApplicationRange) return;

    try {
      // 检查是否正在加载中
      if (_loadingTextures.contains(texturePath)) {
        // 已经在加载中，仅绘制占位内容
        _drawFallbackTexture(canvas, rect);
        return;
      }

      // 尝试同步检查是否已缓存
      ui.Image? image;
      try {
        // 尝试使用同步方式获取图像
        // 注意：这里假设有一个同步方法来检查缓存
        // 如果实际上没有，可能需要实现一个
        image = null; // 这里应该调用同步获取方法，如果有的话
      } catch (e) {
        debugPrint('⚠️ 同步获取纹理缓存图像时出错: $e');
      }

      if (image != null) {
        // 有纹理图片，绘制纹理
        _drawTextureWithImage(canvas, rect, image);
      } else {
        // 纹理加载中，显示占位符
        _drawFallbackTexture(canvas, rect);

        // 异步加载纹理图片
        if (!_loadingTextures.contains(texturePath)) {
          _loadingTextures.add(texturePath);

          // 使用 scheduleMicrotask 安排异步加载
          scheduleMicrotask(() {
            _loadAndCacheTexture(texturePath).then((loadedImage) {
              _loadingTextures.remove(texturePath);
              if (loadedImage != null && _repaintCallback != null) {
                scheduleMicrotask(() {
                  _repaintCallback!();
                });
              }
            });
          });
        }
      }
    } catch (e, stack) {
      debugPrint('❌ 纹理绘制错误: $e\n$stack');
    }
  }

  /// 处理字符图像数据
  ui.Image? _processCharacterImageData(
      dynamic imageData, String char, int index) {
    if (imageData == null) {
      return null;
    }

    // 如果是图像对象，直接返回
    if (imageData is ui.Image) {
      return imageData;
    }

    // 如果是字符串，尝试加载图像
    if (imageData is String) {
      final cacheKey = 'char_${imageData}_$fontSize';

      // 尝试从缓存获取图像
      ui.Image? cachedImage = _imageCacheService.tryGetUiImageSync(cacheKey);
      if (cachedImage != null) {
        return cachedImage;
      }

      // 异步加载
      _loadCharacterImage(imageData, cacheKey);
      return null;
    }

    // 如果是字典，尝试获取characterId
    if (imageData is Map) {
      if (imageData.containsKey('characterId')) {
        final characterId = imageData['characterId'];
        if (characterId is String) {
          final cacheKey = 'char_${characterId}_$fontSize';

          // 尝试从缓存获取图像
          ui.Image? cachedImage =
              _imageCacheService.tryGetUiImageSync(cacheKey);
          if (cachedImage != null) {
            debugPrint('从内存缓存中找到图像: $cacheKey');
            return cachedImage;
          }

          // 异步加载
          _loadCharacterImage(characterId, cacheKey);
        }
      }
    }

    return null;
  }
}
