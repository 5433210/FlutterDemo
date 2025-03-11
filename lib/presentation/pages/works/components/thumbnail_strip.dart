import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/service_providers.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_sizes.dart';
import '../../../widgets/skeleton_loader.dart';

class ThumbnailStrip extends ConsumerWidget {
  final String workId;
  final List<String> imageIds;
  final int selectedIndex;
  final Function(int) onThumbnailTap;
  final double? width;
  final double? height;

  const ThumbnailStrip({
    super.key,
    required this.workId,
    required this.imageIds,
    required this.selectedIndex,
    required this.onThumbnailTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppSizes.r4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < imageIds.length; i++) ...[
              _ThumbnailItem(
                workId: workId,
                imageId: imageIds[i],
                isSelected: i == selectedIndex,
                onTap: () => onThumbnailTap(i),
                width: height,
                height: height,
              ),
              if (i < imageIds.length - 1) const SizedBox(width: AppSizes.p4),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThumbnailItem extends ConsumerWidget {
  final String workId;
  final String imageId;
  final bool isSelected;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const _ThumbnailItem({
    required this.workId,
    required this.imageId,
    required this.isSelected,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageService = ref.watch(storageServiceProvider);

    return FutureBuilder<String>(
      future: storageService.getWorkImageThumbnailPath(workId, imageId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SkeletonLoader(
            width: width ?? 60,
            height: height ?? 60,
          );
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(AppSizes.r4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.r4),
              child: Image.file(
                File(snapshot.data!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.background,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textHint,
      ),
    );
  }
}
