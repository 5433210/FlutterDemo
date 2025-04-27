import 'dart:developer' as developer;

import 'package:demo/presentation/widgets/practice/text_renderer.dart';
import 'package:flutter/material.dart';

/// 文本元素渲染器
class TextElementRenderer extends StatelessWidget {
  final Map<String, dynamic> element;
  final bool isEditing;
  final bool isSelected;
  final double scale;
  final bool isPreviewMode;

  const TextElementRenderer({
    Key? key,
    required this.element,
    this.isEditing = false,
    this.isSelected = false,
    this.scale = 1.0,
    this.isPreviewMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 添加调试日志
    developer
        .log('Building TextElementRenderer with element: ${element['id']}');
    final content = element['content'] as Map<String, dynamic>;
    final String text = content['text'] as String? ?? '';
    final double fontSize =
        ((content['fontSize'] as num?) ?? 16.0).toDouble() * scale;
    final String fontFamily = content['fontFamily'] as String? ?? 'sans-serif';
    final String fontWeight = content['fontWeight'] as String? ?? 'normal';
    final String fontStyle = content['fontStyle'] as String? ?? 'normal';
    final String fontColorStr = content['fontColor'] as String? ?? '#000000';
    final String backgroundColorStr =
        content['backgroundColor'] as String? ?? 'transparent';
    final Color backgroundColor = TextRenderer.hexToColor(backgroundColorStr);
    final String textAlignStr = content['textAlign'] as String? ?? 'left';
    final String verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final double letterSpacing =
        (content['letterSpacing'] as num?)?.toDouble() ?? 0.0;
    final double lineHeight =
        (content['lineHeight'] as num?)?.toDouble() ?? 1.2;
    final bool underline = content['underline'] as bool? ?? false;
    final bool lineThrough = content['lineThrough'] as bool? ?? false;
    final String writingMode =
        content['writingMode'] as String? ?? 'horizontal-l';
    final double padding = (content['padding'] as num?)?.toDouble() ?? 4.0;

    // 创建文本样式
    final TextStyle textStyle = TextRenderer.createTextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontColor: fontColorStr,
      letterSpacing: letterSpacing,
      lineHeight: lineHeight,
      underline: underline,
      lineThrough: lineThrough,
    );

    // 使用与文本属性面板预览区完全相同的外层容器结构
    return Container(
      width: double.infinity,
      height: double.infinity,
      // 在预览模式下不显示边框
      decoration: isPreviewMode
          ? null
          : BoxDecoration(
              border: isSelected
                  ? Border.all(
                      color: Colors.blue.withAlpha(128),
                      width: 1.0,
                    )
                  : null,
            ),
      child: isEditing
          ? TextField(
              controller: TextEditingController(text: text),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: textStyle,
              textAlign: TextRenderer.getTextAlign(textAlignStr),
              maxLines: null,
              onChanged: (value) {
                // 实际应用中，这里应该触发一个回调来更新文本内容
              },
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // 打印调试信息
                developer.log(
                    '画布文本元素参数: textAlign=$textAlignStr, verticalAlign=$verticalAlign, writingMode=$writingMode');
                developer.log(
                    '画布文本元素约束: width=${constraints.maxWidth}, height=${constraints.maxHeight}');
                developer.log('画布文本元素内容: text=$text');
                developer.log(
                    '画布文本元素样式: fontSize=${textStyle.fontSize}, fontFamily=${textStyle.fontFamily}, fontWeight=${textStyle.fontWeight}, fontStyle=${textStyle.fontStyle}, color=${textStyle.color}');

                // 使用与文本属性面板预览区完全相同的容器结构
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Container(
                    alignment: Alignment.topRight, // 与面板预览区保持一致
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      // 在预览模式下不显示边框
                      border: isPreviewMode
                          ? null
                          : isSelected
                              ? Border.all(
                                  color: Colors.blue.withAlpha(128), width: 1.0)
                              : Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: writingMode.startsWith('vertical')
                          ? TextRenderer.renderVerticalText(
                              text: text,
                              style: textStyle,
                              textAlign: textAlignStr,
                              verticalAlign: verticalAlign,
                              writingMode: writingMode,
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth - padding * 2,
                                maxHeight: constraints.maxHeight - padding * 2,
                              ),
                              backgroundColor:
                                  Colors.transparent, // 已经在外层容器中设置了背景色
                            )
                          : TextRenderer.renderHorizontalText(
                              text: text,
                              style: textStyle,
                              textAlign: textAlignStr,
                              verticalAlign: verticalAlign,
                              writingMode: writingMode,
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth - padding * 2,
                                maxHeight: constraints.maxHeight - padding * 2,
                              ),
                              backgroundColor:
                                  Colors.transparent, // 已经在外层容器中设置了背景色
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
