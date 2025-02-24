import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/date_range_filter.dart';
import '../theme/app_sizes.dart';
import '../widgets/date_range_picker.dart';

class DateRangePickerDialog extends StatefulWidget {
  final DateRangeFilter? initialValue;
  
  const DateRangePickerDialog({
    super.key,
    this.initialValue,
  });

  @override
  State<DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<DateRangePickerDialog> {
  
  DateTime? _startDate;
  DateTime? _endDate;
  late int _currentTabIndex;

  @override
  void initState() {
    super.initState();
    // 初始化日期和标签页
    _startDate = widget.initialValue?.start;
    _endDate = widget.initialValue?.end;
    _currentTabIndex = widget.initialValue?.preset != null ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: DefaultTabController(
        length: 2,
        initialIndex: _currentTabIndex,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPresetPage(),
                    _buildCustomPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          title: const Text('选择日期范围'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const TabBar(
          tabs: [
            Tab(text: '快捷选择'),
            Tab(text: '自定义范围'),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetPage() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.m),
      itemCount: DateRangePreset.values.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final preset = DateRangePreset.values[index];
        final isSelected = widget.initialValue?.preset == preset;
        final dateRange = preset.getRange();
        
        return ListTile(
          title: Text(preset.label),
          subtitle: Text(
            '${DateFormat('MM/dd').format(dateRange.start)} - '
            '${DateFormat('MM/dd').format(dateRange.end)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          selected: isSelected,
          trailing: isSelected ? const Icon(Icons.check) : null,
          onTap: () => Navigator.of(context).pop(
            DateRangeFilter.preset(preset),
          ),
        );
      },
    );
  }

  Widget _buildCustomPage() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('自定义日期范围', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSizes.m),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.m),
              child: Column(
                children: [
                  _buildDateField(
                    label: '开始日期',
                    hint: '不限开始日期（从最早）',
                    date: _startDate,
                    onChanged: (date) {
                      setState(() {
                        _startDate = date;
                        // 如果结束日期在开始日期之前，清空结束日期
                        if (_endDate != null && date != null && _endDate!.isBefore(date)) {
                          _endDate = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSizes.m),
                  _buildDateField(
                    label: '结束日期',
                    hint: '不限结束日期（到现在）',
                    date: _endDate,
                    onChanged: (date) {
                      setState(() {
                        _endDate = date;
                        // 如果开始日期在结束日期之后，清空开始日期
                        if (_startDate != null && date != null && _startDate!.isAfter(date)) {
                          _startDate = null;
                        }
                      });
                    },
                    maxDate: DateTime.now(),
                    minDate: _startDate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.l),
          _buildRangePreview(),
          const Divider(height: 32),
          OverflowBar(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: _isValid ? _handleConfirm : null,
                child: const Text('确定'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required DateTime? date,
    required ValueChanged<DateTime?> onChanged,
    DateTime? maxDate,
    DateTime? minDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSizes.xs),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: date ?? 
                  (minDate?.add(const Duration(days: 1))) ?? 
                  (maxDate?.subtract(const Duration(days: 1))) ?? 
                  DateTime.now(),
                firstDate: minDate ?? DateTime(1900),
                lastDate: maxDate ?? DateTime.now(),
                locale: const Locale('zh'),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      dialogTheme: DialogTheme(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (selected != null) {
                onChanged(selected);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.m,
                  vertical: AppSizes.s,
                ),
                suffixIcon: date != null 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onChanged(null),
                    )
                  : const Icon(Icons.calendar_today),
              ),
              child: Text(
                date != null 
                  ? DateFormat('yyyy年MM月dd日').format(date)
                  : hint,
                style: date != null 
                  ? null 
                  : Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangePreview() {
    if (!_isValid) return const SizedBox.shrink();
    
    String rangeText;
    if (_startDate != null && _endDate != null) {
      final days = _endDate!.difference(_startDate!).inDays + 1;
      rangeText = '已选择 $days 天';
    } else if (_startDate != null) {
      rangeText = '从选定日期至今';
    } else {
      rangeText = '截至选定日期';
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.m),
        child: Row(
          children: [
            Icon(
              Icons.date_range,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: AppSizes.s),
            Text(
              rangeText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            if (_startDate != null && _endDate != null) ...[
              const Spacer(),
              Text(
                '${DateFormat('MM/dd').format(_startDate!)} - '
                '${DateFormat('MM/dd').format(_endDate!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _isValid => _startDate != null || _endDate != null;

  void _handleConfirm() {
    Navigator.of(context).pop(DateRangeFilter(
      preset: null,
      start: _startDate,  // Changed from start to startDate
      end: _endDate,      // Changed from end to endDate
    ));
  }

  Future<void> _showDatePicker({
    required bool isStartDate,
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
    final theme = Theme.of(context);
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: minDate ?? DateTime(1900),
      lastDate: maxDate ?? DateTime.now(),
      locale: const Locale('zh'),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: theme.colorScheme.primary,
              headerForegroundColor: theme.colorScheme.onPrimary,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return theme.colorScheme.onPrimary;
                }
                return null;
              }),
              todayForegroundColor: WidgetStateProperty.all(
                theme.colorScheme.primary,
              ),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return theme.colorScheme.onPrimary;
                }
                return null;
              }),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          if (_endDate != null && date.isAfter(_endDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = date;
          if (_startDate != null && date.isBefore(_startDate!)) {
            _startDate = null;
          }
        }
      });
    }
  }
}

Future<DateTimeRange?> showCustomDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
}) async {
  DateTimeRange? selectedRange = initialDateRange;

  return showDialog<DateTimeRange>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '选择日期范围',
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
                child: DateRangePicker(
                  initialDateRange: initialDateRange,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  onDateRangeChanged: (range) {
                    selectedRange = range;
                  },
                ),
              ),
              OverflowBar(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(selectedRange),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}