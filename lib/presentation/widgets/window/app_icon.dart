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
    // Try to load the icon, fallback to default if fails
    try {
      return Image.asset(
        'assets/images/logo.png',
        width: widget.size,
        height: widget.size,
        color: widget.color,
        errorBuilder: (context, error, stackTrace) {
          AppLogger.warning('Failed to load logo.png: $error');
          // Try ICO format as fallback
          return Image.asset(
            'assets/images/logo.ico',
            width: widget.size,
            height: widget.size,
            errorBuilder: (context, error, stackTrace) {
              AppLogger.warning('Failed to load logo.ico: $error');
              return _fallbackIcon();
            },
          );
        },
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
