import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/enums/sort_field.dart';
import '../../../../domain/models/character/character_filter.dart';
import '../../../../domain/models/common/date_range_filter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/character/character_filter_provider.dart';
import '../../../widgets/filter/sections/m3_filter_date_range_section.dart';
import '../../../widgets/filter/sections/m3_filter_favorite_section.dart';
import '../../../widgets/filter/sections/m3_filter_sort_section.dart';
import '../../../widgets/filter/sections/m3_filter_style_section.dart';
import '../../../widgets/filter/sections/m3_filter_tool_section.dart';

/// Material 3 版本的字符筛选面板
class M3CharacterFilterPanel extends ConsumerWidget {
  /// 是否允许折叠面板
  final bool collapsible;

  /// 是否已展开
  final bool isExpanded;

  /// 展开/折叠状态变化时的回调
  final VoidCallback? onToggleExpand;

  /// 构造函数
  const M3CharacterFilterPanel({
    super.key,
    this.collapsible = true,
    this.isExpanded = true,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterNotifier = ref.watch(characterFilterProvider.notifier);
    final filter = ref.watch(characterFilterProvider);

    return _M3CharacterFilterPanelImpl(
      filter: filter,
      onFilterChanged: (newFilter) {
        // 使用 provider 更新筛选条件
        if (newFilter.sortOption != filter.sortOption) {
          filterNotifier.setSortField(newFilter.sortOption.field);
          filterNotifier.setSortDirection(newFilter.sortOption.descending);
        }

        if (newFilter.style != filter.style) {
          filterNotifier.updateCalligraphyStyles(newFilter.style);
        }

        if (newFilter.tool != filter.tool) {
          filterNotifier.updateWritingTools(newFilter.tool);
        }

        if (newFilter.isFavorite != filter.isFavorite) {
          filterNotifier.updateFavoriteFilter(newFilter.isFavorite ?? false);
        }

        if (newFilter.creationDatePreset != filter.creationDatePreset ||
            newFilter.creationDateRange != filter.creationDateRange) {
          filterNotifier.updateCreationDatePreset(newFilter.creationDatePreset);
          filterNotifier.updateCreationDateRange(newFilter.creationDateRange);
        }

        if (newFilter.collectionDatePreset != filter.collectionDatePreset ||
            newFilter.collectionDateRange != filter.collectionDateRange) {
          filterNotifier
              .updateCollectionDatePreset(newFilter.collectionDatePreset);
          filterNotifier
              .updateCollectionDateRange(newFilter.collectionDateRange);
        }

        if (newFilter.tags != filter.tags) {
          filterNotifier.updateTags(newFilter.tags);
        }

        if (newFilter.searchText != filter.searchText) {
          filterNotifier.updateSearchText(newFilter.searchText);
        }
      },
      collapsible: collapsible,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
    );
  }
}

/// 字符筛选面板实现
class _M3CharacterFilterPanelImpl extends StatefulWidget {
  final CharacterFilter filter;
  final ValueChanged<CharacterFilter> onFilterChanged;
  final bool collapsible;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const _M3CharacterFilterPanelImpl({
    required this.filter,
    required this.onFilterChanged,
    this.collapsible = true,
    this.isExpanded = true,
    this.onToggleExpand,
  });

  @override
  State<_M3CharacterFilterPanelImpl> createState() =>
      _M3CharacterFilterPanelImplState();
}

class _M3CharacterFilterPanelImplState
    extends State<_M3CharacterFilterPanelImpl> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    // 如果支持折叠并且当前已折叠，则显示折叠状态
    if (widget.collapsible && !widget.isExpanded) {
      return _buildCollapsedPanel(context, l10n);
    }

