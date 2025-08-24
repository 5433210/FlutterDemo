import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
  // 用于跟踪已记录日志的字符ID，避免重复日志
  static final Set<String> _loggedCharacters = <String>{};

  // 构造函数调用计数器，用于限制调试日志频率
  static int _constructorCallCount = 0;
  static DateTime? _lastConstructorLog;
  static const Duration _logThrottleDelay = Duration(milliseconds: 500);

  // shouldRepaint调用计数器
  static int _shouldRepaintCallCount = 0;
  static DateTime? _lastShouldRepaintLog;

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

  // 临时存储：在paint过程中使用的过滤后字符图像数据
  dynamic _currentFilteredCharacterImages;

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

    // 🔍 调试日志：构造函数调用（限频）
    _constructorCallCount++;
    final now = DateTime.now();
    final shouldLog = _lastConstructorLog == null ||
        now.difference(_lastConstructorLog!) > _logThrottleDelay;

    if (shouldLog) {
      EditPageLogger.rendererDebug('AdvancedCollectionPainter构造函数', data: {
        'callCount': _constructorCallCount,
        'charactersLength': characters.length,
        'positionsLength': positions.length,
        'characterImagesType': characterImages.runtimeType.toString(),
        'characterImagesData': characterImages is Map
            ? (characterImages as Map).keys.toList()
            : 'not_map',
        'painterHashCode': hashCode,
        'operation': 'painter_constructor_throttled',
      });
      _lastConstructorLog = now;
    }
  }

  /// 调试用：显示characterImages内容的简要信息
  Map<String, dynamic> _debugCharacterImagesContent(Map characterImages) {
    final debug = <String, dynamic>{};
    for (final entry in characterImages.entries) {
      if (entry.value is Map) {
        final imageInfo = entry.value as Map;
        final transform = imageInfo['transform'] as Map?;
        debug[entry.key.toString()] = {
          'characterId': imageInfo['characterId'],
          'transform': transform != null
              ? {
                  'characterScale': transform['characterScale'],
                  'offsetX': transform['offsetX'],
                  'offsetY': transform['offsetY'],
                }
              : null,
        };
      }
    }
    return debug;
  }

  /// 主绘制方法
  @override
  void paint(Canvas canvas, Size size) {
    try {
      // � 过滤掉强制重绘标志，避免影响实际渲染
      dynamic filteredCharacterImages = characterImages;
      if (characterImages is Map &&
          characterImages.containsKey('_forceRepaintTimestamp')) {
        filteredCharacterImages = Map.from(characterImages);
        (filteredCharacterImages as Map).remove('_forceRepaintTimestamp');
        EditPageLogger.rendererDebug('已过滤强制重绘标志', data: {
          'operation': 'filter_force_repaint_timestamp',
        });
      }

      // 保存过滤后的数据，供其他方法使用
      _currentFilteredCharacterImages = filteredCharacterImages;

      // �🔍 DEBUG: 详细输出characterImages结构
      if (filteredCharacterImages is Map) {
        EditPageLogger.rendererDebug('Paint方法开始 - characterImages详细结构', data: {
          'characterImagesKeys': filteredCharacterImages.keys.toList(),
          'characterImagesValues': filteredCharacterImages
              .map((k, v) => MapEntry(k.toString(), v.runtimeType.toString())),
          'operation': 'paint_method_character_images_debug',
        });

        // characterImages现在应该直接是字符图像数据，如果仍有嵌套说明数据传递有问题
        if (filteredCharacterImages.containsKey('characterImages')) {
          final nested = filteredCharacterImages['characterImages'];
          EditPageLogger.rendererDebug(
              '⚠️ Paint方法中发现嵌套characterImages，数据传递可能有问题',
              data: {
                'nestedType': nested.runtimeType.toString(),
                'operation': 'unexpected_nested_structure_in_paint',
              });
        }
      }

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
        if (charImage != null) {
          // 如果有图片，绘制图片
          _drawCharacterImage(canvas, rect, position, charImage);
        } else {
          // 如果没有图片，绘制文本
          _drawFallbackText(canvas, position, rect);
        }
      }

      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      EditPageLogger.rendererError('集字画笔绘制异常', error: e);
    }
  }

  /// 设置重绘回调函数
  void setRepaintCallback(VoidCallback callback) {
    _repaintCallback = callback;
  }

  @override
  bool shouldRepaint(covariant AdvancedCollectionPainter oldDelegate) {
    // 🔍 调试日志：shouldRepaint调用（限频）
    _shouldRepaintCallCount++;
    final now = DateTime.now();
    final shouldLogRepaint = _lastShouldRepaintLog == null ||
        now.difference(_lastShouldRepaintLog!) > _logThrottleDelay;

    if (shouldLogRepaint) {
      EditPageLogger.rendererDebug('shouldRepaint被调用', data: {
        'callCount': _shouldRepaintCallCount,
        'thisHashCode': hashCode,
        'otherHashCode': oldDelegate.hashCode,
        'operation': 'should_repaint_called_throttled',
      });
      _lastShouldRepaintLog = now;
    }

    // 🔧 强制触发：如果hashCode不同，立即返回true
    if (hashCode != oldDelegate.hashCode) {
      EditPageLogger.rendererDebug('检测到hashCode差异，强制重绘', data: {
        'thisHashCode': hashCode,
        'otherHashCode': oldDelegate.hashCode,
        'operation': 'hashcode_diff_force_repaint',
      });
      return true;
    }

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
    bool charactersChanged = oldDelegate.characters != characters;
    bool positionsChanged = oldDelegate.positions != positions;
    bool fontSizeChanged = oldDelegate.fontSize != fontSize;

    // 🔍 特别检查characterImages - 使用更详细的比较
    bool characterImagesChanged = false;
    try {
      if (oldDelegate.characterImages == null && characterImages != null) {
        characterImagesChanged = true;
        EditPageLogger.rendererDebug('字符图像变化：从null变为非null');
      } else if (oldDelegate.characterImages != null &&
          characterImages == null) {
        characterImagesChanged = true;
        EditPageLogger.rendererDebug('字符图像变化：从非null变为null');
      } else if (oldDelegate.characterImages != null &&
          characterImages != null) {
        // 🔥 检查强制重绘标志
        bool forceRepaintChanged = false;
        if (characterImages is Map &&
            characterImages.containsKey('_forceRepaintTimestamp')) {
          final newTimestamp = characterImages['_forceRepaintTimestamp'];
          final oldTimestamp = (oldDelegate.characterImages is Map)
              ? (oldDelegate.characterImages as Map)['_forceRepaintTimestamp']
              : null;
          if (newTimestamp != oldTimestamp) {
            forceRepaintChanged = true;
            EditPageLogger.rendererDebug('检测到强制重绘标志变化', data: {
              'newTimestamp': newTimestamp,
              'oldTimestamp': oldTimestamp,
              'operation': 'force_repaint_timestamp_changed',
            });
          }
        }

        characterImagesChanged = forceRepaintChanged ||
            !_deepEqual(oldDelegate.characterImages, characterImages);
        if (characterImagesChanged) {
          EditPageLogger.rendererDebug('字符图像变化：深度比较检测到变化', data: {
            'oldKeys':
                (oldDelegate.characterImages as Map?)?.keys.toList() ?? [],
            'newKeys': (characterImages as Map?)?.keys.toList() ?? [],
            'forceRepaintChanged': forceRepaintChanged,
            'operation': 'character_images_deep_changed',
          });
        }
      }
    } catch (e) {
      EditPageLogger.rendererError('字符图像比较异常', error: e);
      characterImagesChanged = true; // 发生异常时强制重绘
    }

    bool writingModeChanged = oldDelegate.writingMode != writingMode;
    bool textAlignChanged = oldDelegate.textAlign != textAlign;
    bool verticalAlignChanged = oldDelegate.verticalAlign != verticalAlign;
    bool enableSoftLineBreakChanged =
        oldDelegate.enableSoftLineBreak != enableSoftLineBreak;
    bool paddingChanged = oldDelegate.padding != padding;
    bool letterSpacingChanged = oldDelegate.letterSpacing != letterSpacing;
    bool lineSpacingChanged = oldDelegate.lineSpacing != lineSpacing;

    bool basicChanged = charactersChanged ||
        positionsChanged ||
        fontSizeChanged ||
        characterImagesChanged ||
        writingModeChanged ||
        textAlignChanged ||
        verticalAlignChanged ||
        enableSoftLineBreakChanged ||
        paddingChanged ||
        letterSpacingChanged ||
        lineSpacingChanged;

    final shouldRepaint = basicChanged || textureChanged || _needsRepaint;

    // 只在需要重绘或有重要变化时记录详情
    if (shouldRepaint || shouldLogRepaint) {
      EditPageLogger.rendererDebug('shouldRepaint检查详情', data: {
        'callCount': _shouldRepaintCallCount,
        'charactersChanged': charactersChanged,
        'positionsChanged': positionsChanged,
        'fontSizeChanged': fontSizeChanged,
        'characterImagesChanged': characterImagesChanged,
        'writingModeChanged': writingModeChanged,
        'textAlignChanged': textAlignChanged,
        'verticalAlignChanged': verticalAlignChanged,
        'enableSoftLineBreakChanged': enableSoftLineBreakChanged,
        'paddingChanged': paddingChanged,
        'letterSpacingChanged': letterSpacingChanged,
        'lineSpacingChanged': lineSpacingChanged,
        'textureChanged': textureChanged,
        'needsRepaint': _needsRepaint,
        'basicChanged': basicChanged,
        'finalResult': shouldRepaint,
        'operation': 'should_repaint_detailed_check_conditional',
      });
    }

    // 只在需要重绘时记录结果
    if (shouldRepaint) {
      EditPageLogger.rendererDebug('shouldRepaint结果：需要重绘', data: {
        'result': true,
        'callCount': _shouldRepaintCallCount,
        'operation': 'should_repaint_result_true',
      });
    }

    return shouldRepaint;
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
    // 使用过滤后的字符图像数据
    final characterImagesData =
        _currentFilteredCharacterImages ?? characterImages;

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    // 获取图像源矩形
    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    // 获取字符变换信息
    double characterScale = 1.0;
    double offsetX = 0.0;
    double offsetY = 0.0;

    // 从characterImages中获取变换信息
    if (characterImagesData is Map) {
      final String indexKey = position.originalIndex.toString();
      Map<dynamic, dynamic> targetMap = characterImagesData;

      // 🔍 调试：检查characterImages结构
      EditPageLogger.rendererDebug('characterImages结构检查', data: {
        'component': 'renderer',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'char': position.char,
        'index': position.originalIndex,
        'indexKey': indexKey,
        'characterImagesType': characterImagesData.runtimeType.toString(),
        'characterImagesKeys': characterImagesData.keys.toList(),
        'operation': 'character_images_structure_check',
      });

      // characterImages现在应该直接是字符图像数据，不再有嵌套结构
      // 如果仍有嵌套，说明数据传递可能存在问题，记录但继续处理
      if (characterImagesData.containsKey('characterImages')) {
        final subMap = characterImagesData['characterImages'];
        if (subMap is Map) {
          targetMap = subMap;
          EditPageLogger.rendererDebug('⚠️ 仍然发现嵌套characterImages结构，数据传递可能存在问题',
              data: {
                'component': 'renderer',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'char': position.char,
                'index': position.originalIndex,
                'nestedKeys': subMap.keys.toList(),
                'operation': 'unexpected_nested_structure_found',
              });
        }
      }

      // 🔍 调试：查找字符数据
      EditPageLogger.rendererDebug('查找字符数据', data: {
        'component': 'renderer',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'char': position.char,
        'index': position.originalIndex,
        'indexKey': indexKey,
        'targetMapKeys': targetMap.keys.toList(),
        'hasTargetKey': targetMap.containsKey(indexKey),
        'operation': 'search_character_data',
      });

      // 获取字符图像信息
      if (targetMap.containsKey(indexKey)) {
        final imageData = targetMap[indexKey];

        // 🔍 调试：字符图像数据结构
        EditPageLogger.rendererDebug('字符图像数据结构', data: {
          'component': 'renderer',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'char': position.char,
          'index': position.originalIndex,
          'imageDataType': imageData.runtimeType.toString(),
          'imageDataKeys': (imageData is Map) ? imageData.keys.toList() : [],
          'hasTransform':
              (imageData is Map) ? imageData.containsKey('transform') : false,
          'operation': 'character_image_data_structure',
        });

        if (imageData is Map && imageData.containsKey('transform')) {
          final transform = imageData['transform'];

          // 🔍 调试：transform数据结构
          EditPageLogger.rendererDebug('transform数据结构', data: {
            'component': 'renderer',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'char': position.char,
            'index': position.originalIndex,
            'transformType': transform.runtimeType.toString(),
            'transformKeys': (transform is Map) ? transform.keys.toList() : [],
            'transformValues':
                (transform is Map) ? transform.values.toList() : [],
            'operation': 'transform_data_structure',
          });

          if (transform is Map) {
            characterScale =
                (transform['characterScale'] as num?)?.toDouble() ?? 1.0;
            offsetX = (transform['offsetX'] as num?)?.toDouble() ?? 0.0;
            offsetY = (transform['offsetY'] as num?)?.toDouble() ?? 0.0;

            // 🔍 调试日志：确认变换数据被正确读取
            EditPageLogger.rendererDebug('字符变换数据读取成功', data: {
              'char': position.char,
              'index': position.originalIndex,
              'indexKey': indexKey,
              'characterScale': characterScale,
              'offsetX': offsetX,
              'offsetY': offsetY,
              'rectSize': rect.size.toString(),
              'rectCenter': rect.center.toString(),
              'scaledSize': (rect.width * characterScale).toString(),
              'operation': 'character_transform_data_read_success',
            });
          } else {
            EditPageLogger.rendererDebug('字符变换transform不是Map', data: {
              'char': position.char,
              'index': position.originalIndex,
              'transformType': transform.runtimeType.toString(),
              'operation': 'character_transform_invalid',
            });
          }
        } else {
          EditPageLogger.rendererDebug('字符图像数据缺少transform', data: {
            'char': position.char,
            'index': position.originalIndex,
            'imageDataKeys': (imageData is Map) ? imageData.keys.toList() : [],
            'operation': 'character_transform_missing',
          });
        }
      } else {
        // 🔍 调试日志：索引键不存在
        EditPageLogger.rendererDebug('字符变换索引键不存在', data: {
          'char': position.char,
          'index': position.originalIndex,
          'indexKey': indexKey,
          'availableKeys': targetMap.keys.toList(),
          'operation': 'character_transform_key_missing',
        });
      }
    }

    // 保存画布状态
    canvas.save();

    // 计算应用字符缩放后的目标矩形
    final scaledSize = rect.width * characterScale;
    final scaledRect = Rect.fromCenter(
      center: rect.center.translate(offsetX, offsetY),
      width: scaledSize,
      height: scaledSize,
    );

    // 🔍 详细的缩放调试日志
    EditPageLogger.rendererDebug('字符缩放应用详情', data: {
      'char': position.char,
      'index': position.originalIndex,
      'originalRect':
          '${rect.left.toStringAsFixed(1)},${rect.top.toStringAsFixed(1)} ${rect.width.toStringAsFixed(1)}x${rect.height.toStringAsFixed(1)}',
      'characterScale': characterScale,
      'scaledSize': scaledSize.toStringAsFixed(1),
      'scaledRect':
          '${scaledRect.left.toStringAsFixed(1)},${scaledRect.top.toStringAsFixed(1)} ${scaledRect.width.toStringAsFixed(1)}x${scaledRect.height.toStringAsFixed(1)}',
      'offsetX': offsetX,
      'offsetY': offsetY,
      'centerTranslation': '($offsetX, $offsetY)',
      'operation': 'character_scale_application_details',
    });

    // 检查是否需要应用颜色处理
    final bool needsColorProcessing = position.fontColor != Colors.black;

    // 如果不需要任何颜色处理，直接绘制原始图像
    if (!needsColorProcessing) {
      canvas.drawImageRect(image, srcRect, scaledRect, paint);
      canvas.restore();
      return;
    }

    // 需要进行颜色处理
    canvas.saveLayer(scaledRect, Paint());

    // 创建基础绘制配置
    final basePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(image, srcRect, scaledRect, basePaint);
    canvas.drawRect(
        scaledRect,
        Paint()
          ..color = position.fontColor
          ..blendMode = BlendMode.srcIn);

    // 完成绘制
    canvas.restore();
    canvas.restore();
  }

  /// 绘制普通背景
  void _drawFallbackBackground(
      Canvas canvas, Rect rect, CharacterPosition position) {
    // 当纹理启用时，不在字符区域绘制背景色
    // 这样可以让背景纹理透过来，避免被遮挡
    if (textureConfig.enabled && textureConfig.data != null) {
      return;
    }

    // 只有在背景色不是透明时才绘制背景
    if (position.backgroundColor != Colors.transparent) {
      final bgPaint = Paint()
        ..color = position.backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, bgPaint);
    }
    // 如果背景色是透明的，什么都不绘制，保持完全透明
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
    // 使用过滤后的字符图像数据
    final characterImagesData =
        _currentFilteredCharacterImages ?? characterImages;

    // 如果没有字符图像，直接返回null
    if (characterImagesData == null) {
      return null;
    }

    try {
      // 如果是图像对象，直接返回
      if (characterImagesData is ui.Image) {
        return characterImagesData;
      }

      // 处理用户的JSON结构 - 字符图像是一个以索引为键的Map
      if (characterImagesData is Map) {
        // 尝试使用字符索引作为键 - 使用原始位置索引
        final String indexKey = index.toString();

        // characterImages现在应该直接是字符数据，不再有嵌套结构
        Map<dynamic, dynamic> targetMap = characterImagesData;
        if (characterImagesData.containsKey('characterImages')) {
          final subMap = characterImagesData['characterImages'];
          if (subMap is Map) {
            targetMap = subMap;
            EditPageLogger.rendererDebug(
                '⚠️ _loadCharacterImage中发现嵌套结构，数据传递可能有问题',
                data: {
                  'index': index,
                  'char': char,
                  'operation': 'unexpected_nested_in_load_character_image',
                });
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

                // 在加载之前，先检查字符是否仍然存在
                // 如果字符已被删除，直接返回null以触发fallback文本渲染
                _characterImageService
                    .hasCharacterImage(
                        characterId,
                        imageData['type'] ?? 'square-binary',
                        imageData['format'] ?? 'png-binary')
                    .then((exists) {
                  if (!exists) {
                    // 字符已被删除，清除缓存并触发重绘以显示fallback
                    _imageCacheService.clearCharacterImageCaches(characterId);
                    if (_repaintCallback != null) {
                      _debounceRepaint();
                    }
                    return;
                  }

                  // 字符存在，继续正常加载流程
                  // 使用CharacterImageService加载图像
                  // 首先获取可用的格式
                  _loadCharacterImageViaService(characterId, cacheKey)
                      .then((success) {
                    if (success && _repaintCallback != null) {
                      // 🚀 优化：使用防抖重绘，避免GPU高负载
                      _debounceRepaint();
                    } else {
                      // 如果无法使用服务加载，创建占位图像
                      _createPlaceholderImage(cacheKey)
                          .then((placeholderSuccess) {
                        if (placeholderSuccess && _repaintCallback != null) {
                          // 🚀 优化：使用防抖重绘，避免GPU高负载
                          _debounceRepaint();
                        }
                      });
                    }
                  });
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

      // 🚀 优化：减少字符图像加载成功的重复日志
      // 只在首次加载或特殊情况下记录
      if (!_loggedCharacters.contains(characterId)) {
        _loggedCharacters.add(characterId);
        EditPageLogger.rendererDebug('字符图像服务加载成功', data: {
          'characterId': characterId,
          'cacheKey': cacheKey,
          'imageSize': '${image.width}x${image.height}',
        });
      }
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
        if (_repaintCallback != null) {
          // 🚀 优化：使用防抖重绘，避免GPU高负载
          _debounceRepaint();
        }
      }
    });
  }

  /// 深度比较两个对象是否相等
  bool _deepEqual(dynamic obj1, dynamic obj2) {
    if (identical(obj1, obj2)) return true;
    if (obj1 == null || obj2 == null) return obj1 == obj2;

    if (obj1.runtimeType != obj2.runtimeType) return false;

    if (obj1 is Map && obj2 is Map) {
      if (obj1.length != obj2.length) return false;
      for (final key in obj1.keys) {
        if (!obj2.containsKey(key) || !_deepEqual(obj1[key], obj2[key])) {
          return false;
        }
      }
      return true;
    }

    if (obj1 is List && obj2 is List) {
      if (obj1.length != obj2.length) return false;
      for (int i = 0; i < obj1.length; i++) {
        if (!_deepEqual(obj1[i], obj2[i])) return false;
      }
      return true;
    }

    return obj1 == obj2;
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

    // 🚀 优化：防止重复加载，避免不必要的重绘
    if (_loadingTextures.contains(cacheKey)) {
      return null; // 已在加载中，避免重复请求
    }

    _loadingTextures.add(cacheKey);

    // 异步加载图像 - 🚀 优化：添加防抖机制
    _loadCharacterImage(imagePath, cacheKey).then((success) {
      _loadingTextures.remove(cacheKey);

      if (success && _repaintCallback != null) {
        // 🚀 优化：使用防抖，避免频繁重绘导致GPU高负载
        _debounceRepaint();
      }
    }).catchError((error) {
      _loadingTextures.remove(cacheKey);
      EditPageLogger.rendererError('图像加载失败', error: error);
    });

    return null;
  }

  // 🚀 优化：添加重绘防抖机制，减少GPU使用率
  Timer? _repaintDebounceTimer;
  static const Duration _repaintDebounceDelay =
      Duration(milliseconds: 16); // 约60fps

  void _debounceRepaint() {
    _repaintDebounceTimer?.cancel();
    _repaintDebounceTimer = Timer(_repaintDebounceDelay, () {
      if (_repaintCallback != null) {
        _needsRepaint = true;
        _repaintCallback!();
      }
    });
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

  /// 🔧 重写相等性比较，确保Flutter能正确检测painter变化
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AdvancedCollectionPainter) return false;

    final result =
        // 基本属性比较
        _listEquals(characters, other.characters) &&
            _listEquals(positions, other.positions) &&
            fontSize == other.fontSize &&
            _deepEqual(characterImages, other.characterImages) &&
            textureConfig == other.textureConfig &&
            // 布局参数比较
            writingMode == other.writingMode &&
            textAlign == other.textAlign &&
            verticalAlign == other.verticalAlign &&
            enableSoftLineBreak == other.enableSoftLineBreak &&
            padding == other.padding &&
            letterSpacing == other.letterSpacing &&
            lineSpacing == other.lineSpacing;

    // 🔍 调试日志：相等性比较结果
    EditPageLogger.rendererDebug('Painter相等性比较', data: {
      'result': result,
      'thisHashCode': hashCode,
      'otherHashCode': other.hashCode,
      'characterImagesEqual':
          _deepEqual(characterImages, other.characterImages),
      'operation': 'painter_equality_check',
    });

    return result;
  }

  /// 🔧 重写hashCode，确保相等的painter有相同的hash值
  @override
  int get hashCode {
    return Object.hashAll([
      // 基本属性hash
      Object.hashAll(characters),
      Object.hashAll(
          positions.map((p) => Object.hashAll([p.char, p.x, p.y, p.size]))),
      fontSize,
      _computeCharacterImagesHash(characterImages),
      textureConfig.hashCode,
      // 布局参数hash
      writingMode,
      textAlign,
      verticalAlign,
      enableSoftLineBreak,
      padding,
      letterSpacing,
      lineSpacing,
    ]);
  }

  /// 计算characterImages的hash值
  int _computeCharacterImagesHash(dynamic images) {
    if (images == null) return 0;
    if (images is Map) {
      final sortedEntries = images.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return Object.hashAll(sortedEntries
          .map((e) => Object.hashAll([e.key, _computeValueHash(e.value)])));
    }
    return images.hashCode;
  }

  /// 递归计算复杂值的hash
  int _computeValueHash(dynamic value) {
    if (value == null) return 0;
    if (value is Map) {
      final sortedEntries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return Object.hashAll(sortedEntries
          .map((e) => Object.hashAll([e.key, _computeValueHash(e.value)])));
    }
    if (value is List) {
      return Object.hashAll(value.map(_computeValueHash));
    }
    return value.hashCode;
  }

  /// 列表相等性比较
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
