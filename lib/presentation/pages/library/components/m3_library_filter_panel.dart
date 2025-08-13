import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/enums/sort_field.dart';
import '../../../../domain/models/common/date_range_filter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/library/library_management_provider.dart';
import '../../../widgets/filter/sections/m3_filter_date_range_section.dart';
import '../../../widgets/filter/sections/m3_filter_sort_section.dart';
import 'library_category_panel.dart';

/// 图库过滤面板
class M3LibraryFilterPanel extends ConsumerStatefulWidget {
  /// 搜索控制器
  final TextEditingController? searchController;

  /// 搜索回调
  final Function(String)? onSearch;

  /// 刷新回调
  final VoidCallback? onRefresh;

  /// 展开/折叠状态变化时的回调
  final VoidCallback? onToggleExpand;

  const M3LibraryFilterPanel({
    super.key,
    this.searchController,
    this.onSearch,
    this.onRefresh,
    this.onToggleExpand,
  });

  @override
  ConsumerState<M3LibraryFilterPanel> createState() =>
      _M3LibraryFilterPanelState();
}

class _M3LibraryFilterPanelState extends ConsumerState<M3LibraryFilterPanel> {
  static const List<String> _fileTypes = ['image', 'texture', 'all'];
  static const List<String> _fileFormats = [
    'jpg',
    'png',
    'webp',
    'gif',
    'tiff'
  ];

  // Add l10n field
  late AppLocalizations l10n;

  // Filter states
  String? _selectedType;
  bool _showFavoritesOnly = false;
  String? _selectedFormat;
  String _sortBy = 'fileName';
  bool _sortDesc = false;
  // Size range states
  late TextEditingController _minWidthController;
  late TextEditingController _maxWidthController;
  late TextEditingController _minHeightController;
  late TextEditingController _maxHeightController;
  late TextEditingController _minSizeController;
  late TextEditingController _maxSizeController;

  // Date filter states
  DateRangeFilter _creationDateFilter =
      const DateRangeFilter(preset: DateRangePreset.all);
  DateRangeFilter _updateDateFilter =
      const DateRangeFilter(preset: DateRangePreset.all);

