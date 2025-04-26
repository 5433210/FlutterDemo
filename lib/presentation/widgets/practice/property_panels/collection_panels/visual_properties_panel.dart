import 'package:flutter/material.dart';

import '../../../common/editable_number_field.dart';
import 'collection_color_utils.dart';

/// 集字内容的视觉属性面板
class VisualPropertiesPanel extends StatelessWidget {
  final Map<String, dynamic> element;
  final Function(String, dynamic) onPropertyChanged;
  final Function(String, dynamic) onContentPropertyChanged;

  const VisualPropertiesPanel({
    Key? key,
    required this.element,
    required this.onPropertyChanged,
    required this.onContentPropertyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;
    final content = element['content'] as Map<String, dynamic>;
    final fontColor = content['fontColor'] as String? ?? '#000000';
    final backgroundColor =
        content['backgroundColor'] as String? ?? 'transparent';
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;

    return ExpansionTile(
      title: const Text('视觉设置'),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 字体颜色和背景颜色
              const Text('颜色设置:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Text('字体颜色:'),
                  const SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: () {
                      showColorPickerDialog(
                        context,
                        fontColor,
                        (color) {
                          onContentPropertyChanged('fontColor',
                              CollectionColorUtils.colorToHex(color));
                        },
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CollectionColorUtils.hexToColor(fontColor),
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  const Text('背景颜色:'),
                  const SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: () {
                      showColorPickerDialog(
                        context,
                        backgroundColor,
                        (color) {
                          onContentPropertyChanged('backgroundColor',
                              CollectionColorUtils.colorToHex(color));
                        },
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CollectionColorUtils.hexToColor(backgroundColor),
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),

              // 透明度
              const Text('透明度:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Slider(
                      value: opacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      label: '${(opacity * 100).round()}%',
                      onChanged: (value) {
                        onPropertyChanged('opacity', value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    flex: 2,
                    child: EditableNumberField(
                      label: '透明度',
                      value: opacity * 100, // 转换为百分比
                      suffix: '%',
                      min: 0,
                      max: 100,
                      decimalPlaces: 0,
                      onChanged: (value) {
                        // 转换回 0-1 范围
                        onPropertyChanged('opacity', value / 100);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),

              // 内边距设置
              const Text('内边距:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Slider(
                      value: padding,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      label: '${padding.round()}px',
                      onChanged: (value) {
                        onContentPropertyChanged('padding', value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    flex: 2,
                    child: EditableNumberField(
                      label: '内边距',
                      value: padding,
                      suffix: 'px',
                      min: 0,
                      max: 100,
                      decimalPlaces: 0,
                      onChanged: (value) {
                        onContentPropertyChanged('padding', value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
