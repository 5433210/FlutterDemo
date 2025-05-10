import 'package:flutter/material.dart';

import '../../../../../domain/enums/sort_field.dart';
import '../../../../../domain/models/common/sort_option.dart';
import '../../../../../domain/models/work/work_filter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../theme/app_sizes.dart';

class SortSection extends StatelessWidget {
  // 默认排序选项
  static const defaultSortOption =
      SortOption(field: SortField.createTime, descending: true);
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
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.filterSortSection, style: theme.textTheme.titleMedium),
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
                    Flexible(
                      child: Text(
                        filter.sortOption.descending
                            ? l10n.filterSortDescending
                            : l10n.filterSortAscending,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
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
        ...SortField.values.where((field) => field != SortField.none).map(
            (field) =>
                _buildSortItem(field, _getSortFieldLabel(field, l10n), theme)),
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
        onTap: () {
          // 如果点击当前选中的项，重置为默认排序
          if (selected) {
            onFilterChanged(filter.copyWith(
              sortOption: defaultSortOption,
            ));
          } else {
            // 选择新的排序字段
            onFilterChanged(filter.copyWith(
              sortOption: filter.sortOption.copyWith(field: field),
            ));
          }
        },
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
                  onChanged: (_) {
                    // 如果点击当前选中的项，重置为默认排序
                    if (selected) {
                      onFilterChanged(filter.copyWith(
                        sortOption: defaultSortOption,
                      ));
                    } else {
                      onFilterChanged(filter.copyWith(
                        sortOption: filter.sortOption.copyWith(field: field),
                      ));
                    }
                  },
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

  String _getSortFieldLabel(SortField field, AppLocalizations l10n) {
    return switch (field) {
      SortField.title => l10n.filterSortFieldTitle,
      SortField.author => l10n.filterSortFieldAuthor,
      SortField.creationDate => l10n.filterSortFieldCreationDate,
      SortField.createTime => l10n.filterSortFieldCreateTime,
      SortField.updateTime => l10n.filterSortFieldUpdateTime,
      SortField.tool => l10n.filterSortFieldTool,
      SortField.style => l10n.filterSortFieldStyle,
      SortField.none => l10n.filterSortFieldNone,
      SortField.fileName => l10n.filterSortFieldFileName,
      SortField.fileUpdatedAt => l10n.filterSortFieldFileUpdatedAt,
      SortField.fileSize => l10n.filterSortFieldFileSize,
    };
  }
}
