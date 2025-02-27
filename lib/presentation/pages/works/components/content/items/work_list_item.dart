import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../../domain/entities/work.dart';
import '../../../../../../domain/enums/work_style.dart';
import '../../../../../../domain/enums/work_tool.dart';
import '../../../../../../theme/app_sizes.dart';
import '../../../../../../utils/date_formatter.dart';
import '../../../../../../utils/path_helper.dart';

class WorkListItem extends StatelessWidget {
  final Work work;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;

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
        child: SizedBox(
          height: 160, // 增加高度以容纳更多信息
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 缩略图区域 - 列表宽度的大约1/3 - 固定宽高比
              SizedBox(
                width: 200,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _buildThumbnail(context),
                ),
              ),

              // 信息区域 - 扩展以填满剩余空间
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题行
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              work.name ?? '未命名作品',
                              style: theme.textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (work.imageCount != null && work.imageCount! > 0)
                            _buildImageCount(context, work.imageCount!),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xs),

                      // 作者行
                      if (work.author != null)
                        Text(
                          work.author!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: AppSizes.s),

                      // 风格和工具
                      Row(
                        children: [
                          if (work.style != null)
                            _buildInfoItem(
                                context,
                                Icons.brush_outlined,
                                WorkStyle.fromValue(work.style!)?.label ??
                                    work.style!),
                          const SizedBox(width: AppSizes.m),
                          if (work.tool != null)
                            _buildInfoItem(
                                context,
                                Icons.construction_outlined,
                                WorkTool.fromValue(work.tool!)?.label ??
                                    work.tool!),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xs),

                      // 元数据信息和创作日期
                      if (_hasMetadata()) ...[
                        Text(
                          _getMetadataPreview(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const Spacer(),

                      // 底部日期信息
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 创作日期
                          if (work.creationDate != null)
                            _buildInfoItem(context, Icons.palette_outlined,
                                '创作于 ${DateFormatter.formatFull(work.creationDate!)}'),

                          // 导入日期
                          _buildInfoItem(context, Icons.add_circle_outline,
                              '导入于 ${DateFormatter.formatFull(work.createTime!)}'),
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

  Widget _buildImageCount(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xs,
        vertical: AppSizes.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 16, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (work.id == null) return _buildPlaceholder(context);

    return FutureBuilder<String?>(
      future: PathHelper.getWorkThumbnailPath(work.id!),
      builder: (context, pathSnapshot) {
        if (!pathSnapshot.hasData) return _buildPlaceholder(context);
        return FutureBuilder<bool>(
          future: PathHelper.isFileExists(pathSnapshot.data!),
          builder: (context, existsSnapshot) {
            if (!existsSnapshot.hasData || !existsSnapshot.data!) {
              return _buildPlaceholder(context);
            }
            final file = File(pathSnapshot.data!);
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(context),
            );
          },
        );
      },
    );
  }

  String _getMetadataPreview() {
    if (!_hasMetadata()) return '';

    // 尝试提取备注或其他重要信息
    final remarks = work.metadata?['remarks'] as String?;
    final description = work.metadata?['description'] as String?;

    if (remarks != null && remarks.isNotEmpty) {
      return remarks;
    } else if (description != null && description.isNotEmpty) {
      return description;
    } else {
      // 如果没有特定字段，显示前几个键值对
      final entries = work.metadata!.entries
          .take(2)
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      return entries;
    }
  }

  bool _hasMetadata() {
    return work.metadata != null && work.metadata!.isNotEmpty;
  }
}
