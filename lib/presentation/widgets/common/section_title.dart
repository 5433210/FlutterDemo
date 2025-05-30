import 'package:flutter/material.dart';

/// 一个简单的部分标题组件，用于在表单或页面的不同部分之间提供分隔和标题
class SectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final TextStyle? textStyle;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.only(bottom: 8.0),
    this.color,
    this.textStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: textStyle ??
                  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color ?? theme.colorScheme.primary,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 一个带有底部分隔线的部分标题
class SectionTitleWithDivider extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final TextStyle? textStyle;
  final Widget? trailing;
  final Color? dividerColor;

  const SectionTitleWithDivider({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.only(bottom: 8.0),
    this.color,
    this.textStyle,
    this.trailing,
    this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: title,
          padding: padding,
          color: color,
          textStyle: textStyle,
          trailing: trailing,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: dividerColor ?? theme.dividerColor.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}
