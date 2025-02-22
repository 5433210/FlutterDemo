import 'package:flutter/material.dart';

import '../../../../theme/app_sizes.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSizes.l),
          Text(
            '点击或拖放图片到此处',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.m),
          Text(
            '支持 jpg、png、webp 格式',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}