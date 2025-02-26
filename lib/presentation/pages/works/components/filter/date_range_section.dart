import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_sizes.dart';

class DateRangeSection extends StatefulWidget {
  final DateTimeRange? initialValue;
  final ValueChanged<DateTimeRange?> onChanged;

  const DateRangeSection({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<DateRangeSection> createState() => _DateRangeSectionState();
}

class _DateRangeSectionState extends State<DateRangeSection> {
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _hasSelection => _startDate != null || _endDate != null;

  bool get _hasValidRange =>
      _startDate != null && _endDate != null && _startDate!.isBefore(_endDate!);

  @override
  Widget build(BuildContext context) {
    final isStartDateError = _startDate != null &&
        _endDate != null &&
        _startDate!.isAfter(_endDate!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDateField(
          context: context,
          label: '开始日期',
          value: _startDate,
          error: isStartDateError ? '开始日期不能晚于结束日期' : null,
          onPressed: () => _selectDate(
            context: context,
            initialDate: _startDate,
            isStartDate: true,
            maxDate: _endDate,
          ),
          onClear: () => _updateDateRange(startDate: null),
        ),
        const SizedBox(height: AppSizes.m),
        _buildDateField(
          context: context,
          label: '结束日期',
          value: _endDate,
          onPressed: () => _selectDate(
            context: context,
            initialDate: _endDate,
            isStartDate: false,
            minDate: _startDate,
          ),
          onClear: () => _updateDateRange(endDate: null),
        ),
        // 添加应用和清除按钮
        if (_hasValidRange || _hasSelection) ...[
          const SizedBox(height: AppSizes.m),
          Row(
            children: [
              if (_hasValidRange)
                Expanded(
                  child: FilledButton(
                    onPressed: _applyDateRange,
                    child: const Text('应用'),
                  ),
                ),
              if (_hasSelection) ...[
                if (_hasValidRange) const SizedBox(width: AppSizes.s),
                Expanded(
                  child: TextButton(
                    onPressed: _clearDateRange,
                    child: const Text('清除'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialValue?.start;
    _endDate = widget.initialValue?.end;
  }

  void _applyDateRange() {
    if (_hasValidRange) {
      widget.onChanged(DateTimeRange(
        start: _startDate!,
        end: _endDate!,
      ));
    }
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

  Future<void> _selectDate({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    required bool isStartDate,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: maxDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
        _updateDateRange();
      });
    }
  }

  void _updateDateRange({DateTime? startDate, DateTime? endDate}) {
    setState(() {
      _startDate = startDate ?? _startDate;
      _endDate = endDate ?? _endDate;
      widget.onChanged(_startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null);
    });
  }
}
