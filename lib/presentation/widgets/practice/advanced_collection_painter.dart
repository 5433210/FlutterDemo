import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../application/services/character_image_service.dart';
import '../../../infrastructure/cache/services/image_cache_service.dart';
import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../infrastructure/providers/cache_providers.dart'
    as cache_providers;
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

/// 增强版集字绘制器 - 提供更多高级功能和更好的性能
class AdvancedCollectionPainter extends CustomPainter {
  // 基本属性
  final List<String> characters;
  final List<CharacterPosition> positions;
  final double fontSize;
  final dynamic characterImages;
  final TextureConfig textureConfig;
  final WidgetRef ref;

  // 增强版布局参数
  final String writingMode;
  final String textAlign;
  final String verticalAlign;
  final bool enableSoftLineBreak;
  final double padding;
  final double letterSpacing;
  final double lineSpacing;

  // 内部状态变量
  final Set<String> _loadingTextures = {};
  bool _needsRepaint = false;
  VoidCallback? _repaintCallback;
  String? _cacheKey;

  // 服务
  late ImageCacheService _imageCacheService;
  late CharacterImageService _characterImageService;

  /// 构造函数
  AdvancedCollectionPainter({
    required this.characters,
    required this.positions,
    required this.fontSize,
    required this.characterImages,
    required this.textureConfig,
    required this.ref,
    // 增强版参数
    required this.writingMode,
    required this.textAlign,
    required this.verticalAlign,
    required this.enableSoftLineBreak,
    required this.padding,
    required this.letterSpacing,
    required this.lineSpacing,
  }) {
    _imageCacheService = ref.read(cache_providers.imageCacheServiceProvider);
    _characterImageService = ref.read(characterImageServiceProvider);
  }

  /// 主绘制方法
  @override
  void paint(Canvas canvas, Size size) {
    try {
      // 计算实际可用区域（考虑内边距）
      final availableRect = Rect.fromLTWH(padding, padding,
          size.width - padding * 2, size.height - padding * 2);

      // 保存当前画布状态并设置裁剪区域
      canvas.save();
      canvas.clipRect(availableRect);

      // 1. 首先绘制整体背景（如果需要）
      if (textureConfig.enabled && textureConfig.data != null) {
        final rect = Offset.zero & size;
        _paintTexture(canvas, rect);
      }

      // 2. 检查是否启用词匹配模式
      final bool wordMatchingMode = _isWordMatchingMode();
      final List<Map<String, dynamic>> segments = _getSegments();

      print('[WORD_MATCHING_DEBUG] === AdvancedCollectionPainter Debug ===');
      print('[WORD_MATCHING_DEBUG] wordMatchingMode: $wordMatchingMode');
      print('[WORD_MATCHING_DEBUG] segments: $segments');
      print('[WORD_MATCHING_DEBUG] positions.length: ${positions.length}');
      print('[WORD_MATCHING_DEBUG] characterImages: $characterImages');

      if (wordMatchingMode && segments.isNotEmpty) {
        // 词匹配模式：按分段渲染
        print('[WORD_MATCHING_DEBUG] Using segment rendering mode');
        _paintSegments(canvas, size, segments);
      } else {
        // 字符模式：逐个字符渲染
        print('[WORD_MATCHING_DEBUG] Using character rendering mode');
        _paintCharacters(canvas, size);
      }

      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      EditPageLogger.rendererError('集字画笔绘制异常', error: e);
    }
  }

