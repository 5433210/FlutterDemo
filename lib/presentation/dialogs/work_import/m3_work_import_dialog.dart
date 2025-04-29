import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/work_import_provider.dart';
import 'components/form/m3_work_import_form.dart';
import 'components/preview/m3_work_import_preview.dart';

/// Material 3 version of the dialog for importing works with preview and metadata input
class M3WorkImportDialog extends ConsumerWidget {
  const M3WorkImportDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workImportProvider);
    final viewModel = ref.read(workImportProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog.fullscreen(
      child: LayoutBuilder(builder: (context, constraints) {
        // Calculate responsive sizes based on available space
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final isLargeScreen = availableWidth >= 1100;
        final isMediumScreen = availableWidth >= 800 && availableWidth < 1100;
        final isSmallScreen = availableWidth < 800;

        return Material(
          color: theme.colorScheme.surface,
          child: PopScope(
            // Prevent dialog dismissal during processing
            canPop: !state.isProcessing,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AppBar with action buttons moved here
                  AppBar(
                    title: Text(l10n.workImportDialogTitle),
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
                        label: Text(l10n.workImportDialogCancel),
                        style: TextButton.styleFrom(
                          foregroundColor: state.isProcessing
                              ? theme.colorScheme.onSurface.withOpacity(0.38)
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
                        label: Text(l10n.workImportDialogImport),
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
                  // Show processing indicator when importing
                  if (state.isProcessing)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            l10n.workImportDialogProcessing,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
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
              child: const M3WorkImportPreviewWithoutButtons(),
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
                child: M3WorkImportForm(
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
          child: const M3WorkImportPreviewWithoutButtons(),
        ),

        const SizedBox(height: 16),

        // Form section that can scroll to fit in remaining space
        Expanded(
          child: SingleChildScrollView(
            child: M3WorkImportForm(
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
    // Reset state before opening dialog
    ProviderScope.containerOf(context)
        .read(workImportProvider.notifier)
        .reset();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const M3WorkImportDialog(),
    );
  }
}

/// A version of M3WorkImportPreview without bottom buttons
class M3WorkImportPreviewWithoutButtons extends ConsumerWidget {
  const M3WorkImportPreviewWithoutButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const M3WorkImportPreview(showBottomButtons: false);
  }
}
