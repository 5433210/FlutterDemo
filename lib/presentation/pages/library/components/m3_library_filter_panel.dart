import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/library/library_management_provider.dart';
import '../../../widgets/section_header.dart';
import 'library_category_panel.dart'; // 改回使用 LibraryCategoryPanel

/// 图库过滤面板
class M3LibraryFilterPanel extends ConsumerStatefulWidget {
  /// 构造函数
  const M3LibraryFilterPanel({
    super.key,
  });

  @override
  ConsumerState<M3LibraryFilterPanel> createState() =>
      _M3LibraryFilterPanelState();
}

class _M3LibraryFilterPanelState extends ConsumerState<M3LibraryFilterPanel> {
  // 常量定义
  static const List<String> _fileTypes = ['image', 'texture', 'all'];
  static const List<String> _fileFormats = [
    'jpg',
    'png',
    'webp',
    'gif',
    'tiff'
  ];
  // 本地状态，暂时用于原型开发，后续整合到全局状态中
  String? _selectedType;
  bool _showFavoritesOnly = false;
  String? _selectedFormat;
  RangeValues? _widthRange;
  RangeValues? _heightRange;
  RangeValues? _sizeRange;
  DateTimeRange? _createTimeRange;
  DateTimeRange? _updateTimeRange;
  String? _createDatePreset = 'all'; // 入库日期预设
  String? _updateDatePreset = 'all'; // 更新日期预设

