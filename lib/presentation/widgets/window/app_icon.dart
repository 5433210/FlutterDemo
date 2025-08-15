import 'package:charasgem/infrastructure/logging/logger.dart';
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
    // Try to load from a specific file path
    try {
      return CachedImage(
        path: Theme.of(context).brightness == Brightness.dark
            ? 'assets/images/zi.ico'
            : 'assets/images/zi.ico',

        width: widget.size,
        height: widget.size,
        // Note: CachedImage doesn't support color and colorBlendMode directly
        // Consider using a ColorFiltered widget if needed
      );
    } catch (e) {
      AppLogger.error('Error loading icon: $e');
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
