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
    this.onSelected,
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

  Widget _buildThumbnail(BuildContext context) => // ...existing thumbnail code...
  Widget _buildMetadata(BuildContext context) => // ...existing metadata code...
  Widget _buildSelectionOverlay(BuildContext context) => // ...existing overlay code...
  Widget _buildPlaceholder(BuildContext context) => // ...existing placeholder code...
}