  String _sortBy = 'name';
  bool _sortDesc = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.filterHeader,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetFilters,
                tooltip: l10n.filterReset,
              ),
            ],
          ),

          const Divider(),

          // 内容区域 - 滚动视图
          Expanded(
            child: ListView(
              children: [
                // 分类列表
                SectionHeader(
                  title: l10n.libraryManagementCategories,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSizes.spacing8), // 添加分类列表面板
                const Card(
                  margin: EdgeInsets.only(bottom: 16.0),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 300, // 增加高度以适应分类面板
                    child:
                        LibraryCategoryPanel(), // 使用 LibraryCategoryPanel 替代 LibraryCategoryListPanel
                  ),
                ),

                const Divider(),

                // 类型筛选
                _buildFilterSection(
                  title: '类型筛选',
                  child: Column(
                    children: [
                      ...List.generate(_fileTypes.length, (index) {
                        final type = _fileTypes[index];
                        return RadioListTile<String?>(
                          title: Text(type == 'all' ? '所有类型' : type),
                          value: type == 'all' ? null : type,
                          groupValue: _selectedType,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value;
                            });
                            // Apply filter immediately
                            ref
                                .read(libraryManagementProvider.notifier)
                                .setTypeFilter(value);
                          },
                        );
                      }),
                    ],
                  ),
                ),

                // 收藏筛选
                _buildFilterSection(
                  title: '收藏筛选',
                  child: SwitchListTile(
                    title: Text(l10n.filterFavoritesOnly),
                    value: _showFavoritesOnly,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _showFavoritesOnly = value;
                      });
                      // Apply filter immediately
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

                // 格式筛选
                _buildFilterSection(
                  title: '格式筛选',
                  child: Wrap(
                    spacing: 8,
                    children: _fileFormats.map((format) {
                      return FilterChip(
                        label: Text(format),
                        selected: _selectedFormat == format,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFormat = selected ? format : null;
                          });
                          // Apply filter immediately
                          ref
                              .read(libraryManagementProvider.notifier)
                              .setFormatFilter(selected ? format : null);
                        },
                      );
                    }).toList(),
                  ),
                ),

                // 尺寸范围筛选
                _buildFilterSection(
                  title: '尺寸范围',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('宽度 (px)'),
                      RangeSlider(
                        values: _widthRange ?? const RangeValues(0, 4000),
                        min: 0,
                        max: 4000,
                        divisions: 40,
                        labels: RangeLabels(
                          (_widthRange?.start ?? 0).round().toString(),
                          (_widthRange?.end ?? 4000).round().toString(),
                        ),
                        onChanged: (values) {
                          setState(() {
                            _widthRange = values;
                          });
                        },
                        onChangeEnd: (values) {
                          // Apply filter when slider change ends
                          ref
                              .read(libraryManagementProvider.notifier)
                              .setWidthRange(
                                  values.start.round(), values.end.round());
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${(_widthRange?.start ?? 0).round()}px'),
                          Text('${(_widthRange?.end ?? 4000).round()}px'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('高度 (px)'),
                      RangeSlider(
                        values: _heightRange ?? const RangeValues(0, 4000),
                        min: 0,
                        max: 4000,
                        divisions: 40,
                        labels: RangeLabels(
                          (_heightRange?.start ?? 0).round().toString(),
                          (_heightRange?.end ?? 4000).round().toString(),
                        ),
                        onChanged: (values) {
                          setState(() {
                            _heightRange = values;
                          });
                        },
                        onChangeEnd: (values) {
                          // Apply filter when slider change ends
                          ref
                              .read(libraryManagementProvider.notifier)
                              .setHeightRange(
                                  values.start.round(), values.end.round());
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${(_heightRange?.start ?? 0).round()}px'),
                          Text('${(_heightRange?.end ?? 4000).round()}px'),
                        ],
                      ),
                    ],
                  ),
                ),

                // 文件大小筛选
                _buildFilterSection(
                  title: '文件大小',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RangeSlider(
                        values: _sizeRange ?? const RangeValues(0, 10),
                        min: 0,
                        max: 10,
                        divisions: 20,
                        labels: RangeLabels(
                          '${(_sizeRange?.start ?? 0).round()} MB',
                          '${(_sizeRange?.end ?? 10).round()} MB',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _sizeRange = values;
                          });
                        },
                        onChangeEnd: (values) {
                          // Apply filter when slider change ends
                          ref
                              .read(libraryManagementProvider.notifier)
                              .setSizeRange(
                                  (values.start * 1024 * 1024).round(),
                                  (values.end * 1024 * 1024).round());
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${(_sizeRange?.start ?? 0).round()} MB'),
                          Text('${(_sizeRange?.end ?? 10).round()} MB'),
                        ],
                      ),
                    ],
                  ),
                ), // 入库日期范围筛选
                _buildFilterSection(
                  title: '入库日期',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 预设选项
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDatePresetChip('today', '今天'),
                          _buildDatePresetChip('yesterday', '昨天'),
                          _buildDatePresetChip('thisWeek', '本周'),
                          _buildDatePresetChip('lastWeek', '上周'),
                          _buildDatePresetChip('thisMonth', '本月'),
                          _buildDatePresetChip('lastMonth', '上月'),
                          _buildDatePresetChip('thisYear', '今年'),
                          _buildDatePresetChip('lastYear', '去年'),
                          _buildDatePresetChip('all', '全部'),
                          _buildDatePresetChip('custom', '自定义'),
                        ],
                      ),

                      // 自定义日期范围
                      if (_createDatePreset == 'custom')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  label: '开始日期',
                                  date: _createTimeRange?.start,
                                  onTap: () => _selectDateRange(context, true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateField(
                                  label: '结束日期',
                                  date: _createTimeRange?.end,
                                  onTap: () => _selectDateRange(context, true),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_createTimeRange != null ||
                          _createDatePreset != null &&
                              _createDatePreset != 'all')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _createTimeRange = null;
                                _createDatePreset = 'all';
                              });
                              // Apply filter immediately
                              ref
                                  .read(libraryManagementProvider.notifier)
                                  .setCreateTimeRange(null, null);
                            },
                            child: Text(l10n.filterClear),
                          ),
                        ),
                    ],
                  ),
                ),

                // 文件更新日期筛选
                _buildFilterSection(
                  title: '更新日期',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 预设选项
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildUpdateDatePresetChip('today', '今天'),
                          _buildUpdateDatePresetChip('yesterday', '昨天'),
                          _buildUpdateDatePresetChip('thisWeek', '本周'),
                          _buildUpdateDatePresetChip('lastWeek', '上周'),
                          _buildUpdateDatePresetChip('thisMonth', '本月'),
                          _buildUpdateDatePresetChip('lastMonth', '上月'),
                          _buildUpdateDatePresetChip('thisYear', '今年'),
                          _buildUpdateDatePresetChip('lastYear', '去年'),
                          _buildUpdateDatePresetChip('all', '全部'),
                          _buildUpdateDatePresetChip('custom', '自定义'),
                        ],
                      ),

                      // 自定义日期范围
                      if (_updateDatePreset == 'custom')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  label: '开始日期',
                                  date: _updateTimeRange?.start,
                                  onTap: () => _selectDateRange(context, false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateField(
                                  label: '结束日期',
                                  date: _updateTimeRange?.end,
                                  onTap: () => _selectDateRange(context, false),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_updateTimeRange != null ||
                          _updateDatePreset != null &&
                              _updateDatePreset != 'all')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _updateTimeRange = null;
                                _updateDatePreset = 'all';
                              });
                              // Apply filter immediately
                              ref
                                  .read(libraryManagementProvider.notifier)
                                  .setUpdateTimeRange(null, null);
                            },
                            child: Text(l10n.filterClear),
                          ),
                        ),
                    ],
                  ),
                ),

                const Divider(), // 排序选项
                SectionHeader(
                  title: l10n.libraryManagementSortBy,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSizes.spacing8),
                // 排序字段选择
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
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
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('文件名')),
                      DropdownMenuItem(value: 'createdAt', child: Text('入库时间')),
                      DropdownMenuItem(value: 'updatedAt', child: Text('更新时间')),
                      DropdownMenuItem(value: 'size', child: Text('文件大小')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                        // Apply sorting immediately
                        ref
                            .read(libraryManagementProvider.notifier)
                            .updateSorting(_sortBy, _sortDesc);
                      }
                    },
                  ),
                ),

                const SizedBox(height: AppSizes.spacing8),

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
                          groupValue: _sortDesc,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortDesc = value;
                              });
                              // Apply sorting immediately
                              ref
                                  .read(libraryManagementProvider.notifier)
                                  .updateSorting(_sortBy, _sortDesc);
                            }
                          },
                        ),
                        const Flexible(
                          child: Text('升序 (A→Z, 旧→新, 小→大)'),
                        )
                      ],
                    ),

                    // 降序
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _sortDesc,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortDesc = value;
                              });
                              // Apply sorting immediately
                              ref
                                  .read(libraryManagementProvider.notifier)
                                  .updateSorting(_sortBy, _sortDesc);
                            }
                          },
                        ),
                        const Flexible(
                          child: Text('降序 (Z→A, 新→旧, 大→小)'),
                        )
                      ],
                    ),
                  ],
                ), // 重置筛选按钮
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _resetFilters,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(l10n.filterReset),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Initialize local state from provider state
    final state = ref.read(libraryManagementProvider);
    _selectedType = state.typeFilter;
    _showFavoritesOnly = state.showFavoritesOnly;
    _selectedFormat = state.formatFilter;

    // Initialize width range if set in state
    if (state.minWidth != null || state.maxWidth != null) {
      _widthRange = RangeValues(
          state.minWidth?.toDouble() ?? 0, state.maxWidth?.toDouble() ?? 4000);
    }

    // Initialize height range if set in state
    if (state.minHeight != null || state.maxHeight != null) {
      _heightRange = RangeValues(state.minHeight?.toDouble() ?? 0,
          state.maxHeight?.toDouble() ?? 4000);
    }

    // Initialize size range if set in state (convert bytes to MB)
    if (state.minSize != null || state.maxSize != null) {
      _sizeRange = RangeValues((state.minSize ?? 0) / (1024 * 1024),
          (state.maxSize ?? (10 * 1024 * 1024)) / (1024 * 1024));
    } // Initialize create time range
    if (state.createStartDate != null && state.createEndDate != null) {
      _createTimeRange = DateTimeRange(
          start: state.createStartDate!, end: state.createEndDate!);
      _createDatePreset = 'custom'; // 当有日期时设置为自定义
    } else {
      _createDatePreset = 'all';
    }

    // Initialize update time range
    if (state.updateStartDate != null && state.updateEndDate != null) {
      _updateTimeRange = DateTimeRange(
          start: state.updateStartDate!, end: state.updateEndDate!);
      _updateDatePreset = 'custom'; // 当有日期时设置为自定义
    } else {
      _updateDatePreset = 'all';
    }

    // Initialize sort settings
    _sortBy = state.sortBy;
    _sortDesc = state.sortDesc;
  }

  // 使用LibraryCategoryPanel替代原来的分类列表
  // 构建日期输入字段
  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        child: Text(
          date != null ? DateFormat.yMd().format(date) : '选择日期',
          style: TextStyle(
            color: date != null ? null : Colors.black38,
          ),
        ),
      ),
    );
  }

  // 构建入库日期预设选择芯片
  Widget _buildDatePresetChip(String preset, String label) {
    return FilterChip(
      label: Text(label),
      selected: _createDatePreset == preset,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _createDatePreset = preset;

            // 根据预设设置日期范围
            final now = DateTime.now();
            if (preset == 'today') {
              final today = DateTime(now.year, now.month, now.day);
              _createTimeRange = DateTimeRange(start: today, end: now);
            } else if (preset == 'yesterday') {
              final yesterday = DateTime(now.year, now.month, now.day - 1);
              final endOfYesterday = DateTime(now.year, now.month, now.day)
                  .subtract(const Duration(seconds: 1));
              _createTimeRange =
                  DateTimeRange(start: yesterday, end: endOfYesterday);
            } else if (preset == 'thisWeek') {
              // 计算本周的开始（周一）
              final firstDayOfWeek =
                  now.subtract(Duration(days: now.weekday - 1));
              final startOfWeek = DateTime(firstDayOfWeek.year,
                  firstDayOfWeek.month, firstDayOfWeek.day);
              _createTimeRange = DateTimeRange(start: startOfWeek, end: now);
            } else if (preset == 'lastWeek') {
              // 上周
              final firstDayOfThisWeek =
                  now.subtract(Duration(days: now.weekday - 1));
              final lastDayOfLastWeek =
                  firstDayOfThisWeek.subtract(const Duration(seconds: 1));
              final firstDayOfLastWeek =
                  lastDayOfLastWeek.subtract(const Duration(days: 6));
              _createTimeRange = DateTimeRange(
                  start: firstDayOfLastWeek, end: lastDayOfLastWeek);
            } else if (preset == 'thisMonth') {
              // 本月
              final startOfMonth = DateTime(now.year, now.month, 1);
              _createTimeRange = DateTimeRange(start: startOfMonth, end: now);
            } else if (preset == 'lastMonth') {
              // 上月
              final startOfThisMonth = DateTime(now.year, now.month, 1);
              final lastDayOfLastMonth =
                  startOfThisMonth.subtract(const Duration(seconds: 1));
              final startOfLastMonth = DateTime(
                  lastDayOfLastMonth.year, lastDayOfLastMonth.month, 1);
              _createTimeRange = DateTimeRange(
                  start: startOfLastMonth, end: lastDayOfLastMonth);
            } else if (preset == 'thisYear') {
              // 今年
              final startOfYear = DateTime(now.year, 1, 1);
              _createTimeRange = DateTimeRange(start: startOfYear, end: now);
            } else if (preset == 'lastYear') {
              // 去年
              final startOfThisYear = DateTime(now.year, 1, 1);
              final lastDayOfLastYear =
                  startOfThisYear.subtract(const Duration(seconds: 1));
              final startOfLastYear = DateTime(lastDayOfLastYear.year, 1, 1);
              _createTimeRange =
                  DateTimeRange(start: startOfLastYear, end: lastDayOfLastYear);
            } else if (preset == 'all') {
              // 全部（不筛选）
              _createTimeRange = null;
            } else if (preset == 'custom') {
              // 自定义，不改变当前范围
              _createTimeRange ??= DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 7)),
                end: DateTime.now(),
              );
            }

            // 立即应用筛选
            if (preset != 'custom') {
              ref.read(libraryManagementProvider.notifier).setCreateTimeRange(
                    _createTimeRange?.start,
                    _createTimeRange?.end,
                  );
            }
          });
        }
      },
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSizes.spacing8),
        child,
        const SizedBox(height: AppSizes.spacing16),
      ],
    );
  }

  // 构建更新日期预设选择芯片
  Widget _buildUpdateDatePresetChip(String preset, String label) {
    return FilterChip(
      label: Text(label),
      selected: _updateDatePreset == preset,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _updateDatePreset = preset;

            // 根据预设设置日期范围
            final now = DateTime.now();
            if (preset == 'today') {
              final today = DateTime(now.year, now.month, now.day);
              _updateTimeRange = DateTimeRange(start: today, end: now);
            } else if (preset == 'yesterday') {
              final yesterday = DateTime(now.year, now.month, now.day - 1);
              final endOfYesterday = DateTime(now.year, now.month, now.day)
                  .subtract(const Duration(seconds: 1));
              _updateTimeRange =
                  DateTimeRange(start: yesterday, end: endOfYesterday);
            } else if (preset == 'thisWeek') {
              // 计算本周的开始（周一）
              final firstDayOfWeek =
                  now.subtract(Duration(days: now.weekday - 1));
              final startOfWeek = DateTime(firstDayOfWeek.year,
                  firstDayOfWeek.month, firstDayOfWeek.day);
              _updateTimeRange = DateTimeRange(start: startOfWeek, end: now);
            } else if (preset == 'lastWeek') {
              // 上周
              final firstDayOfThisWeek =
                  now.subtract(Duration(days: now.weekday - 1));
              final lastDayOfLastWeek =
                  firstDayOfThisWeek.subtract(const Duration(seconds: 1));
              final firstDayOfLastWeek =
                  lastDayOfLastWeek.subtract(const Duration(days: 6));
              _updateTimeRange = DateTimeRange(
                  start: firstDayOfLastWeek, end: lastDayOfLastWeek);
            } else if (preset == 'thisMonth') {
              // 本月
              final startOfMonth = DateTime(now.year, now.month, 1);
              _updateTimeRange = DateTimeRange(start: startOfMonth, end: now);
            } else if (preset == 'lastMonth') {
              // 上月
              final startOfThisMonth = DateTime(now.year, now.month, 1);
              final lastDayOfLastMonth =
                  startOfThisMonth.subtract(const Duration(seconds: 1));
              final startOfLastMonth = DateTime(
                  lastDayOfLastMonth.year, lastDayOfLastMonth.month, 1);
              _updateTimeRange = DateTimeRange(
                  start: startOfLastMonth, end: lastDayOfLastMonth);
            } else if (preset == 'thisYear') {
              // 今年
              final startOfYear = DateTime(now.year, 1, 1);
              _updateTimeRange = DateTimeRange(start: startOfYear, end: now);
            } else if (preset == 'lastYear') {
              // 去年
              final startOfThisYear = DateTime(now.year, 1, 1);
              final lastDayOfLastYear =
                  startOfThisYear.subtract(const Duration(seconds: 1));
              final startOfLastYear = DateTime(lastDayOfLastYear.year, 1, 1);
              _updateTimeRange =
                  DateTimeRange(start: startOfLastYear, end: lastDayOfLastYear);
            } else if (preset == 'all') {
              // 全部（不筛选）
              _updateTimeRange = null;
            } else if (preset == 'custom') {
              // 自定义，不改变当前范围
              _updateTimeRange ??= DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 7)),
                end: DateTime.now(),
              );
            }

            // 立即应用筛选
            if (preset != 'custom') {
              ref.read(libraryManagementProvider.notifier).setUpdateTimeRange(
                    _updateTimeRange?.start,
                    _updateTimeRange?.end,
                  );
            }
          });
        }
      },
    );
  }

  void _resetFilters() {
    // Reset local state
    setState(() {
      _selectedType = null;
      _showFavoritesOnly = false;
      _selectedFormat = null;
      _widthRange = null;
      _heightRange = null;
      _sizeRange = null;
      _createTimeRange = null;
      _updateTimeRange = null;
      _createDatePreset = 'all';
      _updateDatePreset = 'all';
      _sortBy = 'name';
      _sortDesc = false;
    });

    // Reset provider state
    final notifier = ref.read(libraryManagementProvider.notifier);
    notifier.resetAllFilters();

    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已重置所有筛选条件'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, bool isCreateTime) async {
    final initialDateRange = isCreateTime ? _createTimeRange : _updateTimeRange;

    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: isCreateTime ? '选择入库日期范围' : '选择更新日期范围',
    );

    if (result != null) {
      setState(() {
        if (isCreateTime) {
          _createTimeRange = result;
        } else {
          _updateTimeRange = result;
        }
      });
    }
  }
}
