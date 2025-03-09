import 'package:flutter/material.dart';

import '../../../../../domain/enums/sort_field.dart';
import '../../../../../domain/models/work/work_filter.dart';
import '../../../../../theme/app_sizes.dart';

class SortSection extends StatelessWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;

  const SortSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                onTap: () => onFilterChanged(filter.copyWith(
                    sortOption: filter.sortOption
                        .copyWith(descending: !filter.sortOption.descending))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter.sortOption.descending ? '降序' : '升序',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.sort,
                      size: 18,
                      textDirection: filter.sortOption.descending
                          ? TextDirection.rtl
                          : TextDirection.ltr,
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
            .map((field) => _buildSortItem(field, field.label, theme)),
      ],
    );
  }

  Widget _buildSortItem(
    SortField field,
    String label,
    ThemeData theme,
  ) {
    final bool selected = filter.sortOption.field == field;

    return Material(
      color:
          selected ? theme.colorScheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.s),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.s),
        onTap: () => onFilterChanged(filter.copyWith(
            sortOption: filter.sortOption.copyWith(field: field))),
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
                  onChanged: (_) => onFilterChanged(filter.copyWith(
                      sortOption: filter.sortOption.copyWith(field: field))),
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
