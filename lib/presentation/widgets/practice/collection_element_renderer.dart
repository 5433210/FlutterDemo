import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../infrastructure/providers/storage_providers.dart';

/// 集字绘制器
class CollectionElementRenderer {
  /// 构建集字布局
  static Widget buildCollectionLayout({
    required String characters,
    required String writingMode,
    required double fontSize,
    required double letterSpacing,
    required double lineSpacing,
    required String textAlign,
    required String verticalAlign,
    required dynamic characterImages, // 可以是字符图片列表或Map
    required BoxConstraints constraints,
    required double padding,
    String fontColor = '#000000',
    String backgroundColor = 'transparent',
    WidgetRef? ref,
  }) {
    // 添加调试日志，查看传入的颜色值
    debugPrint('集字布局 - 传入的字体颜色: $fontColor');
    debugPrint('集字布局 - 传入的背景颜色: $backgroundColor');

    if (characters.isEmpty) {
      return const Center(
          child: Text('请输入汉字内容', style: TextStyle(color: Colors.grey)));
    }

    // 获取可用区域大小
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    // 处理换行符并创建字符列表
    List<String> charList = [];
    List<bool> isNewLineList = []; // 标记每个字符是否是换行符后的第一个字符

    // 按行分割文本
    final lines = characters.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // 添加当前行的所有字符
      final lineChars = line.characters.toList();
      charList.addAll(lineChars);

      // 为当前行的字符添加标记（第一个字符是换行后的第一个字符，如果不是第一行）
      isNewLineList.addAll(
          List.generate(lineChars.length, (index) => index == 0 && i > 0));

      // 如果不是最后一行，添加一个换行标记
      if (i < lines.length - 1) {
        isNewLineList.add(true);
        charList.add('\n'); // 添加换行符作为占位符
      }
    }

    // 确定布局方向
    final isHorizontal = writingMode.startsWith('horizontal');
    final isLeftToRight = writingMode.endsWith('l');

    // 解析颜色
    final parsedFontColor = _parseColor(fontColor);
    final parsedBackgroundColor = _parseColor(backgroundColor);

    debugPrint('解析后的字体颜色: $parsedFontColor');
    debugPrint('解析后的背景颜色: $parsedBackgroundColor');

    // 计算每个字符的位置
    final List<_CharacterPosition> positions = _calculateCharacterPositions(
      charList: charList,
      isHorizontal: isHorizontal,
      isLeftToRight: isLeftToRight,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      lineSpacing: lineSpacing,
      textAlign: textAlign,
      verticalAlign: verticalAlign,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
      isNewLineList: isNewLineList,
      fontColor: parsedFontColor,
      backgroundColor: parsedBackgroundColor,
    );

