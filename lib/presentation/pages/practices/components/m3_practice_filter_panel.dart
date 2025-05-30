import 'package:flutter/material.dart';

import '../../../../domain/models/practice/practice_filter.dart';
import '../../../../l10n/app_localizations.dart';

/// 字帖过滤面板
class M3PracticeFilterPanel extends StatelessWidget {
  /// 当前过滤条件
  final PracticeFilter filter;

  /// 当前搜索关键字
  final String? initialSearchValue;

  /// 搜索文本控制器
  final TextEditingController? searchController;

  /// 过滤条件变化时的回调
  final ValueChanged<PracticeFilter> onFilterChanged;

  /// 搜索回调
  final ValueChanged<String> onSearch;

  /// 是否允许折叠面板
  final bool collapsible;

  /// 是否已展开
  final bool isExpanded;

  /// 展开/折叠状态变化时的回调
  final VoidCallback? onToggleExpand;

  /// 构造函数
  const M3PracticeFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearch,
    this.initialSearchValue,
    this.searchController,
    this.collapsible = true,
    this.isExpanded = true,
    this.onToggleExpand,
  });
  @override
  Widget build(BuildContext context) {
    return _M3PracticeFilterPanelImpl(
      filter: filter,
      onFilterChanged: onFilterChanged,
      onSearch: onSearch,
      collapsible: collapsible,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
      initialSearchValue: initialSearchValue,
      searchController: searchController,
    );
  }
}

/// 字帖过滤面板实现
class _M3PracticeFilterPanelImpl extends StatefulWidget {
  /// 当前过滤条件
  final PracticeFilter filter;

  /// 过滤条件变化时的回调
  final ValueChanged<PracticeFilter> onFilterChanged;

  /// 搜索回调
  final ValueChanged<String> onSearch;

  /// 初始搜索值
  final String? initialSearchValue;

  /// 搜索文本控制器
  final TextEditingController? searchController;

  /// 是否允许折叠面板
  final bool collapsible;

  /// 是否已展开
  final bool isExpanded;

  /// 展开/折叠状态变化时的回调
  final VoidCallback? onToggleExpand;

  const _M3PracticeFilterPanelImpl({
    required this.filter,
    required this.onFilterChanged,
    required this.onSearch,
    this.initialSearchValue,
    this.searchController,
    this.collapsible = true,
    this.isExpanded = true,
    this.onToggleExpand,
  });

  @override
  State<_M3PracticeFilterPanelImpl> createState() =>
      _M3PracticeFilterPanelImplState();
}

class _M3PracticeFilterPanelImplState
    extends State<_M3PracticeFilterPanelImpl> {
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

    // 定义可用的排序字段
    final sortFieldOptions = [
      {'value': 'updateTime', 'label': l10n.practiceListSortByUpdateTime},
      {'value': 'title', 'label': l10n.practiceListSortByTitle},
      {'value': 'createTime', 'label': l10n.practiceListSortByCreateTime},
    ];

    return [
      // 搜索部分
      _buildSectionCard(
        context,
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.practiceListSearch,
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.practiceListSearch,
              onPressed: () {
                final newFilter =
                    widget.filter.copyWith(keyword: _searchController.text);
                widget.onFilterChanged(newFilter);
                widget.onSearch(_searchController.text);
                // Keep focus and cursor at the end of text
                Future.microtask(() {
                  if (!mounted) return;
                  _searchFocusNode.requestFocus();
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
            final newFilter = widget.filter.copyWith(keyword: value);
            widget.onFilterChanged(newFilter);
            widget.onSearch(value);
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
      ),

      // 排序部分
      _buildSectionCard(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.filterSortSection,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            // 排序字段选择
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: widget.filter.sortField,
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
                items: sortFieldOptions.map((field) {
                  return DropdownMenuItem<String>(
                    value: field['value'],
                    child: Text(
                      field['label']!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final newFilter = widget.filter.copyWith(sortField: value);
                    widget.onFilterChanged(newFilter);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            // 排序方向
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 升序
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: widget.filter.sortOrder == 'desc',
                      onChanged: (value) {
                        if (value != null) {
                          final newFilter = widget.filter.copyWith(
                            sortOrder: value ? 'desc' : 'asc',
                          );
                          widget.onFilterChanged(newFilter);
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
                    Radio<bool>(
                      value: true,
                      groupValue: widget.filter.sortOrder == 'desc',
                      onChanged: (value) {
                        if (value != null) {
                          final newFilter = widget.filter.copyWith(
                            sortOrder: value ? 'desc' : 'asc',
                          );
                          widget.onFilterChanged(newFilter);
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
        ),
      ),

      // 收藏过滤部分
      _buildSectionCard(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.practiceListFilterFavorites,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            // 收藏过滤选项
            Row(
              children: [
                Checkbox(
                  value: widget.filter.isFavorite,
                  onChanged: (value) {
                    final newFilter =
                        widget.filter.copyWith(isFavorite: value ?? false);
                    widget.onFilterChanged(newFilter);
                  },
                ),
                Expanded(
                  child: Text(l10n.filterFavoritesOnly),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  @override
  void didUpdateWidget(_M3PracticeFilterPanelImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If using external controller, don't manage it here
    if (widget.searchController == null &&
        oldWidget.initialSearchValue != widget.initialSearchValue) {
      _searchController.text = widget.initialSearchValue ?? '';
    }
  }

  @override
  void dispose() {
    // Only dispose if we created the controller internally
    if (widget.searchController == null) {
      _searchController.dispose();
    }
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ??
        TextEditingController(text: widget.initialSearchValue ?? '');
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
                message: l10n.filterReset,
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
                      ? l10n.filterCollapse
                      : l10n.filterExpand,
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
    return l10n.filterExpand;
  }

  String _getFilterTitle(AppLocalizations l10n) {
    return l10n.practiceListFilterTitle;
  }

  void _resetFilters() {
    widget.onFilterChanged(const PracticeFilter());
    widget.onSearch('');
  }
}
