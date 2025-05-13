import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../infrastructure/providers/cache_providers.dart' as cache;
import 'character_position.dart';
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

            // 如果不在加载中，则启动异步加载
            if (!_loadingImages.contains(cacheKey)) {
              _loadingImages.add(cacheKey);
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

      // 预先加载字符图像
      _preloadCharacterImages();

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

        // 跳过换行符，但不做其他特殊处理
        if (position.char == '\n') {
          debugPrint('  跳过换行符 (索引: $i)');
          continue;
        }

        // 创建字符固有区域
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

        // 绘制字符（带图像或占位符）
        if (charImage != null) {
          _drawCharacterWithImage(canvas, charRect, position, charImage);
        } else {
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

          // 绘制索引编号，帮助调试
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${i + 1}',
              style: TextStyle(
                fontSize: 10,
                color: position.isAfterNewLine ? Colors.red : Colors.blue,
                fontWeight: position.isAfterNewLine
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
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
    } catch (e, stackTrace) {
      debugPrint('绘制异常：$e');
      debugPrint('堆栈跟踪：$stackTrace');
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

  /// 计算实际字符索引（忽略换行符）
  int _calculateRealCharIndex(int positionIndex) {
    int realIndex = 0;
    int newlineCount = 0;

    // 检查边界条件
    if (positionIndex < 0 || positions.isEmpty) {
      return 0;
    }

    // 计算在当前位置之前的换行符数量和真实字符数量
    for (int i = 0; i < positionIndex && i < positions.length; i++) {
      if (positions[i].char == '\n') {
        newlineCount++;
      } else {
        realIndex++;
      }
    }

    debugPrint(
        '  实际字符索引计算: 位置索引=$positionIndex, 换行符数量=$newlineCount, 实际字符索引=$realIndex');
    return realIndex;
  }

  /// 计算行内索引（每行重新从0开始计数）
  int _calculateRowBasedIndex(int positionIndex) {
    // 检查边界
    if (positionIndex < 0 ||
        positions.isEmpty ||
        positionIndex >= positions.length) {
      return 0;
    }

    // 获取当前字符所在的行
    int currentRow = -1;
    int rowBasedIndex = 0;

    // 遍历所有的字符位置查找行号并计算行内索引
    for (int i = 0; i <= positionIndex; i++) {
      if (i < positions.length) {
        // 检查是否是换行符
        if (positions[i].char == '\n') {
          // 遇到换行符，重置行内索引并更新行号
          currentRow++;
          rowBasedIndex = 0;
          continue;
        }

        // 检查是否是一行的第一个字符
        if (positions[i].isAfterNewLine) {
          // 遇到行的第一个字符，重置行内索引
          rowBasedIndex = 0;
          currentRow++;
        } else if (i > 0 && positions[i - 1].char == '\n') {
          // 如果前一个是换行符但isAfterNewLine没设置，也视为新行
          rowBasedIndex = 0;
          currentRow++;
        } else if (i == 0) {
          // 第一个字符也是第一行的开始
          currentRow = 0;
        } else {
          // 其他情况，递增行内索引
          rowBasedIndex++;
        }
      }
    }

    // 边界检查：如果是第一个字符，行内索引应该是0
    if (positionIndex == 0 || positions[positionIndex].isAfterNewLine) {
      rowBasedIndex = 0;
    }

    debugPrint(
        '  行内索引计算: 位置=$positionIndex, 行号=$currentRow, 行内索引=$rowBasedIndex');
    return rowBasedIndex;
  }

  /// 创建字符图像结果对象
  Map<String, dynamic> _createCharacterImageResult(
      Map<String, dynamic> imageInfo) {
    // 创建基本结果对象
    final result = {
      'characterId': imageInfo['characterId'],
      'type': imageInfo['drawingType'] ?? imageInfo['type'] ?? 'square-binary',
      'format':
          imageInfo['drawingFormat'] ?? imageInfo['format'] ?? 'png-binary',
    };

    // 添加transform属性（如果有）
    if (imageInfo.containsKey('transform')) {
      result['transform'] = imageInfo['transform'];
    } else if (imageInfo.containsKey('invert') && imageInfo['invert'] == true) {
      result['invert'] = true;
    }

    return result;
  }

  /// 绘制带图片的字符 - 使用ImageCacheService
  void _drawCharacterWithImage(Canvas canvas, Rect rect,
      CharacterPosition position, Map<String, dynamic> charImage) async {
    // 输出详细调试信息
    debugPrint('🖼️ 绘制带图片的字符:');
    debugPrint('  字符: "${position.char}"');
    debugPrint('  位置: x=${position.x}, y=${position.y}, size=${position.size}');
    debugPrint('  是否换行后第一个字符: ${position.isAfterNewLine ? "是" : "否"}');

    // 检查是否有字符ID等必要信息
    if (charImage['characterId'] == null ||
        charImage['type'] == null ||
        charImage['format'] == null) {
      debugPrint('  ⚠️ 缺少必要信息，使用占位符文本');
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
    final simpleKey = characterId; // 简化的缓存键

    // 输出调试信息
    debugPrint('  图片信息:');
    debugPrint('    字符ID: $characterId');
    debugPrint('    类型: $type');
    debugPrint('    格式: $format');
    debugPrint('    缓存键: $cacheKey');
    debugPrint('    反转显示: ${invertDisplay ? "是" : "否"}');

    // 需要Riverpod引用才能获取服务
    if (ref == null) {
      debugPrint('  ⚠️ 缺少Riverpod引用，无法获取图像');
      _drawFallbackText(canvas, position, rect);
      return;
    }

    // 获取ImageCacheService
    final imageCacheService = ref!.read(cache.imageCacheServiceProvider);
    
    // 尝试从缓存中获取UI图像
    ui.Image? image;
    try {
      image = await imageCacheService.getUiImage(cacheKey);
      
      // 如果找不到，尝试使用简化键
      if (image == null) {
        image = await imageCacheService.getUiImage(simpleKey);
        if (image != null) {
          debugPrint('  ✅ 使用简化缓存键找到图像: $simpleKey');
        }
      } else {
        debugPrint('  ✅ 已从缓存获取图像: $cacheKey');
      }
    } catch (e) {
      debugPrint('  ⚠️ 获取缓存图像时出错: $e');
    }

    if (image != null) {
      // 有图像，绘制图像
      debugPrint('  ✅ 已从ImageCacheService获取图像，开始绘制');

      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      // 应用反转效果
      if (invertDisplay) {
        debugPrint('  应用反转效果');
        paint.colorFilter = const ColorFilter.matrix([
          -1, 0, 0, 0, 255, // 红色通道反转
          0, -1, 0, 0, 255, // 绿色通道反转
          0, 0, -1, 0, 255, // 蓝色通道反转
          0, 0, 0, 1, 0, // Alpha通道保持不变
        ]);
      }

      // 绘制图像，铺满整个字符区域
      final srcRect = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );

      canvas.drawImageRect(image, srcRect, rect, paint);
      debugPrint('  ✅ 字符图像绘制完成');
    } else {
      // 无图像，绘制占位符
      debugPrint('  ⚠️ 图像未在缓存中，使用占位符文本');
      _drawFallbackText(canvas, position, rect);

      // 添加到待加载集合
      if (!_loadingImages.contains(cacheKey)) {
        _loadingImages.add(cacheKey);
        debugPrint('  🔄 添加到图像加载队列: $cacheKey');

        // 异步加载图像
        _loadAndCacheImage(characterId, type, format).then((_) {
          debugPrint('  📥 图像加载完成，标记需要重绘');
          _needsRepaint = true;
          if (_repaintCallback != null) {
            _repaintCallback!();
          }
        }).catchError((e) {
          debugPrint('  ❌ 图像加载失败: $e');
          _loadingImages.remove(cacheKey);
        });
      }
    }
  }

  /// 绘制占位符文本
  void _drawFallbackText(Canvas canvas, CharacterPosition position, Rect rect) {
    debugPrint('  📝 绘制占位符文本: "${position.char}"');

    // 创建用于绘制文本的画笔
    final textStyle = TextStyle(
      color: position.fontColor,
      fontSize: position.size * 0.75, // 适当缩小以适应区域
      fontWeight: FontWeight.bold,
    );

    // 创建文本绘制器
    final textSpan = TextSpan(
      text: position.char,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(
      minWidth: rect.width,
      maxWidth: rect.width,
    );

    // 计算文本位置，使其在矩形中居中
    final xCenter = rect.left + (rect.width - textPainter.width) / 2;
    final yCenter = rect.top + (rect.height - textPainter.height) / 2;

    // 绘制背景，如果字符是换行后的第一个字符，使用淡红色背景以便于调试
    final bgPaint = Paint()
      ..color = position.isAfterNewLine
          ? Colors.red.withOpacity(0.2)
          : position.backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, bgPaint);

    // 绘制文本
    textPainter.paint(canvas, Offset(xCenter, yCenter));

    // 如果是换行后第一个字符，添加一个标记
    if (position.isAfterNewLine) {
      final markerPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawRect(rect, markerPaint);

      // 添加一个小的换行标记
      final nlMarkerPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(rect.left + 4, rect.top + 4),
        2,
        nlMarkerPaint,
      );
    }
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

  /// 查找字符对应的图片 - 增强版
  Map<String, dynamic>? _findCharacterImage(String char, int positionIndex) {
    try {
      // 计算实际字符索引（不包含换行符）
      int realCharIndex = _calculateRealCharIndex(positionIndex);

      // 检查是否是换行符后的字符
      bool isAfterNewline = false;
      if (positionIndex > 0 && positionIndex < positions.length) {
        isAfterNewline = positions[positionIndex].isAfterNewLine;
      }

      // 检查换行修正 - 这是关键修复
      int rowBasedIndex = _calculateRowBasedIndex(positionIndex);

      debugPrint(
          '✨ 查找字符图像: 字符="$char", 位置索引=$positionIndex, 实际字符索引=$realCharIndex, 行内索引=$rowBasedIndex');

      // 递归查找字符图像
      Map<String, dynamic>? findImageInMap(
          Map<String, dynamic> source, String prefix) {
        // 首先检查是否有 characterImages 属性
        Map<String, dynamic>? images;

        if (source.containsKey('characterImages')) {
          final imagesData = source['characterImages'];
          if (imagesData is Map<String, dynamic>) {
            images = imagesData;
          }
        }

        // 如果没有找到 characterImages，则使用源对象本身
        images ??= source;

        // 开始按优先级顺序查找

        // 1. 使用行内索引
        if (rowBasedIndex >= 0 && images.containsKey('$rowBasedIndex')) {
          debugPrint('$prefix 在行内索引 $rowBasedIndex 处找到图像信息');
          return images['$rowBasedIndex'] as Map<String, dynamic>;
        }

        // 2. 使用位置索引
        if (images.containsKey('$positionIndex')) {
          debugPrint('$prefix 在位置索引 $positionIndex 处找到图像信息');
          return images['$positionIndex'] as Map<String, dynamic>;
        }

        // 3. 使用实际字符索引
        if (realCharIndex >= 0 && images.containsKey('$realCharIndex')) {
          debugPrint('$prefix 在实际字符索引 $realCharIndex 处找到图像信息');
          return images['$realCharIndex'] as Map<String, dynamic>;
        }

        // 4. 换行后字符特殊处理
        if (isAfterNewline && images.containsKey('0')) {
          debugPrint('$prefix 使用行内索引0找到图像信息（换行后特殊处理）');
          return images['0'] as Map<String, dynamic>;
        }

        // 5. 使用字符作为键
        if (images.containsKey(char)) {
          debugPrint('$prefix 使用字符 "$char" 作为键找到图像信息');
          return images[char] as Map<String, dynamic>;
        }

        // 6. 检查嵌套结构
        if (source.containsKey('content') &&
            source['content'] is Map<String, dynamic>) {
          final nestedContent = source['content'] as Map<String, dynamic>;
          debugPrint('$prefix 检查嵌套内容结构');
          return findImageInMap(nestedContent, '$prefix  嵌套>');
        }

        return null;
      }

      // 检查 characterImages 是否是 Map 类型
      if (characterImages is Map<String, dynamic>) {
        final result =
            findImageInMap(characterImages as Map<String, dynamic>, '  ');
        if (result != null) {
          return _createCharacterImageResult(result);
        }
      } else if (characterImages is List) {
        // 如果是 List 类型，则遍历查找
        final charImagesList = characterImages as List;
        debugPrint('  在列表中查找字符图像，列表长度: ${charImagesList.length}');

        for (int i = 0; i < charImagesList.length; i++) {
          final image = charImagesList[i];

          if (image is Map<String, dynamic>) {
            // 检查是否有字符信息和索引信息
            if (image.containsKey('character') && image['character'] == char) {
              debugPrint('  在列表类型中找到字符: $char');
              // 检查是否有字符图像信息
              if (image.containsKey('characterId')) {
                return _createCharacterImageResult(image);
              }
            }

            // 根据索引检查
            if (image.containsKey('index')) {
              final imgIndex = int.tryParse('${image['index']}') ?? -1;
              // 同时检查多种索引
              if (imgIndex == positionIndex ||
                  imgIndex == realCharIndex ||
                  imgIndex == rowBasedIndex) {
                debugPrint('  在列表类型中找到索引匹配项: $imgIndex');
                if (image.containsKey('characterId')) {
                  return _createCharacterImageResult(image);
                }
              }
            }

            // 检查嵌套结构
            if (image.containsKey('content') &&
                image['content'] is Map<String, dynamic>) {
              final nestedResult = findImageInMap(image, '  列表项[$i]>');
              if (nestedResult != null) {
                return _createCharacterImageResult(nestedResult);
              }
            }
          }
        }
      }

      // 未找到字符图像，记录详细信息
      debugPrint(
          '❌ 未找到字符图像 "$char"（位置：$positionIndex，实际索引：$realCharIndex，行内索引：$rowBasedIndex）');

      // 输出 characterImages 结构信息以便于调试
      if (characterImages is Map<String, dynamic>) {
        final keys = (characterImages as Map<String, dynamic>).keys.join(', ');
        debugPrint('ℹ️ characterImages 的键列表: $keys');

        if ((characterImages as Map<String, dynamic>)
            .containsKey('characterImages')) {
          final innerKeys =
              ((characterImages as Map<String, dynamic>)['characterImages']
                          as Map<String, dynamic>?)
                      ?.keys
                      .join(', ') ??
                  '空';
          debugPrint('ℹ️ characterImages.characterImages 的键列表: $innerKeys');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 查找字符图像失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
    }

    return null;
  }

  /// 加载并缓存图像 - 使用ImageCacheService实现
  Future<void> _loadAndCacheImage(
      String characterId, String type, String format) async {
    // 构建缓存键
    final cacheKey = '$characterId-$type-$format';
    final simpleKey = characterId; // 简化的缓存键
    
    // 标记正在加载
    _loadingImages.add(cacheKey);
    debugPrint('✨ 开始加载字符图像: $cacheKey');
    
    try {
      // 需要Riverpod引用才能加载
      if (ref == null) {
        debugPrint('❌ 缺少Riverpod引用，无法加载图像');
        _loadingImages.remove(cacheKey);
        return;
      }

      // 获取服务
      final characterImageService = ref!.read(characterImageServiceProvider);
      final imageCacheService = ref!.read(cache.imageCacheServiceProvider);

      // 检查是否已经在缓存中
      final cachedImageData = await imageCacheService.getBinaryImage(cacheKey);
      if (cachedImageData != null) {
        debugPrint('✅ 图像已在ImageCacheService缓存中: $cacheKey');
        
        // 解码图像
        final image = await imageCacheService.decodeImageFromBytes(cachedImageData);
        if (image != null) {
          // 缓存UI图像
          await imageCacheService.cacheUiImage(cacheKey, image);
          await imageCacheService.cacheUiImage(simpleKey, image);
          
          // 标记需要重绘
          _needsRepaint = true;
          if (_repaintCallback != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _repaintCallback!();
            });
          }
        }
        
        _loadingImages.remove(cacheKey);
        return;
      }

      debugPrint('ℹ️ 使用字符ID: $characterId, 类型: $type, 格式: $format');

      // 检查可用格式
      debugPrint('ℹ️ 检查字符 $characterId 的可用格式');
      final availableFormat =
          await characterImageService.getAvailableFormat(characterId);
      
      // 优先使用可用格式
      String preferredType = type;
      String preferredFormat = format;
      
      if (availableFormat != null) {
        preferredType = availableFormat['type']!;
        preferredFormat = availableFormat['format']!;
        debugPrint('✅ 找到可用格式: 类型=$preferredType, 格式=$preferredFormat');
      } else {
        debugPrint('⚠️ 未找到可用格式，使用默认值: 类型=$preferredType, 格式=$preferredFormat');
      }

      // 更新实际缓存键
      final actualCacheKey = '$characterId-$preferredType-$preferredFormat';
      
      // 尝试从CharacterImageService获取图像
      final imageData = await characterImageService.getCharacterImage(
          characterId, preferredType, preferredFormat);

      if (imageData != null) {
        debugPrint('✅ 成功获取图像数据: ${imageData.length} 字节');
        
        // 缓存到ImageCacheService
        await imageCacheService.cacheBinaryImage(cacheKey, imageData);
        await imageCacheService.cacheBinaryImage(actualCacheKey, imageData);
        await imageCacheService.cacheBinaryImage(simpleKey, imageData); // 简单键

        // 解码图像
        debugPrint('ℹ️ 开始解码图像数据');
        final image = await imageCacheService.decodeImageFromBytes(imageData);

        if (image != null) {
          debugPrint('✅ 成功解码图像: ${image.width}x${image.height}');

          // 缓存UI图像
          await imageCacheService.cacheUiImage(actualCacheKey, image);
          await imageCacheService.cacheUiImage(cacheKey, image);
          await imageCacheService.cacheUiImage(simpleKey, image); // 简单键
          
          // 验证缓存
          final cachedImageData = await imageCacheService.getBinaryImage(cacheKey);
          if (cachedImageData != null) {
            debugPrint('✅ ImageCacheService缓存验证成功: $cacheKey');
          } else {
            debugPrint('⚠️ ImageCacheService缓存验证失败: $cacheKey');
          }

          // 标记需要重绘
          _needsRepaint = true;
          if (_repaintCallback != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _repaintCallback!();
            });
          }
        } else {
          debugPrint('❌ 解码图像失败');
        }
      } else {
        debugPrint('❌ 获取图像数据失败');
      }
    } catch (e) {
      debugPrint('❌ 加载图像过程中发生错误: $e');
    } finally {
      // 移除加载标记
      _loadingImages.remove(cacheKey);
    }
  }

  /// 绘制纹理背景 - 使用ImageCacheService
  void _paintTexture(Canvas canvas, Rect rect, {required String mode}) async {
    if (!textureConfig.enabled || textureConfig.data == null) return;

    final data = textureConfig.data!;
    final texturePath = data['path'] as String?;
    if (texturePath == null || texturePath.isEmpty) return;

    // 处理纹理模式，只有在当前模式匹配时才绘制
    bool shouldApply = false;
    switch (mode) {
      case 'background':
        shouldApply = textureConfig.textureApplicationRange == 'background';
        break;
      case 'characterBackground':
        shouldApply =
            textureConfig.textureApplicationRange == 'characterBackground' ||
                textureConfig.textureApplicationRange == 'character';
        break;
      case 'character':
        shouldApply = textureConfig.textureApplicationRange == 'character' ||
            textureConfig.textureApplicationRange == 'characterTexture';
        break;
      default:
        shouldApply = textureConfig.textureApplicationRange == mode;
    }

    if (!shouldApply) return;

    debugPrint('🎨 开始绘制纹理 - 模式: $mode, 纹理路径: $texturePath');

    try {
      // 需要Riverpod引用才能获取服务
      if (ref == null) {
        debugPrint('⚠️ 缺少Riverpod引用，无法获取纹理图像');
        _drawFallbackTexture(canvas, rect);
        return;
      }
      
      // 获取ImageCacheService
      final imageCacheService = ref!.read(cache.imageCacheServiceProvider);
      
      // 尝试从缓存中获取UI图像
      ui.Image? image;
      try {
        image = await imageCacheService.getUiImage(texturePath);
      } catch (e) {
        debugPrint('⚠️ 获取纹理缓存图像时出错: $e');
      }

      if (image != null) {
        // 有纹理图片，绘制纹理
        debugPrint('✅ 从ImageCacheService获取纹理图像成功');
        _drawTextureWithImage(canvas, rect, image);
      } else {
        // 纹理加载中，显示占位符
        debugPrint('⏳ 纹理图像未加载，显示占位符');
        _drawFallbackTexture(canvas, rect);

        // 异步加载纹理图片
        if (!_loadingTextures.contains(texturePath)) {
          _loadingTextures.add(texturePath);
          debugPrint('🔄 开始加载纹理图像: $texturePath');

          // 使用增强版纹理管理器加载纹理
          EnhancedTextureManager.instance.loadTexture(texturePath, ref,
              onLoaded: () {
            _loadingTextures.remove(texturePath);
            debugPrint('✅ 纹理图像加载完成: $texturePath');
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

  // 预先加载字符图像 - 使用ImageCacheService
  void _preloadCharacterImages() async {
    // 创建缓存键集合，避免重复加载
    final Set<String> charsToLoad = {};

    // 先扫描所有需要加载的字符图像
    for (int i = 0; i < positions.length; i++) {
      final position = positions[i];

      // 跳过换行符
      if (position.char == '\n') continue;

      // 查找字符图像
      final charImage = _findCharacterImage(position.char, i);

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
    if (ref != null) {
      // 获取ImageCacheService
      final imageCacheService = ref!.read(cache.imageCacheServiceProvider);
      
      for (final cacheKey in charsToLoad) {
        final parts = cacheKey.split('-');
        if (parts.length >= 3) {
          final characterId = parts[0];
          final type = parts[1];
          final format = parts.sublist(2).join('-');

          // 检查是否已经在缓存中
          try {
            final cachedImage = await imageCacheService.getBinaryImage(cacheKey);
            if (cachedImage == null && !_loadingImages.contains(cacheKey)) {
              // 如果缓存中没有图像且不在加载中，则启动异步加载
              _loadingImages.add(cacheKey);
              _loadAndCacheImage(characterId, type, format);
            }
          } catch (e) {
            debugPrint('⚠️ 检查缓存时出错: $e');
          }
        }
      }
    }
  }
}
