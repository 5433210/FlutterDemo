import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/enums/sort_field.dart';
import '../../../../domain/enums/work_style.dart';
import '../../../../domain/enums/work_tool.dart';
import '../../../../domain/models/character/character_filter.dart';
import '../../../../domain/models/common/date_range_filter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/character/character_filter_provider.dart';
import '../../works/components/filter/date_range_filter_section.dart';

/// Material 3 version of the character filter panel
class M3CharacterFilterPanel extends ConsumerWidget {
  /// Whether the panel is expanded
  final bool isExpanded;

  /// Callback when the expand/collapse button is pressed
  final VoidCallback? onToggleExpand;

  /// Callback when the expanded state changes
  final ValueChanged<bool>? onExpandedChanged;

  /// Constructor
  const M3CharacterFilterPanel({
    super.key,
    this.isExpanded = true,
    this.onToggleExpand,
    this.onExpandedChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filterNotifier = ref.watch(characterFilterProvider.notifier);
    final filter = ref.watch(characterFilterProvider);

    if (!isExpanded) {
      return _buildCollapsedPanel(context, onToggleExpand, l10n);
    }

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, onToggleExpand, l10n),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort options
                    _buildSortSection(context, filter, filterNotifier, l10n),
                    const Divider(),

                    // Favorite filter
                    _buildFavoriteSection(
                        context, filter, filterNotifier, l10n),
                    const Divider(),

                    // Writing tool filter
                    _buildWritingToolSection(
                        context, filter, filterNotifier, l10n),
                    const Divider(),

                    // Calligraphy style filter
                    _buildCalligraphyStyleSection(
                        context, filter, filterNotifier, l10n),
                    const Divider(),

                    // Creation date filter
                    _buildCreationDateSection(
                        context, filter, filterNotifier, l10n),
                    const Divider(),

                    // Collection date filter
                    _buildCollectionDateSection(
                        context, filter, filterNotifier, l10n),
                    const Divider(),

                    // Tags filter
                    _buildTagsSection(context, filter, filterNotifier, l10n),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalligraphyStyleSection(
    BuildContext context,
    CharacterFilter filter,
    CharacterFilterNotifier notifier,
    AppLocalizations l10n,
  ) {
    // Get available calligraphy styles
    final styles = WorkStyle.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.characterFilterCalligraphyStyle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: styles.map((style) {
            final isSelected = filter.style == style;
            return FilterChip(
              label: Text(_getLocalizedStyleName(style, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.updateCalligraphyStyles(style);
                } else {
                  notifier.updateCalligraphyStyles(null);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCollapsedPanel(
    BuildContext context,
    VoidCallback? onToggleExpand,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onToggleExpand,
        child: Container(
          width: 32,
          alignment: Alignment.center,
          child: RotatedBox(
            quarterTurns: 1,
            child: Tooltip(
              message: l10n.characterFilterExpand,
              child: const Icon(Icons.tune),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionDateSection(
    BuildContext context,
    CharacterFilter filter,
    CharacterFilterNotifier notifier,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.characterFilterCollectionDate,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        DateRangeFilterSection(
          filter: DateRangeFilter(
            preset: filter.collectionDatePreset,
            start: filter.collectionDateRange?.start,
            end: filter.collectionDateRange?.end,
          ),
          onChanged: (dateFilter) {
            if (dateFilter == null) {
              // Reset all related fields if filter is cleared
              notifier.updateCollectionDateRange(null);
              notifier.updateCollectionDatePreset(DateRangePreset.all);
            } else {
              notifier.updateCollectionDatePreset(
                  dateFilter.preset ?? DateRangePreset.all);
              notifier.updateCollectionDateRange(dateFilter.effectiveRange);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCreationDateSection(
    BuildContext context,
    CharacterFilter filter,
    CharacterFilterNotifier notifier,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.characterFilterCreationDate,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        DateRangeFilterSection(
          filter: DateRangeFilter(
            preset: filter.creationDatePreset,
            start: filter.creationDateRange?.start,
            end: filter.creationDateRange?.end,
          ),
          onChanged: (dateFilter) {
            if (dateFilter == null) {
              // Reset all related fields if filter is cleared
              notifier.updateCreationDateRange(null);
              notifier.updateCreationDatePreset(DateRangePreset.all);
            } else {
              notifier.updateCreationDatePreset(
                  dateFilter.preset ?? DateRangePreset.all);
              notifier.updateCreationDateRange(dateFilter.effectiveRange);
            }
          },
        ),
      ],
    );
  }

  Widget _buildFavoriteSection(
    BuildContext context,
    CharacterFilter filter,
    CharacterFilterNotifier notifier,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: filter.isFavorite ?? false,
          onChanged: (value) => notifier.updateFavoriteFilter(value ?? false),
        ),
        Flexible(
          child: Text(
            l10n.characterFilterFavoritesOnly,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    VoidCallback? onToggleExpand,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              l10n.characterFilterTitle,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            message: l10n.characterFilterCollapse,
            child: IconButton(
              onPressed: onToggleExpand,
              icon: const Icon(Icons.chevron_left),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection(
    BuildContext context,
    CharacterFilter filter,
    CharacterFilterNotifier notifier,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.characterFilterSort,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),

        // Sort field selection - Constrained to fit the panel width
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 230),
          child: DropdownButtonFormField<SortField>(
            value: filter.sortOption.field,
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
            items: SortField.values.map((field) {
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
                notifier.setSortField(value);
              }
            },
          ),
        ),

        const SizedBox(height: AppSizes.spacingSmall),

        // Sort direction - Column layout instead of Row to prevent overflow
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First radio button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<SortDirection>(
                  value: SortDirection.ascending,
                  groupValue: filter.sortOption.descending
                      ? SortDirection.descending
                      : SortDirection.ascending,
                  onChanged: (value) {
                    if (value != null) {
                      notifier.setSortDirection(false); // false = ascending
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
            // Second radio button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<SortDirection>(
                  value: SortDirection.descending,
                  groupValue: filter.sortOption.descending
                      ? SortDirection.descending
                      : SortDirection.ascending,
                  onChanged: (value) {
                    if (value != null) {
                      notifier.setSortDirection(true); // true = descending
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

  Widget _buildTagsSection(
    BuildContext context,
    CharacterFilter filter,
    CharacterFilterNotifier notifier,
    AppLocalizations l10n,
  ) {
    // Common tags (should be fetched from database in a real implementation)
    final commonTags = ['经典', '传统', '现代', '名家', '精选', '教学用例'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.characterFilterTags,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: commonTags.map((tag) {
            final isSelected = filter.tags.contains(tag);

            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.addTag(tag);
                } else {
                  notifier.removeTag(tag);
                }
              },
            );
          }).toList(),
        ),

        const SizedBox(height: AppSizes.spacingMedium),

        // Custom tag input
        TextField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.characterFilterAddTag,
            hintText: l10n.characterFilterAddTagHint,
            suffixIcon: const Icon(Icons.add),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              notifier.addTag(value);
            }
          },
        ),

        if (filter.tags.isNotEmpty) ...[
          const SizedBox(height: AppSizes.spacingMedium),

          // Selected tags
          Text(
            l10n.characterFilterSelectedTags,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filter.tags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () => notifier.removeTag(tag),
                deleteIcon: const Icon(Icons.close, size: 14),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildWritingToolSection(
    BuildContext context,
    CharacterFilter filter,
    CharacterFilterNotifier notifier,
    AppLocalizations l10n,
  ) {
    // Get available writing tools
    final writingTools = WorkTool.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.characterFilterWritingTool,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: writingTools.map((tool) {
            final isSelected = filter.tool == tool;

            return FilterChip(
              label: Text(_getLocalizedToolName(tool, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.updateWritingTools(tool);
                } else {
                  notifier.updateWritingTools(null);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper methods to get localized names
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

  String _getLocalizedStyleName(WorkStyle style, AppLocalizations l10n) {
    switch (style) {
      case WorkStyle.regular:
        return l10n.filterStyleRegular;
      case WorkStyle.running:
        return l10n.filterStyleRunning;
      case WorkStyle.cursive:
        return l10n.filterStyleCursive;
      case WorkStyle.clerical:
        return l10n.filterStyleClerical;
      case WorkStyle.seal:
        return l10n.filterStyleSeal;
      case WorkStyle.other:
        return l10n.filterStyleOther;
    }
  }

  String _getLocalizedToolName(WorkTool tool, AppLocalizations l10n) {
    switch (tool) {
      case WorkTool.brush:
        return l10n.filterToolBrush;
      case WorkTool.hardPen:
        return l10n.filterToolHardPen;
      case WorkTool.other:
        return l10n.filterToolOther;
    }
  }
}
