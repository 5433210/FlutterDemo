import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../../pages/works/components/m3_work_import_navigation_bar.dart';
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
        // 打印对话框导航器信息，帮助调试
        print('【WorkImportDialog】构建全屏对话框，context: $context');
        print(
            '【WorkImportDialog】Navigator状态: ${Navigator.of(context).canPop() ? "可关闭" : "不可关闭"}');

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
          appBar: M3WorkImportNavigationBar(
            onClose: () {
              print('【WorkImportDialog】点击关闭按钮');
              viewModel.reset();
              Navigator.of(context).pop(false);
            },
            onStart: (state.canSubmit && !state.isProcessing)
                ? () async {
                    print('【WorkImportDialog】点击导入按钮，开始导入作品');
                    final success = await viewModel.importWork();
                    print('【WorkImportDialog】导入结果: ${success ? "成功" : "失败"}');
                    if (success && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  }
                : () {
                    print('【WorkImportDialog】导入按钮禁用状态被点击');
                  },
            isProcessing: state.isProcessing,
            totalPages: state.images.length,
            currentPage: state.selectedImageIndex + 1,
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
                          l10n.workImportDialogProcessing,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          backgroundColor: theme.colorScheme.surface,
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
    final notifier =
        ProviderScope.containerOf(context).read(workImportProvider.notifier);
    notifier.reset();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 禁止点击背景关闭对话框
      useRootNavigator: false, // 使用局部导航器，确保与M3LibraryPickerDialog保持一致
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
