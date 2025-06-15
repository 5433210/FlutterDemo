// filepath: c:\Users\wailik\Documents\Code\Flutter\demo\demo\lib\presentation\widgets\practice\collection_element_renderer.dart
// 完整修复版本 - 集成所有原有功能与新特性

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'advanced_collection_painter.dart';
import 'character_position.dart';
// 引入所有已拆分的模块
import 'texture_config.dart' as tc;

// 所有工具类和函数已移动到各自的模块文件中

/// 集字绘制器 - 主类
/// 负责构建集字布局并管理渲染流程
/// 完全兼容原有功能，并添加了增强的渲染和纹理处理功能
class CollectionElementRenderer {
  /// 构建集字布局
  ///
  /// 此方法创建一个带有自定义绘制器的Widget，用于显示集字内容
  ///
  /// 参数:
  /// * characters - 要渲染的字符串
  /// * writingMode - 书写模式，如'horizontal-tb', 'vertical-rl'等
  /// * fontSize - 字体大小
  /// * letterSpacing - 字符间距
  /// * lineSpacing - 行间距
  /// * textAlign - 文本对齐方式
  /// * verticalAlign - 垂直对齐方式
  /// * characterImages - 字符图片资源
  /// * constraints - 容器约束
  /// * padding - 内边距
  /// * fontColor - 字体颜色代码
  /// * backgroundColor - 背景颜色代码
  /// * enableSoftLineBreak - 是否启用软换行
  /// * hasCharacterTexture - 是否有字符纹理
  /// * characterTextureData - 字符纹理数据
  /// * textureFillMode - 纹理填充模式
  /// * textureOpacity - 纹理不透明度
  /// * applicationMode - 纹理应用模式（背景或字符背景）
  /// * ref - Riverpod引用
  static Widget buildCollectionLayout({
    required String characters,
    required String
        writingMode, // 'horizontal-l', 'vertical-r', 'horizontal-r', 'vertical-l'
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
    String textureFillMode = 'stretch',
    String textureFitMode = 'fill', // 新增适应模式参数
    double textureOpacity = 1.0,
    double textureWidth = 0, // 纹理宽度
    double textureHeight = 0, // 纹理高度
    WidgetRef? ref,
  }) {
    // 使用增强版纹理管理器清除缓存，确保纹理变更可立即生效
    if (ref != null) {
      // 强制清除纹理缓存
      // EnhancedTextureManager.instance.invalidateTextureCache(ref);
      EditPageLogger.editPageDebug('强制清除纹理缓存以确保立即更新');
    } // 兼容原有支持 - 无内容且无背景纹理时显示提示
    if (characters.isEmpty && !hasCharacterTexture) {
      return const Center(
          child: Text('请输入汉字内容', style: TextStyle(color: Colors.grey)));
    }

    // 检查是否为空字符情况
    final bool isEmpty = characters.isEmpty;

    // 获取绘制区域的布局信息
    final layoutWidth = constraints.maxWidth;
    final layoutHeight = constraints.maxHeight;
    final contentWidth = layoutWidth - padding * 2;
    final contentHeight = layoutHeight - padding * 2; // 添加调试信息 (条件化以提升性能)

    // 创建字符列表及换行标记列表
    List<String> charList = [];
    List<bool> isNewLineList = []; // 标记每个字符是否是换行符后的第一个字符

    if (isEmpty) {
      // 如果字符串为空，添加空格作为占位符，以创建可渲染的区域
      charList.add(' ');
      isNewLineList.add(false);
    } else {
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
    }

    // 确定布局方向
    final isHorizontal = writingMode.startsWith('horizontal');
    final isLeftToRight = writingMode.endsWith('l');

    // 解析颜色
    final parsedFontColor = tc.parseColor(fontColor);
    final parsedBackgroundColor = tc.parseColor(backgroundColor);

    // 计算每列字符数（用于自动换行）
    int charsPerCol = 0;
    double adjustedFontSize = fontSize;

    // 调整字体大小以适应内边距
    final maxSize = math.min(contentWidth, contentHeight);
    if (fontSize > maxSize) {
      adjustedFontSize = maxSize;
    }

    if (enableSoftLineBreak) {
      // 根据书写模式决定使用宽度还是高度
      final effectiveSize = isHorizontal ? contentWidth : contentHeight;

      // 计算每行/列可容纳的字符数，考虑字间距
      if (effectiveSize > 0 && adjustedFontSize > 0) {
        // 计算时已经考虑了内边距后的有效尺寸
        final maxCharsPerLine = ((effectiveSize + letterSpacing) /
                (adjustedFontSize + letterSpacing))
            .floor();
        charsPerCol = maxCharsPerLine > 0 ? maxCharsPerLine : 1;

        EditPageLogger.editPageDebug(
          '自动换行计算',
          data: {
            'effectiveSize': effectiveSize,
            'fontSize': fontSize,
            'letterSpacing': letterSpacing,
            'maxCharsPerLine': maxCharsPerLine,
            'actualCharsPerCol': charsPerCol,
            'totalChars': charList.length,
            'estimatedLines': (charList.length / charsPerCol).ceil(),
          },
        );
      }
    }

    // 计算每个字符的位置，基于内容区域
    final List<CharacterPosition> positions =
        LayoutCalculator.calculatePositions(
      processedChars: charList,
      isNewLineList: isNewLineList,
      charSize: adjustedFontSize,
      availableWidth: contentWidth,
      availableHeight: contentHeight,
      textAlign: textAlign,
      isVertical: !isHorizontal,
      fontColor: parsedFontColor,
      backgroundColor: parsedBackgroundColor,
      maxCharsPerLine: charsPerCol,
      enableSoftLineBreak: enableSoftLineBreak,
      isLeftToRight: isLeftToRight,
      lineSpacing: lineSpacing,
      letterSpacing: letterSpacing,
      verticalAlign: verticalAlign,
    );

    // 为所有位置应用内边距偏移
    final List<CharacterPosition> adjustedPositions = positions.map((pos) {
      return CharacterPosition(
        char: pos.char,
        x: pos.x + padding,
        y: pos.y + padding,
        size: pos.size,
        index: pos.index,
        fontColor: pos.fontColor,
        backgroundColor: pos.backgroundColor,
        isAfterNewLine: pos.isAfterNewLine,
        originalIndex: pos.originalIndex,
      );
    }).toList(); // 使用StatefulBuilder来支持重绘
    return StatefulBuilder(
      builder: (context, setState) {
        // 移除textureApplicationRange，现在只支持background模式

        Map<String, dynamic>? effectiveTextureData;
        bool hasEffectiveTexture = hasCharacterTexture;
        String textureId = '';

        // 输出调试信息
        EditPageLogger.editPageDebug(
          '集字渲染状态',
          data: {
            'characters': isEmpty ? "空" : characters,
            'hasTexture': hasCharacterTexture,
            'mode': 'background',
          },
        );

        // 处理纹理数据
        if (hasCharacterTexture && characterTextureData != null) {
          textureId = characterTextureData['id'] as String;
        }

        // 创建纹理变化键，用于强制widget重建
        final textureChangeKey = ValueKey(
            'texture_${hasEffectiveTexture}_${textureId}_${textureWidth}_${textureHeight}_${textureFillMode}_${textureFitMode}_${textureOpacity}_${DateTime.now().millisecondsSinceEpoch}');

        EditPageLogger.rendererDebug('创建纹理变化键', 
          data: {'textureChangeKey': textureChangeKey.value});

        // 创建纹理配置，使用新的配置结构（移除应用范围，只使用背景模式）
        final textureConfig = tc.TextureConfig(
          enabled: hasEffectiveTexture && (characterTextureData != null),
          data: characterTextureData ?? effectiveTextureData,
          fillMode: textureFillMode,
          fitMode: textureFitMode,
          opacity: textureOpacity,
          textureWidth: textureWidth,
          textureHeight: textureHeight,
        );

        // 根据情况决定使用基础绘制器还是增强版绘制器
        if (ref == null) {
          // 当没有ref时，返回一个错误提示组件
          return const Center(
            child: Text('需要WidgetRef才能创建CollectionPainter',
                style: TextStyle(color: Colors.red)),
          );
        }

        CustomPainter painter;
        // 使用增强版绘制器，支持原有的字符图像加载功能
        // try {
        painter = AdvancedCollectionPainter(
          characters: charList,
          positions: adjustedPositions,
          fontSize: adjustedFontSize,
          characterImages: characterImages,
          textureConfig: textureConfig,
          ref: ref,
          // 增加布局参数，这些参数将被传递给绘制器以便正确绘制
          writingMode: writingMode,
          textAlign: textAlign,
          verticalAlign: verticalAlign,
          enableSoftLineBreak: enableSoftLineBreak,
          padding: padding,
          letterSpacing: letterSpacing,
          lineSpacing: lineSpacing,
        );

        // 设置重绘回调 - 高级版本
        // 注意：如果 AdvancedCollectionPainter 没有实现 setRepaintCallback方法，这里会抛出异常
        // 在生产环境中应该添加适当的类型检查
        try {
          dynamic dynamicPainter = painter;
          if (dynamicPainter.setRepaintCallback != null) {
            dynamicPainter.setRepaintCallback(() {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                WidgetsBinding.instance.scheduleForcedFrame();
                setState(() {
                  // 触发 Widget 重建，进而触发 CustomPaint 重绘
                });
              });
            });
          }
        } catch (e) {
          EditPageLogger.rendererError('设置重绘回调失败', error: e);
        }
        // } catch (e) {
        // // 如果创建AdvancedCollectionPainter失败，尝试使用基础绘制器
        // debugPrint('创建AdvancedCollectionPainter失败，使用CollectionPainter: $e');
        // painter = CollectionPainter(
        //   characters: charList,
        //   positions: adjustedPositions,
        //   fontSize: adjustedFontSize,
        //   characterImages: characterImages,
        //   textureConfig: textureConfig,
        //   ref: ref,
        // );

        // // 设置重绘回调 - 基础版本
        // (painter as CollectionPainter).setRepaintCallback(() {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     WidgetsBinding.instance.scheduleForcedFrame();
        //   });
        // });
        // }

        // 汇报实际生效的参数值
        EditPageLogger.rendererDebug('实际使用的集字渲染参数', 
          data: {
            'padding': padding,
            'writingMode': writingMode,
            'textAlign': textAlign,
            'verticalAlign': verticalAlign,
            'letterSpacing': letterSpacing,
            'lineSpacing': lineSpacing,
            'enableSoftLineBreak': enableSoftLineBreak
          }); // 创建容器并应用尺寸约束，使用纹理变化键强制重建
        return SizedBox(
          key: textureChangeKey, // 使用纹理变化键确保纹理变化时widget重建
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: ClipRect(
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: painter,
                // 确保子组件扩展以填满整个区域
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }
}
