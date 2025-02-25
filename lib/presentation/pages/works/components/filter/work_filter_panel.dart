import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/work_browse_provider.dart';
import '../../../../theme/app_sizes.dart';
import '../../../work_browser/components/sidebar_toggle.dart';
import 'sort_section.dart';
import 'style_section.dart';
import 'tool_section.dart';
import 'date_section.dart';

class WorkFilterPanel extends ConsumerWidget {
  const WorkFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(workBrowseProvider);
    final viewModel = ref.read(workBrowseProvider.notifier);

    return Material(
      color: theme.colorScheme.surface,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isSidebarOpen)
            Container(
              width: 280,
              padding: const EdgeInsets.all(AppSizes.m),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.dividerColor,
                  ),
                ),
              ),
              child: CustomScrollView(  // 使用 CustomScrollView 替代 SingleChildScrollView
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SortSection(),
                        Divider(height: AppSizes.l),
                        StyleSection(),
                        Divider(height: AppSizes.l),
                        ToolSection(),
                        Divider(height: AppSizes.l),
                        DateSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SidebarToggle(
            isOpen: state.isSidebarOpen,
            onToggle: viewModel.toggleSidebar,
          ),
        ],
      ),
    );
  }
}
