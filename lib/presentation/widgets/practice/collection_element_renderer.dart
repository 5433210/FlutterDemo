// filepath: c:\Users\wailik\Documents\Code\Flutter\demo\demo\lib\presentation\widgets\practice\collection_element_renderer.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../infrastructure/providers/storage_providers.dart';
import 'texture_painters.dart';

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
    bool enableSoftLineBreak = false, // 纹理相关属性
    bool hasCharacterTexture = false,
    Map<String, dynamic>? characterTextureData,
    String textureFillMode = 'repeat',
    double textureOpacity = 1.0,
    String applicationMode =
        'character', // Added explicit applicationMode parameter
    WidgetRef? ref,
  }) {
    if (characters.isEmpty) {
      return const Center(
          child: Text('请输入汉字内容', style: TextStyle(color: Colors.grey)));
    }

    // 获取可用区域大小，扣减内边距
    final availableWidth = constraints.maxWidth - padding * 2;
    final availableHeight = constraints.maxHeight - padding * 2;

    // 添加调试信息
    debugPrint('''集字布局初始化:
  原始尺寸: ${constraints.maxWidth}x${constraints.maxHeight}
  内边距: $padding
  可用尺寸: ${availableWidth}x$availableHeight''');

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
        // 解析纹理应用范围
        String effectiveApplicationMode = applicationMode;
        bool hasNestedTexture = false;
        Map<String, dynamic>? nestedTextureData;
        bool hasEffectiveTexture = hasCharacterTexture;

        if (characterImages is Map<String, dynamic>) {
          // 首先检查主 content 中的应用范围设置
          if (characterImages.containsKey('textureApplicationRange')) {
            applicationMode =
                characterImages['textureApplicationRange'] as String? ??
                    'character';
            debugPrint('使用主content的纹理应用范围: $applicationMode');
          }

          final content = characterImages['content'] as Map<String, dynamic>?;
          if (content != null) {
            // 仅当主content没有设置时，才使用嵌套content的应用范围
            if (!characterImages.containsKey('textureApplicationRange')) {
              applicationMode =
                  content['textureApplicationRange'] as String? ?? 'character';
              debugPrint('使用嵌套content的纹理应用范围: $applicationMode');
            }

            // 检查嵌套内容中是否有纹理数据
            if (content.containsKey('backgroundTexture') &&
                content['backgroundTexture'] != null) {
              final backgroundTexture = content['backgroundTexture'];
              if (backgroundTexture != null &&
                  backgroundTexture is Map<String, dynamic>) {
                hasNestedTexture = true;
                nestedTextureData = backgroundTexture;
                hasEffectiveTexture = true;
                debugPrint('发现有效的嵌套纹理数据: $nestedTextureData');
              }
            }
          }
        } // 创建纹理配置，优先使用显式传入的应用模式参数
        final textureConfig = TextureConfig(
          enabled: hasEffectiveTexture &&
              (characterTextureData != null || nestedTextureData != null),
          data: characterTextureData ?? nestedTextureData,
          fillMode: textureFillMode,
          opacity: textureOpacity,
          applicationMode: effectiveApplicationMode,
        );

        debugPrint('''🎨 纹理配置详情:
  启用状态: ${hasEffectiveTexture ? "✅" : "❌"}
  纹理数据: ${(characterTextureData != null || nestedTextureData != null) ? "✅" : "❌"}
  应用模式: $effectiveApplicationMode
  填充模式: $textureFillMode
  不透明度: $textureOpacity''');
        debugPrint('''创建集字绘制器 (详细):
  纹理状态: ${textureConfig.enabled ? "启用" : "禁用"}
  纹理数据: ${textureConfig.data != null ? "有效" : "无效"}
  填充模式: ${textureConfig.fillMode}
  不透明度: ${textureConfig.opacity}
  应用模式: ${textureConfig.applicationMode}
  hasCharacterTexture: $hasCharacterTexture
  hasNestedTexture: $hasNestedTexture
  characterTextureData: $characterTextureData
  nestedTextureData: $nestedTextureData'''); // 创建自定义绘制器
        final painter = _CollectionPainter(
          characters: charList,
          positions: positions,
          fontSize: fontSize,
          characterImages: characterImages,
          textureConfig: textureConfig,
          ref: ref,
        );

        // 设置重绘回调
        painter.setRepaintCallback(() {
          setState(() {});
        });

        // 创建容器并应用尺寸约束
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: CustomPaint(
            // 使用已配置好重绘回调的painter
            painter: painter,
            // 确保子组件不会超出绘制区域
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: const SizedBox.expand(),
            ),
          ),
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

