import 'package:flutter/material.dart';

import '../../../../../theme/app_sizes.dart';
import '../../../../models/work_filter.dart';
import 'date_section.dart';
import 'sort_section.dart';
import 'style_section.dart';
import 'tool_section.dart';

class WorkFilterPanel extends StatelessWidget {
  final WorkFilter filter;
  final ValueChanged<WorkFilter> onFilterChanged;

  const WorkFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(AppSizes.m),
        // 移除所有边框线
        // decoration: BoxDecoration(
        //   border: Border(
        //     right: BorderSide(
        //       color: Theme.of(context).dividerColor,
        //     ),
        //   ),
        // ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SortSection(
                    filter: filter,
                    onFilterChanged: onFilterChanged,
                  ),
                  const Divider(height: AppSizes.l),
                  StyleSection(
                    filter: filter,
                    onFilterChanged: onFilterChanged,
                  ),
                  const Divider(height: AppSizes.l),
                  ToolSection(
                    filter: filter,
                    onFilterChanged: onFilterChanged,
                  ),
                  const Divider(height: AppSizes.l),
                  DateSection(
                    filter: filter,
                    onFilterChanged: onFilterChanged,
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
