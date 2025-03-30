import 'package:flutter/material.dart';

/// 笔刷大小滑块
/// 提供笔刷大小调节功能
class BrushSizeSlider extends StatelessWidget {
  /// 当前值
  final double value;

  /// 最小值
  final double min;

  /// 最大值
  final double max;

  /// 变更回调
  final ValueChanged<double>? onChanged;

  /// 构造函数
  const BrushSizeSlider({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.brush, size: 16),

        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 1).round(),
            label: '${value.round()}px',
            onChanged: onChanged,
          ),
        ),

        // 显示当前笔刷大小
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${value.round()}px',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
