import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../image/cached_image.dart';

/// 应用图标组件，确保与Windows任务栏图标保持一致
class AppIconWidget extends StatefulWidget {
  final Color? color;
  final double size;

  const AppIconWidget({
    super.key,
    this.color,
    this.size = AppSizes.iconMedium,
  });

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    // 使用与应用图标相同的图标
    // return Icon(
    //   Icons.brush_outlined, // 您可以替换为自定义图标
    //   color: color,
    //   size: widget.size,
    // );

    // Try to load from a specific file path
    try {
      return CachedImage(
        path: Theme.of(context).brightness == Brightness.dark
            ? 'assets/images/app_trans_bg4.ico'
            : 'assets/images/app_trans_bg4.ico',
        width: widget.size,
        height: widget.size,
        // Note: CachedImage doesn't support color and colorBlendMode directly
        // Consider using a ColorFiltered widget if needed
      );
    } catch (e) {
      print('Error loading icon: $e');
      return _fallbackIcon();
    }
  }

  // 默认使用Flutter图标作为备用
  Widget _fallbackIcon() {
    return Icon(
      Icons.brush_outlined,
      color: widget.color,
      size: widget.size,
    );
  }
}
