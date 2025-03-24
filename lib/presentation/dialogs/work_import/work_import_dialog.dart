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
                  AppBar(
                    title: const Text('导入作品'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: state.isProcessing
                            ? null // Disable close button when processing
                            : () {
                                viewModel.reset();
                                Navigator.of(context).pop();
                              },
                        // Visual feedback for disabled state
                        style: IconButton.styleFrom(
                          foregroundColor: state.isProcessing
                              ? Theme.of(context).disabledColor
                              : null,
                        ),
                      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview section
          Expanded(
            flex: 3,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: availableHeight - 48, // Account for padding
              ),
              child: const WorkImportPreview(),
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
          child: const WorkImportPreview(),
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
