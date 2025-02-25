import 'package:flutter/material.dart';
import '../../../../../domain/entities/work.dart';
import '../../../../theme/app_sizes.dart';
import 'items/work_grid_item.dart';

class WorkGridView extends StatelessWidget {
  final List<Work> works;
  final bool batchMode;
  final Set<String> selectedWorks;
  final Function(String, bool) onSelectionChanged;
  final Function(String)? onItemTap;

  const WorkGridView({
    super.key,
    required this.works,
    required this.batchMode,
    required this.selectedWorks,
    required this.onSelectionChanged,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - (AppSizes.m * 2);
        final columns = (width / 280.0).floor();
        final crossAxisCount = columns < 2 ? 2 : columns;

        final spacing = AppSizes.m;
        final availableWidth =
            (width - (spacing * (crossAxisCount - 1))) / crossAxisCount;
        final aspectRatio = availableWidth / (availableWidth * 1.4);

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
            return WorkGridItem(
              work: work,
              isSelected: selectedWorks.contains(work.id),
              isSelectionMode: batchMode,
              onTap: () => batchMode 
                  ? onSelectionChanged(work.id!, !selectedWorks.contains(work.id))
                  : onItemTap?.call(work.id!),
            );
          },
        );
      },
    );
  }
}