    return Material(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          _buildHeader(context, l10n),

          // 内容区域
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: buildFilterSections(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  List<Widget> buildFilterSections(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 获取可用的排序字段
    final sortFields = [
      SortField.title,
      SortField.createTime,
      SortField.updateTime,
      SortField.style,
      SortField.tool,
    ];

    return [
      // 搜索框部分
      _buildSectionCard(
        context,
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.characterCollectionSearchHint,
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.characterCollectionSearchHint,
              onPressed: () {
                final newFilter =
                    widget.filter.copyWith(searchText: _searchController.text);
                widget.onFilterChanged(newFilter);
                // Schedule focus and cursor update for the next frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  FocusScope.of(context).requestFocus(_searchFocusNode);
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _searchController.text.length),
                  );
                });
              },
            ),
          ),
          controller: _searchController,
          focusNode: _searchFocusNode,
          enableInteractiveSelection: true,
          autofocus: false,
          onTap: () {
            // Position cursor at the end of text instead of selecting all text
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
          },
          onSubmitted: (value) {
            final newFilter = widget.filter.copyWith(searchText: value);
            widget.onFilterChanged(newFilter);
            // Keep focus and cursor at the end of text
            Future.microtask(() {
              if (!mounted) return;
              _searchFocusNode.requestFocus();
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: _searchController.text.length),
              );
            });
          },
          textInputAction: TextInputAction.search,
        ),
      ), // 排序部分
      _buildSectionCard(
        context,
        M3FilterSortSection(
          sortField: widget.filter.sortOption.field,
          descending: widget.filter.sortOption.descending,
          availableSortFields: sortFields,
          onSortFieldChanged: (field) {
            final newFilter = widget.filter.copyWith(
              sortOption: widget.filter.sortOption.copyWith(field: field),
            );
            widget.onFilterChanged(newFilter);
          },
          onSortDirectionChanged: (isDescending) {
            final newFilter = widget.filter.copyWith(
              sortOption:
                  widget.filter.sortOption.copyWith(descending: isDescending),
            );
            widget.onFilterChanged(newFilter);
          },        ),
      ),
      // 收藏部分
      _buildSectionCard(
        context,
        M3FilterFavoriteSection(
          isFavoriteOnly: widget.filter.isFavorite ?? false,
          onFavoriteChanged: (value) {
            final newFilter = widget.filter.copyWith(isFavorite: value);
            widget.onFilterChanged(newFilter);
          },
        ),
      ),
      // 书写工具部分
      _buildSectionCard(
        context,
        M3FilterToolSection(
          selectedTool: widget.filter.tool,
          onToolChanged: (tool) {
            final newFilter = widget.filter.copyWith(tool: tool);
            widget.onFilterChanged(newFilter);
          },
        ),
      ),
      // 书法风格部分
      _buildSectionCard(
        context,
        M3FilterStyleSection(
          selectedStyle: widget.filter.style,
          onStyleChanged: (style) {
            final newFilter = widget.filter.copyWith(style: style);
            widget.onFilterChanged(newFilter);
          },        ),
      ),
      // 收集日期部分
      _buildSectionCard(
        context,
        M3FilterDateRangeSection(
          title: l10n.collectionDate,
          filter: DateRangeFilter(
            preset: widget.filter.collectionDatePreset,
            start: widget.filter.collectionDateRange?.start,
            end: widget.filter.collectionDateRange?.end,
          ),
          onChanged: (dateFilter) {
            if (dateFilter == null) {
              // 重置所有相关字段
              final newFilter = widget.filter.copyWith(
                collectionDatePreset: DateRangePreset.all,
                collectionDateRange: null,
              );
              widget.onFilterChanged(newFilter);
            } else {
              final newFilter = widget.filter.copyWith(
                collectionDatePreset: dateFilter.preset!,
                collectionDateRange: dateFilter.effectiveRange,
              );
              widget.onFilterChanged(newFilter);
            }
          },
        ),
      ),
    ];
  }

  @override
  void didUpdateWidget(_M3CharacterFilterPanelImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the controller text if the filter's searchText changed
    if (oldWidget.filter.searchText != widget.filter.searchText &&
        widget.filter.searchText != _searchController.text) {
      _searchController.text = widget.filter.searchText ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filter.searchText);
  }

  Widget _buildCollapsedPanel(BuildContext context, AppLocalizations l10n) {
    return InkWell(
      onTap: widget.onToggleExpand,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.filter_list),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_getExpandMessage(l10n)),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              _getFilterTitle(l10n),
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 重置按钮
              Tooltip(
                message: l10n.reset,
                child: IconButton(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(0),
                ),
              ),

              // 展开/折叠按钮
              if (widget.collapsible && widget.onToggleExpand != null)
                Tooltip(
                  message: widget.isExpanded
                      ? l10n.collapse
                      : l10n.expand,
                  child: IconButton(
                    onPressed: widget.onToggleExpand,
                    icon: Icon(
                      widget.isExpanded
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(0),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: child,
        ),
      ),
    );
  }

  String _getExpandMessage(AppLocalizations l10n) {
    // 使用通用回退
    return l10n.expand;
  }

  String _getFilterTitle(AppLocalizations l10n) {
    return l10n.filterAndSort;
  }

  void _resetFilters() {
    widget.onFilterChanged(const CharacterFilter());
  }
}