    // 使用StatefulBuilder来支持重绘
    return StatefulBuilder(
      builder: (context, setState) {
        // 创建自定义绘制器
        final painter = _CollectionPainter(
          characters: charList,
          positions: positions,
          fontSize: fontSize,
          characterImages: characterImages,
          ref: ref,
        );

        // 设置重绘回调
        painter.setRepaintCallback(() {
          setState(() {});
        });

        // 添加调试信息
        debugPrint('创建集字绘制器: ref=${ref != null ? "非空" : "为空"}');

        return CustomPaint(
          size: Size(availableWidth, availableHeight),
          painter: painter,
        );
      },
    );
  }

  /// 计算字符位置
  static List<_CharacterPosition> _calculateCharacterPositions({
    required List<String> charList,
    required bool isHorizontal,
    required bool isLeftToRight,
    required double fontSize,
    required double letterSpacing,
    required double lineSpacing,
    required String textAlign,
    required String verticalAlign,
    required double availableWidth,
    required double availableHeight,
    List<bool>? isNewLineList,
    Color fontColor = Colors.black,
    Color backgroundColor = Colors.transparent,
  }) {
    final List<_CharacterPosition> positions = [];

    if (charList.isEmpty) return positions;

    // 字符尺寸（假设是正方形）
    final charSize = fontSize;

    if (isHorizontal) {
      // 水平布局的计算逻辑
      // 计算每行可容纳的字符数
      final charsPerRow =
          ((availableWidth + letterSpacing) / (charSize + letterSpacing))
              .floor();
      if (charsPerRow <= 0) return positions;

      // 创建一个新的字符列表，去除换行符，但记录每个字符的行号
      List<String> processedChars = [];
      List<int> rowIndices = []; // 每个字符所在的行号

      if (isNewLineList != null && isNewLineList.isNotEmpty) {
        // 使用换行标记处理
        int currentRow = 0;
        for (int i = 0; i < charList.length; i++) {
          if (charList[i] == '\n') {
            // 遇到换行符，增加行号但不添加到处理后的字符列表
            currentRow++;
          } else {
            // 普通字符，添加到处理后的字符列表
            processedChars.add(charList[i]);
            rowIndices.add(currentRow);
          }
        }
      } else {
        // 没有换行标记，按照原来的逻辑处理
        processedChars = List.from(charList);
        for (int i = 0; i < processedChars.length; i++) {
          rowIndices.add(i ~/ charsPerRow);
        }
      }

      // 计算行数（使用最大行号+1）
      final rowCount = rowIndices.isEmpty ? 0 : rowIndices.reduce(max) + 1;

      // 计算实际使用的高度和有效行间距
      double effectiveLineSpacing = lineSpacing;
      final usedHeight = min(availableHeight,
          rowCount * charSize + (rowCount - 1) * effectiveLineSpacing);

      // 计算起始位置（考虑对齐方式）
      double startY = 0;
      switch (verticalAlign) {
        case 'top':
          startY = 0;
          break;
        case 'middle':
          startY = (availableHeight - usedHeight) / 2;
          break;
        case 'bottom':
          startY = availableHeight - usedHeight;
          break;
        case 'justify':
          // 如果行数大于1，则均匀分布
          if (rowCount > 1) {
            effectiveLineSpacing =
                (availableHeight - rowCount * charSize) / (rowCount - 1);
          }
          startY = 0;
          break;
      }

      // 遍历每个字符，计算位置
      for (int i = 0; i < processedChars.length; i++) {
        // 计算每个字符的位置
        final rowIndex = rowIndices[i];

        // 计算每行的字符数
        int charsInCurrentRow = rowIndices.where((r) => r == rowIndex).length;

        // 计算行宽
        final rowWidth = charsInCurrentRow * charSize +
            (charsInCurrentRow - 1) * letterSpacing;

        // 计算水平起始位置
        double startX;
        switch (textAlign) {
          case 'left':
            startX = isLeftToRight ? 0 : availableWidth - rowWidth;
            break;
          case 'center':
            startX = (availableWidth - rowWidth) / 2;
            break;
          case 'right':
            startX = isLeftToRight ? availableWidth - rowWidth : 0;
            break;
          case 'justify':
          default:
            startX = isLeftToRight ? 0 : availableWidth - rowWidth;
        }

        // 找到当前字符在当前行中的位置
        int colIndexInRow = 0;
        for (int j = 0; j < i; j++) {
          if (rowIndices[j] == rowIndex) colIndexInRow++;
        }

        // 计算最终位置
        final x = isLeftToRight
            ? startX + colIndexInRow * (charSize + letterSpacing)
            : availableWidth -
                startX -
                (colIndexInRow + 1) * charSize -
                colIndexInRow * letterSpacing;
        final y = startY + rowIndex * (charSize + effectiveLineSpacing);

        positions.add(_CharacterPosition(
          char: processedChars[i],
          x: x,
          y: y,
          size: charSize,
          fontColor: fontColor,
          backgroundColor: backgroundColor,
        ));
      }
    } else {
      // 垂直布局的计算逻辑
      // 创建一个新的字符列表，去除换行符
      List<String> processedChars = [];
      List<int> colIndices = []; // 每个字符所在的列号

      if (isNewLineList != null && isNewLineList.isNotEmpty) {
        // 使用换行标记处理
        int currentCol = 0;
        for (int i = 0; i < charList.length; i++) {
          if (charList[i] == '\n') {
            // 遇到换行符，增加列号但不添加到处理后的字符列表
            currentCol++;
          } else {
            // 普通字符，添加到处理后的字符列表
            processedChars.add(charList[i]);
            colIndices.add(currentCol);
          }
        }
      } else {
        // 没有换行标记，按照原来的逻辑处理
        // 计算每列可容纳的字符数
        final charsPerCol =
            ((availableHeight + letterSpacing) / (charSize + letterSpacing))
                .floor();
        if (charsPerCol <= 0) return positions;

        processedChars = List.from(charList);
        for (int i = 0; i < processedChars.length; i++) {
          colIndices.add(i ~/ charsPerCol);
        }
      }

      // 计算列数（使用最大列号+1）
      final colCount = colIndices.isEmpty ? 0 : colIndices.reduce(max) + 1;

      // 计算实际使用的宽度和有效间距
      double effectiveLineSpacing = lineSpacing;
      final usedWidth = min(availableWidth,
          colCount * charSize + (colCount - 1) * effectiveLineSpacing);

      // 计算起始位置（考虑对齐方式）
      double startX = 0;
      switch (textAlign) {
        case 'left':
          // 对于竖排右起（isLeftToRight=false），左对齐应该是靠右
          startX = isLeftToRight ? 0 : availableWidth - usedWidth;
          break;
        case 'center':
          startX = (availableWidth - usedWidth) / 2;
          break;
        case 'right':
          // 对于竖排右起（isLeftToRight=false），右对齐应该是靠左
          startX = isLeftToRight ? availableWidth - usedWidth : 0;
          break;
        case 'justify':
          if (colCount > 1) {
            effectiveLineSpacing =
                (availableWidth - colCount * charSize) / (colCount - 1);
          }
          startX = 0;
          break;
      }

      // 遍历每个字符，计算位置
      for (int i = 0; i < processedChars.length; i++) {
        final colIndex = colIndices[i];

        // 计算每列的字符数
        int charsInCurrentCol = colIndices.where((c) => c == colIndex).length;

        // 计算列高
        final colHeight = charsInCurrentCol * charSize +
            (charsInCurrentCol - 1) * letterSpacing;

        // 计算垂直起始位置
        double startY;
        switch (verticalAlign) {
          case 'top':
            startY = isLeftToRight ? 0 : 0;
            break;
          case 'middle':
            startY = (availableHeight - colHeight) / 2;
            break;
          case 'bottom':
            startY = availableHeight - colHeight;
            break;
          case 'justify':
          default:
            startY = 0;
        }

        // 找到当前字符在当前列中的位置
        int rowIndexInCol = 0;
        for (int j = 0; j < i; j++) {
          if (colIndices[j] == colIndex) rowIndexInCol++;
        }

        // 计算最终位置
        final x = isLeftToRight
            ? startX + colIndex * (charSize + effectiveLineSpacing)
            : availableWidth -
                startX -
                (colIndex + 1) * charSize -
                colIndex * effectiveLineSpacing;
        final y = startY + rowIndexInCol * (charSize + letterSpacing);

        positions.add(_CharacterPosition(
          char: processedChars[i],
          x: x,
          y: y,
          size: charSize,
          fontColor: fontColor,
          backgroundColor: backgroundColor,
        ));
      }
    }

    return positions;
  }

  /// 解析颜色字符串
  static Color _parseColor(String colorStr) {
    debugPrint('开始解析颜色: "$colorStr"');

    // 处理透明色
    if (colorStr == 'transparent') {
      debugPrint('解析为透明色');
      return Colors.transparent;
    }

    // 处理常见颜色名称
    switch (colorStr.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'cyan':
        return Colors.cyan;
      case 'orange':
        return Colors.orange;
    }

    try {
      // 去除可能的#前缀
      String cleanHex =
          colorStr.startsWith('#') ? colorStr.substring(1) : colorStr;

      debugPrint('清理后的十六进制: "$cleanHex"');

      // 处理不同长度的十六进制颜色
      if (cleanHex.length == 6) {
        // RRGGBB格式，添加完全不透明的Alpha通道
        cleanHex = 'ff$cleanHex';
        debugPrint('6位十六进制，添加不透明Alpha: "$cleanHex"');
      } else if (cleanHex.length == 8) {
        // AARRGGBB格式，已经包含Alpha通道
        debugPrint('8位十六进制，已包含Alpha: "$cleanHex"');
      } else if (cleanHex.length == 3) {
        // RGB格式，扩展为RRGGBB并添加完全不透明的Alpha通道
        cleanHex =
            'ff${cleanHex[0]}${cleanHex[0]}${cleanHex[1]}${cleanHex[1]}${cleanHex[2]}${cleanHex[2]}';
        debugPrint('3位十六进制，扩展并添加Alpha: "$cleanHex"');
      } else {
        debugPrint('⚠️ 无效的颜色格式: "$colorStr" (清理后: "$cleanHex")，使用黑色');
        return Colors.black; // 无效格式，返回黑色
      }

      // 解析十六进制值
      final int colorValue = int.parse(cleanHex, radix: 16);

      // 直接使用Color构造函数创建颜色
      final Color color = Color(colorValue);

      // 使用color.value获取颜色值，然后提取RGBA分量
      final int r = (color.value >> 16) & 0xFF;
      final int g = (color.value >> 8) & 0xFF;
      final int b = color.value & 0xFF;
      final int a = (color.value >> 24) & 0xFF;

      debugPrint('✅ 解析颜色成功: "$colorStr" -> 0x$cleanHex -> $color');
      debugPrint('  - RGBA: ($r, $g, $b, $a)');
      debugPrint(
          '  - 直接获取: (${color.red}, ${color.green}, ${color.blue}, ${color.alpha})');

      return color;
    } catch (e) {
      debugPrint('❌ 解析颜色失败: $e, colorStr: "$colorStr"，使用黑色');
      return Colors.black; // 出错时返回黑色
    }
  }
}