/// 集字绘制器
/// 统一的纹理配置
class TextureConfig {
  final bool enabled;
  final Map<String, dynamic>? data;
  final String fillMode;
  final double opacity;
  final String applicationMode;

  const TextureConfig({
    this.enabled = false,
    this.data,
    this.fillMode = 'repeat',
    this.opacity = 1.0,
    this.applicationMode = 'character',
  });

  @override
  int get hashCode {
    return Object.hash(
        enabled,
        fillMode,
        opacity,
        applicationMode,
        // Use a simple hash for the data map
        data?.length ?? 0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextureConfig) return false;

    return other.enabled == enabled &&
        other.fillMode == fillMode &&
        other.opacity == opacity &&
        other.applicationMode == applicationMode &&
        _mapsEqual(other.data, data);
  }

  bool _mapsEqual(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
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

  // 基本属性
  final List<String> characters;
  final List<_CharacterPosition> positions;
  final double fontSize;
  final dynamic characterImages;

  // 纹理配置
  final TextureConfig textureConfig;
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
    required this.textureConfig,
    this.ref,
  }) {
    // 在初始化时预加载所需资源
    if (ref != null) {
      // 使用微任务确保构造完成后执行
      Future.microtask(() async {
        try {
          // 预加载纹理
          if (textureConfig.enabled && textureConfig.data != null) {
            if (textureConfig.data != null) {
              debugPrint('🎨 开始预加载纹理数据');

              // 获取纹理相关服务
              final characterImageService =
                  ref!.read(characterImageServiceProvider);
              final storage = ref!.read(initializedStorageProvider);

              // 提取纹理路径或ID
              final texturePath = textureConfig.data!['path'] as String?;
              final textureId = textureConfig.data!['id'] as String?;

              if (texturePath != null) {
                // 检查纹理文件是否存在
                final exists = await storage.fileExists(texturePath);
                debugPrint('纹理文件状态: ${exists ? "存在" : "不存在"} ($texturePath)');
              } else if (textureId != null) {
                // 通过加载小尺寸图片来预热缓存
                try {
                  final imageData =
                      await characterImageService.getCharacterImage(
                    textureId,
                    'square-binary',
                    'png-binary',
                  );
                  if (imageData != null) {
                    debugPrint('✅ 纹理资源加载成功: $textureId');
                  }
                } catch (e) {
                  debugPrint('⚠️ 纹理资源加载失败: $e');
                }
              }
            }
          }

          // 创建字符图片加载队列
          final Map<String, Map<String, dynamic>> imageLoadQueue = {};

          // 收集需要加载的字符图片
          for (int i = 0; i < positions.length; i++) {
            final position = positions[i];
            if (position.char == '\n') continue;

            final charImage = _findCharacterImage(position.char, i);
            if (charImage == null) continue;

            final characterId = charImage['characterId'].toString();
            final type = charImage['type'] as String;
            final format = charImage['format'] as String;
            final cacheKey = '$characterId-$type-$format';

            // 如果图片尚未加载且不在队列中，添加到加载队列
            if (!_imageCache.containsKey(cacheKey) &&
                !GlobalImageCache.contains(cacheKey) &&
                !_loadingImages.contains(cacheKey)) {
              imageLoadQueue[cacheKey] = {
                'characterId': characterId,
                'type': type,
                'format': format,
              };
            }
          }

          // 批量加载字符图片
          if (imageLoadQueue.isNotEmpty) {
            debugPrint('📝 开始批量加载字符图片: ${imageLoadQueue.length} 个');
            await Future.wait(
              imageLoadQueue.entries.map((entry) {
                final info = entry.value;
                return _loadAndCacheImage(
                  info['characterId'] as String,
                  info['type'] as String,
                  info['format'] as String,
                );
              }),
            );
            debugPrint('✅ 字符图片预加载完成');
          }
        } catch (e, stack) {
          debugPrint('❌ 资源预加载失败: $e\n$stack');
        }
      });
    }
  }
  @override
  void paint(Canvas canvas, Size size) {
    // 创建绘制区域
    final clipRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.save();
    canvas.clipRect(clipRect);

    debugPrint('''开始绘制集字:
  纹理状态: ${textureConfig.enabled ? "✅" : "❌"}
  纹理数据: ${textureConfig.data != null ? "✅" : "❌"}
  填充模式: ${textureConfig.fillMode}
  不透明度: ${textureConfig.opacity}
  应用模式: ${textureConfig.applicationMode}''');

    try {
      // 如果是背景模式且纹理有效，先绘制背景纹理
      if (textureConfig.enabled &&
          textureConfig.data != null &&
          (textureConfig.applicationMode == 'background' ||
              textureConfig.applicationMode == 'both')) {
        _paintTexture(canvas, clipRect, mode: 'background');
      }

      // 绘制字符
      var positionIndex = 0;
      var characterIndex = 0;

      for (final character in characters) {
        if (character == '\n') {
          characterIndex++;
          continue;
        }

        if (positionIndex >= positions.length) break;

        final position = positions[positionIndex];
        final charImage = _findCharacterImage(position.char, characterIndex);
        positionIndex++;
        characterIndex++;

        if (charImage != null) {
          _drawCharacterImage(canvas, position, charImage);
        } else {
          _drawCharacterText(canvas, position);
        }
      }

      // 触发重绘回调（如果需要）
      if (_needsRepaint && _repaintCallback != null) {
        _needsRepaint = false;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _repaintCallback?.call();
        });
      }
    } catch (e, stack) {
      debugPrint('❌ 绘制失败: $e\n$stack');
    } finally {
      // 确保画布状态正确恢复
      canvas.restore();
    }
  }

  // 设置重绘回调
  void setRepaintCallback(VoidCallback callback) {
    _repaintCallback = callback;
  }

  @override
  bool shouldRepaint(covariant _CollectionPainter oldDelegate) {
    final textureChanged =
        oldDelegate.textureConfig.enabled != textureConfig.enabled ||
            oldDelegate.textureConfig.fillMode != textureConfig.fillMode ||
            oldDelegate.textureConfig.opacity != textureConfig.opacity ||
            oldDelegate.textureConfig.applicationMode !=
                textureConfig.applicationMode ||
            !_mapsEqual(oldDelegate.textureConfig.data, textureConfig.data);

    // 当基本属性或纹理配置发生变化时重绘
    return oldDelegate.characters != characters ||
        oldDelegate.positions != positions ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.characterImages != characterImages ||
        textureChanged;
  }

  /// 绘制字符图片
  void _drawCharacterImage(
      Canvas canvas, _CharacterPosition position, dynamic charImage) {
    debugPrint('''
📝 开始绘制字符:
  字符: ${position.char}
  位置: (${position.x}, ${position.y})
  尺寸: ${position.size}
  颜色: ${position.fontColor}
  背景: ${position.backgroundColor}''');
    // 创建绘制区域
    // 创建字符区域
    final rect = Rect.fromLTWH(
      position.x,
      position.y,
      position.size,
      position.size,
    );

    // 绘制背景
    if (position.backgroundColor != Colors.transparent) {
      canvas.drawRect(
          rect,
          Paint()
            ..color = position.backgroundColor
            ..style = PaintingStyle.fill);
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

      // 获取是否需要反转显示
      bool invertDisplay = false;
      if (charImage.containsKey('transform') &&
          charImage['transform'] is Map<String, dynamic>) {
        final transform = charImage['transform'] as Map<String, dynamic>;
        invertDisplay = transform['invert'] == true;
      } else if (charImage.containsKey('invert')) {
        invertDisplay = charImage['invert'] == true;
      }

      debugPrint('''检查绘制设置:
  字符ID: $characterId
  类型: $type
  格式: $format
  反转显示: ${invertDisplay ? "是" : "否"}''');

      // 创建缓存键
      final cacheKey = '$characterId-$type-$format';

      // 首先检查全局缓存 - 使用实际的缓存键检查
      final actualCacheKey = '$characterId-square-binary-png-binary';

      // 检查缓存状态
      final bool hasOriginalKey = GlobalImageCache.contains(cacheKey);
      final bool hasActualKey = GlobalImageCache.contains(actualCacheKey);

      // 如果缓存中没有图像，尝试加载
      if (!hasOriginalKey &&
          !hasActualKey &&
          !_loadingImages.contains(cacheKey)) {
        // 标记为正在加载
        _loadingImages.add(cacheKey);
        // 异步加载图像
        Future.microtask(() async {
          _loadAndCacheImage(characterId, type, format);
          // 加载完成后标记需要重绘
          _needsRepaint = true;
        }); // 先绘制文本占位符
        _drawCharacterText(canvas, position);
        return;
      }

      if (hasOriginalKey || hasActualKey) {
        final cacheKeyToUse = hasOriginalKey ? cacheKey : actualCacheKey;

        // 使用全局缓存的图像
        final image = GlobalImageCache.get(cacheKeyToUse);
        if (image == null) {
          _drawCharacterText(canvas, position);
          return;
        }

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

        // 创建基础绘制配置
        final basePaint = Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high;

        // 处理反转显示
        if (invertDisplay) {
          canvas.saveLayer(rect, Paint());
          canvas.drawRect(rect, Paint()..color = position.fontColor);
          canvas.drawImageRect(
              image, srcRect, rect, Paint()..blendMode = BlendMode.dstOut);
        }
        // 处理二值图像
        else if (type.contains('binary') && format.contains('binary')) {
          canvas.saveLayer(rect, Paint());
          canvas.drawImageRect(image, srcRect, rect, basePaint);
          canvas.drawRect(
              rect,
              Paint()
                ..color = position.fontColor
                ..blendMode = BlendMode.srcIn);
        }
        // 处理其他图像
        else {
          canvas.drawImageRect(image, srcRect, rect, basePaint);
        }

        // 完成绘制
        canvas.restore();

        // 检查纹理配置并绘制
        final canApplyTexture = textureConfig.enabled &&
            textureConfig.data != null &&
            (textureConfig.applicationMode == 'character' ||
                textureConfig.applicationMode == 'both');

        if (canApplyTexture) {
          debugPrint('''🎨 开始应用字符纹理:
  字符: ${position.char}
  位置: $rect
  颜色: ${position.fontColor}
  不透明度: ${textureConfig.opacity}''');

          try {
            // 第1层：创建主图层以保留原始字符形状
            canvas.saveLayer(rect, Paint());

            // 第2层：绘制原始字符图像形状（以黑色绘制）
            final shapePaint = Paint()..color = Colors.black;
            canvas.drawImageRect(image, srcRect, rect, shapePaint);

            // 第3层：将黑色形状转换为目标颜色
            {
              final colorLayer = Paint()
                ..color = position.fontColor
                ..blendMode = BlendMode.srcIn;
              canvas.drawRect(rect, colorLayer);
            } // 如果启用了纹理，直接使用 _paintTexture 方法
            if (textureConfig.enabled && textureConfig.data != null) {
              // 打印Canvas状态
              debugPrint(
                  '🔎 当前Canvas状态: ${canvas.hashCode}'); // 保存新图层状态 - 重要：字符纹理需要使用 srcATop 混合模式
              final blendLayer = Paint()..blendMode = BlendMode.srcATop;
              canvas.saveLayer(rect, blendLayer); // 使用工具方法绘制纹理，确保使用字符模式
              debugPrint('🔍 应用字符纹理，区域: $rect');
              debugPrint('🔬 详细信息: 字符=$characterId, 类型=$type, 格式=$format');
              _paintTexture(canvas, rect, mode: 'character');

              // 恢复新图层状态
              canvas.restore();
            }

            // 最终恢复画布状态
            canvas.restore();
            debugPrint('✅ 字符纹理绘制完成');
          } catch (e, stack) {
            debugPrint('''❌ 字符纹理绘制失败:
  错误: $e
  堆栈: $stack''');
            canvas.restore();
            _drawFallbackTexture(canvas, rect, position.fontColor);
          }
        }
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

    // 纹理应用标志
    final bool hasTexture = textureConfig.enabled && textureConfig.data != null;
    final bool canApplyBackgroundTexture = hasTexture &&
        (textureConfig.applicationMode == 'background' ||
            textureConfig.applicationMode == 'both');
    final bool canApplyCharacterTexture = hasTexture &&
        (textureConfig.applicationMode == 'character' ||
            textureConfig.applicationMode == 'both');

    debugPrint(
        '🎨 文本绘制纹理配置: bg=$canApplyBackgroundTexture, char=$canApplyCharacterTexture, mode=${textureConfig.applicationMode}');

    // 保存画布状态
    canvas.save();

    // 绘制背景 (with or without texture)
    if (canApplyBackgroundTexture) {
      // 如果有纹理配置，应用背景纹理
      debugPrint('🎨 字符文本绘制时应用背景纹理: $rect');
      try {
        // 使用背景纹理而不是普通背景色
        _paintTexture(canvas, rect, mode: 'background');
      } catch (e) {
        debugPrint('❌ 应用背景纹理失败: $e');
        // 如果纹理应用失败，回退到普通背景
        _drawFallbackBackground(canvas, rect, position);
      }
    } else {
      // 没有纹理时绘制普通背景
      _drawFallbackBackground(canvas, rect, position);
    }
    if (canApplyCharacterTexture) {
      debugPrint('🎨 字符文本绘制时应用字符纹理: ${position.char}');
      try {
        // 第1层：保存主画布状态
        canvas.saveLayer(rect, Paint());

        // 第2层：创建字符蒙版
        canvas.saveLayer(rect, Paint());

        // 使用黑色绘制字符作为不透明度蒙版
        final textPainter = TextPainter(
          text: TextSpan(
            text: position.char,
            style: TextStyle(
              fontSize: position.size * 0.7,
              color: Colors.black,
              fontWeight: FontWeight.bold,
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

        // 第3层：应用字符颜色，使用SrcIn模式确保只在字符形状内上色
        {
          final colorPaint = Paint()
            ..color = position.fontColor
            ..blendMode = BlendMode.srcIn;
          canvas.saveLayer(rect, colorPaint);
          canvas.drawRect(rect, Paint()..color = Colors.white);
          canvas.restore();
        }

        // 第4层：应用纹理，使用DstIn模式保持字符形状
        {
          canvas.saveLayer(rect, Paint()..blendMode = BlendMode.srcATop);
          _paintTexture(canvas, rect, mode: 'character');
          canvas.restore();
        }

        // 恢复所有图层
        canvas.restore(); // 恢复字符蒙版图层
        canvas.restore(); // 恢复主画布状态
      } catch (e) {
        debugPrint('❌ 应用字符纹理失败: $e');
        // 如果纹理应用失败，回退到普通文字绘制
        _drawFallbackText(canvas, position, rect);
      }
    } else {
      // 普通文字绘制
      _drawFallbackText(canvas, position, rect);
    } // 恢复画布状态
    canvas.restore();
  }

  /// 绘制普通背景（当不使用纹理或纹理应用失败时）
  void _drawFallbackBackground(
      Canvas canvas, Rect rect, _CharacterPosition position) {
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

  /// 绘制普通文本（不使用纹理）
  void _drawFallbackText(
      Canvas canvas, _CharacterPosition position, Rect rect) {
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

  /// 绘制备选纹理（当纹理加载失败时使用）
  void _drawFallbackTexture(Canvas canvas, Rect rect, Color color) {
    debugPrint('⚠️ 使用备选纹理填充');
    try {
      canvas.saveLayer(rect, Paint());

      // 创建基础渐变
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.1),
        ],
      );

      // 绘制渐变背景
      final gradientPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, gradientPaint);

      // 添加点阵图案
      final patternPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.fill
        ..strokeWidth = 1.0;

      const spacing = 8.0;
      const dotRadius = 1.0;

      // 计算点的数量
      final horizontalDots = (rect.width / spacing).ceil();
      final verticalDots = (rect.height / spacing).ceil();

      // 居中绘制点阵
      final startX =
          rect.left + (rect.width - (horizontalDots - 1) * spacing) / 2;
      final startY =
          rect.top + (rect.height - (verticalDots - 1) * spacing) / 2;

      for (var i = 0; i < horizontalDots; i++) {
        for (var j = 0; j < verticalDots; j++) {
          final x = startX + i * spacing;
          final y = startY + j * spacing;
          canvas.drawCircle(
            Offset(x, y),
            dotRadius,
            patternPaint,
          );
        }
      }

      canvas.restore();
      debugPrint('✅ 备选纹理绘制完成');
    } catch (e, stack) {
      debugPrint('''❌ 备选纹理绘制失败:
  错误: $e
  堆栈: $stack''');
      // 发生错误时恢复画布状态
      canvas.restore();
    }
  }

  /// 使用变换矩阵绘制纹理
  void _drawTextureWithTransform(
    Canvas canvas,
    Rect rect,
    CustomPainter painter,
  ) {
    try {
      // 设置重绘回调（根据实际类型处理）
      if (painter is BackgroundTexturePainter) {
        painter.repaintCallback = () {
          debugPrint('⚡ 集字元素收到背景纹理重绘回调');
          _needsRepaint = true;
          if (_repaintCallback != null) {
            debugPrint('⚡ 转发重绘回调到上层');
            _repaintCallback!();
          }
        };
      } else if (painter is CharacterTexturePainter) {
        painter.repaintCallback = () {
          debugPrint('⚡ 集字元素收到字符纹理重绘回调');
          _needsRepaint = true;
          if (_repaintCallback != null) {
            debugPrint('⚡ 转发重绘回调到上层');
            _repaintCallback!();
          }
        };
      }

      // 记录绘制前画布信息
      debugPrint('📐 纹理变换绘制:');
      debugPrint('  🔍 画布HashCode: ${canvas.hashCode}');
      debugPrint('  📏 目标区域: $rect');

      // 保存画布状态
      canvas.save();

      // 先平移到目标位置
      canvas.translate(rect.left, rect.top);

      // 在该位置绘制纹理
      final texSize = Size(rect.width, rect.height);
      debugPrint('  📏 纹理绘制尺寸: $texSize');

      // 执行绘制
      painter.paint(canvas, texSize);
    } catch (e, stack) {
      debugPrint('  ❌ 纹理变换绘制错误: $e');
      debugPrint('  ❌ 堆栈: $stack');
    } finally {
      // 恢复平移
      canvas.restore();
      debugPrint('✅ 纹理变换绘制完成');
    }
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
            final result = {
              'characterId': imageInfo['characterId'],
              'type': imageInfo['drawingType'] ?? 'square-binary', // 优先使用绘制格式
              'format': imageInfo['drawingFormat'] ?? 'png-binary',
              'transform': imageInfo['transform'],
            };
            return result;
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
    } catch (e) {
      // 错误处理，静默失败
    }

    return null;
  }

  /// 加载并缓存图像
  Future<void> _loadAndCacheImage(
      String characterId, String type, String format) async {
    final cacheKey = '$characterId-$type-$format';
    debugPrint('📥 开始加载字符图片: $cacheKey');

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
      if (ref == null) {
        return;
      }

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
        final path = '${storage.getAppDataPath()}/characters/$id/$fileName';
        debugPrint('''请求字符图片:
  字符ID: $id
  类型: $imgType
  格式: $imgFormat
  路径: $path''');
        return path;
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
      try {
        // 尝试从文件读取
        if (await file.exists()) {
          try {
            imageData = await file.readAsBytes();
          } catch (e) {
            debugPrint('读取文件失败: $e');
          }
        }

        // 如果文件读取失败，从服务获取
        if (imageData == null) {
          imageData = await characterImageService.getCharacterImage(
            characterId,
            type,
            format,
          );

          // 如果获取成功，保存到文件
          if (imageData != null) {
            try {
              final directory = Directory(file.parent.path);
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }
              await file.writeAsBytes(imageData);
            } catch (e) {
              debugPrint('保存文件失败: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('获取图像数据失败: $e');
        return;
      }

      // 解码图像数据
      if (imageData != null) {
        try {
          final completer = Completer<ui.Image>();
          ui.decodeImageFromList(imageData, completer.complete);
          final image = await completer.future;

          // 更新缓存
          _imageCache[cacheKey] = image;
          GlobalImageCache.add(cacheKey, image);

          // 同时使用规范化的键缓存
          final normalizedKey = '$characterId-square-binary-png-binary';
          if (cacheKey != normalizedKey) {
            _imageCache[normalizedKey] = image;
            GlobalImageCache.add(normalizedKey, image);
          }

          _needsRepaint = true;
        } catch (e) {
          debugPrint('解码图像失败: $e');
        }
      }
    } finally {
      // 移除加载标记
      _loadingImages.remove(cacheKey);
    }
  }

  bool _mapsEqual(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  /// 在指定区域内绘制纹理
  void _paintTexture(Canvas canvas, Rect rect, {required String mode}) {
    // 开始性能计时
    final startTime = DateTime.now();

    // 检查纹理配置并记录详细信息
    if (!textureConfig.enabled || textureConfig.data == null) {
      debugPrint(
          '⚡ 渲染检查耗时: ${DateTime.now().difference(startTime).inMicroseconds}μs');
      debugPrint('''⚠️ 跳过纹理绘制:
  ┌─ 原因: ${!textureConfig.enabled ? "纹理未启用" : "无纹理数据"}
  ├─ 模式: $mode
  ├─ 区域: $rect
  └─ 数据: ${textureConfig.data}''');
      return;
    }

    // 创建纹理缓存键
    final String texturePath = textureConfig.data?['path'] as String? ?? '';
    final String textureCacheKey =
        '${texturePath}_${textureConfig.fillMode}_${textureConfig.opacity}';

    debugPrint('''🎨 开始纹理渲染:
  ┌─ 模式: $mode (${mode == 'character' ? "字符纹理" : "背景纹理"})
  ├─ 区域: $rect
  ├─ 填充: ${textureConfig.fillMode}
  ├─ 透明度: ${textureConfig.opacity}
  ├─ 路径: $texturePath
  └─ 缓存键: $textureCacheKey''');
    try {
      // 根据模式选择适当的纹理绘制器
      final CustomPainter texturePainter;

      if (mode == 'character') {
        // 字符应用范围使用 CharacterTexturePainter
        texturePainter = CharacterTexturePainter(
          textureData: textureConfig.data,
          fillMode: textureConfig.fillMode,
          opacity: textureConfig.opacity,
          ref: ref,
        );
        debugPrint('🎨 创建字符纹理绘制器，模式: ${textureConfig.fillMode}');
      } else {
        // 背景应用范围使用 BackgroundTexturePainter
        texturePainter = BackgroundTexturePainter(
          textureData: textureConfig.data,
          fillMode: textureConfig.fillMode,
          opacity: textureConfig.opacity,
          ref: ref,
        );
        debugPrint('🎨 创建背景纹理绘制器，模式: ${textureConfig.fillMode}');
      }
      // 根据模式选择不同的绘制策略
      if (mode == 'character') {
        // 对于字符纹理，采用以下步骤：
        debugPrint('🔄 字符纹理模式 - 处理');

        // 1. 保存当前画布状态
        canvas.saveLayer(rect, Paint());

        // 2. 绘制纹理
        _drawTextureWithTransform(canvas, rect, texturePainter);

        // 3. 使用DstIn混合模式，将纹理限制在字符形状内
        canvas.saveLayer(rect, Paint()..blendMode = BlendMode.dstIn);

        // 4. 恢复到主图层
        canvas.restore();
        canvas.restore();
        debugPrint('✅ 绘制字符纹理完成');
      } else {
        // 对于背景纹理，直接使用正常绘制
        debugPrint('🔄 背景纹理模式 - 使用正常绘制');

        // 保存画布状态
        canvas.saveLayer(rect, Paint());

        // 绘制纹理
        _drawTextureWithTransform(canvas, rect, texturePainter);

        // 如果需要调整透明度
        if (textureConfig.opacity < 1.0) {
          // 应用透明度调整
          canvas.saveLayer(
              rect,
              Paint()
                ..color = Colors.white.withOpacity(textureConfig.opacity)
                ..blendMode = BlendMode.dstIn);
          canvas.restore();
        }
        canvas.restore();
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('''✅ 纹理渲染完成:
  ┌─ 模式: $mode
  ├─ 耗时: ${duration.inMilliseconds}ms
  └─ 微秒: ${duration.inMicroseconds}μs''');
    } catch (e, stack) {
      debugPrint('❌ 纹理绘制错误: $e\n$stack');
      // 确保即使出错也恢复画布状态
      canvas.restore();
      _drawFallbackTexture(canvas, rect, Colors.black.withOpacity(0.1));
    }
  }
}