  /// 检查是否启用词匹配模式
  bool _isWordMatchingMode() {
    try {
      if (characterImages is Map<String, dynamic>) {
        return characterImages['wordMatchingPriority'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 获取分段信息
  List<Map<String, dynamic>> _getSegments() {
    try {
      if (characterImages is Map<String, dynamic>) {
        final segments = characterImages['segments'] as List<dynamic>? ?? [];
        return segments.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 分段模式渲染
  void _paintSegments(
      Canvas canvas, Size size, List<Map<String, dynamic>> segments) {
    try {
      for (int segmentIndex = 0;
          segmentIndex < segments.length;
          segmentIndex++) {
        final segment = segments[segmentIndex];
        final text = segment['text'] as String;

        // 在词匹配模式下，positions数组的索引就是分段索引
        if (segmentIndex < positions.length) {
          final position = positions[segmentIndex];

          // 跳过换行符
          if (text == '\n') continue;

          // 创建绘制区域
          final rect = Rect.fromLTWH(
            position.x,
            position.y,
            position.size,
            position.size,
          );

          // 绘制分段背景
          _drawFallbackBackground(canvas, rect, position);

          // 查找分段对应的字符图像（使用分段的起始索引）
          final startIndex = segment['startIndex'] as int;
          final firstChar = text.isNotEmpty ? text[0] : '';
          final charImage = _findCharacterImage(firstChar, startIndex);

          if (charImage != null) {
            // 如果有图片，绘制到整个分段区域
            _drawSegmentImage(canvas, rect, position, charImage, text);
          } else {
            // 如果没有图片，绘制分段文本
            _drawSegmentText(canvas, rect, text, position);
          }
        }
      }
    } catch (e) {
      EditPageLogger.rendererError('分段渲染异常', error: e);
    }
  }

  /// 字符模式渲染（原有逻辑）
  void _paintCharacters(Canvas canvas, Size size) {
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
      // 由于删除了textureApplicationRange，现在只支持background模式
      // 所以字符区域只绘制普通背景，不再有characterBackground纹理模式
      _drawFallbackBackground(canvas, rect, position);

      // 4. 获取字符图片并绘制
      // 注意：我们使用position.originalIndex而不是position.index来查找图像，因为position.originalIndex是原始的字符索引
      final charImage =
          _findCharacterImage(position.char, position.originalIndex);

      EditPageLogger.rendererDebug('[PLACEHOLDER_RENDER] 字符渲染分支决策', data: {
        'char': position.char,
        'index': position.originalIndex,
        'hasCharImage': charImage != null,
        'willDrawText': charImage == null,
      });

      if (charImage != null) {
        // 如果有图片，绘制图片
        _drawCharacterImage(canvas, rect, position, charImage);
      } else {
        // 如果没有图片，绘制文本
        _drawFallbackText(canvas, position, rect);
      }
    }
  }

  /// 绘制分段图像
  void _drawSegmentImage(Canvas canvas, Rect rect, CharacterPosition position,
      ui.Image charImage, String segmentText) {
    try {
      // 计算图像绘制参数
      final paint = Paint();
      paint.isAntiAlias = true;

      // 计算保持宽高比的绘制区域
      final imageAspectRatio = charImage.width / charImage.height;
      final rectAspectRatio = rect.width / rect.height;

      Rect drawRect;
      if (imageAspectRatio > rectAspectRatio) {
        // 图像更宽，以宽度为准
        final drawHeight = rect.width / imageAspectRatio;
        final offsetY = (rect.height - drawHeight) / 2;
        drawRect = Rect.fromLTWH(
          rect.left,
          rect.top + offsetY,
          rect.width,
          drawHeight,
        );
      } else {
        // 图像更高，以高度为准
        final drawWidth = rect.height * imageAspectRatio;
        final offsetX = (rect.width - drawWidth) / 2;
        drawRect = Rect.fromLTWH(
          rect.left + offsetX,
          rect.top,
          drawWidth,
          rect.height,
        );
      }

      // 绘制图像，保持宽高比
      final srcRect = Rect.fromLTWH(
          0, 0, charImage.width.toDouble(), charImage.height.toDouble());
      canvas.drawImageRect(charImage, srcRect, drawRect, paint);

      EditPageLogger.rendererDebug('绘制分段图像', data: {
        'segmentText': segmentText,
        'originalRect': '${rect.left},${rect.top},${rect.width},${rect.height}',
        'drawRect':
            '${drawRect.left},${drawRect.top},${drawRect.width},${drawRect.height}',
        'imageSize': '${charImage.width}x${charImage.height}',
        'aspectRatio': 'image=$imageAspectRatio, rect=$rectAspectRatio',
      });
    } catch (e) {
      EditPageLogger.rendererError('绘制分段图像失败', error: e, data: {
        'segmentText': segmentText,
        'rect': rect.toString(),
      });
    }
  }

  /// 绘制分段文本
  void _drawSegmentText(Canvas canvas, Rect rect, String segmentText,
      CharacterPosition position) {
    try {
      final textSpan = TextSpan(
        text: segmentText,
        style: TextStyle(
          fontSize: fontSize * 0.8, // 稍微缩小字体以适应分段
          color: position.fontColor,
          fontWeight: FontWeight.normal,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout(maxWidth: rect.width);

      // 计算居中位置
      final offset = Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      );

      textPainter.paint(canvas, offset);

      EditPageLogger.rendererDebug('绘制分段文本', data: {
        'segmentText': segmentText,
        'rect': '${rect.left},${rect.top},${rect.width},${rect.height}',
      });
    } catch (e) {
      EditPageLogger.rendererError('绘制分段文本失败', error: e, data: {
        'segmentText': segmentText,
      });
    }
  }

  /// 设置重绘回调函数
  void setRepaintCallback(VoidCallback callback) {
    _repaintCallback = callback;
  }

  @override
  bool shouldRepaint(covariant AdvancedCollectionPainter oldDelegate) {
    // 优先检查纹理配置变化 - 这是最关键的
    bool textureChanged = false;

    // 检查纹理配置的每个属性
    if (oldDelegate.textureConfig.enabled != textureConfig.enabled ||
        oldDelegate.textureConfig.fillMode != textureConfig.fillMode ||
        oldDelegate.textureConfig.fitMode != textureConfig.fitMode ||
        oldDelegate.textureConfig.opacity != textureConfig.opacity ||
        oldDelegate.textureConfig.textureWidth != textureConfig.textureWidth ||
        oldDelegate.textureConfig.textureHeight !=
            textureConfig.textureHeight ||
        !_mapsEqual(oldDelegate.textureConfig.data, textureConfig.data)) {
      textureChanged = true;
    }

    if (textureChanged) {
      // 纹理配置变化时，清除相关缓存
      EditPageLogger.rendererDebug('纹理变化检测：清除缓存并强制重绘');
      _loadingTextures.clear();
      _cacheKey = null;
      return true;
    }

    // 如果有明确标记需要重绘，返回true
    if (_needsRepaint) {
      _needsRepaint = false; // 重置标志
      return true;
    }

    // 检查其他基本属性变化
    bool basicChanged = oldDelegate.characters != characters ||
        oldDelegate.positions != positions ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.characterImages != characterImages ||
        oldDelegate.writingMode != writingMode ||
        oldDelegate.textAlign != textAlign ||
        oldDelegate.verticalAlign != verticalAlign ||
        oldDelegate.enableSoftLineBreak != enableSoftLineBreak ||
        oldDelegate.padding != padding ||
        oldDelegate.letterSpacing != letterSpacing ||
        oldDelegate.lineSpacing != lineSpacing;

    return basicChanged;
  }

  /// 根据FitMode计算处理后的纹理尺寸
  Size _applyFitModeToTexture(ui.Image image, Size targetTextureSize) {
    final srcSize = Size(image.width.toDouble(), image.height.toDouble());

    switch (textureConfig.fitMode) {
      case 'scaleToFit':
        // 缩放适应：保持宽高比，完全包含在目标尺寸内
        final scaleX = targetTextureSize.width / srcSize.width;
        final scaleY = targetTextureSize.height / srcSize.height;
        final scale = math.min(scaleX, scaleY);
        return Size(srcSize.width * scale, srcSize.height * scale);

      case 'scaleToCover':
        // 缩放覆盖：保持宽高比，完全覆盖目标尺寸
        final scaleX = targetTextureSize.width / srcSize.width;
        final scaleY = targetTextureSize.height / srcSize.height;
        final scale = math.max(scaleX, scaleY);
        return Size(srcSize.width * scale, srcSize.height * scale);

      case 'fill':
      default:
        // 缩放填充：直接使用目标尺寸
        return targetTextureSize;
    }
  }

  /// 计算实际纹理尺寸
  Size _calculateActualTextureSize(ui.Image image) {
    // 使用配置的纹理尺寸，如果没有设置则使用图片实际像素值
    final double width = textureConfig.textureWidth > 0
        ? textureConfig.textureWidth
        : image.width.toDouble();
    final double height = textureConfig.textureHeight > 0
        ? textureConfig.textureHeight
        : image.height.toDouble();

    return Size(width, height);
  }

  /// 创建占位图像并缓存
  Future<bool> _createPlaceholderImage(String cacheKey) async {
    try {
      // 创建一个简单的占位图像
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(fontSize, fontSize);

      // 绘制一个带有边框的矩形
      final paint = Paint()
        ..color = Colors.grey.withAlpha(128)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

      // 完成绘制并创建图像
      final picture = recorder.endRecording();
      final image =
          await picture.toImage(size.width.toInt(), size.height.toInt());

      // 缓存图像
      await _imageCacheService.cacheUiImage(cacheKey, image);

      return true;
    } catch (e) {
      EditPageLogger.rendererError('创建占位图像失败', error: e);
      return false;
    }
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
    // 检查是否为占位符
    final placeholderInfo = _getPlaceholderInfo(position.originalIndex);
    final isPlaceholder = placeholderInfo != null;

    // 添加调试信息，特别是对占位符的背景处理
    EditPageLogger.rendererDebug(
        '[PLACEHOLDER_RENDER] _drawFallbackBackground 开始',
        data: {
          'backgroundColor': position.backgroundColor.toString(),
          'isTransparent': position.backgroundColor == Colors.transparent,
          'textureEnabled': textureConfig.enabled,
          'hasTextureData': textureConfig.data != null,
          'position': position.originalIndex,
          'char': position.char,
          'isPlaceholder': isPlaceholder,
        });

    // 对于占位符，强制使用透明背景，不绘制任何背景色
    if (isPlaceholder) {
      EditPageLogger.rendererDebug('[PLACEHOLDER_RENDER] 占位符跳过背景绘制', data: {
        'position': position.originalIndex,
        'char': position.char,
      });
      return;
    }

    // 当纹理启用时，不在字符区域绘制背景色
    // 这样可以让背景纹理透过来，避免被遮挡
    if (textureConfig.enabled && textureConfig.data != null) {
      EditPageLogger.rendererDebug('[PLACEHOLDER_RENDER] 跳过背景绘制（纹理启用）', data: {
        'position': position.originalIndex,
      });
      return;
    }

    // 只有在背景色不是透明时才绘制背景
    if (position.backgroundColor != Colors.transparent) {
      final bgPaint = Paint()
        ..color = position.backgroundColor
        ..style = PaintingStyle.fill;

      EditPageLogger.rendererDebug('[PLACEHOLDER_RENDER] 绘制背景矩形', data: {
        'backgroundColor': position.backgroundColor.toString(),
        'rect': {
          'left': rect.left,
          'top': rect.top,
          'width': rect.width,
          'height': rect.height
        },
        'position': position.originalIndex,
      });

      canvas.drawRect(rect, bgPaint);
    } else {
      EditPageLogger.rendererDebug('[PLACEHOLDER_RENDER] 跳过背景绘制（透明背景）', data: {
        'position': position.originalIndex,
      });
    }
    // 如果背景色是透明的，什么都不绘制，保持完全透明
  }

  /// 绘制普通文本
  void _drawFallbackText(Canvas canvas, CharacterPosition position, Rect rect) {
    // 获取字符的占位符信息
    final placeholderInfo = _getPlaceholderInfo(position.originalIndex);

    // 确定要显示的字符和样式
    String displayChar = position.char;
    Color textColor = position.fontColor;
    double opacity = 1.0;

    // 添加详细调试信息
    EditPageLogger.rendererDebug('[PLACEHOLDER_RENDER] _drawFallbackText 开始',
        data: {
          'char': position.char,
          'originalIndex': position.originalIndex,
          'placeholderInfo': placeholderInfo,
          'fontColor': position.fontColor.toString(),
        });

    if (placeholderInfo != null) {
      // 如果是占位符，使用原始字符和半透明样式
      final originalChar = placeholderInfo['originalCharacter'] as String?;
      if (originalChar != null && originalChar.isNotEmpty) {
        displayChar = originalChar;
      }

      // 获取占位符的透明度
      final placeholderOpacity = placeholderInfo['opacity'] as double?;
      if (placeholderOpacity != null) {
        opacity = placeholderOpacity;
      } else {
        opacity = 0.5; // 默认半透明
      }

      // 应用透明度到颜色
      textColor = textColor.withOpacity(opacity);

      EditPageLogger.rendererDebug('[PLACEHOLDER_RENDER] 绘制占位符文本', data: {
        'originalChar': originalChar,
        'displayChar': displayChar,
        'opacity': opacity,
        'position': position.originalIndex,
        'finalTextColor': textColor.toString(),
      });
    } else {
      // 非占位符的普通文本
      EditPageLogger.rendererDebug('[PLACEHOLDER_RENDER] 绘制普通文本', data: {
        'char': displayChar,
        'position': position.originalIndex,
        'textColor': textColor.toString(),
      });
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayChar,
        style: TextStyle(
          fontSize: position.size * 0.8,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // 居中绘制文本
    final double x = rect.left + (rect.width - textPainter.width) / 2;
    final double y = rect.top + (rect.height - textPainter.height) / 2;

    // 添加最终绘制信息
    EditPageLogger.rendererDebug('[PLACEHOLDER_RENDER] 最终绘制文本', data: {
      'displayChar': displayChar,
      'textColor': textColor.toString(),
      'fontSize': position.size * 0.8,
      'position': {'x': x, 'y': y},
      'rect': {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height
      },
      'isPlaceholder': placeholderInfo != null,
    });

    textPainter.paint(canvas, Offset(x, y));
  }

  /// 绘制纹理图像
  void _drawTextureImage(Canvas canvas, Rect rect, ui.Image image) {
    // 使用高性能的Matrix变换方案
    _drawTextureWithMatrixTransform(canvas, rect, image);
  }

  /// 使用Matrix变换的纹理处理（修复FillMode实现）
  void _drawTextureWithMatrixTransform(
      Canvas canvas, Rect rect, ui.Image image) {
    final actualTextureSize = _calculateActualTextureSize(image);

    // 根据填充模式决定渲染策略
    switch (textureConfig.fillMode) {
      case 'repeat':
        _renderRepeatModeWithTransform(canvas, rect, image, actualTextureSize);
        break;
      case 'cover':
        _renderCoverMode(canvas, rect, image, actualTextureSize);
        break;
      case 'stretch':
        _renderStretchMode(canvas, rect, image, actualTextureSize);
        break;
      case 'contain':
        _renderContainMode(canvas, rect, image, actualTextureSize);
        break;
      default:
        // 默认使用repeat模式
        _renderRepeatModeWithTransform(canvas, rect, image, actualTextureSize);
        break;
    }
  }

  /// 查找字符图像
  ui.Image? _findCharacterImage(String char, int index) {
    // 如果没有字符图像，直接返回null
    if (characterImages == null) {
      return null;
    }

    // 首先检查是否为占位符，如果是占位符直接返回null，让文本渲染处理
    final placeholderInfo = _getPlaceholderInfo(index);
    if (placeholderInfo != null) {
      EditPageLogger.rendererDebug('[PLACEHOLDER_RENDER] 占位符跳过图像查找', data: {
        'char': char,
        'index': index,
        'placeholderInfo': placeholderInfo,
      });
      return null;
    }

    try {
      // 如果是图像对象，直接返回
      if (characterImages is ui.Image) {
        return characterImages;
      }

      // 处理用户的JSON结构 - 字符图像是一个以索引为键的Map
      if (characterImages is Map) {
        // 尝试使用字符索引作为键 - 使用原始位置索引
        final String indexKey = index.toString();

        // 首先检查是否有嵌套的characterImages结构
        Map<dynamic, dynamic> targetMap = characterImages;
        if (characterImages.containsKey('characterImages')) {
          final subMap = characterImages['characterImages'];
          if (subMap is Map) {
            targetMap = subMap;
          }
        }

        // 检查是否有对应索引的图像数据
        if (targetMap.containsKey(indexKey)) {
          final imageData = targetMap[indexKey];

          // 如果是字符串，直接使用
          if (imageData is String) {
            final cacheKey = 'char_${imageData}_$fontSize';
            return _processImagePath(imageData, cacheKey);
          }
          // 如果是复杂对象，处理characterId
          else if (imageData is Map) {
            // 再次检查是否为占位符（数据结构中的占位符）
            final isPlaceholder = imageData['isPlaceholder'] as bool? ?? false;
            if (isPlaceholder) {
              EditPageLogger.rendererDebug('[PLACEHOLDER_RENDER] 数据中的占位符跳过图像查找',
                  data: {
                    'char': char,
                    'index': index,
                    'characterId': imageData['characterId'],
                  });
              return null;
            }

            if (imageData.containsKey('characterId')) {
              final characterId = imageData['characterId'];

              if (characterId != null) {
                // 使用characterId作为缓存键
                final cacheKey = 'char_$characterId';

                // 尝试从缓存获取
                ui.Image? cachedImage =
                    _imageCacheService.tryGetUiImageSync(cacheKey);
                if (cachedImage != null) {
                  return cachedImage;
                }

                // 使用CharacterImageService加载图像
                // 首先获取可用的格式
                _loadCharacterImageViaService(characterId, cacheKey)
                    .then((success) {
                  if (success) {
                    _needsRepaint = true;
                    if (_repaintCallback != null) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        _repaintCallback!();
                      });
                    }
                  } else {
                    // 再次检查是否为占位符，如果是占位符则跳过创建灰色方块
                    final placeholderCheck = _getPlaceholderInfo(index);
                    if (placeholderCheck != null) {
                      EditPageLogger.rendererDebug(
                          '[PLACEHOLDER_RENDER] 服务失败时跳过占位图像创建',
                          data: {
                            'char': char,
                            'index': index,
                            'characterId': characterId,
                          });
                      return;
                    }
                    // 如果不是占位符且无法使用服务加载，创建占位图像
                    _createPlaceholderImage(cacheKey)
                        .then((placeholderSuccess) {
                      if (placeholderSuccess) {
                        _needsRepaint = true;
                        if (_repaintCallback != null) {
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            _repaintCallback!();
                          });
                        }
                      }
                    });
                  }
                });
              }
            }
          }
        }
      }

      // 如果没有找到匹配的图像
      return null;
    } catch (e) {
      EditPageLogger.rendererError('获取字符图像时出错', error: e, data: {
        'char': char,
        'index': index,
      });
      return null;
    }
  }

  /// 查找最深层的纹理数据
  String? _findDeepestTextureData(Map<String, dynamic> data) {
    // 如果有path属性，直接返回
    if (data.containsKey('path') && data['path'] is String) {
      return data['path'] as String;
    }

    // 递归查找子节点
    for (final key in data.keys) {
      final value = data[key];
      if (value is Map<String, dynamic>) {
        final path = _findDeepestTextureData(value);
        if (path != null) {
          return path;
        }
      }
    }

    return null;
  }

  /// 加载字符图像
  Future<bool> _loadCharacterImage(String path, String cacheKey) async {
    try {
      // 如果路径是网络路径，从网络加载
      late Uint8List bytes;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(path));
        final response = await request.close();
        bytes = await consolidateHttpClientResponseBytes(response);
      } else if (path.startsWith('assets/')) {
        // 从资源加载
        final data = await rootBundle.load(path);
        bytes = data.buffer.asUint8List();
      } else {
        // 从文件加载
        final file = File(path);
        bytes = await file.readAsBytes();
      }

      // 解码图像
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 缓存UI图像
      await _imageCacheService.cacheUiImage(cacheKey, image);

      EditPageLogger.rendererDebug('字符图像加载成功', data: {
        'path': path,
        'cacheKey': cacheKey,
      });
      return true;
    } catch (e) {
      EditPageLogger.rendererError('字符图像加载失败', error: e, data: {
        'path': path,
        'cacheKey': cacheKey,
      });
      return false;
    }
  }

  /// 通过CharacterImageService加载字符图像
  Future<bool> _loadCharacterImageViaService(
      String characterId, String cacheKey) async {
    try {
      // 获取可用的图像格式
      final format =
          await _characterImageService.getAvailableFormat(characterId);
      if (format == null) {
        return false;
      }

      final type = format['type']!;
      final formatType = format['format']!;

      // 检查图像是否存在
      final hasImage = await _characterImageService.hasCharacterImage(
          characterId, type, formatType);

      if (!hasImage) {
        return false;
      }

      // 获取字符图像数据
      final imageData = await _characterImageService.getCharacterImage(
          characterId, type, formatType);

      if (imageData == null || imageData.isEmpty) {
        return false;
      }

      // 解码图像
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 缓存UI图像
      await _imageCacheService.cacheUiImage(cacheKey, image);

      EditPageLogger.rendererDebug('字符图像服务加载成功', data: {
        'characterId': characterId,
        'cacheKey': cacheKey,
        'imageSize': '${image.width}x${image.height}',
      });
      return true;
    } catch (e) {
      EditPageLogger.rendererError('通过服务加载字符图像失败', error: e, data: {
        'characterId': characterId,
      });
      return false;
    }
  }

  /// 加载纹理图像
  Future<ui.Image?> _loadTextureImage(String path) async {
    try {
      late Uint8List bytes;

      // 根据路径类型加载图像
      if (path.startsWith('http://') || path.startsWith('https://')) {
        // 从网络加载
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(path));
        final response = await request.close();
        bytes = await consolidateHttpClientResponseBytes(response);
      } else if (path.startsWith('assets/')) {
        // 从资源加载
        final data = await rootBundle.load(path);
        bytes = data.buffer.asUint8List();
      } else {
        // 从文件加载
        final file = File(path);
        bytes = await file.readAsBytes();
      }

      // 解码图像
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      EditPageLogger.rendererError('纹理加载错误', error: e, data: {'path': path});
      return null;
    }
  }

  /// 异步加载纹理图像
  void _loadTextureImageAsync(String texturePath, String cacheKey) {
    _loadTextureImage(texturePath).then((image) {
      if (image != null) {
        _imageCacheService.cacheUiImage(cacheKey, image);
        _needsRepaint = true;
        if (_repaintCallback != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _repaintCallback!();
          });
        }
      }
    });
  }

  /// 深度比较两个Map是否相等
  bool _mapsEqual(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key)) return false;
      // 递归比较嵌套的Map
      if (map1[key] is Map && map2[key] is Map) {
        if (!_mapsEqual(map1[key] as Map<String, dynamic>?,
            map2[key] as Map<String, dynamic>?)) {
          return false;
        }
      } else if (map1[key] != map2[key]) {
        return false;
      }
    }

    return true;
  }

  /// 绘制纹理
  void _paintTexture(Canvas canvas, Rect rect) {
    if (!textureConfig.enabled || textureConfig.data == null) return;

    // 获取纹理数据
    final textureData = textureConfig.data!;

    // 获取纹理路径
    final texturePath = _findDeepestTextureData(textureData);
    if (texturePath == null) return;

    // 生成缓存键 - 加入纹理尺寸信息以支持高性能缓存
    _cacheKey = texturePath;

    // 尝试从UI图像缓存获取纹理图像
    final cachedImage = _imageCacheService.tryGetUiImageSync(_cacheKey!);
    if (cachedImage != null) {
      _drawTextureImage(canvas, rect, cachedImage);
    } else {
      // 如果缓存中没有UI图像，异步加载
      _loadTextureImageAsync(texturePath, _cacheKey!);
      // 绘制占位符背景，表明纹理正在加载
      final placeholderPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.2) // 0.2 不透明度
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, placeholderPaint);
    }
  }

  /// 处理图像路径并返回缓存的图像
  ui.Image? _processImagePath(String imagePath, String cacheKey) {
    // 尝试从缓存获取
    ui.Image? cachedImage = _imageCacheService.tryGetUiImageSync(cacheKey);
    if (cachedImage != null) {
      return cachedImage;
    }

    // 异步加载图像
    _loadCharacterImage(imagePath, cacheKey).then((success) {
      if (success) {
        _needsRepaint = true;
        if (_repaintCallback != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _repaintCallback!();
          });
        }
      }
    });

    return null;
  }

  /// 渲染Contain模式：缩放纹理以完全包含在背景内（保持宽高比，可能有空白）
  void _renderContainMode(
      Canvas canvas, Rect rect, ui.Image image, Size textureSize) {
    canvas.save();
    canvas.clipRect(rect);

    // 第一步：根据FitMode处理原始图像到纹理尺寸
    final processedTextureSize = _applyFitModeToTexture(image, textureSize);

    // 第二步：计算如何缩放处理后的纹理以包含在背景内
    final backgroundSize = rect.size;
    final scaleX = backgroundSize.width / processedTextureSize.width;
    final scaleY = backgroundSize.height / processedTextureSize.height;
    final scale = math.min(scaleX, scaleY); // 使用较小的缩放比例确保完全包含

    final finalSize = Size(
      processedTextureSize.width * scale,
      processedTextureSize.height * scale,
    );

    // 居中定位
    final destRect = Rect.fromCenter(
      center: rect.center,
      width: finalSize.width,
      height: finalSize.height,
    );

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..color = Colors.white.withValues(
          alpha: (textureConfig.opacity.clamp(0.0, 1.0)).toDouble());

    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    canvas.drawImageRect(image, srcRect, destRect, paint);
    canvas.restore();
  }

  /// 渲染Cover模式：缩放纹理以覆盖整个背景（保持宽高比，可能裁剪）
  void _renderCoverMode(
      Canvas canvas, Rect rect, ui.Image image, Size textureSize) {
    canvas.save();

    // 裁剪到背景区域
    canvas.clipRect(rect);

    // 第一步：根据FitMode处理原始图像到纹理尺寸
    final processedTextureSize = _applyFitModeToTexture(image, textureSize);

    // 第二步：计算如何缩放处理后的纹理以覆盖整个背景
    final backgroundSize = rect.size;
    final textureRatio =
        processedTextureSize.width / processedTextureSize.height;
    final backgroundRatio = backgroundSize.width / backgroundSize.height;

    late Size finalSize;

    if (textureRatio > backgroundRatio) {
      // 纹理更宽，以高度为准缩放
      finalSize = Size(
        backgroundSize.height * textureRatio,
        backgroundSize.height,
      );
    } else {
      // 纹理更高，以宽度为准缩放
      finalSize = Size(
        backgroundSize.width,
        backgroundSize.width / textureRatio,
      );
    }

    // 居中定位
    final destRect = Rect.fromCenter(
      center: rect.center,
      width: finalSize.width,
      height: finalSize.height,
    );

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..color = Colors.white.withValues(
          alpha: (textureConfig.opacity.clamp(0.0, 1.0)).toDouble());

    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    canvas.drawImageRect(image, srcRect, destRect, paint);
    canvas.restore();
  }

  /// 渲染重复模式（带变换支持）
  void _renderRepeatModeWithTransform(
      Canvas canvas, Rect rect, ui.Image image, Size textureSize) {
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..color = Colors.white
          .withValues(alpha: (textureConfig.opacity.clamp(0.0, 1.0)));

    // 第一步：根据FitMode处理纹理尺寸
    final processedTextureSize = _applyFitModeToTexture(image, textureSize);

    // 第二步：创建ImageShader进行重复填充
    // 计算变换矩阵以正确应用纹理尺寸
    final srcSize = Size(image.width.toDouble(), image.height.toDouble());
    Matrix4 shaderTransform = Matrix4.identity();

    // 计算缩放比例：从原始图像尺寸到处理后的纹理尺寸
    final scaleX = processedTextureSize.width / srcSize.width;
    final scaleY = processedTextureSize.height / srcSize.height;

    // 应用缩放变换
    shaderTransform.scale(scaleX, scaleY);

    // 创建shader
    final shader = ImageShader(
      image,
      TileMode.repeated,
      TileMode.repeated,
      shaderTransform.storage,
    );

    paint.shader = shader;

    // 绘制到整个背景区域
    canvas.drawRect(rect, paint);
  }

  /// 渲染Stretch模式：拉伸纹理以完全填充背景（可能变形）
  void _renderStretchMode(
      Canvas canvas, Rect rect, ui.Image image, Size textureSize) {
    canvas.save();
    canvas.clipRect(rect);

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..color = Colors.white.withValues(
          alpha: (textureConfig.opacity.clamp(0.0, 1.0)).toDouble());

    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    // 直接拉伸到整个背景区域
    canvas.drawImageRect(image, srcRect, rect, paint);
    canvas.restore();
  }

  /// 获取占位符信息
  Map<String, dynamic>? _getPlaceholderInfo(int index) {
    try {
      EditPageLogger.rendererDebug(
          '[PLACEHOLDER_RENDER] _getPlaceholderInfo 开始',
          data: {
            'index': index,
            'characterImages': characterImages.runtimeType.toString(),
          });

      if (characterImages is Map<String, dynamic>) {
        final characterImagesMap =
            characterImages['characterImages'] as Map<String, dynamic>?;

        EditPageLogger.rendererDebug(
            '[PLACEHOLDER_RENDER] _getPlaceholderInfo 检查Map',
            data: {
              'hasCharacterImagesKey':
                  characterImages.containsKey('characterImages'),
              'characterImagesMap': characterImagesMap?.keys.toList(),
            });

        if (characterImagesMap != null) {
          final String indexKey = index.toString();
          final imageData = characterImagesMap[indexKey];

          EditPageLogger.rendererDebug(
              '[PLACEHOLDER_RENDER] _getPlaceholderInfo 查找索引',
              data: {
                'indexKey': indexKey,
                'hasImageData': imageData != null,
                'imageDataType': imageData?.runtimeType.toString(),
                'imageData': imageData,
              });

          if (imageData is Map<String, dynamic>) {
            final isPlaceholder = imageData['isPlaceholder'] as bool? ?? false;

            EditPageLogger.rendererDebug(
                '[PLACEHOLDER_RENDER] _getPlaceholderInfo 检查占位符',
                data: {
                  'isPlaceholder': isPlaceholder,
                  'imageDataKeys': imageData.keys.toList(),
                });

            if (isPlaceholder) {
              EditPageLogger.rendererDebug(
                  '[PLACEHOLDER_RENDER] _getPlaceholderInfo 返回占位符数据',
                  data: {
                    'placeholderData': imageData,
                  });
              return imageData;
            }
          }
        }
      }

      EditPageLogger.rendererDebug(
          '[PLACEHOLDER_RENDER] _getPlaceholderInfo 未找到占位符',
          data: {
            'index': index,
          });
      return null;
    } catch (e) {
      EditPageLogger.rendererError('[PLACEHOLDER_RENDER] 获取占位符信息失败',
          error: e,
          data: {
            'index': index,
          });
      return null;
    }
  }
}