/// 全局图像缓存
class GlobalImageCache {
  // 图像缓存
  static final Map<String, ui.Image> cache = {};

  // 添加图像到缓存
  static void add(String key, ui.Image image) {
    cache[key] = image;
    debugPrint('📦 图像已添加到全局缓存: $key, 当前全局缓存大小: ${cache.length}');
  }

  // 检查缓存中是否有图像
  static bool contains(String key) {
    return cache.containsKey(key);
  }

  // 从缓存中获取图像
  static ui.Image? get(String key) {
    return cache[key];
  }
}

/// 字符位置类
class _CharacterPosition {
  final String char;
  final double x;
  final double y;
  final double size;
  final Color fontColor;
  final Color backgroundColor;

  _CharacterPosition({
    required this.char,
    required this.x,
    required this.y,
    required this.size,
    this.fontColor = Colors.black,
    this.backgroundColor = Colors.transparent,
  });
}

/// 集字绘制器
class _CollectionPainter extends CustomPainter {
  // 图像缓存 - 现在使用全局缓存
  static final Map<String, ui.Image> _imageCache = {};
  // 正在加载的图像
  static final Set<String> _loadingImages = {};
  final List<String> characters;
  final List<_CharacterPosition> positions;
  final double fontSize;

  final dynamic characterImages;

  final WidgetRef? ref;

  // 需要重绘的标志
  bool _needsRepaint = false;

