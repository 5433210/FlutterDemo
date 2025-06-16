import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/enums/sort_field.dart';
import '../../../../../domain/enums/work_style.dart';
import '../../../../../domain/enums/work_tool.dart';
import '../../../../../domain/models/common/date_range_filter.dart';
import '../../../../../domain/models/work/work_filter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../widgets/filter/sections/m3_filter_date_range_section.dart';
import '../../../../widgets/filter/sections/m3_filter_favorite_section.dart';
import '../../../../widgets/filter/sections/m3_filter_sort_section.dart';
import '../../../../widgets/filter/sections/m3_filter_style_section.dart';
import '../../../../widgets/filter/sections/m3_filter_tool_section.dart';

/// Material 3 版本的作品筛选面板
class M3WorkFilterPanel extends ConsumerWidget {
  /// 当前筛选条件
  final WorkFilter filter;

  /// 筛选条件变化时的回调
  final ValueChanged<WorkFilter> onFilterChanged;

  /// 是否允许折叠面板
  final bool collapsible;

  /// 是否已展开
  final bool isExpanded;

  /// 展开/折叠状态变化时的回调
  final VoidCallback? onToggleExpand;

  /// 搜索文本控制器
  final TextEditingController? searchController;

  /// 初始搜索值
  final String? initialSearchValue;

  /// 构造函数
  const M3WorkFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    this.collapsible = true,
    this.isExpanded = true,
    this.onToggleExpand,
    this.searchController,
    this.initialSearchValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _M3WorkFilterPanelImpl(
      filter: filter,
      onFilterChanged: onFilterChanged,
      collapsible: collapsible,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
      searchController: searchController,
      initialSearchValue: initialSearchValue,
    );
  }
}

/// 作品筛选面板实现
class _M3WorkFilterPanelImpl extends StatefulWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;
  final bool collapsible;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final TextEditingController? searchController;
  final String? initialSearchValue;

  const _M3WorkFilterPanelImpl({
    required this.filter,
    required this.onFilterChanged,
    this.collapsible = true,
    this.isExpanded = true,
    this.onToggleExpand,
    this.searchController,
    this.initialSearchValue,
  });

  @override
  State<_M3WorkFilterPanelImpl> createState() => _M3WorkFilterPanelImplState();
}

class _M3WorkFilterPanelImplState extends State<_M3WorkFilterPanelImpl> {
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
      SortField.author,
      SortField.createTime,
      SortField.updateTime,
      SortField.style,
      SortField.tool,
    ];

    // 获取可用的书法风格
    final styles = WorkStyle.values.toList();

    // 获取可用的书写工具
    final tools = WorkTool.values.toList();

    return [
      // 搜索部分
      _buildSectionCard(
        context,
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.workBrowseSearch,
            isDense: true,
            border: const OutlineInputBorder(),
            // 添加提交按钮
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.workBrowseSearch,
              onPressed: () {
                final newFilter =
                    widget.filter.copyWith(keyword: _searchController.text);
                widget.onFilterChanged(newFilter);
                // Keep focus and cursor at the end of text
                Future.microtask(() {
                  if (mounted) {
                    _searchFocusNode.requestFocus();
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _searchController.text.length),
                    );
                  }
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
          // 添加回车键处理
          onSubmitted: (value) {
            final newFilter = widget.filter.copyWith(keyword: value);
            widget.onFilterChanged(newFilter);
            // Keep focus and cursor at the end of text
            Future.microtask(() {
              if (mounted) {
                _searchFocusNode.requestFocus();
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchController.text.length),
                );
              }
            });
          },
          textInputAction: TextInputAction.search,
        ),
      ),

      // 排序部分
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
          },
        ),
      ),

      // 收藏部分 (移动到排序部分下方)
      _buildSectionCard(
        context,
        M3FilterFavoriteSection(
          isFavoriteOnly: widget.filter.isFavoriteOnly,
          onFavoriteChanged: (value) {
            final newFilter = widget.filter.copyWith(isFavoriteOnly: value);
            widget.onFilterChanged(newFilter);
          },
        ),
      ),

      // 书法风格部分
      _buildSectionCard(
        context,
        M3FilterStyleSection(
          selectedStyle: widget.filter.style,
          availableStyles: styles,
          onStyleChanged: (style) {
            final newFilter = widget.filter.copyWith(style: style);
            widget.onFilterChanged(newFilter);
          },
        ),
      ),

      // 书写工具部分
      _buildSectionCard(
        context,
        M3FilterToolSection(
          selectedTool: widget.filter.tool,
          availableTools: tools,
          onToolChanged: (tool) {
            final newFilter = widget.filter.copyWith(tool: tool);
            widget.onFilterChanged(newFilter);
          },
        ),
      ),

      // 创建日期部分
      _buildSectionCard(
        context,
        M3FilterDateRangeSection(
          title: l10n.createTime,
          filter: DateRangeFilter(
            preset: widget.filter.datePreset,
            start: widget.filter.dateRange?.start,
            end: widget.filter.dateRange?.end,
          ),
          onChanged: (dateFilter) {
            if (dateFilter == null) {
              // 重置所有相关字段
              final newFilter = widget.filter.copyWith(
                datePreset: DateRangePreset.all,
                dateRange: null,
              );
              widget.onFilterChanged(newFilter);
            } else {
              final newFilter = widget.filter.copyWith(
                datePreset: dateFilter.preset!,
                dateRange: dateFilter.effectiveRange,
              );
              widget.onFilterChanged(newFilter);
            }
          },
        ),
      ),
    ];
  }

  @override
  void didUpdateWidget(_M3WorkFilterPanelImpl oldWidget) {
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
    widget.onFilterChanged(const WorkFilter());
  }
}
