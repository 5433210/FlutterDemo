import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../domain/entities/work.dart';
import '../../../../../providers/work_browse_provider.dart';
import '../../../../../theme/app_sizes.dart';
import '../../../../../../utils/date_formatter.dart';
import '../../../../../../utils/path_helper.dart';

class WorkGridItem extends StatelessWidget {
  final Work work;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;  // 修改为必需参数

  const WorkGridItem({
    super.key,
    required this.work,
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              children: [
                _buildThumbnail(context),
                _buildMetadata(context),
              ],
            ),
            if (isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                  ),
                ),
              ),
          ],
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
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(context),
            );
          }
        }
        return _buildPlaceholder(context);
      },
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          work.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 4),
            Text(
              DateFormatter.formatCompact(
                work.creationDate ?? work.createTime ?? DateTime.now(),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xs),
          child: Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
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
}
