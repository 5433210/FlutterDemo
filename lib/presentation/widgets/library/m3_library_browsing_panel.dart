import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/service_providers.dart';
import '../../../domain/entities/library_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../pages/library/components/box_selection_painter.dart';
import '../../pages/library/components/m3_library_filter_panel.dart';
import '../../pages/library/components/m3_library_grid_view.dart';
import '../../pages/library/components/m3_library_list_view.dart';
import '../../pages/library/components/resizable_image_preview_panel.dart';
import '../../pages/library/desktop_drop_wrapper.dart';
import '../../providers/library/library_management_provider.dart';
import '../../providers/settings/grid_size_provider.dart';
import '../../viewmodels/states/library_management_state.dart';
import '../common/resizable_panel.dart';
import '../common/sidebar_toggle.dart';
import '../pagination/m3_pagination_controls.dart';

/// 图库检索面板 - 独立可复用的组件
/// 包含筛选面板、图片网格/列表和分页控制
class M3LibraryBrowsingPanel extends ConsumerStatefulWidget {
  /// 是否允许文件拖放导入
  final bool enableFileDrop;

  /// 是否可以多选
  final bool enableMultiSelect;

  /// 选择回调
  final Function(LibraryItem)? onItemSelected;

  /// 多选回调
  final Function(List<LibraryItem>)? onItemsSelected;

  /// 是否显示确认/取消按钮 (对话框模式)
  final bool showConfirmButtons;

  /// 预览面板是否可见
  final bool imagePreviewVisible;

  /// 切换预览面板回调
  final VoidCallback? onToggleImagePreview;

  /// 选中的项目
  final LibraryItem? selectedItem;

  /// 构造函数
  const M3LibraryBrowsingPanel({
    super.key,
    this.enableFileDrop = true,
    this.enableMultiSelect = false,
    this.onItemSelected,
    this.onItemsSelected,
    this.showConfirmButtons = false,
    this.imagePreviewVisible = false,
    this.onToggleImagePreview,
    this.selectedItem,
  });

  @override
  ConsumerState<M3LibraryBrowsingPanel> createState() =>
      _M3LibraryBrowsingPanelState();
}

