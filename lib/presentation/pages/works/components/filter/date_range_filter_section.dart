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
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _hasSelection => _startDate != null || _endDate != null;

  bool get _hasValidRange =>
      _startDate != null && _endDate != null && _startDate!.isBefore(_endDate!);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
    _startDate = widget.filter?.start;
    _endDate = widget.filter?.end;
  }

  void _applyDateRange() {
    if (_hasValidRange) {
      _logger.fine('应用日期范围 - 开始: $_startDate, 结束: $_endDate');
      widget.onChanged(DateRangeFilter(
        start: _startDate,
        end: _endDate,
      ));
    }
  }

  Widget _buildCustomRange(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDateField(
          context: context,
          label: '开始日期',
          value: _startDate,
          onPressed: () => _selectDate(context, true),
        ),
        const SizedBox(height: AppSizes.m),
        _buildDateField(
          context: context,
          label: '结束日期',
          value: _endDate,
          onPressed: () => _selectDate(context, false),
        ),
        if (_hasSelection) ...[
          const SizedBox(height: AppSizes.l),
          Row(
            children: [
              if (_hasValidRange)
                Expanded(
                  child: FilledButton(
                    onPressed: _applyDateRange,
                    child: const Text('应用'),
                  ),
                ),
              if (_hasValidRange) const SizedBox(width: AppSizes.s),
              Expanded(
                child: TextButton(
                  onPressed: _clearDateRange,
                  child: const Text('清除'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSizes.xs),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(value != null ? _formatDate(value) : '点击选择日期'),
            onPressed: onPressed,
          ),
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

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
      widget.onChanged(null);
    });
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
    final initialDate = isStartDate ? _startDate : _endDate;

    final result = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      setState(() {
        if (isStartDate) {
          _startDate = result;
        } else {
          _endDate = result;
        }
      });
    }
  }
}
