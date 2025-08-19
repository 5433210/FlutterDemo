import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../../dialogs/practice_title_edit_dialog.dart';
import '../common/m3_page_navigation_bar.dart';
import 'file_operations.dart';
import 'practice_edit_controller.dart';

/// Material 3 top navigation bar for practice edit page
class M3TopNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  final PracticeEditController controller;
  final String? practiceId;
  final bool isPreviewMode;
  final VoidCallback onTogglePreviewMode;
  final bool showThumbnails;
  final Function(bool) onThumbnailToggle;
  final bool showToolbar;
  final VoidCallback onToggleToolbar;

  const M3TopNavigationBar({
    super.key,
    required this.controller,
    this.practiceId,
    required this.isPreviewMode,
    required this.onTogglePreviewMode,
    required this.showThumbnails,
    required this.onThumbnailToggle,
    this.showToolbar = true,
    required this.onToggleToolbar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Build title text: if there's a title, show "Practice Edit - xxx", otherwise just "Practice Edit"
    final titleText = controller.practiceTitle != null
        ? '${l10n.practiceEditTitle} - ${controller.practiceTitle}'
        : l10n.practiceEditTitle;

    return M3PageNavigationBar(
      title: titleText,
      titleActions: [
        if (controller.practiceTitle != null)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '${l10n.editTitle} (Ctrl+M, T)',
            onPressed: () => _editTitle(context, l10n),
          ),
      ],
      onBackPressed: () => _handleBackButton(context, l10n),
      actions: [
        // 左侧操作按钮组 - 撤销/重做
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Undo button
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: '${l10n.undo} (Ctrl+Z)',
              onPressed: controller.state.canUndo ? controller.undo : null,
              style: IconButton.styleFrom(
                foregroundColor: controller.state.canUndo
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
            const SizedBox(width: AppSizes.s),

            // Redo button
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: '${l10n.redo} (Ctrl+Y)',
              onPressed: controller.state.canRedo ? controller.redo : null,
              style: IconButton.styleFrom(
                foregroundColor: controller.state.canRedo
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
          ],
        ),

        const VerticalDivider(indent: 8, endIndent: 8),

        // 中间操作按钮组 - 预览和保存
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview mode toggle
            IconButton(
              icon:
                  Icon(isPreviewMode ? Icons.visibility_off : Icons.visibility),
              tooltip: isPreviewMode
                  ? '${l10n.exitPreview} (Ctrl+P)'
                  : '${l10n.previewMode} (Ctrl+P)',
              onPressed: onTogglePreviewMode,
              style: IconButton.styleFrom(
                foregroundColor:
                    isPreviewMode ? colorScheme.tertiary : colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSizes.m),

            // Save button - using FilledButton.icon for consistency with other pages
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: Text('${l10n.save} (Ctrl+S)'),
              onPressed: () => _savePractice(context, l10n),
            ),
          ],
        ),

        const VerticalDivider(indent: 8, endIndent: 8),

        // 右侧操作按钮组 - 文件操作
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Save As button
            IconButton(
              icon: const Icon(Icons.save_as),
              tooltip: '${l10n.saveAs} (Ctrl+Shift+S)',
              onPressed: () => _saveAs(context, l10n),
            ),
            const SizedBox(width: AppSizes.s),

            // Export button
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: '${l10n.export} (Ctrl+E)',
              onPressed: () => _exportPractice(context, l10n),
            ),
          ],
        ),

        const VerticalDivider(indent: 8, endIndent: 8),

        // 视图选项按钮组
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toolbar toggle button
            IconButton(
              icon: Icon(
                showToolbar
                    ? Icons.build
                    : Icons.build_outlined,
              ),
              tooltip: showToolbar
                  ? '${l10n.hideToolbar} (Ctrl+Shift+H)'
                  : '${l10n.showToolbar} (Ctrl+Shift+H)',
              onPressed: onToggleToolbar,
              style: IconButton.styleFrom(
                foregroundColor:
                    showToolbar ? colorScheme.tertiary : colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSizes.s),
            
            // Thumbnails toggle button
            IconButton(
              icon: Icon(
                showThumbnails
                    ? Icons.view_carousel
                    : Icons.view_carousel_outlined,
              ),
              tooltip: showThumbnails
                  ? '${l10n.hideThumbnails} (Ctrl+O)'
                  : '${l10n.showThumbnails} (Ctrl+O)',
              onPressed: () => onThumbnailToggle(!showThumbnails),
              style: IconButton.styleFrom(
                foregroundColor:
                    showThumbnails ? colorScheme.tertiary : colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Edit title
  Future<void> _editTitle(BuildContext context, AppLocalizations l10n) async {
    final currentTitle = controller.practiceTitle;
    
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => PracticeTitleEditDialog(
        initialTitle: currentTitle,
        checkTitleExists: controller.checkTitleExists,
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      try {
        controller.updatePracticeTitle(newTitle);
        
        EditPageLogger.editPageInfo(
          '標題更新成功',
          data: {
            'newTitle': newTitle,
          },
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.titleUpdated(newTitle))),
          );
        }
      } catch (error, stackTrace) {
        EditPageLogger.editPageError(
          '標題更新失敗',
          error: error,
          stackTrace: stackTrace,
          data: {
            'newTitle': newTitle,
          },
        );
      }
    }
  }

  /// Export practice
  Future<void> _exportPractice(
      BuildContext context, AppLocalizations l10n) async {
    final defaultFileName = controller.practiceTitle ?? l10n.practiceEditTitle;
    await FileOperations.exportPractice(
      context,
      controller.state.pages,
      controller,
      defaultFileName,
    );
  }

  /// Handle back button
  Future<void> _handleBackButton(
      BuildContext context, AppLocalizations l10n) async {    
    if (controller.state.hasUnsavedChanges) {
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.unsavedChanges),
            content: Text(l10n.unsavedChanges),
            actions: <Widget>[
              TextButton(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(l10n.leave),
                onPressed: () {
                  EditPageLogger.editPageInfo(
                    '用戶確認丟棄更改並離開',
                  );
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (result == true && context.mounted) {
        // Check if we can safely pop
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }
    } else if (context.mounted) {
      // Check if we can safely pop
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Save as new practice
  Future<void> _saveAs(BuildContext context, AppLocalizations l10n) async {
    await FileOperations.saveAs(
      context,
      controller.state.pages,
      controller.state.layers.cast<Map<String, dynamic>>(),
      controller,
    );
  }

  /// Save practice
  Future<void> _savePractice(
      BuildContext context, AppLocalizations l10n) async {
    // 使用優化的保存服務
    await FileOperations.savePracticeOptimized(
      context,
      controller,
      canvasKey: controller.canvasKey,
    );
  }
}
