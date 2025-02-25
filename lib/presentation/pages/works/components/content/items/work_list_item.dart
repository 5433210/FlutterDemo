import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../../domain/entities/work.dart';
import '../../../../../theme/app_sizes.dart';
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
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.m),
          child: SizedBox(
            height: AppSizes.listItemHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSizes.m),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap(),
                    ),
                  ),
                _buildThumbnail(context),
                const SizedBox(width: AppSizes.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        work.name ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (work.author != null) ...[
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          work.author!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          if (work.style != null) _buildTag(context, work.style!),
                          if (work.tool != null)
                            Padding(
                              padding: const EdgeInsets.only(left: AppSizes.s),
                              child: _buildTag(context, work.tool!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
