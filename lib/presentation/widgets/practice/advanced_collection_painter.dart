import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../infrastructure/providers/storage_providers.dart';
import 'character_position.dart';
import 'global_image_cache.dart';
import 'texture_config.dart';
import 'texture_manager.dart';

/// 高级集字绘制器 - 结合原有功能和新特性的绘制器实现
class AdvancedCollectionPainter extends CustomPainter {
  // 基本属性
  final List<String> characters;
  final List<CharacterPosition> positions;
  final double fontSize;
  final dynamic characterImages;
  final TextureConfig textureConfig;
  final WidgetRef? ref;

  // 布局属性
  final String writingMode;
  final String textAlign;
  final String verticalAlign;
  final bool enableSoftLineBreak;
  final double padding;
  final double letterSpacing;
  final double lineSpacing;

  // 内部状态变量
  final Set<String> _loadingTextures = {};
  final Set<String> _loadingImages = {};
  bool _needsRepaint = false;
  VoidCallback? _repaintCallback;

  /// 构造函数
  AdvancedCollectionPainter({
    required this.characters,
    required this.positions,
    required this.fontSize,
    required this.characterImages,
    required this.textureConfig,
    this.ref,
    this.writingMode = 'horizontal-l',
    this.textAlign = 'left',
    this.verticalAlign = 'top',
    this.enableSoftLineBreak = false,
    this.padding = 0.0,
    this.letterSpacing = 0.0,
    this.lineSpacing = 0.0,
  }) {
    // 输出布局调试信息
    debugPrint(
        'ℹ️ 高级集字绘制器初始化\n  字体大小: $fontSize\n  内边距: $padding\n  书写模式: $writingMode\n  水平对齐: $textAlign\n  垂直对齐: $verticalAlign\n  字间距: $letterSpacing\n  行间距: $lineSpacing');

    // 在初始化时预加载所有字符图片
    if (ref != null) {
      // 使用Future.microtask确保在下一个微任务中执行，避免在构造函数中执行异步操作
      Future.microtask(() {
        // 创建一个集合来存储需要加载的字符ID和类型
        final Set<String> charsToLoad = {};

        // 遍历所有字符位置
        for (int i = 0; i < positions.length; i++) {
          final position = positions[i];
          final char = position.char;

          // 查找字符对应的图片信息
          final charImage = _findCharacterImage(char, i);

          // 如果找到了图片信息，则准备加载图片
          if (charImage != null) {
            final characterId = charImage['characterId'].toString();
            final type = charImage['type'] as String;
            final format = charImage['format'] as String;

            // 创建缓存键
            final cacheKey = '$characterId-$type-$format';

            // 添加到待加载集合中
            charsToLoad.add(cacheKey);
          }
        }

        // 开始加载所有需要的字符图片
        for (final cacheKey in charsToLoad) {
          final parts = cacheKey.split('-');
          if (parts.length >= 3) {
            final characterId = parts[0];
            final type = parts[1];
            final format = parts.sublist(2).join('-');

            // 如果缓存中没有图像且不在加载中，则启动异步加载
            if (!GlobalImageCache.contains(cacheKey) &&
                !_loadingImages.contains(cacheKey)) {
              _loadAndCacheImage(characterId, type, format);
            }
          }
        }
      });
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // 添加裁剪区域，限制在画布范围内
      final clipRect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.clipRect(clipRect);

      // 输出调试信息
      debugPrint('ℹ️ 开始绘制集字元素：${positions.length} 个字符');
      debugPrint('  画布尺寸：${size.width}x${size.height}');
      debugPrint('  字体大小：$fontSize');
      debugPrint('  书写模式：$writingMode');
      debugPrint('  内边距：$padding');

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

        // 创建字符固有区域 - 这个位置是考虑了内边距、对齐方式和书写模式的
        // 因为LayoutCalculator已经在计算position时考虑了这些因素
        final charRect = Rect.fromLTWH(
          position.x,
          position.y,
          position.size,
          position.size,
        );

        // 3. 绘制字符背景
        // 根据纹理配置，决定绘制普通背景还是纹理背景
        if (textureConfig.enabled &&
            textureConfig.data != null &&
            (textureConfig.textureApplicationRange == 'characterBackground' ||
                textureConfig.textureApplicationRange == 'character')) {
          _paintTexture(canvas, charRect, mode: 'characterBackground');
        } else if (position.backgroundColor != Colors.transparent) {
          // 绘制字符背景
          final bgPaint = Paint()
            ..color = position.backgroundColor
            ..style = PaintingStyle.fill;
          canvas.drawRect(charRect, bgPaint);
        }

        // 4. 查找字符图片并绘制
        final charImage = _findCharacterImage(position.char, i);
        if (charImage != null) {
          // 如果有图片信息，尝试绘制图片
          _drawCharacterWithImage(canvas, charRect, position, charImage);
        } else {
          // 如果没有图片，绘制文本作为占位符
          _drawFallbackText(canvas, position, charRect);
        }

        // 在调试模式下绘制边框
        if (fontSize > 30 && i < 10) {
          // 只绘制前10个字符的边框，防止过多
          final debugPaint = Paint()
            ..color = position.isAfterNewLine
                ? Colors.red.withOpacity(0.3)
                : Colors.blue.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas.drawRect(charRect, debugPaint);

          // 绘制坐标信息
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${i + 1}',
              style: const TextStyle(fontSize: 10, color: Colors.red),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(charRect.left, charRect.top));
        }
      }

