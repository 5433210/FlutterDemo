import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../../../../../domain/models/common/date_range_filter.dart';
import '../../../../../theme/app_sizes.dart';

class DateRangeFilterSection extends StatefulWidget {
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
  final _logger = Logger('DateRangeFilterSection');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 显示筛选标签的条件：有预设或自定义日期
    final filter = widget.filter;
    final bool showResetChip = filter != null &&
        ((filter.preset != null && filter.preset != DateRangePreset.all) ||
            filter.start != null ||
            filter.end != null);

    _logger.fine('build - filter: $filter, showResetChip: $showResetChip');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showResetChip)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.s),
            child: Row(
              children: [
                Expanded(
                  child: Chip(
                    label: Text(_formatFilterText()),
                    onDeleted: () {
                      _logger.info('点击删除按钮');
                      widget.onChanged(null);
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 0;
  }

  Widget _buildCustomRange(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDateField(
          context: context,
          label: '开始日期',
          value: widget.filter?.start,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: AppSizes.l),
            if (value != null)
              TextButton(
                onPressed: onClear,
                child: const Text('清除'),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(value != null ? _formatDate(value) : '点击选择日期'),
          onPressed: onPressed,
        ),
      ],
    );
  }

  Widget _buildPresets(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSizes.xs,
            runSpacing: AppSizes.xs,
            children: DateRangePreset.values
                .where((preset) => preset != DateRangePreset.all)
                .map((preset) {
              final selected = widget.filter?.preset == preset;
              return FilterChip(
                label: Text(preset.label),
                selected: selected,
                onSelected: (selected) {
                  _logger.fine('选择预设: $preset, selected: $selected');
                  if (selected) {
                    widget.onChanged(DateRangeFilter.preset(preset));
                  } else {
                    widget.onChanged(null);
                  }
                },
                showCheckmark: false,
                selectedColor: theme.colorScheme.primaryContainer,
              );
            }).toList(),
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

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatFilterText() {
    final filter = widget.filter;
    if (filter == null) return '';

    if (filter.preset != null && filter.preset != DateRangePreset.all) {
      return filter.preset!.label;
    }

    if (filter.start != null || filter.end != null) {
      final start = filter.start != null ? _formatDate(filter.start!) : '开始日期';
      final end = filter.end != null ? _formatDate(filter.end!) : '结束日期';
      return '$start - $end';
    }

    return '';
  }

  String _getPresetDateRange(DateRangePreset preset) {
    final range = preset.getRange();
    return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? widget.filter?.start : widget.filter?.end;

    final result = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      _updateDateRange(
        startDate: isStartDate ? result : widget.filter?.start,
        endDate: isStartDate ? widget.filter?.end : result,
      );
    }
  }

  void _updateDateRange({DateTime? startDate, DateTime? endDate}) {
    _logger.fine('更新日期范围 - 开始: $startDate, 结束: $endDate');

    if (startDate == null && endDate == null) {
      widget.onChanged(null);
      return;
    }

    final newFilter = DateRangeFilter(
      start: startDate ?? widget.filter?.start,
      end: endDate ?? widget.filter?.end,
    );

    _logger.fine('新的filter: $newFilter');
    widget.onChanged(newFilter);
  }
}
