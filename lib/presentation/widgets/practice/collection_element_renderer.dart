// filepath: c:\Users\wailik\Documents\Code\Flutter\demo\demo\lib\presentation\widgets\practice\collection_element_renderer.dart
// 完整修复版本 - 解决背景纹理显示问题

import 'package:flutter/material.dart';
// 引入新拆分的模块
import 'texture_config.dart' as tc;
import 'character_position.dart';
import 'collection_painter.dart';

// 所有工具类和函数已移动到各自的模块文件中

/// 集字绘制器 - 主类
/// 负责构建集字布局并管理渲染流程
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
  /// * applicationMode - 应用模式（背景或字符背景）
  /// * ref - Riverpod引用
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
    String applicationMode = 'background', // 'background' or 'characterBackground'
    dynamic ref,
  }) {
    // 强制清除纹理缓存，确保纹理变更可立即生效
    tc.TextureManager.invalidateTextureCache();

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

    // 计算每个字符的位置
    final List<CharacterPosition> positions = LayoutCalculator.calculatePositions(
      processedChars: charList,
      isNewLineList: isNewLineList,
      charSize: fontSize,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
      textAlign: textAlign,
      isVertical: !isHorizontal,
      fontColor: parsedFontColor,
      backgroundColor: parsedBackgroundColor,
      charsPerCol: 0,
      enableSoftLineBreak: enableSoftLineBreak,
      isLeftToRight: isLeftToRight,
      lineSpacing: lineSpacing,
      letterSpacing: letterSpacing,
    );

    // 使用StatefulBuilder来支持重绘
    return StatefulBuilder(
      builder: (context, setState) {
        // 解析纹理应用范围
        String effectiveApplicationMode = applicationMode;
        Map<String, dynamic>? nestedTextureData;
        bool hasEffectiveTexture = hasCharacterTexture;

        // 输出调试信息
        debugPrint('集字字符内容：${isEmpty ? "空" : characters}');
        debugPrint('初始纹理状态 - 应用模式：$applicationMode，是否有纹理：$hasCharacterTexture');

        if (characterImages is Map<String, dynamic>) {
          // 首先检查主 content 中的应用范围设置
          if (characterImages.containsKey('textureApplicationRange')) {
            effectiveApplicationMode =
                characterImages['textureApplicationRange'] as String? ??
                    'background';
            debugPrint('使用主 content 的纹理应用范围：$effectiveApplicationMode');
          }

          final content = characterImages['content'] as Map<String, dynamic>?;
          if (content != null) {
            // 仅当主 content 没有设置时，才使用嵌套 content 的应用范围
            if (!characterImages.containsKey('textureApplicationRange')) {
              effectiveApplicationMode =
                  content['textureApplicationRange'] as String? ?? 'background';
              debugPrint('使用嵌套 content 的纹理应用范围：$effectiveApplicationMode');
            }

            // 检查嵌套内容中是否有纹理数据
            if (content.containsKey('backgroundTexture') &&
                content['backgroundTexture'] != null) {
              final backgroundTexture = content['backgroundTexture'];
              if (backgroundTexture != null &&
                  backgroundTexture is Map<String, dynamic>) {
                nestedTextureData = backgroundTexture;
                hasEffectiveTexture = true;
                debugPrint('发现有效的嵌套纹理数据：$nestedTextureData');
              }
            }
          }
        }

        // 创建纹理配置，优先使用显式传入的应用模式参数
        final textureConfig = tc.TextureConfig(
          enabled: hasEffectiveTexture &&
              (characterTextureData != null || nestedTextureData != null),
          data: characterTextureData ?? nestedTextureData,
          fillMode: textureFillMode,
          opacity: textureOpacity,
          applicationMode: effectiveApplicationMode,
        );

        debugPrint('''纹理配置详情：
  启用状态：${hasEffectiveTexture ? "✅" : "❌"}
  纹理数据：${(characterTextureData != null || nestedTextureData != null) ? "✅" : "❌"}
  应用模式：$effectiveApplicationMode
  填充模式：$textureFillMode
  不透明度：$textureOpacity''');

        // 创建自定义绘制器
        final painter = CollectionPainter(
          characters: charList,
          positions: positions,
          fontSize: fontSize,
          characterImages: characterImages,
          textureConfig: textureConfig,
          ref: ref,
        );

        // 设置重绘回调 - 使用更安全的方式处理异步重绘
        painter.setRepaintCallback(() {
          // 使用安全的方式触发重绘，避免 setState after dispose 错误
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 这里不直接调用 setState，而是通知 Flutter 框架需要重新构建
            // 这样可以避免在组件已经 dispose 后调用 setState 的问题
            WidgetsBinding.instance.scheduleForcedFrame();
          });
        });

        // 创建容器并应用尺寸约束
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: CustomPaint(
            // 使用已配置好重绘回调的 painter
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


}
