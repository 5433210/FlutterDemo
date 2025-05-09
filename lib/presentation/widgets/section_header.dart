import 'package:flutter/material.dart';

/// 区块标题组件
class SectionHeader extends StatelessWidget {
  /// 标题
  final String title;

  /// 内边距
  final EdgeInsetsGeometry padding;

  /// 构造函数
  const SectionHeader({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
