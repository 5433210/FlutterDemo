import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../../domain/entities/work.dart';
import '../../../../../theme/app_sizes.dart';
import '../../../../../../utils/date_formatter.dart';
import '../../../../../../utils/path_helper.dart';

class WorkGridItem extends StatelessWidget {
  final Work work;
  final bool selected;
  final bool selectable;
  final ValueChanged<bool>? onSelected;

  const WorkGridItem({
    super.key,
    required this.work,
    this.selected = false,
    this.selectable = false,
    this.onSelected, void Function()? onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: selectable ? () => onSelected?.call(!selected) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(context),
                  if (selectable || selected) _buildSelectionOverlay(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.m),
              child: _buildMetadata(context),
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
        color: selected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Colors.transparent,
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xs),
          child: Checkbox(
            value: selected,
            onChanged: (value) => onSelected?.call(value ?? false),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
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
