import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/service_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/library/library_management_provider.dart';
import '../../viewmodels/states/library_management_state.dart';
import '../../widgets/common/resizable_panel.dart';
import '../../widgets/common/sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/pagination/m3_pagination_controls.dart';
import 'components/m3_library_detail_panel.dart';
import 'components/m3_library_filter_panel.dart';
import 'components/m3_library_grid_view.dart';
import 'components/m3_library_list_view.dart';
import 'components/m3_library_management_navigation_bar.dart';

/// 文件拖放数据
class DragData {
  final String filePath;
  const DragData(this.filePath);
}

/// Material 3 风格的图库管理页面
class M3LibraryManagementPage extends ConsumerStatefulWidget {
  /// 构造函数
  const M3LibraryManagementPage({super.key});

  @override
  ConsumerState<M3LibraryManagementPage> createState() =>
      _M3LibraryManagementPageState();
}

class _M3LibraryManagementPageState
    extends ConsumerState<M3LibraryManagementPage> {
  late final TextEditingController _searchController;
  bool _isFilterPanelExpanded = true;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryManagementProvider);
    final l10n = AppLocalizations.of(context);

    return PageLayout(
      toolbar: M3LibraryManagementNavigationBar(
        isBatchMode: state.isBatchMode,
        onToggleBatchMode: _toggleBatchMode,
        selectedCount: state.selectedItems.length,
        onDeleteSelected:
            state.selectedItems.isNotEmpty ? _handleDeleteSelectedItems : null,
        isGridView: state.viewMode == ViewMode.grid,
        onToggleViewMode: _toggleViewMode,
        onSearch: _handleSearch,
        searchController: _searchController,
        onImportFiles: _handleImportFiles,
        onImportFolder: _handleImportFolder,
      ),
      body: Row(
        children: [
          // 左侧过滤面板
          if (_isFilterPanelExpanded)
            const ResizablePanel(
              initialWidth: 300,
              minWidth: 280,
              maxWidth: 400,
              isLeftPanel: true,
              child: M3LibraryFilterPanel(),
            ),

          // 主内容区
          Expanded(
            child: Column(
              children: [
                // 过滤面板切换按钮
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SidebarToggle(
                        isOpen: _isFilterPanelExpanded,
                        onToggle: _toggleFilterPanel,
                      ),
                    ],
                  ),
                ),

                // 内容区域
                Expanded(
                  child: Row(
                    children: [
                      // 主内容区
                      Expanded(
                        child: _buildDragTarget(
                          child: state.viewMode == ViewMode.grid
                              ? M3LibraryGridView(
                                  items: state.items,
                                  isBatchMode: state.isBatchMode,
                                  selectedItems: state.selectedItems,
                                  onItemTap: _handleItemTap,
                                  onItemLongPress: _handleItemLongPress,
                                )
                              : M3LibraryListView(
                                  items: state.items,
                                  isBatchMode: state.isBatchMode,
                                  selectedItems: state.selectedItems,
                                  onItemTap: _handleItemTap,
                                  onItemLongPress: _handleItemLongPress,
                                ),
                        ),
                      ),

                      // 详情面板
                      if (state.selectedItem != null && state.isDetailOpen)
                        ResizablePanel(
                          initialWidth: 350,
                          minWidth: 250,
                          maxWidth: 500,
                          isLeftPanel: false,
                          child: M3LibraryDetailPanel(
                            item: state.selectedItem!,
                          ),
                        ),
                    ],
                  ),
                ),

                // 分页控件
                _buildPaginationControls(state, l10n),
              ],
            ),
          ),
        ],
      ),
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
    // 页面创建时加载初始数据
    Future.microtask(() {
      ref.read(libraryManagementProvider.notifier).loadData();
    });
  }

  /// 构建拖拽导入目标
  Widget _buildDragTarget({required Widget child}) {
    return DragTarget<DragData>(
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            child,
            if (candidateData.isNotEmpty)
              Container(
                color: Colors.blue.withOpacity(0.2),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.file_upload,
                        size: 64,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '释放鼠标以导入图片',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      onWillAcceptWithDetails: (details) {
        // 只接受文件拖放
        return true; // Fixed: removed data != null check as it's always true
      },
      onAcceptWithDetails: (details) async {
        final importService = ref.read(libraryImportServiceProvider);
        final state = ref.read(libraryManagementProvider);
        final List<String> categories =
            state.selectedCategoryId != null ? [state.selectedCategoryId!] : [];

        final BuildContext dialogContext = context;
        BuildContext? dialogBuilderContext;

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

        try {
          final dragData = details.data;
          final file = File(dragData.filePath);
          if (await file.exists()) {
            final item = await importService.importFile(dragData.filePath);
            if (item != null && categories.isNotEmpty) {
              final updatedItem = item.copyWith(categories: categories);
              await ref.read(libraryRepositoryProvider).update(updatedItem);
            }
          }

          await _refreshData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('成功导入文件'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('导入失败: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } finally {
          if (mounted && dialogBuilderContext != null) {
            Navigator.of(dialogBuilderContext!).pop();
          }
        }
      },
    );
  }

  Widget _buildPaginationControls(
    LibraryManagementState state,
    AppLocalizations l10n,
  ) {
    return M3PaginationControls(
      currentPage: state.currentPage,
      pageSize: state.pageSize,
      totalItems: state.totalCount,
      onPageChanged: _handlePageChange,
      onPageSizeChanged: _handlePageSizeChanged,
      availablePageSizes: const [10, 20, 50, 100],
    );
  }

  void _handleCategorySelected(String? categoryId) {
    ref.read(libraryManagementProvider.notifier).selectCategory(categoryId);
  }

  void _handleDeleteSelectedItems() {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final state = ref.read(libraryManagementProvider);

    if (state.selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.libraryManagementDeleteConfirm),
        content: Text(l10n.libraryManagementDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted) {
                ref
                    .read(libraryManagementProvider.notifier)
                    .deleteSelectedItems();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  /// 处理导入文件
  Future<void> _handleImportFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final importService = ref.read(libraryImportServiceProvider);

      final BuildContext dialogContext = context;
      BuildContext? dialogBuilderContext;

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

      try {
        int successCount = 0;

        for (final file in result.files) {
          if (file.path != null) {
            final item = await importService.importFile(file.path!);
            if (item != null) successCount++;
          }
        }

        await _refreshData();

        if (mounted && successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功导入 $successCount 个文件'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导入失败: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted && dialogBuilderContext != null) {
          Navigator.of(dialogBuilderContext!).pop();
        }
      }
    }
  }

  /// 处理导入文件夹
  Future<void> _handleImportFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      final importService = ref.read(libraryImportServiceProvider);
      final state = ref.read(libraryManagementProvider);
      final List<String> categories =
          state.selectedCategoryId != null ? [state.selectedCategoryId!] : [];

      final BuildContext dialogContext = context;
      BuildContext? dialogBuilderContext;

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

      try {
        final items = await importService.importDirectory(
          result,
          recursive: true,
          categories: categories,
        );

        await _refreshData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功导入 ${items.length} 个文件'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导入失败: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted && dialogBuilderContext != null) {
          Navigator.of(dialogBuilderContext!).pop();
        }
      }
    }
  }

  void _handleItemLongPress(String itemId) {
    if (!mounted) return;

    final state = ref.read(libraryManagementProvider);

    if (!state.isBatchMode) {
      ref.read(libraryManagementProvider.notifier).toggleBatchMode();
    }
    ref.read(libraryManagementProvider.notifier).toggleItemSelection(itemId);
  }

  void _handleItemTap(String itemId) {
    if (!mounted) return;

    final state = ref.read(libraryManagementProvider);

    if (state.isBatchMode) {
      ref.read(libraryManagementProvider.notifier).toggleItemSelection(itemId);
    } else {
      ref.read(libraryManagementProvider.notifier).selectItem(itemId);
    }
  }

  void _handlePageChange(int page) {
    ref.read(libraryManagementProvider.notifier).changePage(page);
  }

  void _handlePageSizeChanged(int? size) {
    if (size != null) {
      ref.read(libraryManagementProvider.notifier).updatePageSize(size);
    }
  }

  void _handleSearch(String query) {
    ref.read(libraryManagementProvider.notifier).updateSearchQuery(query);
  }

  /// 刷新数据
  Future<void> _refreshData() async {
    if (!mounted) return;

    final BuildContext dialogContext = context;
    BuildContext? dialogBuilderContext;

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
                Text('正在刷新数据...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      await ref.read(libraryManagementProvider.notifier).loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新数据失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && dialogBuilderContext != null) {
        Navigator.of(dialogBuilderContext!).pop();
      }
    }
  }

  void _toggleBatchMode() {
    ref.read(libraryManagementProvider.notifier).toggleBatchMode();
  }

  void _toggleFilterPanel() {
    setState(() {
      _isFilterPanelExpanded = !_isFilterPanelExpanded;
    });
  }

  void _toggleViewMode() {
    ref.read(libraryManagementProvider.notifier).toggleViewMode();
  }
}
