import 'package:flutter/material.dart';

class TabBarThemeWrapper extends StatelessWidget {
  final Widget child;

  const TabBarThemeWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        tabBarTheme: TabBarTheme(
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor:
              theme.colorScheme.onSurface.withValues(alpha: 0.7),
          // 将分割线颜色设置为透明，避免重复的分割线
          dividerColor: Colors.transparent,
          indicatorColor: theme.colorScheme.primary,
          // 添加一些水平内边距，使标签页标题不会靠得太近
          indicatorSize: TabBarIndicatorSize.tab,
          // 轻微提升标签切换的动画时长
          labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        dividerTheme: const DividerThemeData(
          thickness: 1,
          space: 1,
        ),
      ),
      child: child,
    );
  }
}
