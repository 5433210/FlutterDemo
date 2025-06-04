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
import '../../../infrastructure/providers/storage_providers.dart';
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
      // 1. 首先绘制整体背景纹理（如果启用）
      if (textureConfig.enabled && textureConfig.data != null) {
        final rect = Offset.zero & size;
        _paintTexture(canvas, rect);
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

        // 3. 绘制字符背景（普通背景色，纹理在整体背景中处理）
        _drawFallbackBackground(canvas, rect, position); // 4. 获取字符图片并绘制
        final charImage =
            _findCharacterImage(position.char, position.originalIndex);
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
    // 现在只有背景纹理模式，字符区域总是绘制普通背景色
    if (position.backgroundColor != Colors.transparent) {
      debugPrint('🎨 CollectionPainter: 绘制字符背景色 ${position.backgroundColor}');
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
      ..color = Colors.grey.withValues(alpha: 26)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
  }

  /// 根据填充模式和适应模式绘制图像
  void _drawImageWithFitMode(
      Canvas canvas, Rect rect, ui.Image image, Paint paint, String fillMode) {
    final imageRatio = image.width / image.height;
    final targetRatio = rect.width / rect.height;

    double scaledWidth, scaledHeight;

    if (fillMode == 'cover') {
      // Cover mode: scale to fill entire area (may crop)
      if (imageRatio > targetRatio) {
        scaledHeight = rect.height;
        scaledWidth = scaledHeight * imageRatio;
      } else {
        scaledWidth = rect.width;
        scaledHeight = scaledWidth / imageRatio;
      }
    } else if (fillMode == 'contain') {
      // Contain mode: scale to fit entirely (may have empty space)
      if (imageRatio > targetRatio) {
        scaledWidth = rect.width;
        scaledHeight = scaledWidth / imageRatio;
      } else {
        scaledHeight = rect.height;
        scaledWidth = scaledHeight * imageRatio;
      }
    } else if (fillMode == 'stretch') {
      // Stretch mode: stretch to exact size
      scaledWidth = rect.width;
      scaledHeight = rect.height;
    } else {
      // Default to contain
      if (imageRatio > targetRatio) {
        scaledWidth = rect.width;
        scaledHeight = scaledWidth / imageRatio;
      } else {
        scaledHeight = rect.height;
        scaledWidth = scaledHeight * imageRatio;
      }
    }

    // Apply fitMode for positioning and additional scaling
    double finalWidth = scaledWidth;
    double finalHeight = scaledHeight;

    if (textureConfig.fitMode == 'scaleToFit') {
      // Scale to fit within bounds while maintaining aspect ratio
      final scale = (rect.width / scaledWidth).clamp(0.0, 1.0);
      finalWidth = scaledWidth * scale;
      finalHeight = scaledHeight * scale;
    } else if (textureConfig.fitMode == 'scaleToCover') {
      // Scale to cover entire area while maintaining aspect ratio
      final scale = (rect.width / scaledWidth).clamp(1.0, double.infinity);
      finalWidth = scaledWidth * scale;
      finalHeight = scaledHeight * scale;
    }
    // scaleToFill uses the calculated size as-is

    final srcRect =
        Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble());
    final destRect = Rect.fromCenter(
      center: rect.center,
      width: finalWidth,
      height: finalHeight,
    );

    canvas.drawImageRect(image, srcRect, destRect, paint);
  }

  /// 使用图像绘制纹理
  void _drawTextureWithImage(Canvas canvas, Rect rect, ui.Image image) {
    // 只使用背景纹理模式，使用 srcOver 混合模式
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Colors.white.withValues(
          alpha: (textureConfig.opacity.clamp(0.0, 1.0) * 255).toDouble())
      ..blendMode = BlendMode
          .srcOver; // 根据新的填充模式绘制纹理 (只支持 repeat, cover, stretch, contain)
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
      _drawImageWithFitMode(canvas, rect, image, paint, 'cover');
    } else if (textureConfig.fillMode == 'contain') {
      // 包含模式 - 调整图像大小以完全显示，可能会有空白
      _drawImageWithFitMode(canvas, rect, image, paint, 'contain');
    } else if (textureConfig.fillMode == 'stretch') {
      // 拉伸模式 - 图像被拉伸以适应目标大小
      _drawImageWithFitMode(canvas, rect, image, paint, 'stretch');
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

  /// 加载并缓存纹理（增强版，使用完整缓存键）
  Future<ui.Image?> _loadAndCacheTextureWithKey(
      String path, String cacheKey) async {
    try {
      debugPrint('🔄 开始加载纹理: $path (缓存键: $cacheKey)');

      ui.Image? image;

      if (path.startsWith('assets/') || path.startsWith('asset/')) {
        // 从资源加载
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        image = frame.image;
      } else if (path.startsWith('http://') || path.startsWith('https://')) {
        // 从网络加载
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(path));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        image = frame.image;
      } else {
        // 从存储系统加载（本地文件）
        final storageService = ref.read(initializedStorageProvider);
        final imageBytes = await storageService.readFile(path);

        if (imageBytes.isNotEmpty) {
          final codec =
              await ui.instantiateImageCodec(Uint8List.fromList(imageBytes));
          final frame = await codec.getNextFrame();
          image = frame.image;
        }
      }

      if (image != null) {
        // 使用增强缓存键缓存图像
        await _imageCacheService.cacheUiImage(cacheKey, image);
        debugPrint('✅ 纹理加载成功并缓存: $cacheKey (${image.width}x${image.height})');
        return image;
      }
    } catch (e) {
      debugPrint('❌ 加载纹理失败: $e, 路径: $path');
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
  void _paintTexture(Canvas canvas, Rect rect) {
    if (!textureConfig.enabled || textureConfig.data == null) return;

    final data = textureConfig.data!;
    final texturePath = data['path'] as String?;
    if (texturePath == null || texturePath.isEmpty) return;

    // 生成增强缓存键 - 包含所有纹理相关属性以确保缓存正确性
    final timestamp = data.containsKey('timestamp')
        ? data['timestamp'].toString()
        : DateTime.now().millisecondsSinceEpoch.toString();

    final cacheKey = 'texture_${texturePath}_'
        '${textureConfig.textureWidth.toInt()}_'
        '${textureConfig.textureHeight.toInt()}_'
        '${textureConfig.fillMode}_'
        '${textureConfig.fitMode}_'
        '${(textureConfig.opacity * 1000).toInt()}_' // 乘以1000避免浮点精度问题
        '${textureConfig.enabled}_'
        '$timestamp';

    debugPrint('🔑 生成纹理缓存键: $cacheKey');

    try {
      // 检查是否正在加载中
      if (_loadingTextures.contains(cacheKey)) {
        // 已经在加载中，仅绘制占位内容
        _drawFallbackTexture(canvas, rect);
        return;
      }

      // 尝试同步检查是否已缓存
      ui.Image? image;
      try {
        // 使用增强缓存键尝试获取缓存图像
        image = _imageCacheService.tryGetUiImageSync(cacheKey);
      } catch (e) {
        debugPrint('⚠️ 同步获取纹理缓存图像时出错: $e');
      }
      if (image != null) {
        // 有纹理图片，绘制纹理
        _drawTextureWithImage(canvas, rect, image);
        return;
      }

      // 如果没有缓存图像，尝试异步加载
      if (!_loadingTextures.contains(cacheKey)) {
        _loadingTextures.add(cacheKey);

        // 异步加载纹理图片
        scheduleMicrotask(() {
          _loadAndCacheTextureWithKey(texturePath, cacheKey)
              .then((loadedImage) {
            _loadingTextures.remove(cacheKey);
            if (loadedImage != null && _repaintCallback != null) {
              scheduleMicrotask(() {
                _repaintCallback!();
              });
            }
          });
        });
      }

      // 纹理加载中，显示占位符
      _drawFallbackTexture(canvas, rect);
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
          final cacheKey = 'char_$characterId';

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
