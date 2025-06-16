import 'package:flutter/material.dart';

import '../../../../domain/models/common/date_range_filter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';

/// 通用的日期范围筛选部分组件
class M3FilterDateRangeSection extends StatefulWidget {
  /// 日期筛选器标题
  final String title;

  /// 当前的日期范围筛选条件
  final DateRangeFilter filter;

  /// 日期范围变化时的回调
  final ValueChanged<DateRangeFilter?> onChanged;

  /// 构造函数
  const M3FilterDateRangeSection({
    super.key,
    required this.title,
    required this.filter,
    required this.onChanged,
  });

  @override
  State<M3FilterDateRangeSection> createState() =>
      _M3FilterDateRangeSectionState();
}

class _M3FilterDateRangeSectionState extends State<M3FilterDateRangeSection> {
  late DateRangePreset _currentPreset;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacingSmall),

        // 预设选项
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetChip(DateRangePreset.today, l10n.today),
            _buildPresetChip(DateRangePreset.yesterday, l10n.yesterday),
            _buildPresetChip(DateRangePreset.thisWeek, l10n.thisWeek),
            _buildPresetChip(DateRangePreset.lastWeek, l10n.lastWeek),
            _buildPresetChip(DateRangePreset.thisMonth, l10n.thisMonth),
            _buildPresetChip(DateRangePreset.lastMonth, l10n.lastMonth),
            _buildPresetChip(DateRangePreset.thisYear, l10n.thisYear),
            _buildPresetChip(DateRangePreset.lastYear, l10n.lastYear),
            _buildPresetChip(DateRangePreset.all, l10n.allTime),
            _buildPresetChip(DateRangePreset.custom, l10n.custom),
          ],
        ),

        // 自定义日期范围
        if (_currentPreset == DateRangePreset.custom)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        label: l10n.startDate,
                        date: _startDate,
                        onTap: () => _selectDate(true),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingMedium),
                    Expanded(
                      child: _buildDateField(
                        label: l10n.endDate,
                        date: _endDate,
                        onTap: () => _selectDate(false),
                      ),
                    ),
                  ],
                ),
                // 在自定义模式下也显示清除按钮
                if (_startDate != null || _endDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.spacingMedium),
                    child: TextButton.icon(
                      icon: const Icon(Icons.clear, size: 16),
                      label: Text(l10n.filterClear),
                      onPressed: _clearCustomDateFilter,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // 其他预设的清除按钮
        if (_currentPreset != DateRangePreset.custom &&
            _currentPreset != DateRangePreset.all)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.spacingMedium),
            child: TextButton.icon(
              icon: const Icon(Icons.clear, size: 16),
              label: Text(l10n.filterClear),
              onPressed: _clearDateFilter,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void didUpdateWidget(M3FilterDateRangeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.preset != widget.filter.preset ||
        oldWidget.filter.start != widget.filter.start ||
        oldWidget.filter.end != widget.filter.end) {
      setState(() {
        _currentPreset = widget.filter.preset!;
        _startDate = widget.filter.start;
        _endDate = widget.filter.end;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPreset = widget.filter.preset!;
    _startDate = widget.filter.start;
    _endDate = widget.filter.end;
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
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
          date == null
              ? '-'
              : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildPresetChip(DateRangePreset preset, String label) {
    return FilterChip(
      label: Text(label),
      selected: _currentPreset == preset,
      onSelected: (selected) {
        if (_currentPreset == preset) {
          // 如果重复点击已选中项，则重置为全部（默认项）
          setState(() {
            _currentPreset = DateRangePreset.all;
            final range = DateRangePreset.all.getRange();
            _startDate = range.start;
            _endDate = range.end;
          });

          widget.onChanged(const DateRangeFilter(
            preset: DateRangePreset.all,
            start: null,
            end: null,
          ));
        } else if (selected) {
          setState(() {
            _currentPreset = preset;

            if (preset != DateRangePreset.custom) {
              final range = preset.getRange();
              _startDate = range.start;
              _endDate = range.end;
            }
          });

          widget.onChanged(DateRangeFilter(
            preset: preset,
            start: _startDate,
            end: _endDate,
          ));
        }
      },
    );
  }

  // 清除自定义日期范围，但保持在自定义模式
  void _clearCustomDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });

    widget.onChanged(const DateRangeFilter(
      preset: DateRangePreset.custom,
      start: null,
      end: null,
    ));
  }

  void _clearDateFilter() {
    setState(() {
      _currentPreset = DateRangePreset.all;
      _startDate = null;
      _endDate = null;
    });

    widget.onChanged(const DateRangeFilter(
      preset: DateRangePreset.all,
      start: null,
      end: null,
    ));
  }

  Future<void> _selectDate(bool isStart) async {
    final now = DateTime.now();
    final firstDate = DateTime(2000); // 日期选择器的最早可选日期
    final lastDate = DateTime(now.year + 10); // 日期选择器的最晚可选日期

    // 确保初始日期在有效范围内
    DateTime effectiveInitialDate;
    final initialDate = isStart ? _startDate : _endDate;

    if (initialDate == null) {
      // 如果没有初始日期，使用当前日期
      effectiveInitialDate = now;
    } else if (initialDate.isBefore(firstDate)) {
      // 如果初始日期早于允许的最早日期，使用最早日期
      effectiveInitialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      // 如果初始日期晚于允许的最晚日期，使用最晚日期
      effectiveInitialDate = lastDate;
    } else {
      // 初始日期在有效范围内
      effectiveInitialDate = initialDate;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          // 如果结束日期早于开始日期，则更新结束日期
          if (_endDate != null && _endDate!.isBefore(date)) {
            _endDate = date;
          }
        } else {
          _endDate = date;
          // 如果开始日期晚于结束日期，则更新开始日期
          if (_startDate != null && _startDate!.isAfter(date)) {
            _startDate = date;
          }
        }
      });

      // 确保在回调中正确设置preset为custom
      widget.onChanged(DateRangeFilter(
        preset: DateRangePreset.custom,
        start: _startDate,
        end: _endDate,
      ));
    }
  }
}
