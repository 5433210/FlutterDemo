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
    bool enableSoftLineBreak = false,
    WidgetRef? ref,
  }) {
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
      enableSoftLineBreak: enableSoftLineBreak,
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
    bool enableSoftLineBreak = false,
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
        int charCountInCurrentRow = 0; // 当前行已有字符数

        for (int i = 0; i < charList.length; i++) {
          if (charList[i] == '\n') {
            // 遇到换行符，增加行号但不添加到处理后的字符列表
            currentRow++;
            charCountInCurrentRow = 0;
          } else {
            // 普通字符
            processedChars.add(charList[i]);

            // 如果启用软回车且当前行字符数已达到最大值，则自动换行
            if (enableSoftLineBreak &&
                charCountInCurrentRow >= charsPerRow &&
                charsPerRow > 0) {
              currentRow++;
              charCountInCurrentRow = 0;
            }

            rowIndices.add(currentRow);
            charCountInCurrentRow++;
          }
        }
      } else {
        // 没有换行标记，按照原来的逻辑处理
        processedChars = List.from(charList);
        if (enableSoftLineBreak && charsPerRow > 0) {
          // 启用软回车时，按照每行最大字符数自动分配行号
          for (int i = 0; i < processedChars.length; i++) {
            rowIndices.add(i ~/ charsPerRow);
          }
        } else {
          // 不启用软回车时，所有字符在同一行
          rowIndices = List.filled(processedChars.length, 0);
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
        double effectiveLetterSpacing = letterSpacing;
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
            // 两端对齐：如果字符数大于1，则均匀分布字符间距
            if (charsInCurrentRow > 1) {
              effectiveLetterSpacing =
                  (availableWidth - charsInCurrentRow * charSize) /
                      (charsInCurrentRow - 1);
            }
            startX = isLeftToRight ? 0 : 0;
            break;
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
            ? startX + colIndexInRow * (charSize + effectiveLetterSpacing)
            : availableWidth -
                startX -
                (colIndexInRow + 1) * charSize -
                colIndexInRow * effectiveLetterSpacing;
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
      // 计算每列可容纳的字符数（如果启用软回车）
      final charsPerCol =
          ((availableHeight + letterSpacing) / (charSize + letterSpacing))
              .floor();

      // 创建一个新的字符列表，去除换行符
      List<String> processedChars = [];
      List<int> colIndices = []; // 每个字符所在的列号

      if (isNewLineList != null && isNewLineList.isNotEmpty) {
        // 使用换行标记处理
        int currentCol = 0;
        int charCountInCurrentCol = 0; // 当前列已有字符数

        for (int i = 0; i < charList.length; i++) {
          if (charList[i] == '\n') {
            // 遇到换行符，增加列号但不添加到处理后的字符列表
            currentCol++;
            charCountInCurrentCol = 0;
          } else {
            // 普通字符
            processedChars.add(charList[i]);

            // 如果启用软回车且当前列字符数已达到最大值，则自动换列
            if (enableSoftLineBreak &&
                charCountInCurrentCol >= charsPerCol &&
                charsPerCol > 0) {
              currentCol++;
              charCountInCurrentCol = 0;
            }

            colIndices.add(currentCol);
            charCountInCurrentCol++;
          }
        }
      } else {
        // 没有换行标记，按照原来的逻辑处理
        processedChars = List.from(charList);
        if (enableSoftLineBreak && charsPerCol > 0) {
          // 启用软回车时，按照每列最大字符数自动分配列号
          for (int i = 0; i < processedChars.length; i++) {
            colIndices.add(i ~/ charsPerCol);
          }
        } else {
          // 不启用软回车时，所有字符在同一列
          colIndices = List.filled(processedChars.length, 0);
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
        double effectiveLetterSpacing = letterSpacing;
        switch (verticalAlign) {
          case 'top':
            startY = 0;
            break;
          case 'middle':
            startY = (availableHeight - colHeight) / 2;
            break;
          case 'bottom':
            startY = availableHeight - colHeight;
            break;
          case 'justify':
            // 垂直两端对齐：如果字符数大于1，则均匀分布字符间距
            if (charsInCurrentCol > 1) {
              effectiveLetterSpacing =
                  (availableHeight - charsInCurrentCol * charSize) /
                      (charsInCurrentCol - 1);
            }
            startY = 0;
            break;
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
        final y = startY + rowIndexInCol * (charSize + effectiveLetterSpacing);

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
    // 处理透明色
    if (colorStr == 'transparent') {
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

      // 处理不同长度的十六进制颜色
      if (cleanHex.length == 6) {
        // RRGGBB格式，添加完全不透明的Alpha通道
        cleanHex = 'ff$cleanHex';
      } else if (cleanHex.length == 8) {
        // AARRGGBB格式，已经包含Alpha通道
      } else if (cleanHex.length == 3) {
        // RGB格式，扩展为RRGGBB并添加完全不透明的Alpha通道
        cleanHex =
            'ff${cleanHex[0]}${cleanHex[0]}${cleanHex[1]}${cleanHex[1]}${cleanHex[2]}${cleanHex[2]}';
      } else {
        return Colors.black; // 无效格式，返回黑色
      }

      // 解析十六进制值
      final int colorValue = int.parse(cleanHex, radix: 16);

      // 直接使用Color构造函数创建颜色
      final Color color = Color(colorValue);

      return color;
    } catch (e) {
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
        var positionIndex = 0;

        for (var characterIndex = 0;
            characterIndex < characters.length;
            characterIndex++) {
          // 查找字符对应的图片信息
          if (characters[characterIndex] == '\n') {
            continue;
          }
          if (positionIndex >= positions.length) {
            break;
          }
          final charImage = _findCharacterImage(
              positions[positionIndex].char, characterIndex);

          positionIndex++;
          characterIndex++;

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
              _loadAndCacheImage(characterId, type, format);
            }
          }
        }
      });
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 添加裁剪区域，限制在画布范围内
    final clipRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(clipRect);

    // 绘制每个字符
    var positionIndex = 0;
    var characterIndex = 0;
    for (final chararcter in characters) {
      if (chararcter == '\n') {
        characterIndex++;
        continue;
      }
      // 查找字符对应的图片
      if (positionIndex >= positions.length) {
        break;
      }
      final position = positions[positionIndex];
      final charImage =
          _findCharacterImage(positions[positionIndex].char, characterIndex);
      positionIndex++;
      characterIndex++;

      if (charImage != null) {
        // 绘制图片
        _drawCharacterImage(canvas, position, charImage);
      } else {
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

      // 获取是否需要反转显示 - 先检查transform属性
      bool invertDisplay = false;
      if (charImage.containsKey('transform') &&
          charImage['transform'] is Map<String, dynamic>) {
        final transform = charImage['transform'] as Map<String, dynamic>;
        invertDisplay = transform['invert'] == true;
      } else if (charImage.containsKey('invert')) {
        // 直接检查invert属性
        invertDisplay = charImage['invert'] == true;
      }

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
          // 处理错误
        }
      }

      // 检查是否是替代字符
      final bool isSubstitute = charImage['isSubstitute'] == true;
      final String originalChar =
          charImage['originalChar'] as String? ?? position.char;

      // 创建缓存键
      final cacheKey = '$characterId-$type-$format';

      // 首先检查全局缓存 - 使用实际的缓存键检查
      final actualCacheKey = '$characterId-square-binary-png-binary';
      if (GlobalImageCache.contains(cacheKey) ||
          GlobalImageCache.contains(actualCacheKey)) {
        final cacheKeyToUse =
            GlobalImageCache.contains(cacheKey) ? cacheKey : actualCacheKey;
        // 使用全局缓存的图像
        final image = GlobalImageCache.get(cacheKeyToUse)!;

        // 同时更新本地缓存
        if (!_imageCache.containsKey(cacheKey)) {
          _imageCache[cacheKey] = image;
        }

        // 准备绘制
        final paint = Paint()
          ..filterQuality = FilterQuality.high
          ..isAntiAlias = true;

        // 获取图像源矩形
        final srcRect = Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble());

        // 检查是否需要应用颜色处理
        final bool needsColorProcessing =
            position.fontColor != Colors.black || invertDisplay;

        // 如果不需要任何颜色处理，直接绘制原始图像
        if (!needsColorProcessing) {
          canvas.drawImageRect(image, srcRect, rect, paint);
          return;
        }

        // 需要进行颜色处理
        canvas.saveLayer(rect, Paint());

        if (invertDisplay) {
          // 步骤1：首先用字体颜色填充整个区域
          canvas.drawRect(rect, Paint()..color = position.fontColor);

          // 步骤2：使用原始图像作为遮罩，通过BlendMode.dstOut混合模式实现反转
          // 这会使原图中黑色部分将字体颜色"挖空"（变透明），而原来透明的部分保持字体颜色
          final maskPaint = Paint()..blendMode = BlendMode.dstOut;
          canvas.drawImageRect(image, srcRect, rect, maskPaint);
        } else {
          // 标准处理：直接将黑色替换为字体颜色
          if (type.contains('binary') && format.contains('binary')) {
            // 1. 首先绘制原始图像
            canvas.drawImageRect(image, srcRect, rect, Paint());

            // 2. 使用BlendMode.srcIn将黑色部分替换为字体颜色
            // 这种方法比使用ColorFilter.matrix更高效
            final colorPaint = Paint()
              ..color = position.fontColor
              ..blendMode = BlendMode.srcIn;

            canvas.drawRect(rect, colorPaint);
          } else {
            // 非二值图像，直接绘制
            canvas.drawImageRect(image, srcRect, rect, paint);
          }
        }

        // 完成绘制
        canvas.restore();
      }
    }
  }

  /// 绘制字符文本
  void _drawCharacterText(Canvas canvas, _CharacterPosition position) {
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
    } else {
      // 绘制默认占位符背景
      final paint = Paint()
        ..color = Colors.grey.withAlpha(26) // 约等于 0.1 不透明度
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
    }

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

    textPainter.paint(
      canvas,
      textOffset,
    );
  }

  /// 查找字符对应的图片
  dynamic _findCharacterImage(String char, int positionIndex) {
    try {
      // 检查 characterImages 是否是 Map 类型
      if (characterImages is Map<String, dynamic>) {
        // 如果是 Map 类型，则直接查找字符索引
        final charImages = characterImages as Map<String, dynamic>;

        // 查找当前字符在集字内容中的索引
        int charIndex = -1;
        for (int i = 0; i < characters.length; i++) {
          if (characters[i] == char && i == positionIndex) {
            charIndex = i;
            break;
          }
        }

        // 如果找到了字符索引，则查找对应的图像信息
        if (charIndex >= 0) {
          // 直接在 charImages 中查找字符索引
          if (charImages.containsKey('$charIndex')) {
            final imageInfo = charImages['$charIndex'] as Map<String, dynamic>;

            // 优先使用绘制格式（如果有），否则优先使用方形二值化图，其次是方形SVG轮廓
            return {
              'characterId': imageInfo['characterId'],
              'type': imageInfo['drawingType'] ?? 'square-binary', // 优先使用绘制格式
              'format': imageInfo['drawingFormat'] ?? 'png-binary',
              'transform': imageInfo['transform'],
            };
          }

          // 检查是否有 content.characterImages 结构
          if (charImages.containsKey('content')) {
            final content = charImages['content'] as Map<String, dynamic>?;
            if (content != null && content.containsKey('characterImages')) {
              final images =
                  content['characterImages'] as Map<String, dynamic>?;

              if (images != null && images.containsKey('$charIndex')) {
                final imageInfo = images['$charIndex'] as Map<String, dynamic>;

                // 优先使用绘制格式（如果有），否则优先使用方形二值化图，其次是方形SVG轮廓
                final result = {
                  'characterId': imageInfo['characterId'],
                  'type':
                      imageInfo['drawingType'] ?? 'square-binary', // 优先使用绘制格式
                  'format': imageInfo['drawingFormat'] ?? 'png-binary',
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
        }

        return null;
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
                // 优先使用绘制格式（如果有），否则优先使用方形二值化图，其次是方形SVG轮廓
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
    } catch (e, stack) {
      // 错误处理
    }

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

      // 从全局缓存复制到本地缓存
      if (!_imageCache.containsKey(cacheKey)) {
        _imageCache[cacheKey] = GlobalImageCache.get(cacheKeyToUse)!;

        // 标记需要重绘
        _needsRepaint = true;
      }
      return;
    }

    // 标记为正在加载
    _loadingImages.add(cacheKey);

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
      final availableFormat =
          await characterImageService.getAvailableFormat(characterId);
      if (availableFormat != null) {
        preferredType = availableFormat['type']!;
        preferredFormat = availableFormat['format']!;
      }

      // 获取图片路径
      final imagePath =
          getImagePath(characterId, preferredType, preferredFormat);

      final imageData = await characterImageService.getCharacterImage(
          characterId, preferredType, preferredFormat);

      // 更新缓存键以使用实际加载的类型和格式
      final actualCacheKey = '$characterId-$preferredType-$preferredFormat';

      if (imageData != null) {
        // 解码图像
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(imageData, (ui.Image image) {
          completer.complete(image);
        });

        final image = await completer.future;

        // 缓存图像到本地缓存
        _imageCache[actualCacheKey] = image;

        // 同时缓存到全局缓存
        GlobalImageCache.add(actualCacheKey, image);

        // 同时缓存到原始请求的键，以便能找到图像
        if (cacheKey != actualCacheKey) {
          _imageCache[cacheKey] = image;
          GlobalImageCache.add(cacheKey, image);
        }

        // 标记需要重绘
        _needsRepaint = true;
      }
    } catch (e) {
      // 错误处理
    } finally {
      // 移除加载标记
      _loadingImages.remove(cacheKey);
    }
  }
}
