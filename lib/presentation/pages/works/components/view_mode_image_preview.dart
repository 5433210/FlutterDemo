import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../domain/models/work/work_image.dart';
import 'thumbnail_strip.dart';

/// 作品图片预览组件（查看模式）
class ViewModeImagePreview extends StatelessWidget {
  final List<WorkImage> images;
  final int selectedIndex;
  final Function(int) onImageSelect;

  const ViewModeImagePreview({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onImageSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildPreviewArea(context),
        ),
        if (images.length > 1)
          SizedBox(
            height: 100,
            child: ThumbnailStrip<WorkImage>(
              images: images,
              selectedIndex: selectedIndex,
              onTap: onImageSelect,
              pathResolver: (image) => image.thumbnailPath.isNotEmpty
                  ? image.thumbnailPath
                  : image.path,
              keyResolver: (image) => image.id,
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewArea(BuildContext context) {
    if (images.isEmpty) {
      return const Center(
        child: Text('没有图片'),
      );
    }

    final image = images[selectedIndex];
    final imagePath =
        image.thumbnailPath.isNotEmpty ? image.thumbnailPath : image.path;

    return Center(
      child: Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('图片加载失败', style: TextStyle(color: Colors.red)),
              ],
            ),
          );
        },
      ),
    );
  }
}
