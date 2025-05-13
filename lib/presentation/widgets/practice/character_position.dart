import 'dart:math';

import 'package:flutter/material.dart';

/// 字符位置类 - 存储字符绘制所需的位置信息
class CharacterPosition {
  /// 字符内容
  final String char;

  /// X坐标
  final double x;

  /// Y坐标
  final double y;

  /// 字符大小
  final double size;

  /// 字符索引
  final int index;

  /// 字体颜色
  final Color fontColor;

  /// 背景颜色
  final Color backgroundColor;

  /// 是否是换行符后的第一个字符
  final bool isAfterNewLine;

  /// 构造函数
  CharacterPosition({
    required this.char,
    required this.x,
    required this.y,
    required this.size,
    required this.index,
    this.fontColor = Colors.black,
    this.backgroundColor = Colors.transparent,
    this.isAfterNewLine = false,
  });

  /// 获取内部可用区域
  Rect get innerRect {
    return Rect.fromLTWH(
      x + padding.left,
      y + padding.top,
      size - padding.horizontal,
      size - padding.vertical,
    );
  }

  /// 获取内边距
  EdgeInsets get padding => EdgeInsets.all(size * 0.05);
}

/// 布局计算工具类 - 提供字符位置计算的功能
class LayoutCalculator {
  /// 计算字符位置
  ///
  /// 参数说明:
  /// - characters: 字符列表
  /// - charSize: 字符大小
  /// - availableWidth: 可用宽度
  /// - availableHeight: 可用高度
  /// - textAlign: 文本对齐方式
  /// - isVertical: 是否垂直排列
  /// - fontColor: 字体颜色
  /// - backgroundColor: 背景颜色
  /// - charsPerCol: 每列字符数
  /// - enableSoftLineBreak: 是否启用软换行
  /// - isLeftToRight: 是否从左到右
  /// - lineSpacing: 行间距
  /// - letterSpacing: 字符间距
  static List<CharacterPosition> calculatePositions({
    required List<String> processedChars,
    required List<bool> isNewLineList,
    required double charSize,
    required double availableWidth,
    required double availableHeight,
    required String textAlign,
    required bool isVertical, // !isHorizontal
    Color fontColor = Colors.black,
    Color backgroundColor = Colors.transparent,
    int maxCharsPerLine = 0,
    bool enableSoftLineBreak = false,
    bool isLeftToRight = true,
    double lineSpacing = 0,
    double letterSpacing = 0,
    String verticalAlign = 'top',
  }) {
    final List<CharacterPosition> positions = [];

    if (processedChars.isEmpty) {
      return positions;
    }

    final bool isHorizontal = !isVertical;

    // 创建一个新的字符列表，去除换行符
    List<String> actualChars = [];
    List<int> lineIndices = []; // 每个字符所在的行号或列号

    if (isHorizontal) {
      // 水平布局的字符处理
      // 计算每行可容纳的字符数
      final charsPerRow = enableSoftLineBreak && maxCharsPerLine > 0
          ? maxCharsPerLine
          : ((availableWidth + letterSpacing) / (charSize + letterSpacing))
              .floor();

      if (charsPerRow <= 0) return positions;

      // 如果有换行标记，则根据换行标记分配行号
      if (isNewLineList.isNotEmpty &&
          isNewLineList.length == processedChars.length) {
        int currentRow = 0;
        int charCountInCurrentRow = 0; // 当前行已有字符数
        int charIndex = 0; // 实际字符的索引（不包括换行符）

        for (int i = 0; i < processedChars.length; i++) {
          if (processedChars[i] == '\n') {
            // 遇到换行符，增加行号但不添加到处理后的字符列表
            currentRow++;
            charCountInCurrentRow = 0;
            // 注意：不增加charIndex，因为换行符不会被添加到actualChars中
          } else {
            // 普通字符
            actualChars.add(processedChars[i]);

            // 如果启用软回车且当前行字符数已达到最大值，则自动换行
            if (enableSoftLineBreak &&
                charCountInCurrentRow >= charsPerRow &&
                charsPerRow > 0) {
              currentRow++;
              charCountInCurrentRow = 0;
            }

            lineIndices.add(currentRow);
            charCountInCurrentRow++;
            charIndex++; // 实际字符索引递增
          }
        }
      } else {
        // 没有换行标记，按照原来的逻辑处理
        actualChars = List.from(processedChars);
        if (enableSoftLineBreak && charsPerRow > 0) {
          // 启用软回车时，按照每行最大字符数自动分配行号
          for (int i = 0; i < actualChars.length; i++) {
            lineIndices.add(i ~/ charsPerRow);
          }
        } else {
          // 不启用软回车时，所有字符在同一行
          lineIndices = List.filled(actualChars.length, 0);
        }
      }

      // 计算行数（使用最大行号+1）
      final rowCount = lineIndices.isEmpty ? 0 : lineIndices.reduce(max) + 1;

      // 计算实际使用的高度和有效行间距
      double effectiveLineSpacing = lineSpacing;
      final usedHeight = min(availableHeight,
          rowCount * charSize + (rowCount - 1) * effectiveLineSpacing);

      // 计算起始位置（考虑垂直对齐方式）
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
        default:
          startY = 0;
          break;
      }

      // 遍历每个字符，计算位置
      for (int i = 0; i < actualChars.length; i++) {
        // 获取行号
        final rowIndex = lineIndices[i];

        // 计算每行的字符数 - 优化性能，使用where计数而不是循环
        int charsInCurrentRow = lineIndices.where((r) => r == rowIndex).length;

        // 计算行宽
        final rowWidth = charsInCurrentRow * charSize +
            (charsInCurrentRow - 1) * letterSpacing;

        // 计算水平起始位置和有效字间距
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
            startX = 0;
            break;
          default:
            startX = isLeftToRight ? 0 : availableWidth - rowWidth;
            break;
        }

        // 找到当前字符在当前行中的位置
        int colIndexInRow = 0;
        for (int j = 0; j < i; j++) {
          if (lineIndices[j] == rowIndex) colIndexInRow++;
        }

        // 计算最终位置
        double x;
        if (isLeftToRight) {
          x = startX + colIndexInRow * (charSize + effectiveLetterSpacing);
        } else {
          x = availableWidth -
              startX -
              (colIndexInRow + 1) * charSize -
              colIndexInRow * effectiveLetterSpacing;
        }

        final y = startY + rowIndex * (charSize + effectiveLineSpacing);

        positions.add(CharacterPosition(
          char: actualChars[i],
          x: x,
          y: y,
          size: charSize,
          index: i,
          fontColor: fontColor,
          backgroundColor: backgroundColor,
          isAfterNewLine: isNewLineList.isNotEmpty && i < isNewLineList.length
              ? isNewLineList[i]
              : false,
        ));
      }
    } else {
      // 垂直布局的字符处理
      // 计算每列可容纳的字符数
      final charsPerCol = enableSoftLineBreak && maxCharsPerLine > 0
          ? maxCharsPerLine
          : ((availableHeight + letterSpacing) / (charSize + letterSpacing))
              .floor();

      if (charsPerCol <= 0) return positions;

      // 如果有换行标记，则根据换行标记分配列号
      if (isNewLineList.isNotEmpty &&
          isNewLineList.length == processedChars.length) {
        int currentCol = 0;
        int charCountInCurrentCol = 0; // 当前列已有字符数

        for (int i = 0; i < processedChars.length; i++) {
          if (processedChars[i] == '\n') {
            // 遇到换行符，增加列号但不添加到处理后的字符列表
            currentCol++;
            charCountInCurrentCol = 0;
          } else {
            // 普通字符
            actualChars.add(processedChars[i]);

            // 如果启用软回车且当前列字符数已达到最大值，则自动换列
            if (enableSoftLineBreak &&
                charCountInCurrentCol >= charsPerCol &&
                charsPerCol > 0) {
              currentCol++;
              charCountInCurrentCol = 0;
            }

            lineIndices.add(currentCol);
            charCountInCurrentCol++;
          }
        }
      } else {
        // 没有换行标记，按照原来的逻辑处理
        actualChars = List.from(processedChars);
        if (enableSoftLineBreak && charsPerCol > 0) {
          // 启用软回车时，按照每列最大字符数自动分配列号
          for (int i = 0; i < actualChars.length; i++) {
            lineIndices.add(i ~/ charsPerCol);
          }
        } else {
          // 不启用软回车时，所有字符在同一列
          lineIndices = List.filled(actualChars.length, 0);
        }
      }

      // 计算列数（使用最大列号+1）
      final colCount = lineIndices.isEmpty ? 0 : lineIndices.reduce(max) + 1;

      // 计算实际使用的宽度和有效列间距
      double effectiveColumnSpacing = lineSpacing;
      final usedWidth = min(availableWidth,
          colCount * charSize + (colCount - 1) * effectiveColumnSpacing);

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
            effectiveColumnSpacing =
                (availableWidth - colCount * charSize) / (colCount - 1);
          }
          startX = isLeftToRight ? 0 : 0;
          break;
        default:
          startX = isLeftToRight ? 0 : availableWidth - usedWidth;
          break;
      }

      // 遍历每个字符，计算位置
      for (int i = 0; i < actualChars.length; i++) {
        final colIndex = lineIndices[i];

        // 计算每列的字符数 - 优化性能，使用where计数而不是循环
        int charsInCurrentCol = lineIndices.where((c) => c == colIndex).length;

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
            break;
        }

        // 找到当前字符在当前列中的位置
        int rowIndexInCol = 0;
        for (int j = 0; j < i; j++) {
          if (lineIndices[j] == colIndex) rowIndexInCol++;
        }

        // 计算最终位置
        double x;
        if (isLeftToRight) {
          x = startX + colIndex * (charSize + effectiveColumnSpacing);
        } else {
          x = availableWidth -
              startX -
              (colIndex + 1) * charSize -
              colIndex * effectiveColumnSpacing;
        }

        final y = startY + rowIndexInCol * (charSize + effectiveLetterSpacing);

        positions.add(CharacterPosition(
          char: actualChars[i],
          x: x,
          y: y,
          size: charSize,
          index: i,
          fontColor: fontColor,
          backgroundColor: backgroundColor,
          isAfterNewLine: isNewLineList.isNotEmpty && i < isNewLineList.length
              ? isNewLineList[i]
              : false,
        ));
      }
    }

    return positions;
  }
}
