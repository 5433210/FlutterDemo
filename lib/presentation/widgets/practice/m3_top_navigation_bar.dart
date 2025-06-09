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

  const M3TopNavigationBar({
    super.key,
    required this.controller,
    this.practiceId,
    required this.isPreviewMode,
    required this.onTogglePreviewMode,
    required this.showThumbnails,
    required this.onThumbnailToggle,
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
            tooltip: '${l10n.practiceEditEditTitle} (Ctrl+M, T)',
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
              tooltip: '${l10n.practiceEditTopNavUndo} (Ctrl+Z)',
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
              tooltip: '${l10n.practiceEditTopNavRedo} (Ctrl+Y)',
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
                  ? '${l10n.practiceEditTopNavExitPreview} (Ctrl+P)'
                  : '${l10n.practiceEditTopNavPreviewMode} (Ctrl+P)',
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
              label: Text('${l10n.practiceEditTopNavSave} (Ctrl+S)'),
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
              tooltip: '${l10n.practiceEditTopNavSaveAs} (Ctrl+Shift+S)',
              onPressed: () => _saveAs(context, l10n),
            ),
            const SizedBox(width: AppSizes.s),

            // Export button
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: '${l10n.practiceEditTopNavExport} (Ctrl+E)',
              onPressed: () => _exportPractice(context, l10n),
            ),
          ],
        ),

        const VerticalDivider(indent: 8, endIndent: 8),

        // 视图选项按钮组
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnails toggle button
            IconButton(
              icon: Icon(
                showThumbnails
                    ? Icons.view_carousel
                    : Icons.view_carousel_outlined,
              ),
              tooltip: showThumbnails
                  ? '${l10n.practiceEditTopNavHideThumbnails} (Ctrl+O)'
                  : '${l10n.practiceEditTopNavShowThumbnails} (Ctrl+O)',
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
    
    EditPageLogger.editPageDebug(
      '开始编辑标题',
      data: {
        'currentTitle': currentTitle,
        'operation': 'title_edit_start',
      },
    );
    
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => PracticeTitleEditDialog(
        initialTitle: currentTitle,
        checkTitleExists: controller.checkTitleExists,
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      EditPageLogger.editPageDebug(
        '标题编辑确认',
        data: {
          'oldTitle': currentTitle,
          'newTitle': newTitle,
          'operation': 'title_edit_confirmed',
        },
      );
      
      try {
        controller.updatePracticeTitle(newTitle);
        
        EditPageLogger.editPageDebug(
          '标题更新成功',
          data: {
            'newTitle': newTitle,
            'operation': 'title_update_success',
          },
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.practiceEditTitleUpdated(newTitle))),
          );
        }
      } catch (error, stackTrace) {
        EditPageLogger.editPageError(
          '标题更新失败',
          error: error,
          stackTrace: stackTrace,
          data: {
            'newTitle': newTitle,
            'operation': 'title_update_error',
          },
        );
      }
    } else {
      EditPageLogger.editPageDebug(
        '标题编辑取消',
        data: {
          'currentTitle': currentTitle,
          'operation': 'title_edit_cancelled',
        },
      );
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
    EditPageLogger.editPageDebug(
      '导航返回按钮点击',
      data: {
        'hasUnsavedChanges': controller.state.hasUnsavedChanges,
        'pageCount': controller.state.pages.length,
        'operation': 'navigation_back_pressed',
      },
    );
    
    if (controller.state.hasUnsavedChanges) {
      EditPageLogger.editPageDebug(
        '显示未保存更改确认对话框',
        data: {
          'operation': 'unsaved_changes_dialog_show',
        },
      );
      
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.practiceEditUnsavedChanges),
            content: Text(l10n.practiceEditUnsavedChangesMessage),
            actions: <Widget>[
              TextButton(
                child: Text(l10n.cancel),
                onPressed: () {
                  EditPageLogger.editPageDebug(
                    '取消离开编辑页',
                    data: {
                      'operation': 'navigation_back_cancelled',
                    },
                  );
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(l10n.practiceEditLeave),
                onPressed: () {
                  EditPageLogger.editPageDebug(
                    '确认离开编辑页（丢弃更改）',
                    data: {
                      'operation': 'navigation_back_confirmed_discard',
                    },
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
          EditPageLogger.editPageDebug(
            '离开编辑页面',
            data: {
              'reason': 'user_confirmed_discard_changes',
              'operation': 'navigation_exit',
            },
          );
          Navigator.of(context).pop();
        }
      }
    } else if (context.mounted) {
      // Check if we can safely pop
      if (Navigator.canPop(context)) {
        EditPageLogger.editPageDebug(
          '离开编辑页面',
          data: {
            'reason': 'no_unsaved_changes',
            'operation': 'navigation_exit',
          },
        );
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
    EditPageLogger.editPageDebug(
      '保存字帖练习',
      data: {
        'practiceId': practiceId,
        'hasTitle': controller.practiceTitle != null,
        'pageCount': controller.state.pages.length,
        'hasUnsavedChanges': controller.state.hasUnsavedChanges,
      },
    );
    
    await FileOperations.savePractice(
      context,
      controller.state.pages,
      controller.state.layers.cast<Map<String, dynamic>>(),
      practiceId,
      controller,
    );
  }
}
