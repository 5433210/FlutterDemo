import 'package:flutter/material.dart';
import '../../../../../domain/entities/work.dart';
import '../../../../theme/app_sizes.dart';
import 'items/work_list_item.dart';

class WorkListView extends StatelessWidget {
  final List<Work> works;
  final bool batchMode;
  final Set<String> selectedWorks;
  final void Function(String workId, bool selected) onSelectionChanged;
  final Function(String)? onItemTap;

  const WorkListView({
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
      padding: const EdgeInsets.all(AppSizes.m),
      itemCount: works.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.s),
      itemBuilder: (context, index) {
        final work = works[index];
        return WorkListItem(
          work: work,
          isSelected: selectedWorks.contains(work.id),
          isSelectionMode: batchMode,
          onTap: () => batchMode 
              ? onSelectionChanged(work.id!, !selectedWorks.contains(work.id))
              : onItemTap?.call(work.id!),
        );
      },
    );
  }
}
