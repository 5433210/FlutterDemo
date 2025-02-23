import 'dart:io';

import 'package:flutter/material.dart';
import '../../../theme/app_sizes.dart';
import 'image_preview.dart';

class PracticePreview extends StatelessWidget {
  final String? imagePath;
  final String? backgroundImagePath;
  final double opacity;
  final VoidCallback? onRefresh;

  const PracticePreview({
    super.key,
    this.imagePath,
    this.backgroundImagePath,
    this.opacity = 0.5,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // 背景图层
        if (backgroundImagePath != null)
          Opacity(
            opacity: opacity,
            child: ImagePreview(
              file: File(backgroundImagePath!),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        // 练习图层
        if (imagePath != null)
          ImagePreview(
            file: File(imagePath!),
            width: double.infinity,
            height: double.infinity,
          ),
        // 无内容时的占位
        if (imagePath == null && backgroundImagePath == null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: AppSizes.spacingSmall),
                Text(
                  '暂无预览内容',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        // 刷新按钮
        if (onRefresh != null)
          Positioned(
            top: AppSizes.spacingSmall,
            right: AppSizes.spacingSmall,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
              tooltip: '刷新预览',
            ),
          ),
      ],
    );
  }
}
