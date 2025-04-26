import 'package:flutter/material.dart';

import '../../../common/editable_number_field.dart';

/// 集字内容的几何属性面板
class GeometryPropertiesPanel extends StatelessWidget {
  final Map<String, dynamic> element;
  final Function(String, dynamic) onPropertyChanged;

  const GeometryPropertiesPanel({
    Key? key,
    required this.element,
    required this.onPropertyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    return ExpansionTile(
      title: const Text('几何属性'),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // X和Y位置
              Row(
                children: [
                  Expanded(
                    child: EditableNumberField(
                      label: 'X',
                      value: x,
                      suffix: 'px',
                      min: 0,
                      max: 10000,
                      onChanged: (value) => onPropertyChanged('x', value),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: EditableNumberField(
                      label: 'Y',
                      value: y,
                      suffix: 'px',
                      min: 0,
                      max: 10000,
                      onChanged: (value) => onPropertyChanged('y', value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // 宽度和高度
              Row(
                children: [
                  Expanded(
                    child: EditableNumberField(
                      label: '宽度',
                      value: width,
                      suffix: 'px',
                      min: 10,
                      max: 10000,
                      onChanged: (value) => onPropertyChanged('width', value),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: EditableNumberField(
                      label: '高度',
                      value: height,
                      suffix: 'px',
                      min: 10,
                      max: 10000,
                      onChanged: (value) => onPropertyChanged('height', value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // 旋转角度
              EditableNumberField(
                label: '旋转',
                value: rotation,
                suffix: '°',
                min: -360,
                max: 360,
                decimalPlaces: 1,
                onChanged: (value) => onPropertyChanged('rotation', value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
