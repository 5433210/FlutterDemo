import 'package:flutter/material.dart';
import 'dart:math';

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

  /// 构造函数
  CharacterPosition({
    required this.char,
    required this.x,
    required this.y,
    required this.size,
    required this.index,
    this.fontColor = Colors.black,
    this.backgroundColor = Colors.transparent,
  });
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
    required bool isVertical,
    Color fontColor = Colors.black,
    Color backgroundColor = Colors.transparent,
    int charsPerCol = 0,
    bool enableSoftLineBreak = false,
    bool isLeftToRight = true,
    double lineSpacing = 0,
    double letterSpacing = 0,
  }) {
    final List<CharacterPosition> positions = [];
    
    if (processedChars.isEmpty) {
      return positions;
    }
    
    // 列索引数组 - 记录每个字符所在的列
    List<int> colIndices = [];
    
    // 如果有换行标记，则根据换行标记分配列号
    if (isNewLineList.isNotEmpty && isNewLineList.length == processedChars.length) {
      int currentCol = 0;
      
      for (int i = 0; i < processedChars.length; i++) {
        if (isNewLineList[i]) {
          currentCol++;
        }
        
        colIndices.add(currentCol);
      }
    } else {
      // 没有换行标记，按照原来的逻辑处理
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
          // 两端对齐时，重新计算行间距
          effectiveLineSpacing = (availableWidth - colCount * charSize) / (colCount - 1);
        }
        startX = 0;
        break;
      default:
        startX = 0;
        break;
    }
    
    // 计算所有字符的位置
    for (int i = 0; i < processedChars.length; i++) {
      final colIndex = colIndices[i];
      
      // 计算该列中的字符数
      int charsInCurrentCol = 0;
      for (int j = 0; j < colIndices.length; j++) {
        if (colIndices[j] == colIndex) {
          charsInCurrentCol++;
        }
      }
      
      // 计算字间距
      double effectiveLetterSpacing = letterSpacing;
      
      // 计算起始Y坐标
      double startY;
      
      // 根据垂直对齐方式计算起始Y坐标
      if (isVertical) {
        // 垂直布局时，根据对齐方式和每列字符数计算Y起点
        startY = 0; // 默认上对齐
            
        // 如果启用了两端对齐，且字符数大于1，重新计算字间距
        if (textAlign == 'justify' && charsInCurrentCol > 1) {
          effectiveLetterSpacing = 
              (availableHeight - charsInCurrentCol * charSize) / 
              (charsInCurrentCol - 1);
        }
      } else {
        // 水平布局时Y起点直接是0
        startY = 0;
      }
      
      // 找到当前字符在当前列中的位置
      int rowIndexInCol = 0;
      for (int j = 0; j < i; j++) {
        if (colIndices[j] == colIndex) rowIndexInCol++;
      }
      
      // 计算最终位置
      final x = startX + colIndex * (charSize + effectiveLineSpacing);
      final y = startY + rowIndexInCol * (charSize + effectiveLetterSpacing);
      
      positions.add(CharacterPosition(
        char: processedChars[i],
        x: x,
        y: y,
        size: charSize,
        index: i,
        fontColor: fontColor,
        backgroundColor: backgroundColor,
      ));
    }
    
    return positions;
  }
}
