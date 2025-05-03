import 'package:flutter/material.dart';

import '../../../../domain/enums/sort_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';

/// 通用的排序部分组件
class M3FilterSortSection extends StatelessWidget {
  /// 排序字段
  final SortField sortField;

  /// 是否降序排序
  final bool descending;

  /// 可用的排序字段列表
  final List<SortField> availableSortFields;

  /// 排序字段变化时的回调
  final ValueChanged<SortField> onSortFieldChanged;

  /// 排序方向变化时的回调
  final ValueChanged<bool> onSortDirectionChanged;

  /// 构造函数
  const M3FilterSortSection({
    super.key,
    required this.sortField,
    required this.descending,
    required this.availableSortFields,
    required this.onSortFieldChanged,
    required this.onSortDirectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.filterSortSection,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),

        // 排序字段选择
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 230),
          child: DropdownButtonFormField<SortField>(
            value: sortField,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: availableSortFields.map((field) {
              return DropdownMenuItem<SortField>(
                value: field,
                child: Text(
                  _getLocalizedSortFieldName(field, l10n),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onSortFieldChanged(value);
              }
            },
          ),
        ),

        const SizedBox(height: AppSizes.spacingSmall),

        // 排序方向
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 升序
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<SortDirection>(
                  value: SortDirection.ascending,
                  groupValue: descending
                      ? SortDirection.descending
                      : SortDirection.ascending,
                  onChanged: (value) {
                    if (value == SortDirection.ascending) {
                      onSortDirectionChanged(false);
                    }
                  },
                ),
                Flexible(
                  child: Text(
                    l10n.filterSortAscending,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // 降序
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<SortDirection>(
                  value: SortDirection.descending,
                  groupValue: descending
                      ? SortDirection.descending
                      : SortDirection.ascending,
                  onChanged: (value) {
                    if (value == SortDirection.descending) {
                      onSortDirectionChanged(true);
                    }
                  },
                ),
                Flexible(
                  child: Text(
                    l10n.filterSortDescending,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 获取本地化的排序字段名称
  String _getLocalizedSortFieldName(SortField field, AppLocalizations l10n) {
    switch (field) {
      case SortField.title:
        return l10n.filterSortFieldTitle;
      case SortField.author:
        return l10n.filterSortFieldAuthor;
      case SortField.creationDate:
        return l10n.filterSortFieldCreationDate;
      case SortField.createTime:
        return l10n.filterSortFieldCreateTime;
      case SortField.updateTime:
        return l10n.filterSortFieldUpdateTime;
      case SortField.tool:
        return l10n.filterSortFieldTool;
      case SortField.style:
        return l10n.filterSortFieldStyle;
      default:
        return l10n.filterSortFieldNone;
    }
  }
}

/// 排序方向枚举
enum SortDirection {
  ascending,
  descending,
}
