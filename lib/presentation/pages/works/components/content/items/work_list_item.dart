import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../../domain/entities/work.dart';
import '../../../../../../theme/app_sizes.dart';
import '../../../../../../utils/date_formatter.dart';
import '../../../../../../utils/path_helper.dart';

class WorkListItem extends StatelessWidget {
  final Work work;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;  // 修改为必需参数

  const WorkListItem({
    super.key,
    required this.work,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: isSelected ? AppSizes.cardElevationSelected : AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        side: isSelected ? BorderSide(
          color: theme.colorScheme.primary,
          width: 2,
        ) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: AppSizes.listItemHeight,
          child: Row(
            children: [
              // 缩略图区域
              AspectRatio(
                aspectRatio: 1,
                child: _buildThumbnail(context),
              ),
              // 信息区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题行
                      Text(
                        work.name ?? '未命名作品',
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.xs),
                      // 作者行
                      if (work.author != null)
                        Text(
                          work.author!,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      // 底部信息行
                      Row(
                        children: [
                          // 标签组
                          Expanded(
                            child: Row(
                              children: [
                                if (work.style != null)
                                  _buildTag(context, work.style!),
                                if (work.tool != null) ...[
                                  const SizedBox(width: AppSizes.xs),
                                  _buildTag(context, work.tool!),
                                ],
                              ],
                            ),
                          ),
                          // 时间
                          Text(
                            DateFormatter.formatCompact(work.creationDate ?? work.createTime!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (work.id == null) return _buildPlaceholder(context);
    
    return FutureBuilder<String?>(
      future: PathHelper.getWorkThumbnailPath(work.id!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final file = File(snapshot.data!);
          return Image.file(
            file,
            width: AppSizes.thumbnailSize,
            height: AppSizes.thumbnailSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(context),
          );
        }
        return _buildPlaceholder(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(work.name ?? '', style: theme.textTheme.titleMedium),
        if (work.author != null) ...[
          const SizedBox(height: 4),
          Text(work.author!, style: theme.textTheme.bodyMedium),
        ],
        const Spacer(),
        Row(
          children: [
            if (work.style != null) _buildTag(context, work.style!),
            if (work.tool != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildTag(context, work.tool!),
              ),
          ],
        )
      ],
    );
  }

  Widget _buildTag(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s,
        vertical: AppSizes.xxs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.xs),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: AppSizes.thumbnailSize,
      height: AppSizes.thumbnailSize,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
