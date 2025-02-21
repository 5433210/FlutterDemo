import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/date_range_filter.dart';
import '../../theme/app_sizes.dart';

class DateRangeFilterSection extends StatelessWidget {
  final DateRangeFilter? filter;
  final ValueChanged<DateRangeFilter?> onChanged;

  const DateRangeFilterSection({
    super.key,
    this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filter != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.s),
              child: Wrap(
                spacing: AppSizes.xs,
                children: [
                  Chip(
                    label: Text(_formatFilterText()),
                    onDeleted: () => onChanged(null),
                  ),
                ],
              ),
            ),
          const TabBar(
            tabs: [
              Tab(text: '快捷选择'),
              Tab(text: '自定义范围'),
            ],
          ),
          const SizedBox(height: AppSizes.m),
          SizedBox(
            height: 240,
            child: TabBarView(
              children: [
                _buildPresets(),
                _buildCustomRange(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresets() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: AppSizes.xs,
        runSpacing: AppSizes.xs,
        children: [
          for (final preset in DateRangePreset.values)
            FilterChip(
              label: Text(preset.label),
              selected: filter?.preset == preset,
              onSelected: (selected) {
                onChanged(selected ? DateRangeFilter.preset(preset) : null);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomRange(BuildContext context) {
    final isStartDateError = filter?.startDate != null && 
                           filter?.endDate != null && 
                           filter!.startDate!.isAfter(filter!.endDate!);
                           
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateField(
            context: context,
            label: '开始日期',
            value: filter?.startDate,
            error: isStartDateError ? '开始日期不能晚于结束日期' : null,
            onPressed: () => _selectDate(
              context,
              initialDate: filter?.startDate,
              isStartDate: true,
              maxDate: filter?.endDate,
            ),
            onClear: () => _updateDateRange(startDate: null),
          ),
          const SizedBox(height: AppSizes.m),
          _buildDateField(
            context: context,
            label: '结束日期',
            value: filter?.endDate,
            onPressed: () => _selectDate(
              context,
              initialDate: filter?.endDate,
              isStartDate: false,
              minDate: filter?.startDate,
            ),
            onClear: () => _updateDateRange(endDate: null),
          ),
        ],
      ),
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(value != null ? _formatDate(value) : '点击选择日期'),
                onPressed: onPressed,
                style: error != null ? 
                  OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ) : null,
              ),
            ),
            if (value != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
              ),
          ],
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

  Future<void> _selectDate(
    BuildContext context, {
    required DateTime? initialDate,
    required bool isStartDate,
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
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
        startDate: isStartDate ? result : filter?.startDate,
        endDate: isStartDate ? filter?.endDate : result,
      );
    }
  }

  void _updateDateRange({DateTime? startDate, DateTime? endDate}) {
    onChanged(DateRangeFilter(
      startDate: startDate,
      endDate: endDate,
    ));
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMd().format(date);
  }

  String _formatFilterText() {
    if (filter == null) return '不限';
    if (filter!.preset != null) return filter!.preset!.label;
    final start = filter!.startDate != null ? _formatDate(filter!.startDate!) : '不限';
    final end = filter!.endDate != null ? _formatDate(filter!.endDate!) : '不限';
    return '$start - $end';
  }
}