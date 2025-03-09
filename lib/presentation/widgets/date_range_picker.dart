import 'package:flutter/material.dart';

import '../../domain/models/common/date_range_filter.dart';
import '../../theme/app_sizes.dart';

class DateRangePicker extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTimeRange> onDateRangeChanged;

  const DateRangePicker({
    super.key,
    this.initialDateRange,
    required this.firstDate,
    required this.lastDate,
    required this.onDateRangeChanged,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  late DateTime _startDate;
  late DateTime _endDate;
  DateTime? _selectedDate;

  bool get _isSelectingStart => _selectedDate == null;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildDateHeader(),
              Expanded(
                child: CalendarDatePicker(
                  initialDate: _selectedDate ?? _startDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onDateChanged: _handleDateSelected,
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 200,
          child: _buildQuickSelections(),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange?.start ?? widget.lastDate;
    _endDate = widget.initialDateRange?.end ?? widget.lastDate;
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.s),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              _formatDate(date),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSizes.m),
      child: Row(
        children: [
          _buildDateButton(
            label: '开始日期',
            date: _startDate,
            isSelected: _selectedDate == null || _isSelectingStart,
            onPressed: () => _handleModeChange(true),
          ),
          const SizedBox(width: AppSizes.m),
          Text('至', style: theme.textTheme.bodyMedium),
          const SizedBox(width: AppSizes.m),
          _buildDateButton(
            label: '结束日期',
            date: _endDate,
            isSelected: _selectedDate != null && !_isSelectingStart,
            onPressed: () => _handleModeChange(false),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          title: const Text('某个日期之前'),
          onTap: () => _showSingleDatePicker(
            title: '选择日期',
            initialDate: _endDate,
            onDateSelected: (date) {
              setState(() {
                _endDate = date;
                _startDate = widget.firstDate;
                widget.onDateRangeChanged(DateTimeRange(
                  start: _startDate,
                  end: _endDate,
                ));
              });
            },
          ),
        ),
        ListTile(
          dense: true,
          title: const Text('某个日期之后'),
          onTap: () => _showSingleDatePicker(
            title: '选择日期',
            initialDate: _startDate,
            onDateSelected: (date) {
              setState(() {
                _startDate = date;
                _endDate = widget.lastDate;
                widget.onDateRangeChanged(DateTimeRange(
                  start: _startDate,
                  end: _endDate,
                ));
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSelections() {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.m),
      children: [
        Text(
          '快捷选择',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.m),
        _buildDateTypeSection(),
        const Divider(),
        ...DateRangePreset.values.map(
          (preset) => ListTile(
            dense: true,
            title: Text(_getPresetLabel(preset)),
            onTap: () => _handlePresetSelected(preset),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getPresetLabel(DateRangePreset preset) {
    // Convert the preset enum value to a readable label.
    return preset.toString().split('.').last;
  }

  void _handleDateSelected(DateTime date) {
    if (_isSelectingStart) {
      setState(() {
        _startDate = date;
        _selectedDate = date;
      });
    } else {
      setState(() {
        _endDate = date;
        _selectedDate = null;
        widget.onDateRangeChanged(DateTimeRange(
          start: _startDate,
          end: _endDate,
        ));
      });
    }
  }

  void _handleModeChange(bool selectingStart) {
    setState(() {
      _selectedDate = selectingStart ? null : _startDate;
    });
  }

  void _handlePresetSelected(DateRangePreset preset) {
    final range = preset.getRange();
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
      _selectedDate = null;
      widget.onDateRangeChanged(range);
    });
  }

  Future<void> _showSingleDatePicker({
    required String title,
    required DateTime initialDate,
    required ValueChanged<DateTime> onDateSelected,
  }) async {
    final date = await showDialog<DateTime>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 480,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.m),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Expanded(
                  child: CalendarDatePicker(
                    initialDate: initialDate,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    onDateChanged: (date) => Navigator.of(context).pop(date),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (date != null) {
      onDateSelected(date);
    }
  }
}