      // 如果需要重绘，触发回调
      if (_needsRepaint && _repaintCallback != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _repaintCallback!();
        });
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
  bool shouldRepaint(covariant AdvancedCollectionPainter oldDelegate) {
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

  /// 绘制带图片的字符
  void _drawCharacterWithImage(Canvas canvas, Rect rect,
      CharacterPosition position, Map<String, dynamic> charImage) {
    // 不需要再次绘制背景，因为背景已经在paint方法中绘制过了

    // 检查是否有字符ID等必要信息
    if (charImage['characterId'] == null ||
        charImage['type'] == null ||
        charImage['format'] == null) {
      _drawFallbackText(canvas, position, rect);
      return;
    }

    // 获取字符图像数据
    final characterId = charImage['characterId'].toString();
    final type = charImage['type'] as String;
    final format = charImage['format'] as String;

    // 获取是否需要反转显示
    bool invertDisplay = false;
    if (charImage.containsKey('transform') &&
        charImage['transform'] is Map<String, dynamic>) {
      final transform = charImage['transform'] as Map<String, dynamic>;
      invertDisplay = transform['invert'] == true;
    } else if (charImage.containsKey('invert')) {
      invertDisplay = charImage['invert'] == true;
    }

    // 创建缓存键
    final cacheKey = '$characterId-$type-$format';

    // 创建标准化的缓存键（用于兼容原来的逻辑）
    final normalizedKey = '$characterId-square-binary-png-binary';

    // 检查缓存状态
    ui.Image? image;
    if (GlobalImageCache.contains(cacheKey)) {
      image = GlobalImageCache.get(cacheKey);
    } else if (GlobalImageCache.contains(normalizedKey)) {
      image = GlobalImageCache.get(normalizedKey);
    }

    // 如果找到了图像，绘制图像
    if (image != null) {
      _drawImageWithEffects(
          canvas, rect, image, position.fontColor, invertDisplay);
    } else {
      // 如果没有找到图像且不在加载中，开始加载
      if (!_loadingImages.contains(cacheKey)) {
        _loadingImages.add(cacheKey);
        Future.microtask(() async {
          await _loadAndCacheImage(characterId, type, format);
          _needsRepaint = true;
        });
      }

      // 绘制文本作为占位符
      _drawFallbackText(canvas, position, rect);
    }
  }

  /// 绘制普通文本 - 支持多种文本对齐方式
  void _drawFallbackText(Canvas canvas, CharacterPosition position, Rect rect) {
    // 首先绘制背景（如果字符本身没有背景色）
    if (position.backgroundColor == Colors.transparent) {
      final bgPaint = Paint()
        ..color = Colors.grey.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, bgPaint);
    }

    // 设置文本样式 - 使用与原始代码一致的大小比例
    final textStyle = TextStyle(
      fontSize: position.size * 0.7, // 保持与原始代码一致的字体大小比例
      color: position.fontColor,
      fontWeight: FontWeight.normal,
    );

    // 绘制字符
    final textPainter = TextPainter(
      text: TextSpan(
        text: position.char,
        style: textStyle,
      ),
      textDirection:
          writingMode == 'horizontal-r' ? TextDirection.rtl : TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();

    // 计算居中位置 - 确保字符在其区域内居中
    final offset = Offset(
      rect.left + (rect.width - textPainter.width) / 2,
      rect.top + (rect.height - textPainter.height) / 2,
    );

    // 绘制文本
    textPainter.paint(canvas, offset);
  }

  /// 绘制占位符纹理
  void _drawFallbackTexture(Canvas canvas, Rect rect) {
    // 绘制简单的占位符纹理
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    // 仅在调试模式下绘制边框
    if (fontSize > 30) {
      // 当字符足够大时显示边框
      final debugPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(rect, debugPaint);
    }

    // 绘制斜线图案
    final diagonalPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    const spacing = 8.0;
    double y = rect.top;
    while (y < rect.bottom) {
      canvas.drawLine(Offset(rect.left, y),
          Offset(rect.left + (y - rect.top), rect.top), diagonalPaint);
      y += spacing;
    }

    double x = rect.left + spacing;
    while (x < rect.right) {
      canvas.drawLine(Offset(x, rect.top),
          Offset(rect.right, rect.top + (rect.right - x)), diagonalPaint);
      x += spacing;
    }
  }

  /// 使用特效绘制图像
  void _drawImageWithEffects(Canvas canvas, Rect rect, ui.Image image,
      Color fontColor, bool invertDisplay) {
    // 获取图像源矩形
    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    // 检查是否需要应用颜色处理
    final bool needsColorProcessing =
        fontColor != Colors.black || invertDisplay;

    // 如果不需要任何颜色处理，直接绘制原始图像
    if (!needsColorProcessing) {
      final paint = Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true;
      canvas.drawImageRect(image, srcRect, rect, paint);
      return;
    }

    // 需要进行颜色处理
    canvas.saveLayer(rect, Paint());

    if (invertDisplay) {
      // 反转显示 - 使用字体颜色填充区域，然后使用图像作为遮罩
      canvas.drawRect(rect, Paint()..color = fontColor);

      // 使用BlendMode.dstOut混合模式实现反转
      final maskPaint = Paint()..blendMode = BlendMode.dstOut;
      canvas.drawImageRect(image, srcRect, rect, maskPaint);
    } else {
      // 标准处理：将黑色替换为字体颜色
      // 首先绘制原始图像
      canvas.drawImageRect(image, srcRect, rect, Paint());

      // 使用BlendMode.srcIn将黑色部分替换为字体颜色
      final colorPaint = Paint()
        ..color = fontColor
        ..blendMode = BlendMode.srcIn;

      canvas.drawRect(rect, colorPaint);
    }

    // 恢复画布状态
    canvas.restore();
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
    } else {
      // 默认拉伸模式
      final srcRect =
          Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble());
      canvas.drawImageRect(image, srcRect, rect, paint);
    }
  }

  /// 查找字符对应的图片
  Map<String, dynamic>? _findCharacterImage(String char, int index) {
    try {
      // 检查 characterImages 是否是 Map 类型
      if (characterImages is Map<String, dynamic>) {
        final charImages = characterImages as Map<String, dynamic>;

        // 直接在 charImages 中查找字符索引
        if (charImages.containsKey('$index')) {
          final imageInfo = charImages['$index'] as Map<String, dynamic>;

          // 创建结果对象
          final result = {
            'characterId': imageInfo['characterId'],
            'type': imageInfo['drawingType'] ??
                imageInfo['type'] ??
                'square-binary',
            'format': imageInfo['drawingFormat'] ??
                imageInfo['format'] ??
                'png-binary',
          };

          // 添加transform属性（如果有）
          if (imageInfo.containsKey('transform')) {
            result['transform'] = imageInfo['transform'];
          } else if (imageInfo.containsKey('invert') &&
              imageInfo['invert'] == true) {
            result['invert'] = true;
          }

          return result;
        }

        // 检查嵌套结构
        if (charImages.containsKey('content')) {
          final content = charImages['content'] as Map<String, dynamic>?;
          if (content != null && content.containsKey('characterImages')) {
            final images = content['characterImages'] as Map<String, dynamic>?;

            if (images != null && images.containsKey('$index')) {
              final imageInfo = images['$index'] as Map<String, dynamic>;

              // 创建结果对象
              final result = {
                'characterId': imageInfo['characterId'],
                'type': imageInfo['drawingType'] ??
                    imageInfo['type'] ??
                    'square-binary',
                'format': imageInfo['drawingFormat'] ??
                    imageInfo['format'] ??
                    'png-binary',
              };

              // 添加transform属性（如果有）
              if (imageInfo.containsKey('transform')) {
                result['transform'] = imageInfo['transform'];
              } else if (imageInfo.containsKey('invert') &&
                  imageInfo['invert'] == true) {
                result['invert'] = true;
              }

              return result;
            }
          }
        }
      } else if (characterImages is List) {
        // 如果是 List 类型，则遍历查找
        final charImagesList = characterImages as List;

        for (int i = 0; i < charImagesList.length; i++) {
          final image = charImagesList[i];

          if (image is Map<String, dynamic>) {
            // 检查是否有字符信息
            if (image.containsKey('character') && image['character'] == char) {
              // 检查是否有字符图像信息
              if (image.containsKey('characterId')) {
                // 创建结果对象
                final result = {
                  'characterId': image['characterId'],
                  'type':
                      image['drawingType'] ?? image['type'] ?? 'square-binary',
                  'format':
                      image['drawingFormat'] ?? image['format'] ?? 'png-binary',
                };

                // 添加transform属性（如果有）
                if (image.containsKey('transform')) {
                  result['transform'] = image['transform'];
                } else if (image.containsKey('invert') &&
                    image['invert'] == true) {
                  result['invert'] = true;
                }

                return result;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('查找字符图像失败: $e');
    }

    return null;
  }

  /// 加载并缓存图像
  Future<void> _loadAndCacheImage(
      String characterId, String type, String format) async {
    final cacheKey = '$characterId-$type-$format';

    try {
      // 跳过已加载的图像
      if (GlobalImageCache.contains(cacheKey)) {
        return;
      }

      // 需要Riverpod引用才能加载
      if (ref == null) {
        _loadingImages.remove(cacheKey);
        return;
      }

      // 使用字符图像服务加载
      final characterImageService = ref!.read(characterImageServiceProvider);
      final storage = ref!.read(initializedStorageProvider);

      // 获取图片路径
      String getImagePath(String id, String imgType, String imgFormat) {
        // 根据类型和格式构建文件名
        String fileName;
        switch (imgType) {
          case 'square-binary':
            fileName = '$id-square-binary.png';
            break;
          case 'square-transparent':
            fileName = '$id-square-transparent.png';
            break;
          case 'square-outline':
            fileName = '$id-square-outline.svg';
            break;
          case 'thumbnail':
            fileName = '$id-thumbnail.jpg';
            break;
          default:
            fileName = '$id-$imgType.$imgFormat';
        }

        // 构建完整路径
        return '${storage.getAppDataPath()}/characters/$id/$fileName';
      }

      // 优先尝试使用方形二值化透明背景图
      String preferredType = 'square-binary';
      String preferredFormat = 'png-binary';

      // 检查可用格式
      final availableFormat =
          await characterImageService.getAvailableFormat(characterId);
      if (availableFormat != null) {
        preferredType = availableFormat['type']!;
        preferredFormat = availableFormat['format']!;
      }

      // 获取图片路径
      final imagePath =
          getImagePath(characterId, preferredType, preferredFormat);

      // 检查文件是否存在
      final file = File(imagePath);
      Uint8List? imageData;

      if (await file.exists()) {
        // 如果文件存在，直接从文件读取
        try {
          imageData = await file.readAsBytes();
        } catch (e) {
          debugPrint('读取文件失败: $e');
        }
      }

      // 如果从文件读取失败，尝试从服务获取
      if (imageData == null) {
        imageData = await characterImageService.getCharacterImage(
            characterId, preferredType, preferredFormat);

        // 如果获取成功，保存到文件
        if (imageData != null) {
          try {
            // 确保目录存在
            final directory = Directory(file.parent.path);
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }

            // 保存文件
            await file.writeAsBytes(imageData);
          } catch (e) {
            debugPrint('保存文件失败: $e');
          }
        }
      }

      // 更新缓存键以使用实际加载的类型和格式
      final actualCacheKey = '$characterId-$preferredType-$preferredFormat';

      if (imageData != null) {
        // 解码图像
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(imageData, (ui.Image image) {
          completer.complete(image);
        });

        final image = await completer.future;

        // 同时缓存到全局缓存
        GlobalImageCache.put(actualCacheKey, image);

        // 同时缓存到原始请求的键，以便能找到图像
        if (cacheKey != actualCacheKey) {
          GlobalImageCache.put(cacheKey, image);
        }

        // 标记需要重绘
        _needsRepaint = true;
      }
    } catch (e) {
      debugPrint('加载图像失败: $e');
    } finally {
      // 移除加载标记
      _loadingImages.remove(cacheKey);
    }
  }

  /// 绘制纹理背景
  void _paintTexture(Canvas canvas, Rect rect, {required String mode}) {
    if (!textureConfig.enabled || textureConfig.data == null) return;

    final data = textureConfig.data!;
    final texturePath = data['path'] as String?;
    if (texturePath == null || texturePath.isEmpty) return;

    // 处理纹理模式，只有在当前模式匹配时才绘制
    if (mode != textureConfig.textureApplicationRange) return;

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

          // 使用增强版纹理管理器加载纹理
          EnhancedTextureManager.instance.loadTexture(texturePath, ref,
              onLoaded: () {
            _loadingTextures.remove(texturePath);
            if (_repaintCallback != null) {
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
}
