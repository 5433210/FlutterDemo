import 'package:flutter/material.dart';

import '../../../../../domain/models/work/work_entity.dart';
import '../../../../../theme/app_sizes.dart';
import 'items/m3_work_grid_item.dart';

class M3WorkGridView extends StatelessWidget {
  final List<WorkEntity> works;
  final bool batchMode;
  final Set<String> selectedWorks;
  final Function(String, bool) onSelectionChanged;
  final Function(String)? onItemTap;

  /// 切换收藏状态的回调
  final Function(String)? onToggleFavorite;

  /// 编辑标签的回调
  final Function(String)? onTagsEdited;

  const M3WorkGridView({
    super.key,
    required this.works,
    required this.batchMode,
    required this.selectedWorks,
    required this.onSelectionChanged,
    this.onItemTap,
    this.onToggleFavorite,
    this.onTagsEdited,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - (AppSizes.m * 2);
        final columns = (width / AppSizes.gridCardWidth).floor();
        final crossAxisCount = columns < 2 ? 2 : columns;

        const spacing = AppSizes.m;
        const aspectRatio = 1 / 1.4;

        return GridView.builder(
          padding: const EdgeInsets.all(AppSizes.m),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: works.length,
          itemBuilder: (context, index) {
            final work = works[index];
            return M3WorkGridItem(
              work: work,
              isSelected: selectedWorks.contains(work.id),
              isSelectionMode: batchMode,
              onTap: () => batchMode
                  ? onSelectionChanged(
                      work.id, !selectedWorks.contains(work.id))
                  : onItemTap?.call(work.id),
              onToggleFavorite: onToggleFavorite != null
                  ? () => onToggleFavorite!.call(work.id)
                  : null,
              onTagsEdited: onTagsEdited != null
                  ? () => onTagsEdited!.call(work.id)
                  : null,
            );
          },
        );
      },
    );
  }
}
