import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/service_providers.dart';
import '../../../../domain/models/work/work_entity.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../widgets/image/cached_image.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../../widgets/tag_list.dart';

class WorkCard extends ConsumerWidget {
  final WorkEntity work;
  final void Function()? onTap;
  final bool selected;
  final double? width;
  final double? height;

  const WorkCard({
    super.key,
    required this.work,
    this.onTap,
    this.selected = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageService = ref.watch(workStorageProvider);

    return FutureBuilder<String>(
      future: Future.value(storageService.getWorkCoverThumbnailPath(work.id)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SkeletonLoader(
            width: width ?? 200,
            height: height ?? 280,
          );
        }

        final coverPath = snapshot.data!;

        return Card(
          clipBehavior: Clip.antiAlias,
          color: selected ? AppColors.selectedCard : null,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 缩略图
                Expanded(
                  child: CachedImage(
                    path: coverPath,
                    width: width,
                    cacheKey: work.updateTime.millisecondsSinceEpoch.toString(),
                    height: height,
                    fit: BoxFit.cover,
                  ),
                ),
                // 标题和标签
                Padding(
                  padding: const EdgeInsets.all(AppSizes.p8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        work.title,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.p4),
                      if (work.tags.isNotEmpty)
                        TagList(
                          tags: work.tags,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
