import 'package:flutter/material.dart';
import '../../models/date_range_filter.dart';

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
    return Column(
      children: [
        if (filter != null) ...[
          Chip(
            label: Text(
              '${_formatDate(filter!.start)} - ${_formatDate(filter!.end)}',
            ),
            onDeleted: () => onChanged(null),
          ),
        ] else
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: const Text('选择时间范围'),
            onPressed: () => _showDateRangePicker(context),
          ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '不限';
    return '${date.year}/${date.month}/${date.day}';
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDateRange: filter != null
          ? DateTimeRange(
              start: filter!.start ?? DateTime(1900),
              end: filter!.end ?? DateTime.now(),
            )
          : null,
    );

    if (result != null) {
      onChanged(DateRangeFilter(
        start: result.start,
        end: result.end,
      ));
    }
  }
}