// 图库浏览面板修复版本
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/service_providers.dart';
import '../../../domain/entities/library_item.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../pages/library/components/box_selection_painter.dart';
import '../../pages/library/components/m3_library_filter_panel.dart';
import '../../pages/library/components/m3_library_grid_view.dart';
import '../../pages/library/components/m3_library_list_view.dart';
import '../../pages/library/components/resizable_image_preview_panel.dart';
import '../../pages/library/desktop_drop_wrapper.dart';
import '../../providers/library/library_management_provider.dart';
import '../../viewmodels/states/library_management_state.dart';
import '../common/persistent_resizable_panel.dart';
import '../common/persistent_sidebar_toggle.dart';
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
                PersistentResizablePanel(
                  panelId: 'library_browsing_filter_panel',
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
                          onRefresh: () {
                            // 触发图库数据刷新
                            ref
                                .read(libraryManagementProvider.notifier)
                                .refresh();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Filter panel toggle
              PersistentSidebarToggle(
                sidebarId: 'library_browsing_filter_sidebar',
                defaultIsOpen: _isFilterPanelExpanded,
                onToggle: (isOpen) => _toggleFilterPanel(),
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
                    final selectedItems = state.items
                        .where((item) => state.selectedItems.contains(item.id))
                        .toList();

                    if (selectedItems.isEmpty) {
                      return;
                    }

                    // 先调用回调，然后再关闭对话框
                    if (widget.enableMultiSelect &&
                        widget.onItemsSelected != null) {
                      // 调用回调前不关闭对话框，让回调处理关闭
                      widget.onItemsSelected!(selectedItems);
                    } else if (!widget.enableMultiSelect &&
                        widget.onItemSelected != null) {
                      // 调用回调前不关闭对话框，让回调处理关闭
                      widget.onItemSelected!(selectedItems.first);
                    } else {
                      // 如果没有回调，才由这里关闭对话框
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
            RenderBox? box =
                _contentKey.currentContext?.findRenderObject() as RenderBox?;
            if (box == null) return;

            Offset localPosition = box.globalToLocal(details.globalPosition);

            setState(() {
              _isBoxSelecting = true;
              _boxSelectionStart = localPosition;
              _boxSelectionCurrent = localPosition;
            });
          },
          onPanUpdate: (details) {
            if (!_isBoxSelecting) return;

            RenderBox? box =
                _contentKey.currentContext?.findRenderObject() as RenderBox?;
            if (box == null) return;

            Offset localPosition = box.globalToLocal(details.globalPosition);

            // 只有当位置确实发生明显变化时才更新
            if (_boxSelectionCurrent == null ||
                (_boxSelectionCurrent! - localPosition).distance > 2.0) {
              setState(() {
                _boxSelectionCurrent = localPosition;
              });
            }
          },
          onPanEnd: (details) {
            if (!_isBoxSelecting) return;

            // 如果选择矩形太小（可能是意外点击），则取消选择
            if (_boxSelectionStart != null && _boxSelectionCurrent != null) {
              final selectionRect =
                  Rect.fromPoints(_boxSelectionStart!, _boxSelectionCurrent!);
              if (selectionRect.width < 5 && selectionRect.height < 5) {
                // 取消选择操作 - 可能是意外点击
                setState(() {
                  _isBoxSelecting = false;
                  _boxSelectionStart = null;
                  _boxSelectionCurrent = null;
                });
                return;
              }
            }

            // 应用最终选择
            _handleBoxSelection();

            // 重置框选状态
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
          // 显示导入进度对话框
          await _showBatchImportDialog(files);
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

  // 查找所有图库项目的真实位置
  Map<String, Rect> _findRealLibraryItemPositions(RenderBox containerBox) {
    final result = <String, Rect>{};

    void visitor(Element element) {
      // 检查元素的键是否包含图库项目ID
      final key = element.widget.key;
      if (key is ValueKey && key.value.toString().startsWith('library_item_')) {
        // 从键字符串中提取图库项目ID
        final itemId =
            key.value.toString().substring(13); // 'library_item_'.length

        // 获取位置信息
        final renderObj = element.renderObject;
        if (renderObj is RenderBox && renderObj.hasSize) {
          try {
            // 计算相对于容器的位置
            final pos =
                renderObj.localToGlobal(Offset.zero, ancestor: containerBox);
            final rect = Rect.fromLTWH(
                pos.dx, pos.dy, renderObj.size.width, renderObj.size.height);
            result[itemId] = rect;
          } catch (e) {
            // 处理可能的异常，例如元素已经不在视图树中
          }
        }
      }

      // 继续遍历子元素
      element.visitChildren(visitor);
    }

    // 开始遍历
    if (_contentKey.currentContext != null) {
      _contentKey.currentContext!.visitChildElements(visitor);
    }

    return result;
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
    if (contentBox == null) {
      return;
    }

    // 使用元素遍历来找到实际的图库项目位置
    final libraryItems = _findRealLibraryItemPositions(contentBox);
    if (libraryItems.isEmpty) {
      return;
    }

    final notifier = ref.read(libraryManagementProvider.notifier);

    // 记录框选内的所有图库项目ID
    Set<String> boxSelectedIds = {};

    // 选中在选择框内的所有图库项目
    for (var entry in libraryItems.entries) {
      if (selectionRect.overlaps(entry.value)) {
        boxSelectedIds.add(entry.key);
      }

      if (boxSelectedIds.isEmpty) {
        return;
      }

      // 更新批量模式状态
      if (!state.isBatchMode && boxSelectedIds.isNotEmpty) {
        notifier.toggleBatchMode();
      } // 只添加新选择的项目，保留已有选择
      for (final id in boxSelectedIds) {
        if (!state.selectedItems.contains(id)) {
          // 只有未选中的项目才需要切换状态
          notifier.toggleItemSelection(id);
        }
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
          widget.onItemSelected!(selectedItem);
        }
      }
    } else if (state.isBatchMode || widget.enableMultiSelect) {
      // 批量选择模式 - 切换选择状态
      notifier.toggleItemSelection(itemId);
    } else if (widget.onItemSelected != null) {
      // 有选择回调的单选模式
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
            content: Text(
                AppLocalizations.of(context).refreshDataFailed(e.toString())),
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

  // 显示批量导入对话框
  Future<void> _showBatchImportDialog(List<String> files) async {
    if (!mounted) return;

    final BuildContext dialogContext = context;
    BuildContext? dialogBuilderContext;
    int successCount = 0;
    int failureCount = 0;
    String? lastError;

    // 显示导入进度对话框
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (builderContext) {
        dialogBuilderContext = builderContext;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context).importing),
                const SizedBox(height: 8),
                Text('正在处理 ${files.length} 个文件...'),
              ],
            ),
          ),
        );
      },
    );

    // 安全关闭对话框的函数
    void closeDialog() {
      try {
        if (mounted && dialogBuilderContext != null) {
          Navigator.of(dialogBuilderContext!).pop();
          dialogBuilderContext = null;
        }
      } catch (e) {
        AppLogger.error('Error closing batch import dialog: $e');
      }
    }

    try {
      final importService = ref.read(libraryImportServiceProvider);
      final state = ref.read(libraryManagementProvider);
      final List<String> categories =
          state.selectedCategoryId != null ? [state.selectedCategoryId!] : [];

      // 逐个导入文件
      for (final filePath in files) {
        try {
          final item = await importService.importFile(filePath);
          if (item != null) {
            // 如果指定了分类，更新项目
            if (categories.isNotEmpty) {
              final updatedItem = item.copyWith(categories: categories);
              await ref.read(libraryRepositoryProvider).update(updatedItem);
            }
            successCount++;
          }
        } catch (e) {
          failureCount++;
          lastError = e.toString();
          AppLogger.warning('导入文件失败: $filePath', error: e);
        }
      }

      // 关闭对话框
      closeDialog();

      // 刷新数据
      await _refreshData();

      // 显示结果消息
      if (mounted) {
        if (successCount > 0 && failureCount == 0) {
          // 全部成功
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功导入 $successCount 个文件'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (successCount > 0 && failureCount > 0) {
          // 部分成功
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导入完成：成功 $successCount 个，失败 $failureCount 个'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // 全部失败
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导入失败：${lastError ?? "未知错误"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // 关闭对话框
      closeDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('批量导入失败：${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
