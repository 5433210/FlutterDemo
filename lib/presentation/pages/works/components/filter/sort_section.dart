import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/work_filter.dart';
import '../../../../providers/work_browse_provider.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../viewmodels/states/work_browse_state.dart';
import '../../../../viewmodels/work_browse_view_model.dart';

class SortSection extends ConsumerWidget {
  const SortSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);
    final theme = Theme.of(context);
    final isDescending = state.filter.sortOption.descending;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('排序', style: theme.textTheme.titleMedium),
            const SizedBox(width: AppSizes.s),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.s),
              ),
              child: InkWell(
                onTap: () => viewModel.toggleSortDirection(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isDescending ? '降序' : '升序',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.sort,
                      size: 18,
                      textDirection: isDescending ? TextDirection.rtl : TextDirection.ltr,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s),
        ...SortField.values
            .where((field) => field != SortField.none)
            .map((field) => _buildSortItem(field, field.label, state, viewModel, theme)),
      ],
    );
  }

  Widget _buildSortItem(
    SortField field, 
    String label, 
    WorkBrowseState state,
    WorkBrowseViewModel viewModel,
    ThemeData theme,
  ) {
    final bool selected = state.filter.sortOption.field == field;

    return Material(
      color: selected ? theme.colorScheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.s),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.s),
        onTap: () => viewModel.updateSortField(field),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.m,
            vertical: AppSizes.s,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Radio<SortField>(
                  value: field,
                  groupValue: selected ? field : null,
                  onChanged: (_) => viewModel.updateSortField(field),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: AppSizes.s),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected 
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
