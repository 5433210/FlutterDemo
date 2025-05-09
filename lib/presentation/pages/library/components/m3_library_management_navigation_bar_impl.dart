import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/m3_page_navigation_bar.dart';

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

  /// 是否为网格视图
  final bool isGridView;

  /// 切换视图模式回调
  final VoidCallback onToggleViewMode;

  /// 搜索回调
  final ValueChanged<String> onSearch;

  /// 搜索控制器
  final TextEditingController searchController;

  /// 导入文件回调
  final VoidCallback? onImportFiles;

  /// 导入文件夹回调
  final VoidCallback? onImportFolder;

  /// 构造函数
  const M3LibraryManagementNavigationBar({
    super.key,
    required this.isBatchMode,
    required this.onToggleBatchMode,
    required this.selectedCount,
    this.onDeleteSelected,
    required this.isGridView,
    required this.onToggleViewMode,
    required this.onSearch,
    required this.searchController,
    this.onImportFiles,
    this.onImportFolder,
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
        // 居中的搜索框
        SizedBox(
          width: 240,
          child: SearchBar(
            controller: widget.searchController,
            hintText: l10n.libraryManagementSearch,
            leading: const Icon(Icons.search),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 8),
            ),
            onChanged: widget.onSearch,
            trailing: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.searchController,
                builder: (context, value, child) {
                  return AnimatedOpacity(
                    opacity: value.text.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        widget.searchController.clear();
                        widget.onSearch('');
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),

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

        // 右侧按钮组
        // 批量删除按钮
        if (widget.isBatchMode && widget.selectedCount > 0)
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: l10n.libraryManagementDeleteSelected,
            onPressed: widget.onDeleteSelected,
          ),

        // 批量操作按钮
        IconButton(
          icon: Icon(widget.isBatchMode ? Icons.close : Icons.checklist),
          tooltip:
              widget.isBatchMode ? l10n.exitBatchMode : l10n.batchOperations,
          onPressed: widget.onToggleBatchMode,
        ),

        // 视图切换按钮
        IconButton(
          icon: Icon(widget.isGridView ? Icons.view_list : Icons.grid_view),
          tooltip: widget.isGridView ? l10n.listView : l10n.gridView,
          onPressed: widget.onToggleViewMode,
        ),
      ],
    );
  }
}
