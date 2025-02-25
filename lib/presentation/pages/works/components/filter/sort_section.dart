import 'package:flutter/material.dart';
import '../../../../../domain/enums/sort_field.dart';

class SortSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(workBrowseProvider.notifier);
    final state = ref.watch(workBrowseProvider);

    return WorkFilterSection(
      title: '排序',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<SortField>(
            value: state.filter.sortOption.field,
            items: SortField.values.map((field) {
              return DropdownMenuItem(
                value: field,
                child: Text(field.label),
              );
            }).toList(),
            onChanged: viewModel.updateSortField,
          ),
          IconButton(
            icon: Icon(
              state.filter.sortOption.descending 
                ? Icons.arrow_downward 
                : Icons.arrow_upward
            ),
            onPressed: viewModel.toggleSortDirection,
          ),
        ],
      ),
    );
  }
}