class _M3LibraryBrowsingPanelState
    extends ConsumerState<M3LibraryBrowsingPanel> {
  late final TextEditingController _searchController;
  bool _isFilterPanelExpanded = true;

  // 框选相关变量
  bool _isBoxSelecting = false;
  Offset? _boxSelectionStart;
  Offset? _boxSelectionCurrent;
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryManagementProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // Main content area with filter, list and search
        Expanded(
          child: Row(
            children: [
              // Left filter panel (resizable)
              if (_isFilterPanelExpanded)
                ResizablePanel(
                  initialWidth: 300,
                  minWidth: 280,
                  maxWidth: 400,
                  isLeftPanel: true,
                  child: Column(
                    children: [
                      // 筛选面板内容（搜索框已移至筛选面板内部）
                      Expanded(
                        child: M3LibraryFilterPanel(
                          searchController: _searchController,
                          onSearch: _handleSearch,
                        ),
                      ),
                    ],
                  ),
                ),

              // Filter panel toggle
              SidebarToggle(
                isOpen: _isFilterPanelExpanded,
                onToggle: _toggleFilterPanel,
                alignRight: false,
              ),

              // Main content area
              Expanded(
                child: widget.enableFileDrop
                    ? _buildDropTarget(state)
                    : _buildContentArea(state),
              ),
            ],
          ),
        ),

        // Pagination controls
        _buildPaginationControls(state, l10n),

        // 确认/取消按钮 (对话框模式)
        if (widget.showConfirmButtons) _buildConfirmButtons(state),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // 组件创建时加载初始数据
    Future.microtask(() {
      if (mounted) {
        // 每次打开面板时，先清空选择状态和搜索条件，再加载数据
        final notifier = ref.read(libraryManagementProvider.notifier);

        // 清空选择状态
        notifier.clearSelection();

        // 重置搜索条件
        notifier.updateSearchQuery('');
        _searchController.clear(); // 确保搜索框UI也被清空

        // 重置所有筛选条件，确保每次打开面板时都是干净的状态
        notifier.resetAllFilters();

        print('【M3LibraryBrowsingPanel】initState - 已重置所有选择状态和搜索条件');

        // 加载数据
        notifier.loadData();
      }
    });
  }

  // 构建确认/取消按钮 (对话框模式)
  Widget _buildConfirmButtons(LibraryManagementState state) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              print('【LibraryBrowsingPanel】点击取消按钮');
              // 使用普通的Navigator.pop，而不是指定rootNavigator
              Navigator.pop(context);
            },
            child: Text(l10n.cancel),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: state.selectedItems.isEmpty
                ? null
                : () {
                    print('【LibraryBrowsingPanel】点击确认按钮');
                    final selectedItems = state.items
                        .where((item) => state.selectedItems.contains(item.id))
                        .toList();

                    if (selectedItems.isEmpty) {
                      return;
                    }

                    print(
                        '【LibraryBrowsingPanel】已选择${selectedItems.length}个项目');

                    // 先调用回调，然后再关闭对话框
                    if (widget.enableMultiSelect &&
                        widget.onItemsSelected != null) {
                      print('【LibraryBrowsingPanel】调用onItemsSelected回调');
                      // 调用回调前不关闭对话框，让回调处理关闭
                      widget.onItemsSelected!(selectedItems);
                    } else if (!widget.enableMultiSelect &&
                        widget.onItemSelected != null) {
                      print('【LibraryBrowsingPanel】调用onItemSelected回调');
                      // 调用回调前不关闭对话框，让回调处理关闭
                      widget.onItemSelected!(selectedItems.first);
                    } else {
                      // 如果没有回调，才由这里关闭对话框
                      print('【LibraryBrowsingPanel】没有回调函数，直接关闭对话框');
                      Navigator.pop(context);
                    }
                  },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  // 构建内容区域 (网格或列表视图)
  Widget _buildContentArea(LibraryManagementState state) {
    // 创建基础内容
    Widget content = Column(
      children: [
        // 图片预览面板 (如果可见并且有选中的项目)
        if (widget.imagePreviewVisible && widget.selectedItem != null)
          ResizableImagePreviewPanel(
            selectedItem: widget.selectedItem,
            isVisible: widget.imagePreviewVisible,
            onClose: widget.onToggleImagePreview,
          ),

        // 图库内容 (网格或列表)
        Expanded(
          child: state.viewMode == ViewMode.grid
              ? M3LibraryGridView(
                  items: state.items,
                  isBatchMode: state.isBatchMode || widget.enableMultiSelect,
                  selectedItems: state.selectedItems,
                  onItemTap: _handleItemTap,
                  onItemLongPress: _handleItemLongPress,
                )
              : M3LibraryListView(
                  items: state.items,
                  isBatchMode: state.isBatchMode || widget.enableMultiSelect,
                  selectedItems: state.selectedItems,
                  onItemTap: _handleItemTap,
                  onItemLongPress: _handleItemLongPress,
                ),
        ),
      ],
    );

    // 如果不是批量模式或不允许多选，则不启用框选功能
    if (!state.isBatchMode && !widget.enableMultiSelect) {
      return content;
    }

    // 包装在GestureDetector中以支持框选功能
    return Stack(
      children: [
        // 内容区域，带有key以便我们可以获取其大小
        GestureDetector(
          key: _contentKey,
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            if (!state.isBatchMode && !widget.enableMultiSelect) return;

            // 检查是否点击了项目，如果是则不启动框选
            RenderBox box =
                _contentKey.currentContext!.findRenderObject() as RenderBox;
            Offset localPosition = box.globalToLocal(details.globalPosition);

            setState(() {
              _isBoxSelecting = true;
              _boxSelectionStart = localPosition;
              _boxSelectionCurrent = localPosition;
            });
          },
          onPanUpdate: (details) {
            if (!_isBoxSelecting) return;

            RenderBox box =
                _contentKey.currentContext!.findRenderObject() as RenderBox;
            Offset localPosition = box.globalToLocal(details.globalPosition);

            setState(() {
              _boxSelectionCurrent = localPosition;
            });
          },
          onPanEnd: (details) {
            if (!_isBoxSelecting) return;

            _handleBoxSelection();

            setState(() {
              _isBoxSelecting = false;
              _boxSelectionStart = null;
              _boxSelectionCurrent = null;
            });
          },
          child: content,
        ),

        // 绘制选择框
        if (_isBoxSelecting &&
            _boxSelectionStart != null &&
            _boxSelectionCurrent != null)
          Positioned.fill(
            child: CustomPaint(
              painter: BoxSelectionPainter(
                start: _boxSelectionStart!,
                end: _boxSelectionCurrent!,
              ),
            ),
          ),
      ],
    );
  }

  // 处理支持文件拖放的内容区域
  Widget _buildDropTarget(LibraryManagementState state) {
    return DesktopDropWrapper(
      onFilesDropped: (files) async {
        if (files.isNotEmpty) {
          for (final file in files) {
            await _importFile(file);
          }
        }
      },
      child: _buildContentArea(state),
    );
  }

  // 构建分页控件
  Widget _buildPaginationControls(
    LibraryManagementState state,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: M3PaginationControls(
        currentPage: state.currentPage,
        pageSize: state.pageSize,
        totalItems: state.totalCount,
        onPageChanged: _handlePageChange,
        onPageSizeChanged: _handlePageSizeChanged,
        availablePageSizes: const [10, 20, 50, 100],
      ),
    );
  }

  // 处理框选完成
  void _handleBoxSelection() {
    if (_boxSelectionStart == null || _boxSelectionCurrent == null) return;

    final state = ref.read(libraryManagementProvider);
    if (!state.isBatchMode && !widget.enableMultiSelect) return;

    // 将选择框规范化为左上角到右下角的形式
    final selectionRect =
        Rect.fromPoints(_boxSelectionStart!, _boxSelectionCurrent!);

    // 获取内容区域的RenderBox对象
    RenderBox? contentBox =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (contentBox == null) return;

    final notifier = ref.read(libraryManagementProvider.notifier);
    Set<String> selectedIds = Set.from(state.selectedItems);
    
    if (state.viewMode == ViewMode.grid) {
      // 从provider直接获取实际的grid size设置
      final gridSizeOption = ref.read(gridSizeProvider);
      final minItemWidth = gridSizeOption.minItemWidth;
      
      // 使用与M3LibraryGridView完全相同的计算逻辑
      const spacing = 16.0;
      final viewportSize = contentBox.size;
      
      // 动态计算列数，与M3LibraryGridView保持一致
      int crossAxisCount = math.max(2, math.min(8, 
          (viewportSize.width - spacing) ~/ (minItemWidth + spacing)));
      
      final itemWidth = (viewportSize.width - spacing * (crossAxisCount + 1)) / crossAxisCount;
      final itemHeight = itemWidth;
      
      // 查找滚动偏移量
      double scrollOffset = 0;
      try {
        final scrollable = Scrollable.of(_contentKey.currentContext!);
        if (scrollable.position != null) {
          scrollOffset = scrollable.position.pixels;
        }
      } catch (e) {
        // 忽略错误，使用默认值0
      }
      
      // 遍历项目并计算位置
      for (int i = 0; i < state.items.length; i++) {
        final column = i % crossAxisCount;
        final row = i ~/ crossAxisCount;
        
        final left = spacing + column * (itemWidth + spacing);
        final top = spacing + row * (itemHeight + spacing) - scrollOffset;
        
        final itemRect = Rect.fromLTWH(left, top, itemWidth, itemHeight);
        
        if (itemRect.overlaps(selectionRect)) {
          selectedIds.add(state.items[i].id);
        }
      }
    } else {
      // 列表视图的简化处理
      const itemHeight = 72.0; // 使用实际的列表项高度
      const spacing = 8.0;
      
      // 查找滚动偏移量
      double scrollOffset = 0;
      try {
        final scrollable = Scrollable.of(_contentKey.currentContext!);
        if (scrollable.position != null) {
          scrollOffset = scrollable.position.pixels;
        }
      } catch (e) {
        // 忽略错误
      }
      
      for (int i = 0; i < state.items.length; i++) {
        final top = spacing + i * (itemHeight + spacing) - scrollOffset;
        final itemRect = Rect.fromLTWH(
          spacing, 
          top, 
          contentBox.size.width - 2 * spacing, 
          itemHeight
        );
        
        if (itemRect.overlaps(selectionRect)) {
          selectedIds.add(state.items[i].id);
        }
      }
    }
    
    // 更新选中状态
    if (!state.isBatchMode && selectedIds.isNotEmpty) {
      notifier.toggleBatchMode();
    }
    
    // 更新所有项目的选中状态
    for (final item in state.items) {
      final id = item.id;
      final isCurrentlySelected = state.selectedItems.contains(id);
      final shouldBeSelected = selectedIds.contains(id);
      
      if (isCurrentlySelected != shouldBeSelected) {
        notifier.toggleItemSelection(id);
      }
    }
  }

  // 处理列表项长按
  void _handleItemLongPress(String itemId) {
    if (!mounted || !widget.enableMultiSelect) return;

    final state = ref.read(libraryManagementProvider);

    if (!state.isBatchMode) {
      ref.read(libraryManagementProvider.notifier).toggleBatchMode();
    }
    ref.read(libraryManagementProvider.notifier).toggleItemSelection(itemId);
  }

  // 处理列表项点击
  void _handleItemTap(String itemId) {
    if (!mounted) return;

    final state = ref.read(libraryManagementProvider);
    final notifier = ref.read(libraryManagementProvider.notifier);
    final selectedItem = state.items.firstWhere((item) => item.id == itemId);

    // 根据不同场景处理点击
    if (widget.showConfirmButtons) {
      // 选择对话框模式
      if (widget.enableMultiSelect) {
        // 多选模式
        notifier.toggleItemSelection(itemId);
      } else {
        // 单选模式
        notifier.clearSelection();
        notifier.selectItem(itemId);
        if (widget.onItemSelected != null) {
          print('【LibraryBrowsingPanel】单击项目，调用onItemSelected回调');
          widget.onItemSelected!(selectedItem);
        }
      }
    } else if (state.isBatchMode || widget.enableMultiSelect) {
      // 批量选择模式 - 切换选择状态
      print('【LibraryBrowsingPanel】批量选择模式 - 切换选择状态');
      notifier.toggleItemSelection(itemId);
    } else if (widget.onItemSelected != null) {
      // 有选择回调的单选模式
      print('【LibraryBrowsingPanel】有选择回调的单选模式');
      notifier.selectItem(itemId);
      notifier.setDetailItem(selectedItem); // Also update the detail item
      widget.onItemSelected!(selectedItem);
    } else {
      // 图库管理页模式 - 不选中项目，只显示详情
      notifier.openDetailPanel();
      notifier.clearSelection();
      notifier.setDetailItem(selectedItem);
    }
  }

  // 处理分页
  void _handlePageChange(int page) {
    ref.read(libraryManagementProvider.notifier).changePage(page);
  }

  // 处理每页项目数量变化
  void _handlePageSizeChanged(int? size) {
    if (size != null) {
      ref.read(libraryManagementProvider.notifier).updatePageSize(size);
    }
  }

  // 处理搜索
  void _handleSearch(String query) {
    ref.read(libraryManagementProvider.notifier).updateSearchQuery(query);
  }

  // 处理导入文件
  Future<void> _importFile(String filePath) async {
    final importService = ref.read(libraryImportServiceProvider);
    final state = ref.read(libraryManagementProvider);
    final List<String> categories =
        state.selectedCategoryId != null ? [state.selectedCategoryId!] : [];

    // Ensure we have a valid BuildContext for the dialog
    if (!mounted) {
      print('Component not mounted, cannot show dialog');
      return;
    }

    final BuildContext dialogContext = context;
    BuildContext? dialogBuilderContext;

    // Show loading dialog
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (builderContext) {
        dialogBuilderContext = builderContext;
        return WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在导入图片，请稍候...'),
              ],
            ),
          ),
        );
      },
    );

    // Create a function to safely close the dialog
    void closeDialog() {
      try {
        if (mounted && dialogBuilderContext != null) {
          Navigator.of(dialogBuilderContext!).pop();
          dialogBuilderContext = null;
        }
      } catch (e) {
        print('Error closing dialog: $e');
      }
    }

    try {
      // Normalize file path (this can help with some platform-specific path issues)
      final normalizedPath = filePath.replaceAll(r'\', '/');

      final file = File(normalizedPath);
      final fileExists = await file.exists();

      if (!fileExists) {
        final originalFile = File(filePath);
        if (!await originalFile.exists()) {
          throw Exception('文件不存在或无法访问: $filePath');
        }
      }

      // Use the path that worked
      final pathToUse = fileExists ? normalizedPath : filePath;

      // Import the file
      final item = await importService.importFile(pathToUse);

      // If import successful and categories are specified, update the item
      if (item != null && categories.isNotEmpty) {
        final updatedItem = item.copyWith(categories: categories);
        await ref.read(libraryRepositoryProvider).update(updatedItem);
      }

      // Close the dialog before refreshing data
      closeDialog();

      // Refresh data
      await _refreshData();

      // Show success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('成功导入文件'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close dialog in case of error
      closeDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 刷新数据
  Future<void> _refreshData() async {
    if (!mounted) return;

    try {
      // Load data
      await ref.read(libraryManagementProvider.notifier).loadData();

      // Reload category counts to ensure "All Categories" count is accurate
      await ref
          .read(libraryManagementProvider.notifier)
          .loadCategoryItemCounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新数据失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 切换筛选面板显示
  void _toggleFilterPanel() {
    setState(() {
      _isFilterPanelExpanded = !_isFilterPanelExpanded;
    });
  }
}