  // 重绘回调
  VoidCallback? _repaintCallback;

  _CollectionPainter({
    required this.characters,
    required this.positions,
    required this.fontSize,
    required this.characterImages,
    this.ref,
  }) {
    // 在初始化时预加载所有字符图片
    if (ref != null) {
      // 使用Future.microtask确保在下一个微任务中执行，避免在构造函数中执行异步操作
      Future.microtask(() {
        // 遍历所有字符位置
        for (final position in positions) {
          // 查找字符对应的图片信息
          final charImage = _findCharacterImage(position.char);

          // 如果找到了图片信息，则加载图片
          if (charImage != null) {
            final characterId = charImage['characterId'].toString();
            final type = charImage['type'] as String;
            final format = charImage['format'] as String;

            // 创建缓存键
            final cacheKey = '$characterId-$type-$format';

            // 如果缓存中没有图像且不在加载中，则启动异步加载
            if (!_imageCache.containsKey(cacheKey) &&
                !_loadingImages.contains(cacheKey)) {
              debugPrint('预加载字符图像: $cacheKey');
              _loadAndCacheImage(characterId, type, format);
            }
          }
        }
      });
    } else {
      debugPrint('无法预加载字符图片: ref 为 null');
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('开始绘制集字元素，字符数量: ${positions.length}');
    debugPrint('characterImages类型: ${characterImages.runtimeType}');

    // 绘制每个字符
    for (final position in positions) {
      // 查找字符对应的图片
      final charImage = _findCharacterImage(position.char);

      if (charImage != null) {
        debugPrint('找到字符 ${position.char} 的图片: $charImage');
        // 绘制图片
        _drawCharacterImage(canvas, position, charImage);
      } else {
        debugPrint('❌ 未找到字符 "${position.char}" 的图片，使用占位符');
        debugPrint('  - 字符索引: ${characters.indexOf(position.char)}');
        debugPrint('  - 位置: (${position.x}, ${position.y})');
        debugPrint('  - 尺寸: ${position.size}x${position.size}');
        // 找不到图片，绘制文本作为占位符
        _drawCharacterText(canvas, position);
      }
    }

    // 如果需要重绘，触发回调
    if (_needsRepaint && _repaintCallback != null) {
      _needsRepaint = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _repaintCallback?.call();
      });
    }
  }

  // 设置重绘回调
  void setRepaintCallback(VoidCallback callback) {
    _repaintCallback = callback;
  }

  @override
  bool shouldRepaint(_CollectionPainter oldDelegate) {
    return oldDelegate.characters != characters ||
        oldDelegate.positions != positions ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.characterImages != characterImages;
  }

  /// 绘制字符图片
  void _drawCharacterImage(
      Canvas canvas, _CharacterPosition position, dynamic charImage) {
    // 创建绘制区域
    final rect = Rect.fromLTWH(
      position.x,
      position.y,
      position.size,
      position.size,
    );

    // 绘制背景
    if (position.backgroundColor != Colors.transparent) {
      final bgPaint = Paint()
        ..color = position.backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, bgPaint);

      // 提取RGB分量进行调试
      final int r = position.backgroundColor.r.toInt();
      final int g = position.backgroundColor.g.toInt();
      final int b = position.backgroundColor.b.toInt();
      final int a = position.backgroundColor.a.toInt();
      debugPrint('  - 背景色RGBA: ($r, $g, $b, $a)');
    }

    // 检查是否有字符图像信息，并且不是临时字符
    if (charImage != null &&
        charImage['characterId'] != null &&
        charImage['type'] != null &&
        charImage['format'] != null &&
        charImage['isTemporary'] != true) {
      // 获取字符图像数据
      final characterId = charImage['characterId'].toString();
      final type = charImage['type'] as String;
      final format = charImage['format'] as String;

      // 获取图片路径
      String imagePath = '';
      if (ref != null) {
        try {
          final storage = ref!.read(initializedStorageProvider);
          // 根据类型和格式构建文件名
          String fileName;
          switch (type) {
            case 'square-binary':
              fileName = '$characterId-square-binary.png';
              break;
            case 'square-transparent':
              fileName = '$characterId-square-transparent.png';
              break;
            case 'square-outline':
              fileName = '$characterId-square-outline.svg';
              break;
            case 'thumbnail':
              fileName = '$characterId-thumbnail.jpg';
              break;
            default:
              fileName = '$characterId-$type.$format';
          }

          // 构建完整路径
          imagePath =
              '${storage.getAppDataPath()}/characters/$characterId/$fileName';
        } catch (e) {
          debugPrint('❌ 获取图片路径失败: $e');
        }
      }

      // 检查是否是替代字符
      final bool isSubstitute = charImage['isSubstitute'] == true;
      final String originalChar =
          charImage['originalChar'] as String? ?? position.char;

      if (isSubstitute) {
        debugPrint('🔄 绘制替代字符 "${position.char}" 图像:');
        debugPrint('  - 原始字符: $originalChar');

        if (charImage.containsKey('substituteKey')) {
          debugPrint('  - 替代键: ${charImage['substituteKey']}');
        }

        if (charImage.containsKey('substituteChar')) {
          debugPrint('  - 替代字符: ${charImage['substituteChar'] ?? '未知'}');
        }

        if (charImage.containsKey('substituteIndex')) {
          debugPrint('  - 替代索引: ${charImage['substituteIndex']}');
        }
      } else {
        debugPrint('🎨 绘制字符 "${position.char}" 图像:');
      }

      debugPrint('  - 字符ID: $characterId');
      debugPrint('  - 图片类型: $type');
      debugPrint('  - 图片格式: $format');
      if (imagePath.isNotEmpty) {
        debugPrint('  - 图片路径: $imagePath');
      }

      // 创建缓存键
      final cacheKey = '$characterId-$type-$format';

      // 首先检查全局缓存 - 使用实际的缓存键检查
      final actualCacheKey = '$characterId-square-binary-png-binary';
      if (GlobalImageCache.contains(cacheKey) ||
          GlobalImageCache.contains(actualCacheKey)) {
        final cacheKeyToUse =
            GlobalImageCache.contains(cacheKey) ? cacheKey : actualCacheKey;
        debugPrint('✅ 使用全局缓存的图像: $cacheKeyToUse (原始键: $cacheKey)');
        // 使用全局缓存的图像
        final image = GlobalImageCache.get(cacheKeyToUse)!;

        // 同时更新本地缓存
        if (!_imageCache.containsKey(cacheKey)) {
          _imageCache[cacheKey] = image;
          debugPrint('📦 从全局缓存复制到本地缓存: $cacheKey');
        }

        final paint = Paint()
          ..filterQuality = FilterQuality.high
          ..isAntiAlias = true;

        final srcRect = Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble());

        // 绘制图像
        canvas.drawImageRect(
          image,
          srcRect,
          rect,
          paint,
        );

        debugPrint('✅ 图像绘制完成: ${image.width}x${image.height}');
      }
      // 然后检查本地缓存
      else if (_imageCache.containsKey(cacheKey)) {
        debugPrint('✅ 使用本地缓存的图像: $cacheKey');
        // 使用本地缓存的图像
        final image = _imageCache[cacheKey]!;

        // 同时更新全局缓存
        if (!GlobalImageCache.contains(cacheKey)) {
          GlobalImageCache.add(cacheKey, image);
          debugPrint('📦 从本地缓存复制到全局缓存: $cacheKey');
        }

        final paint = Paint()
          ..filterQuality = FilterQuality.high
          ..isAntiAlias = true;

        final srcRect = Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble());

        // 绘制图像
        canvas.drawImageRect(
          image,
          srcRect,
          rect,
          paint,
        );

        debugPrint('✅ 图像绘制完成: ${image.width}x${image.height}');
      } else {
        debugPrint('⚠️ 缓存中没有图像: $cacheKey，绘制占位符并启动异步加载');
        debugPrint('  - 字符: "${position.char}"');
        debugPrint('  - 位置: (${position.x}, ${position.y})');
        debugPrint('  - 尺寸: ${position.size}x${position.size}');

        // 如果缓存中没有图像，则绘制占位符并启动异步加载
        _drawPlaceholder(canvas, position);

        // 检查是否已经在加载中
        if (!_loadingImages.contains(cacheKey) && ref != null) {
          debugPrint('🔄 开始加载图像: $cacheKey');
          _loadAndCacheImage(characterId, type, format);
        } else if (_loadingImages.contains(cacheKey)) {
          debugPrint('⏳ 图像正在加载中: $cacheKey');
        } else if (ref == null) {
          debugPrint('❌ 无法加载图像: ref 为 null');
        }
      }
    } else if (charImage != null && charImage['isTemporary'] == true) {
      // 如果是临时字符，显示特殊日志并绘制占位符
      debugPrint('⚠️ 字符 "${position.char}" 是临时字符，绘制占位符');
      debugPrint('  - 临时字符ID: ${charImage['characterId']}');
      _drawPlaceholder(canvas, position);
    } else {
      debugPrint('⚠️ 字符 "${position.char}" 没有有效的图像信息，绘制占位符');
      _drawPlaceholder(canvas, position);
    }
  }

  /// 绘制字符文本
  void _drawCharacterText(Canvas canvas, _CharacterPosition position) {
    debugPrint('📝 绘制字符文本:');
    debugPrint('  - 字符: "${position.char}"');
    debugPrint('  - 位置: (${position.x}, ${position.y})');
    debugPrint('  - 尺寸: ${position.size}x${position.size}');
    debugPrint('  - 字体颜色: ${position.fontColor}');
    debugPrint('  - 背景颜色: ${position.backgroundColor}');

    // 创建绘制区域
    final rect = Rect.fromLTWH(
      position.x,
      position.y,
      position.size,
      position.size,
    );

    // 绘制背景
    if (position.backgroundColor != Colors.transparent) {
      final bgPaint = Paint()
        ..color = position.backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, bgPaint);
      debugPrint('  - 使用自定义背景色: ${position.backgroundColor}');

      // 提取RGB分量进行调试
      final int r = position.backgroundColor.r.toInt();
      final int g = position.backgroundColor.g.toInt();
      final int b = position.backgroundColor.b.toInt();
      final int a = position.backgroundColor.a.toInt();
      debugPrint('  - 背景色RGBA: ($r, $g, $b, $a)');
    } else {
      // 绘制默认占位符背景
      final paint = Paint()
        ..color = Colors.grey.withAlpha(26) // 约等于 0.1 不透明度
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
      debugPrint('  - 使用默认背景色: ${Colors.grey.withAlpha(26)}');
    }

    // 提取字体颜色的RGB分量进行调试
    final int fr = position.fontColor.r.toInt();
    final int fg = position.fontColor.g.toInt();
    final int fb = position.fontColor.b.toInt();
    final int fa = position.fontColor.a.toInt();
    debugPrint('  - 字体颜色RGBA: ($fr, $fg, $fb, $fa)');

    // 绘制字符文本
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

    debugPrint('  - 文本尺寸: ${textPainter.width}x${textPainter.height}');
    debugPrint('  - 文本位置: (${textOffset.dx}, ${textOffset.dy})');

    textPainter.paint(
      canvas,
      textOffset,
    );
  }

  /// 绘制占位符
  void _drawPlaceholder(Canvas canvas, _CharacterPosition position) {
    debugPrint('🔲 绘制占位符:');
    debugPrint('  - 字符: "${position.char}"');
    debugPrint('  - 位置: (${position.x}, ${position.y})');
    debugPrint('  - 尺寸: ${position.size}x${position.size}');
    debugPrint('  - 字体颜色: ${position.fontColor}');
    debugPrint('  - 背景颜色: ${position.backgroundColor}');

    // 创建绘制区域
    final rect = Rect.fromLTWH(
      position.x,
      position.y,
      position.size,
      position.size,
    );

    // 绘制背景
    if (position.backgroundColor != Colors.transparent) {
      final bgPaint = Paint()
        ..color = position.backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, bgPaint);
      debugPrint('  - 使用自定义背景色: ${position.backgroundColor}');

      // 提取RGB分量进行调试
      final int r = position.backgroundColor.r.toInt();
      final int g = position.backgroundColor.g.toInt();
      final int b = position.backgroundColor.b.toInt();
      final int a = position.backgroundColor.a.toInt();
      debugPrint('  - 背景色RGBA: ($r, $g, $b, $a)');
    } else {
      // 绘制默认占位符背景
      final paint = Paint()
        ..color = Colors.grey.withAlpha(77) // 约等于 0.3 不透明度
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
      debugPrint('  - 使用默认背景色: ${Colors.grey.withAlpha(77)}');
    }

    // 提取字体颜色的RGB分量进行调试
    final int fr = position.fontColor.r.toInt();
    final int fg = position.fontColor.g.toInt();
    final int fb = position.fontColor.b.toInt();
    final int fa = position.fontColor.a.toInt();
    debugPrint('  - 字体颜色RGBA: ($fr, $fg, $fb, $fa)');

    // 绘制字符文本作为占位符
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

    debugPrint('  - 文本尺寸: ${textPainter.width}x${textPainter.height}');
    debugPrint('  - 文本位置: (${textOffset.dx}, ${textOffset.dy})');

    textPainter.paint(
      canvas,
      textOffset,
    );
  }

  /// 查找字符对应的图片
  dynamic _findCharacterImage(String char) {
    try {
      debugPrint('🔍 查找字符 "$char" 的图片:');
      debugPrint('  - characterImages类型: ${characterImages.runtimeType}');

      // 检查 characterImages 是否是 Map 类型
      if (characterImages is Map<String, dynamic>) {
        // 如果是 Map 类型，则直接查找字符索引
        final charImages = characterImages as Map<String, dynamic>;
        debugPrint('  - characterImages是Map类型，包含 ${charImages.length} 个键');
        debugPrint('  - characterImages键: ${charImages.keys.toList()}');

        // 尝试直接用字符作为键查找
        if (charImages.containsKey(char)) {
          final imageInfo = charImages[char] as Map<String, dynamic>;
          debugPrint('✅ 直接使用字符 "$char" 作为键找到图像信息: $imageInfo');

          // 优先使用绘制格式（如果有），否则优先使用方形二值化图，其次是方形SVG轮廓
          return {
            'characterId': imageInfo['characterId'],
            'type': imageInfo['drawingType'] ?? 'square-binary', // 优先使用绘制格式
            'format': imageInfo['drawingFormat'] ?? 'png-binary',
          };
        }

        // 查找当前字符在集字内容中的索引
        int charIndex = -1;
        for (int i = 0; i < characters.length; i++) {
          if (characters[i] == char) {
            charIndex = i;
            break;
          }
        }
        debugPrint('  - 字符 "$char" 在集字内容中的索引: $charIndex');

        // 如果找到了字符索引，则查找对应的图像信息
        if (charIndex >= 0) {
          // 直接在 charImages 中查找字符索引
          if (charImages.containsKey('$charIndex')) {
            final imageInfo = charImages['$charIndex'] as Map<String, dynamic>;
            debugPrint('✅ 在charImages中找到索引 $charIndex 的图像信息: $imageInfo');

            // 优先使用绘制格式（如果有），否则优先使用方形二值化图，其次是方形SVG轮廓
            return {
              'characterId': imageInfo['characterId'],
              'type': imageInfo['drawingType'] ?? 'square-binary', // 优先使用绘制格式
              'format': imageInfo['drawingFormat'] ?? 'png-binary',
            };
          }
          debugPrint('  - 在charImages中未找到索引 "$charIndex" 的图像信息');

          // 兼容旧格式：检查是否有 characterImages 子 Map
          if (charImages.containsKey('characterImages')) {
            final images =
                charImages['characterImages'] as Map<String, dynamic>?;
            debugPrint('  - 检查characterImages子Map: ${images?.keys.toList()}');

            // 尝试直接用字符作为键查找
            if (images != null && images.containsKey(char)) {
              final imageInfo = images[char] as Map<String, dynamic>;
              debugPrint(
                  '✅ 在characterImages子Map中直接使用字符 "$char" 作为键找到图像信息: $imageInfo');

              // 优先使用绘制格式（如果有），否则优先使用方形二值化图，其次是方形SVG轮廓
              return {
                'characterId': imageInfo['characterId'],
                'type': imageInfo['drawingType'] ?? 'square-binary', // 优先使用绘制格式
                'format': imageInfo['drawingFormat'] ?? 'png-binary',
              };
            }

            if (images != null && images.containsKey('$charIndex')) {
              final imageInfo = images['$charIndex'] as Map<String, dynamic>;
              debugPrint(
                  '✅ 在characterImages子Map中找到索引 $charIndex 的图像信息: $imageInfo');

              // 优先使用绘制格式（如果有），否则优先使用方形二值化图，其次是方形SVG轮廓
              return {
                'characterId': imageInfo['characterId'],
                'type': imageInfo['drawingType'] ?? 'square-binary', // 优先使用绘制格式
                'format': imageInfo['drawingFormat'] ?? 'png-binary',
              };
            }
          }

          // 检查是否有 content.characterImages 结构
          if (charImages.containsKey('content')) {
            final content = charImages['content'] as Map<String, dynamic>?;
            if (content != null && content.containsKey('characterImages')) {
              final images =
                  content['characterImages'] as Map<String, dynamic>?;
              debugPrint(
                  '  - 检查content.characterImages: ${images?.keys.toList()}');

              // 尝试直接用字符作为键查找
              if (images != null && images.containsKey(char)) {
                final imageInfo = images[char] as Map<String, dynamic>;
                debugPrint(
                    '✅ 在content.characterImages中直接使用字符 "$char" 作为键找到图像信息: $imageInfo');

                // 优先使用绘制格式（如果有），否则优先使用方形二值化图，其次是方形SVG轮廓
                return {
                  'characterId': imageInfo['characterId'],
                  'type':
                      imageInfo['drawingType'] ?? 'square-binary', // 优先使用绘制格式
                  'format': imageInfo['drawingFormat'] ?? 'png-binary',
                };
              }

              if (images != null && images.containsKey('$charIndex')) {
                final imageInfo = images['$charIndex'] as Map<String, dynamic>;
                debugPrint(
                    '✅ 在content.characterImages中找到索引 $charIndex 的图像信息: $imageInfo');

                // 优先使用绘制格式（如果有），否则优先使用方形二值化图，其次是方形SVG轮廓
                return {
                  'characterId': imageInfo['characterId'],
                  'type':
                      imageInfo['drawingType'] ?? 'square-binary', // 优先使用绘制格式
                  'format': imageInfo['drawingFormat'] ?? 'png-binary',
                };
              }
            }
          }
        }

        // 不再尝试查找替代字符，直接返回null
        debugPrint('❌ 未找到字符 "$char" 的图像信息，将使用占位图');
        return null;
      } else if (characterImages is List) {
        // 如果是 List 类型，则遍历查找
        final charImagesList = characterImages as List;
        debugPrint('  - characterImages是List类型，长度: ${charImagesList.length}');

        for (int i = 0; i < charImagesList.length; i++) {
          final image = charImagesList[i];
          debugPrint('  - 检查列表项 $i: $image');

          if (image is Map<String, dynamic>) {
            // 检查是否有字符信息
            if (image.containsKey('character') && image['character'] == char) {
              // 检查是否有字符图像信息
              if (image.containsKey('characterId')) {
                debugPrint('✅ 在List中找到字符 "$char" 的图像信息: $image');
                // 优先使用绘制格式（如果有），否则优先使用方形二值化图，其次是方形SVG轮廓
                return {
                  'characterId': image['characterId'],
                  'type':
                      image['drawingType'] ?? image['type'] ?? 'square-binary',
                  'format':
                      image['drawingFormat'] ?? image['format'] ?? 'png-binary',
                };
              }
            }
          }
        }
        debugPrint('❌ 在List中未找到字符 "$char" 的图像信息');
      } else {
        debugPrint('❌ characterImages类型不支持: ${characterImages.runtimeType}');
      }
    } catch (e, stack) {
      debugPrint('❌ 查找字符图像失败: $e');
      debugPrint('  - 堆栈: $stack');
    }

    debugPrint('❌ 未找到字符 "$char" 的图像信息，返回null');
    return null;
  }

  /// 加载并缓存图像
  void _loadAndCacheImage(
      String characterId, String type, String format) async {
    final cacheKey = '$characterId-$type-$format';

    // 首先检查全局缓存 - 使用实际的缓存键检查
    final actualCacheKey = '$characterId-square-binary-png-binary';
    if (GlobalImageCache.contains(cacheKey) ||
        GlobalImageCache.contains(actualCacheKey)) {
      final cacheKeyToUse =
          GlobalImageCache.contains(cacheKey) ? cacheKey : actualCacheKey;
      debugPrint('✅ 图像已存在于全局缓存中: $cacheKeyToUse (原始键: $cacheKey)');

      // 从全局缓存复制到本地缓存
      if (!_imageCache.containsKey(cacheKey)) {
        _imageCache[cacheKey] = GlobalImageCache.get(cacheKeyToUse)!;
        debugPrint('📦 从全局缓存复制到本地缓存: $cacheKey (源键: $cacheKeyToUse)');

        // 标记需要重绘
        _needsRepaint = true;
        debugPrint('🔄 标记需要重绘: $cacheKey');
      }
      return;
    }

    // 标记为正在加载
    _loadingImages.add(cacheKey);
    debugPrint('🔄 开始加载字符图像:');
    debugPrint('  - 字符ID: $characterId');
    debugPrint('  - 图片类型: $type');
    debugPrint('  - 图片格式: $format');
    debugPrint('  - 缓存键: $cacheKey');

    try {
      // 加载图像数据
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
      debugPrint('📋 检查可用格式: $characterId');
      final availableFormat =
          await characterImageService.getAvailableFormat(characterId);
      if (availableFormat != null) {
        preferredType = availableFormat['type']!;
        preferredFormat = availableFormat['format']!;
        debugPrint('✅ 获取到可用格式:');
        debugPrint('  - 类型: $preferredType');
        debugPrint('  - 格式: $preferredFormat');
      } else {
        debugPrint('⚠️ 未获取到可用格式，使用默认格式:');
        debugPrint('  - 类型: $preferredType');
        debugPrint('  - 格式: $preferredFormat');
      }

      // 获取图片路径
      final imagePath =
          getImagePath(characterId, preferredType, preferredFormat);
      debugPrint('📁 图片路径: $imagePath');

      debugPrint('📥 调用 characterImageService.getCharacterImage:');
      debugPrint('  - 字符ID: $characterId');
      debugPrint('  - 类型: $preferredType');
      debugPrint('  - 格式: $preferredFormat');

      final imageData = await characterImageService.getCharacterImage(
          characterId, preferredType, preferredFormat);

      // 更新缓存键以使用实际加载的类型和格式
      final actualCacheKey = '$characterId-$preferredType-$preferredFormat';

      if (imageData != null) {
        debugPrint('✅ 成功获取字符图像数据:');
        debugPrint('  - 缓存键: $actualCacheKey');
        debugPrint('  - 大小: ${imageData.length} 字节');

        // 解码图像
        final completer = Completer<ui.Image>();
        debugPrint('🔄 开始解码图像数据: $actualCacheKey');
        ui.decodeImageFromList(imageData, (ui.Image image) {
          debugPrint('✅ 图像解码完成:');
          debugPrint('  - 缓存键: $actualCacheKey');
          debugPrint('  - 尺寸: ${image.width}x${image.height}');
          completer.complete(image);
        });

        final image = await completer.future;
        debugPrint('✅ 图像解码完成并获取到 future 结果: $actualCacheKey');

        // 缓存图像到本地缓存
        _imageCache[actualCacheKey] = image;

        // 同时缓存到全局缓存
        GlobalImageCache.add(actualCacheKey, image);

        // 同时缓存到原始请求的键，以便能找到图像
        if (cacheKey != actualCacheKey) {
          _imageCache[cacheKey] = image;
          GlobalImageCache.add(cacheKey, image);
          debugPrint('📦 同时缓存到原始请求键: $cacheKey');
        }

        debugPrint('📦 图像已缓存:');
        debugPrint('  - 缓存键: $actualCacheKey');
        debugPrint('  - 本地缓存大小: ${_imageCache.length}');
        debugPrint('  - 全局缓存大小: ${GlobalImageCache.cache.length}');

        // 标记需要重绘
        _needsRepaint = true;
        debugPrint('🔄 标记需要重绘: $actualCacheKey');
      } else {
        debugPrint('❌ 获取字符图像数据失败:');
        debugPrint('  - 缓存键: $actualCacheKey');
        debugPrint('  - 图片路径: $imagePath');
        debugPrint('  - 返回值: null');
      }
    } catch (e) {
      debugPrint('❌ 加载字符图像失败:');
      debugPrint('  - 缓存键: $cacheKey');
      debugPrint('  - 错误: $e');
    } finally {
      // 移除加载标记
      _loadingImages.remove(cacheKey);
      debugPrint('🔄 移除加载标记:');
      debugPrint('  - 缓存键: $cacheKey');
      debugPrint('  - 当前加载中的图像数量: ${_loadingImages.length}');
    }
  }
}
