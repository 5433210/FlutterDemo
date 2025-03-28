import 'package:flutter/material.dart';

import 'preview_types.dart';

class PreviewModeConfig {
  /// Edit mode configuration
  static PreviewModeConfig get edit => PreviewModeConfig(
        toolbarActions: [
          ToolbarAction(
            icon: Icons.add_photo_alternate,
            tooltip: '添加图片',
            onPressed: () {}, // Will be set by consumer
          ),
          ToolbarAction(
            icon: Icons.save,
            tooltip: '保存更改',
            onPressed: () {}, // Will be set by consumer
            placement: ToolbarActionPlacement.right,
          ),
          ToolbarAction(
            icon: Icons.delete,
            tooltip: '删除图片',
            onPressed: () {}, // Will be set by consumer
          ),
        ],
        allowReordering: true,
        enableDeletion: true,
      );

  /// Extract mode configuration
  static PreviewModeConfig get extract => PreviewModeConfig(
        toolbarActions: [
          ToolbarAction(
            icon: Icons.crop_free,
            tooltip: '框选工具',
            onPressed: () {}, // Will be set by consumer
          ),
          ToolbarAction(
            icon: Icons.select_all,
            tooltip: '多选工具',
            onPressed: () {}, // Will be set by consumer
          ),
          ToolbarAction(
            icon: Icons.delete,
            tooltip: '删除选中区域',
            onPressed: () {}, // Will be set by consumer
          ),
        ],
        showControls: false,
        allowReordering: false,
      );

  /// Import mode configuration
  static PreviewModeConfig get import => PreviewModeConfig(
        toolbarActions: [
          ToolbarAction(
            icon: Icons.add_photo_alternate,
            tooltip: '添加图片',
            onPressed: () {}, // Will be set by consumer
          ),
          ToolbarAction(
            icon: Icons.delete,
            tooltip: '删除图片',
            onPressed: () {}, // Will be set by consumer
          ),
        ],
        allowReordering: true,
        enableDeletion: true,
        emptyStateMessage: '点击添加或拖放图片',
      );

  /// View mode configuration
  static PreviewModeConfig get view => const PreviewModeConfig(
        toolbarActions: [],
        showControls: true,
        showToolbar: false,
      );
  final List<ToolbarAction> toolbarActions;
  final bool allowReordering;
  final bool showControls;

  final bool showToolbar;

  final bool showThumbnails;

  final bool enableDeletion;

  final String emptyStateMessage;

  const PreviewModeConfig({
    required this.toolbarActions,
    this.allowReordering = false,
    this.showControls = true,
    this.showToolbar = true,
    this.showThumbnails = true,
    this.enableDeletion = false,
    this.emptyStateMessage = '无图片',
  });

  /// Create a copy with updated action handlers
  PreviewModeConfig copyWithActions({
    VoidCallback? onAdd,
    VoidCallback? onDelete,
    VoidCallback? onSave,
    VoidCallback? onBoxSelect,
    VoidCallback? onMultiSelect,
  }) {
    return PreviewModeConfig(
      toolbarActions: toolbarActions.map((action) {
        if (action.icon == Icons.add_photo_alternate && onAdd != null) {
          return action.copyWith(onPressed: onAdd);
        }
        if (action.icon == Icons.delete && onDelete != null) {
          return action.copyWith(onPressed: onDelete);
        }
        if (action.icon == Icons.save && onSave != null) {
          return action.copyWith(onPressed: onSave);
        }
        if (action.icon == Icons.crop_free && onBoxSelect != null) {
          return action.copyWith(onPressed: onBoxSelect);
        }
        if (action.icon == Icons.select_all && onMultiSelect != null) {
          return action.copyWith(onPressed: onMultiSelect);
        }
        return action;
      }).toList(),
      allowReordering: allowReordering,
      showControls: showControls,
      showToolbar: showToolbar,
      showThumbnails: showThumbnails,
      enableDeletion: enableDeletion,
      emptyStateMessage: emptyStateMessage,
    );
  }

  /// Get configuration for specific mode
  static PreviewModeConfig forMode(PreviewMode mode) {
    switch (mode) {
      case PreviewMode.import:
        return import;
      case PreviewMode.edit:
        return edit;
      case PreviewMode.view:
        return view;
      case PreviewMode.extract:
        return extract;
    }
  }
}
