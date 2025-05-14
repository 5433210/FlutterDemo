import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/cache/services/image_cache_service.dart';
import '../../../infrastructure/providers/cache_providers.dart' as cache_providers;
import 'character_position.dart';
import 'texture_config.dart';

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

  // 图像缓存服务
  late ImageCacheService _imageCacheService;

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
        oldDelegate.characterImages != characterImages ||
        oldDelegate.writingMode != writingMode ||
        oldDelegate.textAlign != textAlign ||
        oldDelegate.verticalAlign != verticalAlign ||
        oldDelegate.enableSoftLineBreak != enableSoftLineBreak ||
        oldDelegate.padding != padding ||
        oldDelegate.letterSpacing != letterSpacing ||
        oldDelegate.lineSpacing != lineSpacing;
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
          fontSize: position.size * 0.8,
          color: position.fontColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // 居中绘制文本
    final double x = rect.left + (rect.width - textPainter.width) / 2;
    final double y = rect.top + (rect.height - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(x, y));
  }

  /// 绘制纹理
  void _paintTexture(Canvas canvas, Rect rect, {required String mode}) {
    if (!textureConfig.enabled || textureConfig.data == null) return;

    // 获取纹理数据
    final textureData = textureConfig.data!;

    // 获取纹理路径
    final texturePath = _findDeepestTextureData(textureData);
    if (texturePath == null) return;

    // 生成缓存键
    _cacheKey = 'texture_${texturePath}_${rect.width.toInt()}_${rect.height.toInt()}';

    // 尝试从缓存获取纹理图像
    final cachedImage = _imageCacheService.tryGetUiImageSync(_cacheKey!);
    if (cachedImage != null) {
      _drawTextureImage(canvas, rect, cachedImage);
      return;
    }
    
    // 如果同步方法没有获取到，尝试异步获取
    _imageCacheService.getUiImage(_cacheKey!).then((image) {
      if (image != null) {
        _needsRepaint = true;
        if (_repaintCallback != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _repaintCallback!();
          });
        }
      }
    });

    // 如果纹理正在加载中，跳过
    if (_loadingTextures.contains(_cacheKey)) return;

    // 标记纹理为加载中
    _loadingTextures.add(_cacheKey!);

    // 加载纹理图像
    _loadTextureImage(texturePath).then((image) {
      if (image != null) {
        // 缓存纹理图像
        _imageCacheService.cacheUiImage(_cacheKey!, image);

        // 标记需要重绘
        _needsRepaint = true;
        _loadingTextures.remove(_cacheKey);

        // 触发重绘
        if (_repaintCallback != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _repaintCallback!();
          });
        }
      }
    }).catchError((e) {
      debugPrint('纹理加载错误: $e');
      _loadingTextures.remove(_cacheKey);
    });
  }

  /// 绘制纹理图像
  void _drawTextureImage(Canvas canvas, Rect rect, ui.Image image) {
    // 创建绘制配置
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..color = Colors.white.withOpacity(textureConfig.opacity);

    // 根据填充模式绘制纹理
    switch (textureConfig.fillMode) {
      case 'repeat':
        // 创建平铺图案
        final shader = ImageShader(
          image,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.identity().storage,
        );
        paint.shader = shader;
        canvas.drawRect(rect, paint);
        break;

      case 'cover':
        // 覆盖模式，保持纵横比并填满整个区域
        final srcSize = Size(image.width.toDouble(), image.height.toDouble());
        final srcRect = Rect.fromLTWH(0, 0, srcSize.width, srcSize.height);
        final destRect = _coverRect(srcSize, rect.size, rect);
        canvas.drawImageRect(image, srcRect, destRect, paint);
        break;

      case 'contain':
        // 包含模式，保持纵横比并完整显示
        final srcSize = Size(image.width.toDouble(), image.height.toDouble());
        final srcRect = Rect.fromLTWH(0, 0, srcSize.width, srcSize.height);
        final destRect = _containRect(srcSize, rect.size, rect);
        canvas.drawImageRect(image, srcRect, destRect, paint);
        break;

      case 'stretch':
      default:
        // 拉伸模式，填满整个区域
        final srcRect = Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble());
        canvas.drawImageRect(image, srcRect, rect, paint);
        break;
    }
  }

  /// 计算覆盖模式的矩形
  Rect _coverRect(Size srcSize, Size destSize, Rect destRect) {
    final srcRatio = srcSize.width / srcSize.height;
    final destRatio = destSize.width / destSize.height;

    double width, height;
    if (srcRatio > destRatio) {
      // 源图像更宽，以高度为基准
      height = destSize.height;
      width = height * srcRatio;
    } else {
      // 源图像更高，以宽度为基准
      width = destSize.width;
      height = width / srcRatio;
    }

    // 居中放置
    final left = destRect.left + (destSize.width - width) / 2;
    final top = destRect.top + (destSize.height - height) / 2;

    return Rect.fromLTWH(left, top, width, height);
  }

  /// 计算包含模式的矩形
  Rect _containRect(Size srcSize, Size destSize, Rect destRect) {
    final srcRatio = srcSize.width / srcSize.height;
    final destRatio = destSize.width / destSize.height;

    double width, height;
    if (srcRatio < destRatio) {
      // 源图像更高，以高度为基准
      height = destSize.height;
      width = height * srcRatio;
    } else {
      // 源图像更宽，以宽度为基准
      width = destSize.width;
      height = width / srcRatio;
    }

    // 居中放置
    final left = destRect.left + (destSize.width - width) / 2;
    final top = destRect.top + (destSize.height - height) / 2;

    return Rect.fromLTWH(left, top, width, height);
  }

  /// 查找字符图像
  ui.Image? _findCharacterImage(String char, int index) {
    // 如果没有字符图像，直接返回null
    if (characterImages == null) return null;

    String? cacheKey;

    // 根据characterImages的类型，获取缓存键
    if (characterImages is List && index < characterImages.length) {
      // 如果是列表，使用索引获取
      final item = characterImages[index];
      if (item != null) {
        cacheKey = 'char_${item}_$fontSize';
      }
    } else if (characterImages is Map && characterImages.containsKey(char)) {
      // 如果是映射，使用字符获取
      final item = characterImages[char];
      if (item != null) {
        cacheKey = 'char_${item}_$fontSize';
      }
    }

    // 如果没有缓存键，返回null
    if (cacheKey == null) return null;

    // 从缓存获取图像
    return _imageCacheService.tryGetUiImageSync(cacheKey);
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
      debugPrint('纹理加载错误: $e');
      return null;
    }
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
