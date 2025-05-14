import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

    // 调试显示字符索引映射
    _debugLogCharacterIndexes();
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
        debugPrint('------字符：${position.char}， 索引：${position.index}------');

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
        // 注意：我们使用position.index而不是i来查找图像，因为position.index是原始的字符索引
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

  /// 创建占位图像并缓存
  Future<bool> _createPlaceholderImage(String cacheKey) async {
    try {
      debugPrint('创建占位图像: $cacheKey');

      // 创建一个简单的占位图像
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(fontSize, fontSize);

      // 绘制一个带有边框的矩形
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.5)
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

      debugPrint('占位图像创建成功: $cacheKey');
      return true;
    } catch (e) {
      debugPrint('创建占位图像失败: $e');
      return false;
    }
  }

  /// 调试工具：记录字符和索引的映射关系
  void _debugLogCharacterIndexes() {
    debugPrint('======= 字符索引映射 =======');
    final List<String> chars = characters;
    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      final displayChar = char == '\n' ? '\\n' : char;
      debugPrint('索引: $i - 字符: "$displayChar"${char == '\n' ? ' (换行符)' : ''}');
    }

    // 如果characterImages是Map，输出其键
    if (characterImages is Map) {
      debugPrint('======= 字符图像映射 =======');
      final Map charImages = characterImages as Map;
      charImages.forEach((key, value) {
        debugPrint('图像键: $key - 值类型: ${value.runtimeType}');
      });

      // 检查是否存在characterImages子映射
      if (charImages.containsKey('characterImages')) {
        debugPrint('======= 子字符图像映射 =======');
        final subMap = charImages['characterImages'];
        if (subMap is Map) {
          subMap.forEach((key, value) {
            debugPrint('子图像键: $key - 值类型: ${value.runtimeType}');
          });
        }
      }
    }
    debugPrint('============================');
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

    // 调试用：输出字符索引信息
    debugPrint('绘制文本字符: "${position.char}" 在索引 ${position.index}');
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

  /// 查找字符图像
  ui.Image? _findCharacterImage(String char, int index) {
    // 如果没有字符图像，直接返回null
    if (characterImages == null) {
      debugPrint('没有字符图像数据');
      return null;
    }

    try {
      // 输出字符图像的类型和索引信息 - 保持原始索引不变
      debugPrint(
          '字符图像类型: ${characterImages.runtimeType}, 当前字符: $char, 原始索引: $index');

      // 如果是图像对象，直接返回
      if (characterImages is ui.Image) {
        return characterImages;
      }

      // 处理用户的JSON结构 - 字符图像是一个以索引为键的Map
      if (characterImages is Map) {
        // 尝试使用字符索引作为键 - 使用原始位置索引
        final String indexKey = index.toString();
        debugPrint('尝试查找索引键: $indexKey');

        // 检查是否有对应索引的图像数据
        if (characterImages.containsKey(indexKey)) {
          final imageData = characterImages[indexKey];
          debugPrint('找到索引 $indexKey 的图像数据: $imageData');

          // 如果是字符串，直接使用
          if (imageData is String) {
            final cacheKey = 'char_${imageData}_$fontSize';
            return _processImagePath(imageData, cacheKey);
          }
          // 如果是复杂对象，处理characterId
          else if (imageData is Map) {
            if (imageData.containsKey('characterId')) {
              final characterId = imageData['characterId'];
              debugPrint('找到characterId: $characterId');

              if (characterId != null) {
                // 使用characterId作为缓存键
                final cacheKey = 'char_${characterId}_$fontSize';

                // 尝试从缓存获取
                ui.Image? cachedImage =
                    _imageCacheService.tryGetUiImageSync(cacheKey);
                if (cachedImage != null) {
                  debugPrint('从缓存找到图像: $cacheKey');
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
                    // 如果无法使用服务加载，创建占位图像
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
        // 如果没有找到索引键，检查其他可能的结构
        else {
          // 检查是否有characterImages子键
          if (characterImages.containsKey('characterImages')) {
            final charImages = characterImages['characterImages'];
            debugPrint('找到characterImages子键: $charImages');

            if (charImages is Map) {
              // 再次尝试索引键
              if (charImages.containsKey(indexKey)) {
                final subImageData = charImages[indexKey];
                debugPrint('在子键中找到索引 $indexKey 的数据: $subImageData');

                if (subImageData is Map &&
                    subImageData.containsKey('characterId')) {
                  final characterId = subImageData['characterId'];
                  final cacheKey = 'char_${characterId}_$fontSize';

                  // 尝试从缓存获取
                  ui.Image? cachedImage =
                      _imageCacheService.tryGetUiImageSync(cacheKey);
                  if (cachedImage != null) {
                    return cachedImage;
                  }

                  // 使用CharacterImageService加载图像
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
                      // 如果无法使用服务加载，创建占位图像
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
      }

      // 如果没有找到匹配的图像
      debugPrint('没有找到字符 "$char" (索引: $index) 的图像');
      return null;
    } catch (e) {
      debugPrint('获取字符图像时出错: $e');
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
      debugPrint('开始加载字符图像: $path (缓存键: $cacheKey)');

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

      debugPrint('字符图像加载成功: $path');
      return true;
    } catch (e) {
      debugPrint('字符图像加载失败: $path, 错误: $e');
      return false;
    }
  }

  /// 通过CharacterImageService加载字符图像
  Future<bool> _loadCharacterImageViaService(
      String characterId, String cacheKey) async {
    try {
      debugPrint('通过CharacterImageService加载字符图像: $characterId');

      // 获取可用的图像格式
      final format =
          await _characterImageService.getAvailableFormat(characterId);
      if (format == null) {
        debugPrint('找不到字符图像的格式: $characterId');
        return false;
      }

      debugPrint('字符图像格式: $format');
      final type = format['type']!;
      final formatType = format['format']!;

      // 获取字符图像数据
      final imageData = await _characterImageService.getCharacterImage(
          characterId, type, formatType);

      if (imageData == null) {
        debugPrint('无法获取字符图像数据: $characterId');
        return false;
      }

      // 解码图像
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 缓存UI图像
      await _imageCacheService.cacheUiImage(cacheKey, image);

      debugPrint('字符图像加载成功: $characterId');
      return true;
    } catch (e) {
      debugPrint('通过服务加载字符图像失败: $characterId, 错误: $e');
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
      debugPrint('纹理加载错误: $e');
      return null;
    }
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
    _cacheKey =
        'texture_${texturePath}_${rect.width.toInt()}_${rect.height.toInt()}';

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
}
