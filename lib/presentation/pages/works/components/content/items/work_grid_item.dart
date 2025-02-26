import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../../domain/entities/work.dart';
import '../../../../../../domain/enums/work_style.dart';
import '../../../../../../domain/enums/work_tool.dart';
import '../../../../../../theme/app_sizes.dart';
import '../../../../../../utils/date_formatter.dart';
import '../../../../../../utils/path_helper.dart';

class WorkGridItem extends StatelessWidget {
  final Work work;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;

  const WorkGridItem({
    super.key,
    required this.work,
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(0), // 移除默认边距
      elevation:
          isSelected ? AppSizes.cardElevationSelected : AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        side: isSelected
            ? BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 使整个卡片尽可能小
          children: [
            // 图片容器 - 固定比例
            AspectRatio(
              aspectRatio: 4 / 3, // 保持4:3的图片比例
              child: _buildThumbnail(context),
            ),
            // 信息容器 - 紧凑但可读的布局
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.s, // 左边距
                AppSizes.xs, // 上边距
                AppSizes.s, // 右边距
                AppSizes.xs, // 底部边距减小
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题 - 单行截断
                  Text(
                    work.name ?? '未命名作品',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15, // 调整为更舒适的标题大小
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs), // 适当的间距
                  // 作者和时间 - 单行截断
                  Row(
                    children: [
                      if (work.author != null)
                        Expanded(
                          child: Text(
                            work.author!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13, // 稍微增大作者字体
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Text(
                        DateFormatter.formatCompact(
                            work.creationDate ?? work.createTime!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12, // 日期字体大小
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xxs),
                  // 标签 - 紧凑但可读的标签
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4), // 底部减少留白
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (work.style != null)
                            _buildTag(
                                context,
                                WorkStyle.fromValue(work.style!)?.label ??
                                    work.style!),
                          if (work.tool != null) ...[
                            const SizedBox(width: AppSizes.xs),
                            _buildTag(
                                context,
                                WorkTool.fromValue(work.tool!)?.label ??
                                    work.tool!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xs,
        vertical: 2, // 增加垂直内边距使标签更可读
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 11, // 增加字体大小
          color: theme.colorScheme.onSecondaryContainer,
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
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(context),
          );
        }
        return _buildPlaceholder(context);
      },
    );
  }
}