  // Expanded states
  bool _isSortExpanded = true;
  bool _isCategoriesExpanded = true;
  bool _isTypeExpanded = true;
  bool _isFavoriteExpanded = true;
  bool _isFormatExpanded = true;
  bool _isSizeExpanded = true;
  bool _isFileSizeExpanded = true;
  bool _isCreationDateExpanded = true;
  bool _isUpdateDateExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    l10n = AppLocalizations.of(context);
    return Container(
      // Remove fixed width to allow panel to be responsive
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          _buildHeader(context),
          // 内容区域
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 搜索框部分
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.spacing16,
                        AppSizes.spacing8,
                        AppSizes.spacing16,
                        AppSizes.spacing16),
                    child: TextField(
                      controller: widget.searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            if (widget.onSearch != null &&
                                widget.searchController != null) {
                              widget.onSearch!(widget.searchController!.text);
                            }
                          },
                          tooltip: l10n.search,
                        ),
                        hintText: l10n.search,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        if (widget.onSearch != null) {
                          widget.onSearch!(value);
                        }
                      },
                    ),
                  ),
                ),

                // Sort section
                SliverToBoxAdapter(
                  child: _buildCollapsibleSection(
                    title: l10n.sortBy,
                    isExpanded: _isSortExpanded,
                    onToggle: () =>
                        setState(() => _isSortExpanded = !_isSortExpanded),
                    child: M3FilterSortSection(
                      sortField: SortField.values.firstWhere(
                        (field) => field.toString().split('.').last == _sortBy,
                        orElse: () => SortField.title,
                      ),
                      descending: _sortDesc,
                      availableSortFields: const [
                        SortField.fileName,
                        SortField.fileUpdatedAt,
                        SortField.fileSize,
                      ],
                      onSortFieldChanged: (field) {
                        setState(
                            () => _sortBy = field.toString().split('.').last);
                        ref
                            .read(libraryManagementProvider.notifier)
                            .setSortBy(_sortBy, _sortDesc);
                      },
                      onSortDirectionChanged: (isDescending) {
                        setState(() => _sortDesc = isDescending);
                        ref
                            .read(libraryManagementProvider.notifier)
                            .setSortBy(_sortBy, _sortDesc);
                      },
                    ),
                  ),
                ),

                // Favorites section (现在位于排序下方)
                SliverToBoxAdapter(
                  child: _buildCollapsibleSection(
                    title: l10n.favorite,
                    isExpanded: _isFavoriteExpanded,
                    onToggle: () => setState(
                        () => _isFavoriteExpanded = !_isFavoriteExpanded),
                    child: SwitchListTile(
                      title: Text(l10n.favoritesOnly),
                      value: _showFavoritesOnly,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() => _showFavoritesOnly = value);
                        if (value !=
                            ref
                                .read(libraryManagementProvider)
                                .showFavoritesOnly) {
                          ref
                              .read(libraryManagementProvider.notifier)
                              .toggleFavoritesOnly();
                        }
                      },
                    ),
                  ),
                ), // Categories section
                SliverToBoxAdapter(
                  child: _buildCollapsibleSection(
                    title: l10n.categories,
                    isExpanded: _isCategoriesExpanded,
                    onToggle: () => setState(
                        () => _isCategoriesExpanded = !_isCategoriesExpanded),
                    child: _isCategoriesExpanded
                        ? const LibraryCategoryPanel() // 动态高度，不再使用固定高度的SizedBox
                        : const SizedBox.shrink(),
                  ),
                ),

                // Type filter section
                SliverToBoxAdapter(
                  child: _buildCollapsibleSection(
                    title: l10n.type,
                    isExpanded: _isTypeExpanded,
                    onToggle: () =>
                        setState(() => _isTypeExpanded = !_isTypeExpanded),
                    child: Column(
                      children: [
                        ...List.generate(_fileTypes.length, (index) {
                          final type = _fileTypes[index];
                          return RadioListTile<String?>(
                            title: Text(type == 'all' ? l10n.allTypes : type),
                            value: type == 'all' ? null : type,
                            groupValue: _selectedType,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() => _selectedType = value);
                              ref
                                  .read(libraryManagementProvider.notifier)
                                  .setTypeFilter(value);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Format filter section
                SliverToBoxAdapter(
                  child: _buildCollapsibleSection(
                    title: l10n.format,
                    isExpanded: _isFormatExpanded,
                    onToggle: () =>
                        setState(() => _isFormatExpanded = !_isFormatExpanded),
                    child: Wrap(
                      spacing: AppSizes.spacing8,
                      children: _fileFormats.map((format) {
                        return FilterChip(
                          label: Text(format),
                          selected: _selectedFormat == format,
                          onSelected: (selected) {
                            setState(() =>
                                _selectedFormat = selected ? format : null);
                            ref
                                .read(libraryManagementProvider.notifier)
                                .setFormatFilter(selected ? format : null);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Size range section
                SliverToBoxAdapter(
                  child: _buildSizeRangeSection(),
                ),

                // File size section
                SliverToBoxAdapter(
                  child: _buildFileSizeSection(),
                ),

                // Creation date section
                SliverToBoxAdapter(
                  child: _buildDateRangeSection(isCreationDate: true),
                ),

                // Update date section
                SliverToBoxAdapter(
                  child: _buildDateRangeSection(isCreationDate: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _minWidthController.dispose();
    _maxWidthController.dispose();
    _minHeightController.dispose();
    _maxHeightController.dispose();
    _minSizeController.dispose();
    _maxSizeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _minWidthController = TextEditingController();
    _maxWidthController = TextEditingController();
    _minHeightController = TextEditingController();
    _maxHeightController = TextEditingController();
    _minSizeController = TextEditingController();
    _maxSizeController = TextEditingController();
  }

  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 可展开的标题栏
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16,
            vertical: AppSizes.spacing8,
          ),
          child: InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        // 内容区域
        if (isExpanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: child,
          ),
      ],
    );
  }

  Widget _buildDateRangeSection({required bool isCreationDate}) {
    return _buildCollapsibleSection(
      title: isCreationDate ? l10n.createdAt : l10n.updatedAt,
      isExpanded:
          isCreationDate ? _isCreationDateExpanded : _isUpdateDateExpanded,
      onToggle: () => setState(() {
        if (isCreationDate) {
          _isCreationDateExpanded = !_isCreationDateExpanded;
        } else {
          _isUpdateDateExpanded = !_isUpdateDateExpanded;
        }
      }),
      child: M3FilterDateRangeSection(
        title: '',
        filter: isCreationDate ? _creationDateFilter : _updateDateFilter,
        onChanged: (newFilter) {
          if (isCreationDate) {
            setState(() {
              _creationDateFilter = newFilter ??
                  const DateRangeFilter(preset: DateRangePreset.all);
            });

            final dateRange = newFilter?.effectiveRange;
            ref.read(libraryManagementProvider.notifier).setCreateTimeRange(
                  dateRange?.start,
                  dateRange?.end,
                );
          } else {
            setState(() {
              _updateDateFilter = newFilter ??
                  const DateRangeFilter(preset: DateRangePreset.all);
            });

            final dateRange = newFilter?.effectiveRange;
            ref.read(libraryManagementProvider.notifier).setUpdateTimeRange(
                  dateRange?.start,
                  dateRange?.end,
                );
          }
        },
      ),
    );
  }

  Widget _buildFileSizeSection() {
    return _buildCollapsibleSection(
      title: l10n.fileSize,
      isExpanded: _isFileSizeExpanded,
      onToggle: () =>
          setState(() => _isFileSizeExpanded = !_isFileSizeExpanded),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minSizeController,
                  decoration: InputDecoration(
                    labelText: l10n.min,
                    suffixText: 'MB',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateFileSizeRange(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxSizeController,
                  decoration: InputDecoration(
                    labelText: l10n.max,
                    suffixText: 'MB',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateFileSizeRange(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeRangeSection() {
    return _buildCollapsibleSection(
      title: '${l10n.width}/${l10n.height}',
      isExpanded: _isSizeExpanded,
      onToggle: () => setState(() => _isSizeExpanded = !_isSizeExpanded),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minWidthController,
                  decoration: InputDecoration(
                    labelText: '${l10n.width} (${l10n.min})',
                    suffixText: 'px',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateSizeRange(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxWidthController,
                  decoration: InputDecoration(
                    labelText: '${l10n.width} (${l10n.max})',
                    suffixText: 'px',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateSizeRange(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minHeightController,
                  decoration: InputDecoration(
                    labelText: '${l10n.height} (${l10n.min})',
                    suffixText: 'px',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateSizeRange(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxHeightController,
                  decoration: InputDecoration(
                    labelText: '${l10n.height} (${l10n.max})',
                    suffixText: 'px',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateSizeRange(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedType = null;
      _showFavoritesOnly = false;
      _selectedFormat = null;
      _sortBy = 'fileName';
      _sortDesc = false;
      _creationDateFilter = const DateRangeFilter(preset: DateRangePreset.all);
      _updateDateFilter = const DateRangeFilter(preset: DateRangePreset.all);
    });

    // 清空搜索框
    if (widget.searchController != null) {
      widget.searchController!.clear();
      if (widget.onSearch != null) {
        widget.onSearch!('');
      }
    }

    ref.read(libraryManagementProvider.notifier).resetFilters();
  }

  void _updateFileSizeRange() {
    final minSize = double.tryParse(_minSizeController.text);
    final maxSize = double.tryParse(_maxSizeController.text);

    if (minSize != null || maxSize != null) {
      // Convert MB to bytes
      final minBytes = minSize != null ? (minSize * 1024 * 1024).toInt() : null;
      final maxBytes = maxSize != null ? (maxSize * 1024 * 1024).toInt() : null;
      ref
          .read(libraryManagementProvider.notifier)
          .setSizeRange(minBytes, maxBytes);
    }
  }

  void _updateSizeRange() {
    final minWidth = int.tryParse(_minWidthController.text);
    final maxWidth = int.tryParse(_maxWidthController.text);
    final minHeight = int.tryParse(_minHeightController.text);
    final maxHeight = int.tryParse(_maxHeightController.text);

    if (minWidth != null || maxWidth != null) {
      ref
          .read(libraryManagementProvider.notifier)
          .setWidthRange(minWidth, maxWidth);
    }
    if (minHeight != null || maxHeight != null) {
      ref
          .read(libraryManagementProvider.notifier)
          .setHeightRange(minHeight, maxHeight);
    }
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              l10n.filter,
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 刷新按钮
              if (widget.onRefresh != null)
                Tooltip(
                  message: l10n.refresh,
                  child: IconButton(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.sync),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(0),
                  ),
                ),

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

              // 关闭按钮（窄屏模式下显示）
              if (widget.onToggleExpand != null)
                Tooltip(
                  message: l10n.close,
                  child: IconButton(
                    onPressed: widget.onToggleExpand,
                    icon: const Icon(Icons.chevron_left),
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
}
