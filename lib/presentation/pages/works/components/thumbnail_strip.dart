import 'package:flutter/material.dart';

import '../../../../domain/models/work/work_image.dart';
import '../../../widgets/image/cached_image.dart';

/// 缩略图条组件
class ThumbnailStrip extends StatelessWidget {
  final List<WorkImage> images;
  final int selectedIndex;
  final Function(int) onTap;
  final ScrollController? controller;

  const ThumbnailStrip({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          final isSelected = index == selectedIndex;

          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: _ThumbnailItem(
              image: image,
              isSelected: isSelected,
              onTap: () => onTap(index),
            ),
          );
        },
      ),
    );
  }
}

/// 缩略图项目组件
class _ThumbnailItem extends StatelessWidget {
  final WorkImage image;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThumbnailItem({
    required this.image,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: CachedImage(
            path: image.thumbnailPath ?? image.path,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
