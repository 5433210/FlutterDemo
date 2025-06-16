import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/work_import_provider.dart';
import '../../widgets/common/base_navigation_bar.dart';
import 'components/form/work_import_form.dart';
import 'components/preview/work_import_preview.dart';

/// Dialog for importing works with preview and metadata input
class WorkImportDialog extends ConsumerWidget {
  const WorkImportDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workImportProvider);
    final viewModel = ref.read(workImportProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Dialog.fullscreen(
      child: LayoutBuilder(builder: (context, constraints) {
        // Calculate responsive sizes based on available space
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final isLargeScreen = availableWidth >= 1100;
        final isMediumScreen = availableWidth >= 800 && availableWidth < 1100;
        final isSmallScreen = availableWidth < 800;

        // Calculate content height by subtracting appbar height
        final contentHeight = availableHeight - AppSizes.appBarHeight;
        final processingIndicatorHeight = state.isProcessing ? 64.0 : 0.0;
        final actualContentHeight = contentHeight -
            processingIndicatorHeight -
            24; // 24 for bottom padding

        return Scaffold(
          appBar: BaseNavigationBar(
            title: Text(l10n.import),
            actions: [
              // Cancel button
              OutlinedButton.icon(
                onPressed: state.isProcessing
                    ? null
                    : () {
                        viewModel.reset();
                        Navigator.of(context).pop(false);
                      },
                icon: const Icon(Icons.close),
                label: Text(l10n.cancel),
              ),
              const SizedBox(width: AppSizes.s),
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
                label: Text(l10n.import),
              ),
              const SizedBox(width: AppSizes.m),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      top: 8,
                    ),
                    child: _buildResponsiveLayout(
                      context,
                      isLargeScreen,
                      isMediumScreen,
                      isSmallScreen,
                      actualContentHeight,
                      availableWidth,
                      state,
                      viewModel,
                    ),
                  ),
                ),
                // Show processing indicator when importing
                if (state.isProcessing)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          l10n.processing,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
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
            child: SizedBox(
              height: availableHeight - 48, // Account for padding
              child: const WorkImportPreviewWithoutButtons(),
            ),
          ),

          const SizedBox(width: 24), // Form section
          Expanded(
            flex: isLargeScreen ? 2 : 3,
            child: SingleChildScrollView(
              child: IntrinsicHeight(
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
