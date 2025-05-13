// filepath: c:\Users\wailik\Documents\Code\Flutter\demo\demo\lib\presentation\widgets\practice\collection_element_renderer.dart
// 完整修复版本 - 集成所有原有功能与新特性

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import 'advanced_collection_painter.dart';
import 'character_position.dart';
import 'collection_painter.dart';
// 引入所有已拆分的模块
import 'texture_config.dart' as tc;
import 'texture_manager.dart';

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
    String textureFillMode = 'repeat',
    double textureOpacity = 1.0,
    String textureApplicationRange =
        'background', // 'background' or 'characterBackground'
    WidgetRef? ref,
  }) {
    // 使用增强版纹理管理器清除缓存，确保纹理变更可立即生效
    if (ref != null) {
      EnhancedTextureManager.instance.invalidateTextureCache(ref);
    }

    // 兼容原有支持 - 无内容时显示提示
    if (characters.isEmpty) {
      return const Center(
          child: Text('请输入汉字内容', style: TextStyle(color: Colors.grey)));
    }

    // 检查是否为空字符情况
    final bool isEmpty = characters.isEmpty;

    // 获取可用区域大小，扣减内边距
    final availableWidth = constraints.maxWidth - padding * 2;
    final availableHeight = constraints.maxHeight - padding * 2;

    // 添加调试信息
    debugPrint('''集字布局初始化：
  原始尺寸：${constraints.maxWidth}x${constraints.maxHeight}
  内边距：$padding
  可用尺寸：${availableWidth}x$availableHeight''');

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
    if (enableSoftLineBreak) {
      // 根据书写模式决定使用宽度还是高度
      final effectiveSize = isHorizontal ? availableWidth : availableHeight;

      // 计算每行/列可容纳的字符数，考虑字间距
      if (effectiveSize > 0 && fontSize > 0) {
        // 使用和原始实现相同的计算方式
        final maxCharsPerLine =
            ((effectiveSize + letterSpacing) / (fontSize + letterSpacing))
                .floor();
        charsPerCol = maxCharsPerLine > 0 ? maxCharsPerLine : 1;

        debugPrint(
            '✅ 自动换行计算 - 有效尺寸: $effectiveSize, 字体大小: $fontSize, 字间距: $letterSpacing');
        debugPrint('✅ 每行字符数计算: 最大值=$maxCharsPerLine, 实际使用值=$charsPerCol');
        debugPrint(
            '✅ 总字符数: ${charList.length}, 预计行数: ${(charList.length / charsPerCol).ceil()}');
      }
    }

    // 计算每个字符的位置
    final List<CharacterPosition> positions =
        LayoutCalculator.calculatePositions(
      processedChars: charList,
      isNewLineList: isNewLineList,
      charSize: fontSize,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
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

    // 使用StatefulBuilder来支持重绘
    return StatefulBuilder(
      builder: (context, setState) {
        // 解析纹理应用范围
        String effectiveApplicationMode = textureApplicationRange;
        Map<String, dynamic>? effectiveTextureData;
        bool hasEffectiveTexture = hasCharacterTexture;

        // 输出调试信息
        debugPrint('集字字符内容：${isEmpty ? "空" : characters}');
        debugPrint(
            '初始纹理状态 - 应用模式：$textureApplicationRange，是否有纹理：$hasCharacterTexture');

        // 递归查找最深层的有效纹理数据
        Map<String, dynamic>? findDeepestTextureData(Map<String, dynamic> data) {
          // 首先检查当前层是否有背景纹理
          if (data.containsKey('backgroundTexture') && 
              data['backgroundTexture'] != null &&
              data['backgroundTexture'] is Map<String, dynamic>) {
            return data;
          }
          
          // 如果当前层没有背景纹理，但有嵌套内容，则递归查找
          if (data.containsKey('content') && 
              data['content'] != null && 
              data['content'] is Map<String, dynamic>) {
            return findDeepestTextureData(data['content'] as Map<String, dynamic>);
          }
          
          // 如果没有找到任何纹理数据，返回null
          return null;
        }

        // 从嵌套结构中提取应用范围
        String extractApplicationRange(Map<String, dynamic> data) {
          // 首先检查当前层是否有应用范围设置
          if (data.containsKey('textureApplicationRange')) {
            return data['textureApplicationRange'] as String? ?? 'background';
          }
          
          // 如果当前层没有应用范围设置，但有嵌套内容，则递归查找
          if (data.containsKey('content') && 
              data['content'] != null && 
              data['content'] is Map<String, dynamic>) {
            return extractApplicationRange(data['content'] as Map<String, dynamic>);
          }
          
          // 如果没有找到任何应用范围设置，返回默认值
          return 'background';
        }

        if (characterImages is Map<String, dynamic>) {
          // 查找最深层的有效纹理数据
          final deepestTextureData = findDeepestTextureData(characterImages);
          
          if (deepestTextureData != null) {
            // 提取应用范围
            effectiveApplicationMode = extractApplicationRange(characterImages);
            debugPrint('使用提取的纹理应用范围：$effectiveApplicationMode');
            
            // 提取纹理数据
            if (deepestTextureData.containsKey('backgroundTexture') &&
                deepestTextureData['backgroundTexture'] != null) {
              effectiveTextureData = deepestTextureData['backgroundTexture'];
              hasEffectiveTexture = true;
              debugPrint('发现有效的纹理数据：$effectiveTextureData');
            }
          }
        }

        // 创建纹理配置，优先使用显式传入的应用模式参数
        final textureConfig = tc.TextureConfig(
          enabled: hasEffectiveTexture &&
              (characterTextureData != null || effectiveTextureData != null),
          data: characterTextureData ?? effectiveTextureData,
          fillMode: textureFillMode,
          opacity: textureOpacity,
          textureApplicationRange: effectiveApplicationMode,
        );

        debugPrint('''纹理配置详情：
  启用状态：${hasEffectiveTexture ? "✅" : "❌"}
  纹理数据：${(characterTextureData != null || effectiveTextureData != null) ? "✅" : "❌"}
  应用模式：$effectiveApplicationMode
  填充模式：$textureFillMode
  不透明度：$textureOpacity''');

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
        try {
          painter = AdvancedCollectionPainter(
            characters: charList,
            positions: positions,
            fontSize: fontSize,
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
                });
              });
            }
          } catch (e) {
            debugPrint('设置重绘回调失败: $e');
          }
        } catch (e) {
          // 如果创建AdvancedCollectionPainter失败，尝试使用基础绘制器
          debugPrint('创建AdvancedCollectionPainter失败，使用CollectionPainter: $e');
          painter = CollectionPainter(
            characters: charList,
            positions: positions,
            fontSize: fontSize,
            characterImages: characterImages,
            textureConfig: textureConfig,
            ref: ref,
          );
          
          // 设置重绘回调 - 基础版本
          (painter as CollectionPainter).setRepaintCallback(() {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              WidgetsBinding.instance.scheduleForcedFrame();
            });
          });
        }

        // 汇报实际生效的参数值
        debugPrint('📍 实际使用的集字渲染参数：');
        debugPrint('  内边距: $padding');
        debugPrint('  书写模式: $writingMode');
        debugPrint('  水平对齐: $textAlign');
        debugPrint('  垂直对齐: $verticalAlign');
        debugPrint('  字间距: $letterSpacing');
        debugPrint('  行间距: $lineSpacing');
        debugPrint('  自动换行: ${enableSoftLineBreak ? '√' : '✗'}');

        // 创建容器并应用尺寸约束
        // 注意：这里我们使用SizedBox来确保尺寸符合传入的constraints
        // 内边距已经在位置计算时考虑，因此不需要额外的Padding组件
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: CustomPaint(
            // 使用已配置好重绘回调的 painter
            painter: painter,
            // 确保子组件扩展以填满整个区域
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
