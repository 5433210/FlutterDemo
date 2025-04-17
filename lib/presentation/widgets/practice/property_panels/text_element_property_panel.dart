import 'package:flutter/material.dart';

import '../../../../domain/models/practice/practice_element.dart';
import 'property_panel_base.dart';

/// 文本内容元素的属性面板
class TextElementPropertyPanel extends StatelessWidget {
  final TextElement element;
  final Function(PracticeElement) onElementChanged;

  const TextElementPropertyPanel({
    Key? key,
    required this.element,
    required this.onElementChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文本内容元素标题
            const Text(
              '文本内容属性',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 基础属性（位置、大小、旋转、透明度、锁定）
            BasicPropertyPanel(
              element: element,
              onElementChanged: onElementChanged,
            ),

            const SizedBox(height: 16),

            // 文本特有属性
            const PropertyGroupTitle(title: '文本属性'),

            // 字体
            DropdownPropertyRow(
              label: '字体',
              value: element.fontFamily,
              options: const [
                'Arial',
                'Times New Roman',
                'Courier New',
                'SimSun',
                'KaiTi',
                'SimHei',
                'Microsoft YaHei'
              ],
              displayLabels: const {
                'Arial': 'Arial',
                'Times New Roman': 'Times New Roman',
                'Courier New': 'Courier New',
                'SimSun': '宋体',
                'KaiTi': '楷体',
                'SimHei': '黑体',
                'Microsoft YaHei': '微软雅黑',
              },
              onChanged: (value) {
                if (value != null) {
                  onElementChanged(element.copyWith(fontFamily: value));
                }
              },
            ),

            // 字体大小
            SliderPropertyRow(
              label: '字体大小',
              value: element.fontSize,
              min: 8.0,
              max: 72.0,
              divisions: 64,
              onChanged: (value) {
                onElementChanged(element.copyWith(fontSize: value));
              },
              valueLabel: '${element.fontSize.toInt()}px',
            ),

            // 字体颜色
            ColorPropertyRow(
              label: '字体颜色',
              color: _parseColor(element.fontColor),
              onChanged: (color) {
                onElementChanged(element.copyWith(
                    fontColor:
                        '#${color.value.toRadixString(16).substring(2).toUpperCase()}'));
              },
            ),

            // 背景颜色
            ColorPropertyRow(
              label: '背景颜色',
              color: _parseColor(element.backgroundColor),
              onChanged: (color) {
                onElementChanged(element.copyWith(
                    backgroundColor:
                        '#${color.value.toRadixString(16).substring(2).toUpperCase()}'));
              },
            ),

            // 对齐方式
            DropdownPropertyRow(
              label: '对齐方式',
              value: _textAlignToString(element.textAlign),
              options: const ['left', 'center', 'right', 'justify'],
              displayLabels: const {
                'left': '左对齐',
                'center': '居中对齐',
                'right': '右对齐',
                'justify': '两端对齐',
              },
              onChanged: (value) {
                if (value != null) {
                  onElementChanged(element.copyWith(
                    textAlign: _parseTextAlign(value),
                  ));
                }
              },
            ),

            // 行间距
            SliderPropertyRow(
              label: '行间距',
              value: element.lineSpacing,
              min: 0.5,
              max: 3.0,
              onChanged: (value) {
                onElementChanged(element.copyWith(lineSpacing: value));
              },
              valueLabel: element.lineSpacing.toStringAsFixed(1),
            ),

            // 字间距
            SliderPropertyRow(
              label: '字间距',
              value: element.letterSpacing,
              min: -2.0,
              max: 10.0,
              onChanged: (value) {
                onElementChanged(element.copyWith(letterSpacing: value));
              },
              valueLabel: '${element.letterSpacing.toStringAsFixed(1)}px',
            ),

            // 透明度
            SliderPropertyRow(
              label: '透明度',
              value: element.opacity,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                onElementChanged(element.copyWith(opacity: value));
              },
              valueLabel: '${(element.opacity * 100).toInt()}%',
            ),

            // 边距设置
            const PropertyGroupTitle(title: '边距设置'),
            _buildPaddingControls(element.padding, (padding) {
              onElementChanged(element.copyWith(padding: padding));
            }),

            // 文本内容
            const PropertyGroupTitle(title: '文本内容'),

            // 内容输入
            TextPropertyRowMultiline(
              label: '内容',
              value: element.text,
              maxLines: 10,
              onChanged: (value) {
                onElementChanged(element.copyWith(text: value));
              },
            ),

            // 预览
            const SizedBox(height: 16),
            const Text(
              '预览',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: _parseColor(element.backgroundColor)
                    .withOpacity(element.opacity),
              ),
              child: Text(
                element.text.isEmpty ? '无内容' : element.text,
                style: TextStyle(
                  fontSize: element.fontSize,
                  fontFamily: element.fontFamily,
                  color: _parseColor(element.fontColor),
                  height: element.lineSpacing,
                  letterSpacing: element.letterSpacing,
                ),
                textAlign: element.textAlign,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建边距控制UI
  Widget _buildPaddingControls(
      EdgeInsets padding, Function(EdgeInsets) onChanged) {
    return Column(
      children: [
        TextPropertyRow(
          label: '上边距',
          value: padding.top.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final top = double.tryParse(value) ?? padding.top;
            onChanged(EdgeInsets.only(
              top: top,
              left: padding.left,
              right: padding.right,
              bottom: padding.bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '右边距',
          value: padding.right.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final right = double.tryParse(value) ?? padding.right;
            onChanged(EdgeInsets.only(
              top: padding.top,
              left: padding.left,
              right: right,
              bottom: padding.bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '下边距',
          value: padding.bottom.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final bottom = double.tryParse(value) ?? padding.bottom;
            onChanged(EdgeInsets.only(
              top: padding.top,
              left: padding.left,
              right: padding.right,
              bottom: bottom,
            ));
          },
        ),
        TextPropertyRow(
          label: '左边距',
          value: padding.left.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final left = double.tryParse(value) ?? padding.left;
            onChanged(EdgeInsets.only(
              top: padding.top,
              left: left,
              right: padding.right,
              bottom: padding.bottom,
            ));
          },
          divider: false,
        ),
      ],
    );
  }

  // 颜色字符串转Color对象
  Color _parseColor(String colorString) {
    return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
  }

  // 字符串转TextAlign枚举
  TextAlign _parseTextAlign(String align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  // TextAlign枚举转字符串
  String _textAlignToString(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return 'center';
      case TextAlign.right:
        return 'right';
      case TextAlign.justify:
        return 'justify';
      default:
        return 'left';
    }
  }
}
