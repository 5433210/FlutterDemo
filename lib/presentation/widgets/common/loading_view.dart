import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// 通用加载视图
class LoadingView extends StatelessWidget {
  final String? message;
  final double? size;
  final double? strokeWidth;
  final bool showBackground;
  final Color? backgroundColor;

  const LoadingView({
    super.key,
    this.message,
    this.size,
    this.strokeWidth,
    this.showBackground = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surface;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size ?? 32,
          height: size ?? 32,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth ?? 2,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSizes.s),
          Text(message!),
        ],
      ],
    );

    if (showBackground) {
      content = Container(
        color: bgColor,
        child: content,
      );
    }

    return Center(child: content);
  }
}
