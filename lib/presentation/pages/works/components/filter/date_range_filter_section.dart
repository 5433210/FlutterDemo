import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/date_range_filter.dart';
import '../../../../theme/app_sizes.dart';

class DateRangeFilterSection extends StatefulWidget {
  // 改为 StatefulWidget
  final DateRangeFilter? filter;
  final ValueChanged<DateRangeFilter?> onChanged;

  const DateRangeFilterSection({
    super.key,
    this.filter,
    required this.onChanged,
  });

  @override
  State<DateRangeFilterSection> createState() => _DateRangeFilterSectionState();
}

class _DateRangeFilterSectionState extends State<DateRangeFilterSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool showResetChip = widget.filter != null &&
        (widget.filter!.preset != null ||
            widget.filter!.start != null ||
            widget.filter!.end != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 当前筛选条件显示
        if (showResetChip)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.s),
            child: Row(
              children: [
                Expanded(
                  child: Chip(
                    label: Text(_formatFilterText()),
                    onDeleted: () {
                      widget.onChanged(null);
                      // 重置时默认切换到预设标签页
                      _tabController.animateTo(0);
                    },
                  ),
                ),
              ],
            ),
          ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '预设'),
            Tab(text: '自定义'),
          ],
          // 移除 onTap 处理器，让用户可以自由切换标签页
        ),
        const SizedBox(height: AppSizes.m),
        SizedBox(
          height: 240,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPresets(theme),
              _buildCustomRange(context),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant DateRangeFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在选择预设时切换到预设标签页
    if (oldWidget.filter?.preset != widget.filter?.preset &&
        widget.filter?.preset != null) {
      _tabController.animateTo(0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 默认显示预设标签页，不再根据过滤器状态决定
    _tabController.index = 0;
  }

  Widget _buildCustomRange(BuildContext context) {
    final isStartDateError = widget.filter?.start != null &&
        widget.filter?.end != null &&
        widget.filter!.start!.isAfter(widget.filter!.end!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDateField(
          context: context,
          label: '开始日期',
          value: widget.filter?.start,
          error: isStartDateError ? '开始日期不能晚于结束日期' : null,
          onPressed: () => _selectDate(context, true),
          onClear: () => _updateDateRange(startDate: null),
        ),
        const SizedBox(height: AppSizes.m),
        _buildDateField(
          context: context,
          label: '结束日期',
          value: widget.filter?.end,
          onPressed: () => _selectDate(context, false),
          onClear: () => _updateDateRange(endDate: null),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required VoidCallback onPressed,
    required VoidCallback onClear,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSizes.xs),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(value != null ? _formatDate(value) : '点击选择日期'),
          onPressed: onPressed,
          style: error != null
              ? OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.xs),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildPresets(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s),
      child: Column(
        // 改用 Column 以获得更好的布局控制
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSizes.xs,
            runSpacing: AppSizes.xs,
            children: [
              for (final preset in DateRangePreset.values)
                FilterChip(
                  label: Text(preset.label),
                  selected: widget.filter?.preset == preset,
                  onSelected: (selected) {
                    widget.onChanged(
                        selected ? DateRangeFilter.preset(preset) : null);
                  },
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primaryContainer,
                ),
            ],
          ),
          if (widget.filter?.preset != null) ...[
            const SizedBox(height: AppSizes.m),
            Text(
              _getPresetDateRange(widget.filter!.preset!),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  void _clearCustomRange() {
    if (widget.filter?.start != null || widget.filter?.end != null) {
      if (widget.filter?.preset != null) {
        widget.onChanged(DateRangeFilter.preset(widget.filter!.preset!));
      } else {
        widget.onChanged(null);
      }
    }
  }

  void _clearPreset() {
    if (widget.filter?.preset != null) {
      widget.onChanged(DateRangeFilter(
        start: widget.filter?.start,
        end: widget.filter?.end,
      ));
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMd().format(date);
  }

  String _formatFilterText() {
    if (widget.filter == null) return '不限';
    if (widget.filter!.preset != null) {
      return widget.filter!.preset!.label;
    }

    final DateTimeRange? range = widget.filter!.effectiveRange;
    if (range == null) return '不限';

    final start = _formatDate(range.start);
    final end = _formatDate(range.end);
    if (start == end) return start;
    return '$start - $end';
  }

  String _getPresetDateRange(DateRangePreset preset) {
    final range = preset.getRange();
    return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? widget.filter?.start : widget.filter?.end;
    final minDate = isStartDate ? null : widget.filter?.start;
    final maxDate = isStartDate ? widget.filter?.end : null;

    final result = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      selectableDayPredicate: (date) {
        if (minDate != null && date.isBefore(minDate)) return false;
        if (maxDate != null && date.isAfter(maxDate)) return false;
        return true;
      },
    );

    if (result != null) {
      _updateDateRange(
        startDate: isStartDate ? result : widget.filter?.start,
        endDate: isStartDate ? widget.filter?.end : result,
      );
    }
  }

  void _updateDateRange({DateTime? startDate, DateTime? endDate}) {
    final newFilter = DateRangeFilter(
      start: startDate ?? widget.filter?.start,
      end: endDate ?? widget.filter?.end,
    );

    if (newFilter != widget.filter) {
      widget.onChanged(newFilter);
    }
  }
}
