import 'package:flutter/material.dart';

import '../../../../../domain/models/work/work_filter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../theme/app_sizes.dart';
import 'date_section.dart';
import 'sort_section.dart';
import 'style_section.dart';
import 'tool_section.dart';

class M3WorkFilterPanel extends StatelessWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;

  const M3WorkFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    
    return Material(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      child: Container(
        width: AppSizes.workFilterPanelWidth,
        padding: const EdgeInsets.all(AppSizes.m),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSizes.xs, 
                      bottom: AppSizes.s
                    ),
                    child: Text(
                      l10n.filterTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    color: colorScheme.surface,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.s),
                      child: SortSection(
                        filter: filter,
                        onFilterChanged: onFilterChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.m),
                  Card(
                    elevation: 0,
                    color: colorScheme.surface,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.s),
                      child: StyleSection(
                        filter: filter,
                        onFilterChanged: onFilterChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.m),
                  Card(
                    elevation: 0,
                    color: colorScheme.surface,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.s),
                      child: ToolSection(
                        filter: filter,
                        onFilterChanged: onFilterChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.m),
                  Card(
                    elevation: 0,
                    color: colorScheme.surface,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.s),
                      child: DateSection(
                        filter: filter,
                        onFilterChanged: onFilterChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.m),
                  // 重置按钮
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.filterReset),
                      onPressed: () => onFilterChanged(const WorkFilter()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
