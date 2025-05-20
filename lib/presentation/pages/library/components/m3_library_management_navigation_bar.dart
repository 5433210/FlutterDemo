import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/m3_page_navigation_bar.dart';
import 'grid_size_selector.dart';

/// 图库管理导航栏 - 使用与角色管理页面相同的设计风格
class M3LibraryManagementNavigationBar extends StatefulWidget
    implements PreferredSizeWidget {
  /// 是否处于批量选择模式
  final bool isBatchMode;

  /// 切换批量选择模式回调
  final VoidCallback onToggleBatchMode;

  /// 选中的项目数量
  final int selectedCount;

  /// 删除选中项目回调
  final VoidCallback? onDeleteSelected;

  /// 删除所有项目回调
  final VoidCallback? onDeleteAll;

  /// 批量设置分类回调
  final VoidCallback? onAssignCategoryBatch;

  /// 从当前分类中移除回调
  final VoidCallback? onRemoveFromCategory;

  /// 选择所有项目回调
  final VoidCallback? onSelectAll;

  /// 取消选择回调
  final VoidCallback? onCancelSelection;

  /// 是否为网格视图
  final bool isGridView;

  /// 切换视图模式回调
  final VoidCallback onToggleViewMode;

  /// 是否显示图片预览面板
  final bool isImagePreviewOpen;

  /// 切换图片预览面板回调
  final VoidCallback onToggleImagePreview;

  /// 导入文件回调
  final VoidCallback? onImportFiles;

  /// 导入文件夹回调
  final VoidCallback? onImportFolder;

  /// 返回按钮回调
  final VoidCallback? onBackPressed;

  /// 构造函数
  const M3LibraryManagementNavigationBar({
    super.key,
    required this.isBatchMode,
    required this.onToggleBatchMode,
    required this.selectedCount,
    this.onDeleteSelected,
    this.onDeleteAll,
    this.onAssignCategoryBatch,
    this.onRemoveFromCategory,
    this.onSelectAll,
    this.onCancelSelection,
    required this.isGridView,
    required this.onToggleViewMode,
    required this.isImagePreviewOpen,
    required this.onToggleImagePreview,
    this.onImportFiles,
    this.onImportFolder,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<M3LibraryManagementNavigationBar> createState() =>
      _M3LibraryManagementNavigationBarState();
}

class _M3LibraryManagementNavigationBarState
    extends State<M3LibraryManagementNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return M3PageNavigationBar(
      title: l10n.libraryManagement,
      onBackPressed: widget.onBackPressed,
      titleActions: widget.isBatchMode
          ? [
              const SizedBox(width: 8),
              Text(
                l10n.selectedCount(widget.selectedCount),
                style: theme.textTheme.bodyMedium,
              ),
              if (widget.selectedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.delete),
                    label: Text(l10n.libraryManagementDeleteSelected),
                    onPressed: widget.onDeleteSelected,
                  ),
                ),
            ]
          : null,
      actions: [
        // 导入按钮 (仅在非批量模式下显示)
        if (!widget.isBatchMode)
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_photo_alternate),
            tooltip: l10n.libraryManagementImport,
            onSelected: (value) {
              if (value == 'file' && widget.onImportFiles != null) {
                widget.onImportFiles!();
              } else if (value == 'folder' && widget.onImportFolder != null) {
                widget.onImportFolder!();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'file',
                child: Row(
                  children: [
                    const Icon(Icons.image),
                    const SizedBox(width: 8),
                    Text(l10n.libraryManagementImportFiles),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'folder',
                child: Row(
                  children: [
                    const Icon(Icons.folder),
                    const SizedBox(width: 8),
                    Text(l10n.libraryManagementImportFolder),
                  ],
                ),
              ),
            ],
          ),

        // 右侧按钮组 - 批量模式下显示的按钮
        if (widget.isBatchMode) ...[
          // 批量选择工具栏中的"全选"按钮
          if (widget.onSelectAll != null)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: '全选',
              onPressed: widget.onSelectAll,
            ),

          // 取消选择按钮
          if (widget.onCancelSelection != null && widget.selectedCount > 0)
            IconButton(
              icon: const Icon(Icons.deselect),
              tooltip: '取消选择',
              onPressed: widget.onCancelSelection,
            ),

          // 从当前分类中移除按钮
          if (widget.onRemoveFromCategory != null && widget.selectedCount > 0)
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: '从当前分类移除',
              onPressed: widget.onRemoveFromCategory,
            ),

          // 批量分类按钮
          if (widget.selectedCount > 0 && widget.onAssignCategoryBatch != null)
            IconButton(
              icon: const Icon(Icons.category),
              tooltip: '设置分类',
              onPressed: widget.onAssignCategoryBatch,
            ),

          // 批量删除按钮
          if (widget.selectedCount > 0)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: l10n.libraryManagementDeleteSelected,
              onPressed: widget.onDeleteSelected,
            ),
        ],

        // 删除全部按钮 - 在非批量模式下显示
        if (!widget.isBatchMode && widget.onDeleteAll != null)
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '删除全部',
            onPressed: widget.onDeleteAll,
          ),

        // 批量操作按钮
        IconButton(
          icon: Icon(widget.isBatchMode ? Icons.close : Icons.checklist),
          tooltip:
              widget.isBatchMode ? l10n.exitBatchMode : l10n.batchOperations,
          onPressed: widget.onToggleBatchMode,
        ), // 视图切换按钮
        IconButton(
          icon: Icon(widget.isGridView ? Icons.view_list : Icons.grid_view),
          tooltip: widget.isGridView ? l10n.listView : l10n.gridView,
          onPressed: widget.onToggleViewMode,
        ),

        // Grid size selector (only show when in grid view)
        if (widget.isGridView) const GridSizeSelector(),

        // 图片预览面板切换按钮
        IconButton(
          icon: Icon(widget.isImagePreviewOpen
              ? Icons.image_not_supported
              : Icons.image),
          tooltip: widget.isImagePreviewOpen ? '隐藏图片预览' : '显示图片预览',
          onPressed: widget.onToggleImagePreview,
        ),
      ],
    );
  }
}
