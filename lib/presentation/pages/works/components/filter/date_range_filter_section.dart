import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../../../../../domain/models/common/date_range_filter.dart';
import '../../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);

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
                    label: Text(_formatFilterText(l10n)),
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
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: [
            Tab(text: l10n.filterDatePresets),
            Tab(text: l10n.filterDateCustom),
          ],
        ),
        const SizedBox(height: AppSizes.m),
        SizedBox(
          height: 240,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPresets(theme, l10n),
              _buildCustomRange(context, l10n),
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

  Widget _buildCustomRange(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDateField(
          context: context,
          label: l10n.filterDateStartDate,
          value: _startDate,
          onPressed: () => _selectDate(context, true),
          l10n: l10n,
        ),
        const SizedBox(height: AppSizes.m),
        _buildDateField(
          context: context,
          label: l10n.filterDateEndDate,
          value: _endDate,
          onPressed: () => _selectDate(context, false),
          l10n: l10n,
        ),
        if (_hasSelection) ...[
          const SizedBox(height: AppSizes.l),
          Row(
            children: [
              if (_hasValidRange)
                Expanded(
                  child: FilledButton(
                    onPressed: _applyDateRange,
                    child: Text(l10n.filterDateApply),
                  ),
                ),
              if (_hasValidRange) const SizedBox(width: AppSizes.s),
              Expanded(
                child: TextButton(
                  onPressed: _clearDateRange,
                  child: Text(l10n.filterDateClear),
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
    required AppLocalizations l10n,
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
            label: Text(value != null
                ? _formatDate(value)
                : l10n.filterDateSelectPrompt),
            onPressed: onPressed,
          ),
        ),
      ],
    );
  }

  Widget _buildPresets(ThemeData theme, AppLocalizations l10n) {
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
                label: Text(_getPresetLabel(preset, l10n)),
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

  String _formatFilterText(AppLocalizations l10n) {
    final filter = widget.filter;
    if (filter == null) return '';

    if (filter.preset != null && filter.preset != DateRangePreset.all) {
      return _getPresetLabel(filter.preset!, l10n);
    }

    if (filter.start != null || filter.end != null) {
      final start = filter.start != null
          ? _formatDate(filter.start!)
          : l10n.filterDateStartDate;
      final end = filter.end != null
          ? _formatDate(filter.end!)
          : l10n.filterDateEndDate;
      return '$start - $end';
    }

    return '';
  }

  String _getPresetDateRange(DateRangePreset preset) {
    final range = preset.getRange();
    return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
  }

  String _getPresetLabel(DateRangePreset preset, AppLocalizations l10n) {
    return switch (preset) {
      DateRangePreset.today => l10n.filterDatePresetToday,
      DateRangePreset.yesterday => l10n.filterDatePresetYesterday,
      DateRangePreset.thisWeek => l10n.filterDatePresetThisWeek,
      DateRangePreset.lastWeek => l10n.filterDatePresetLastWeek,
      DateRangePreset.thisMonth => l10n.filterDatePresetThisMonth,
      DateRangePreset.lastMonth => l10n.filterDatePresetLastMonth,
      DateRangePreset.thisYear => l10n.filterDatePresetThisYear,
      DateRangePreset.lastYear => l10n.filterDatePresetLastYear,
      DateRangePreset.last7Days => l10n.filterDatePresetLast7Days,
      DateRangePreset.last30Days => l10n.filterDatePresetLast30Days,
      DateRangePreset.last90Days => l10n.filterDatePresetLast90Days,
      DateRangePreset.last365Days => l10n.filterDatePresetLast365Days,
      DateRangePreset.all => l10n.filterDatePresetAll,
    };
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
