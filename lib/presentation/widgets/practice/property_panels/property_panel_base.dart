import 'package:flutter/material.dart';

import '../../../../domain/models/practice/practice_element.dart';
import '../../../../l10n/app_localizations.dart';

/// 基础属性面板
class BasicPropertyPanel extends StatelessWidget {
  final PracticeElement element;
  final Function(PracticeElement) onElementChanged;

  const BasicPropertyPanel({
    Key? key,
    required this.element,
    required this.onElementChanged,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PropertyGroupTitle(title: '基础属性'),

        // 位置
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                '位置',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Text('X: '),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: element.x.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final x = double.tryParse(value);
                  if (x != null) {
                    onElementChanged(element.copyWith(x: x));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('Y: '),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: element.y.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final y = double.tryParse(value);
                  if (y != null) {
                    onElementChanged(element.copyWith(y: y));
                  }
                },
              ),
            ),
          ],
        ),
        const Divider(),

        // 大小
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                l10n.elementSize,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text('${l10n.elementWidth}: '),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: element.width.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final width = double.tryParse(value);
                  if (width != null && width > 0) {
                    onElementChanged(element.copyWith(width: width));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Text('${l10n.elementHeight}: '),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: element.height.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final height = double.tryParse(value);
                  if (height != null && height > 0) {
                    onElementChanged(element.copyWith(height: height));
                  }
                },
              ),
            ),
          ],
        ),
        const Divider(),

        // 旋转角度
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                '旋转角度',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Slider(
                value: element.rotation,
                min: 0,
                max: 360,
                divisions: 36,
                onChanged: (value) {
                  onElementChanged(element.copyWith(rotation: value));
                },
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${element.rotation.toInt()}°',
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const Divider(),

        // 透明度
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                '透明度',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Slider(
                value: element.opacity,
                min: 0,
                max: 1,
                divisions: 10,
                onChanged: (value) {
                  onElementChanged(element.copyWith(opacity: value));
                },
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${(element.opacity * 100).toInt()}%',
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const Divider(),

        // 锁定
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                l10n.lock,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Checkbox(
              value: element.isLocked,
              onChanged: (value) {
                if (value != null) {
                  onElementChanged(element.copyWith(isLocked: value));
                }
              },
            ),
            Text(element.isLocked ? l10n.locked : l10n.unlocked),
          ],
        ),
        const Divider(),

        // 图层
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                '所属图层',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(element.layerId),
          ],
        ),
      ],
    );
  }
}

/// 颜色选择属性行
class ColorPropertyRow extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color>? onChanged;
  final bool divider;

  const ColorPropertyRow({
    Key? key,
    required this.label,
    required this.color,
    this.onChanged,
    this.divider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 简单的预设颜色
    final presetColors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.brown,
      Colors.grey,
    ];

    Widget row = Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Text(
            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}'),
        const Spacer(),
        PopupMenuButton<Color>(
          tooltip: l10n.colorPicker,
          icon: const Icon(Icons.colorize),
          itemBuilder: (context) {
            return presetColors.map((presetColor) {
              return PopupMenuItem(
                value: presetColor,
                child: Container(
                  width: 24,
                  height: 24,
                  color: presetColor,
                ),
              );
            }).toList();
          },
          onSelected: onChanged,
        ),
      ],
    );

    if (divider) {
      return Column(
        children: [
          row,
          const Divider(),
        ],
      );
    }
    return row;
  }
}

/// 下拉选择属性行
class DropdownPropertyRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final Map<String, String>? displayLabels;
  final ValueChanged<String?>? onChanged;
  final bool divider;

  const DropdownPropertyRow({
    Key? key,
    required this.label,
    required this.value,
    required this.options,
    this.displayLabels,
    this.onChanged,
    this.divider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget row = Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(displayLabels?[option] ?? option),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );

    if (divider) {
      return Column(
        children: [
          row,
          const Divider(),
        ],
      );
    }
    return row;
  }
}

/// 属性组标题
class PropertyGroupTitle extends StatelessWidget {
  final String title;

  const PropertyGroupTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(thickness: 2),
        ],
      ),
    );
  }
}

/// 滑块属性行
class SliderPropertyRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String? valueLabel;
  final bool divider;

  const SliderPropertyRow({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.onChanged,
    this.valueLabel,
    this.divider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget row = Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            valueLabel ?? value.toString(),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );

    if (divider) {
      return Column(
        children: [
          row,
          const Divider(),
        ],
      );
    }
    return row;
  }
}

/// 文本输入属性行
class TextPropertyRow extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final bool divider;

  const TextPropertyRow({
    Key? key,
    required this.label,
    required this.value,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.divider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget row = Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: TextFormField(
            initialValue: value,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );

    if (divider) {
      return Column(
        children: [
          row,
          const Divider(),
        ],
      );
    }
    return row;
  }
}

/// 多行文本输入属性行
class TextPropertyRowMultiline extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool divider;

  const TextPropertyRowMultiline({
    Key? key,
    required this.label,
    required this.value,
    this.onChanged,
    this.maxLines = 5,
    this.divider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          maxLines: maxLines,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      ],
    );

    if (divider) {
      return Column(
        children: [
          content,
          const Divider(),
        ],
      );
    }
    return content;
  }
}
