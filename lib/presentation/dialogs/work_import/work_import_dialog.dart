import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/work_import_provider.dart';
import 'components/form/work_import_form.dart';
import 'components/preview/work_import_preview.dart';

/// Dialog for importing works with preview and metadata input
class WorkImportDialog extends ConsumerWidget {
  const WorkImportDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workImportProvider);
    final viewModel = ref.read(workImportProvider.notifier);

    return Dialog.fullscreen(
      child: LayoutBuilder(builder: (context, constraints) {
        // Calculate responsive sizes based on available space
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final isLargeScreen = availableWidth >= 1100;
        final isMediumScreen = availableWidth >= 800 && availableWidth < 1100;
        final isSmallScreen = availableWidth < 800;

        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: PopScope(
            // Prevent dialog dismissal during processing
            canPop: !state.isProcessing,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AppBar with action buttons moved here
                  AppBar(
                    title: const Text('导入作品'),
                    actions: [
                      // Cancel button
                      TextButton.icon(
                        onPressed: state.isProcessing
                            ? null
                            : () {
                                viewModel.reset();
                                Navigator.of(context).pop(false);
                              },
                        icon: const Icon(Icons.close),
                        label: const Text('取消'),
                        style: TextButton.styleFrom(
                          foregroundColor: state.isProcessing
                              ? Theme.of(context).disabledColor
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Import button
                      FilledButton.icon(
                        onPressed: (state.canSubmit && !state.isProcessing)
                            ? () async {
                                final success = await viewModel.importWork();
                                if (success && context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              }
                            : null,
                        icon: const Icon(Icons.save),
                        label: const Text('导入'),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildResponsiveLayout(
                        context,
                        isLargeScreen,
                        isMediumScreen,
                        isSmallScreen,
                        availableHeight,
                        availableWidth,
                        state,
                        viewModel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    bool isLargeScreen,
    bool isMediumScreen,
    bool isSmallScreen,
    double availableHeight,
    double availableWidth,
    dynamic state,
    dynamic viewModel,
  ) {
    // For large and medium screens, use horizontal layout
    if (isLargeScreen || isMediumScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align at the top
        children: [
          // Preview section
          Expanded(
            flex: 3,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: availableHeight - 48, // Account for padding
              ),
              child: const WorkImportPreviewWithoutButtons(),
            ),
          ),

          const SizedBox(width: 24),

          // Form section
          Expanded(
            flex: isLargeScreen ? 2 : 3,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight - 48, // Account for padding
                ),
                child: WorkImportForm(
                  state: state,
                  viewModel: viewModel,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // For small screens, use vertical layout
    return Column(
      children: [
        // Preview section with proportional height based on screen size
        SizedBox(
          height: availableHeight * 0.5, // 50% of available height
          child: const WorkImportPreviewWithoutButtons(),
        ),

        const SizedBox(height: 16),

        // Form section that can scroll to fit in remaining space
        Expanded(
          child: SingleChildScrollView(
            child: WorkImportForm(
              state: state,
              viewModel: viewModel,
            ),
          ),
        ),
      ],
    );
  }

  /// Show the work import dialog
  static Future<bool?> show(BuildContext context) {
    // 确保在打开对话框前重置状态
    ProviderScope.containerOf(context)
        .read(workImportProvider.notifier)
        .reset();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WorkImportDialog(),
    );
  }
}

/// A version of WorkImportPreview without bottom buttons
class WorkImportPreviewWithoutButtons extends ConsumerWidget {
  const WorkImportPreviewWithoutButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WorkImportPreview(showBottomButtons: false);
  }
}
