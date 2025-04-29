import 'package:demo/domain/models/work/work_entity.dart';
import 'package:flutter/material.dart';

import '../../../../../theme/app_sizes.dart';
import 'items/m3_work_list_item.dart';

class M3WorkListView extends StatelessWidget {
  final List<WorkEntity> works;
  final bool batchMode;
  final Set<String> selectedWorks;
  final void Function(String workId, bool selected) onSelectionChanged;
  final Function(String)? onItemTap;

  const M3WorkListView({
    super.key,
    required this.works,
    required this.batchMode,
    required this.selectedWorks,
    required this.onSelectionChanged,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.xs),
      itemCount: works.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.s),
      itemBuilder: (context, index) {
        final work = works[index];
        return M3WorkListItem(
          work: work,
          isSelected: selectedWorks.contains(work.id),
          isSelectionMode: batchMode,
          onTap: () => batchMode
              ? onSelectionChanged(work.id, !selectedWorks.contains(work.id))
              : onItemTap?.call(work.id),
        );
      },
    );
  }
}
