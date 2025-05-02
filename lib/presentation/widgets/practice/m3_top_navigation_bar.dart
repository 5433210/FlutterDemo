import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../dialogs/practice_title_edit_dialog.dart';
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Build title text: if there's a title, show "Practice Edit - xxx", otherwise just "Practice Edit"
    final titleText = controller.practiceTitle != null
        ? '${l10n.practiceEditTitle} - ${controller.practiceTitle}'
        : l10n.practiceEditTitle;

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titleText),
          if (controller.practiceTitle != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.practiceEditEditTitle,
              onPressed: () => _editTitle(context, l10n),
            ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.practiceEditTopNavBack,
        onPressed: () => _handleBackButton(context, l10n),
      ),
      actions: [
        // 重做、撤销、预览按钮放在右侧所有图标按钮的最左边
        // Operations group (undo/redo)
        _buildOperationsGroup(l10n, colorScheme),

        // Preview group
        _buildPreviewGroup(l10n, colorScheme),

        const SizedBox(width: 16),

        // File operations group
        _buildFileOperationsGroup(context, l10n, colorScheme),

        const SizedBox(width: 16),

        // View operations group
        _buildViewOperationsGroup(l10n, colorScheme),
      ],
    );
  }

  /// Build file operations group
  Widget _buildFileOperationsGroup(
      BuildContext context, AppLocalizations l10n, ColorScheme colorScheme) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: l10n.practiceEditTopNavSave,
          onPressed: () => _savePractice(context, l10n),
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.primary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.save_as),
          tooltip: l10n.practiceEditTopNavSaveAs,
          onPressed: () => _saveAs(context, l10n),
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.primary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.file_download),
          tooltip: l10n.practiceEditTopNavExport,
          onPressed: () => _exportPractice(context, l10n),
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Build operations group
  Widget _buildOperationsGroup(AppLocalizations l10n, ColorScheme colorScheme) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: l10n.practiceEditTopNavUndo,
          onPressed: controller.state.canUndo ? controller.undo : null,
          style: IconButton.styleFrom(
            foregroundColor: controller.state.canUndo
                ? colorScheme.primary
                : colorScheme.onSurface
                    .withValues(alpha: 97), // 0.38 * 255 ≈ 97
          ),
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: l10n.practiceEditTopNavRedo,
          onPressed: controller.state.canRedo ? controller.redo : null,
          style: IconButton.styleFrom(
            foregroundColor: controller.state.canRedo
                ? colorScheme.primary
                : colorScheme.onSurface
                    .withValues(alpha: 97), // 0.38 * 255 ≈ 97
          ),
        ),
      ],
    );
  }

  /// Build preview group
  Widget _buildPreviewGroup(AppLocalizations l10n, ColorScheme colorScheme) {
    return IconButton(
      icon: Icon(isPreviewMode ? Icons.visibility_off : Icons.visibility),
      tooltip: isPreviewMode
          ? l10n.practiceEditTopNavExitPreview
          : l10n.practiceEditTopNavPreviewMode,
      onPressed: onTogglePreviewMode,
      style: IconButton.styleFrom(
        foregroundColor:
            isPreviewMode ? colorScheme.tertiary : colorScheme.primary,
      ),
    );
  }

  /// Build view operations group
  Widget _buildViewOperationsGroup(
      AppLocalizations l10n, ColorScheme colorScheme) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            showThumbnails ? Icons.view_carousel : Icons.view_carousel_outlined,
          ),
          tooltip: showThumbnails
              ? l10n.practiceEditTopNavHideThumbnails
              : l10n.practiceEditTopNavShowThumbnails,
          onPressed: () => onThumbnailToggle(!showThumbnails),
          style: IconButton.styleFrom(
            foregroundColor:
                showThumbnails ? colorScheme.tertiary : colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Edit title
  Future<void> _editTitle(BuildContext context, AppLocalizations l10n) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => PracticeTitleEditDialog(
        initialTitle: controller.practiceTitle,
        checkTitleExists: controller.checkTitleExists,
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      controller.updatePracticeTitle(newTitle);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.practiceEditTitleUpdated(newTitle))),
        );
      }
    }
  }

  /// Export practice
  Future<void> _exportPractice(
      BuildContext context, AppLocalizations l10n) async {
    // Get default filename
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
    // Check for unsaved changes
    if (controller.state.hasUnsavedChanges) {
      // Show confirmation dialog
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
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(l10n.practiceEditLeave),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
              FilledButton(
                child: Text(l10n.practiceEditSaveAndLeave),
                onPressed: () async {
                  // Save changes
                  await _savePractice(context, l10n);
                  if (context.mounted) {
                    // Return true to confirm leaving
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ],
          );
        },
      );

      // If user confirms leaving, navigate back
      if (result == true && context.mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // No unsaved changes, can leave
      Navigator.of(context).pop();
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
    await FileOperations.savePractice(
      context,
      controller.state.pages,
      controller.state.layers.cast<Map<String, dynamic>>(),
      practiceId,
      controller,
    );
  }
}
