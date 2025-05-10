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
import 'components/category_batch_assign_dialog.dart';
import 'components/m3_library_detail_panel.dart';
import 'components/m3_library_filter_panel.dart';
import 'components/m3_library_grid_view.dart';
import 'components/m3_library_list_view.dart';
import 'components/m3_library_management_navigation_bar.dart';
import 'desktop_drop_wrapper.dart';

/// 文件拖放数据
class DragData {
  final String filePath;
  const DragData(this.filePath);
}

/// A custom widget that supports file drag and drop from the operating system
class DropTarget extends StatefulWidget {
  final Widget child;
  final Function(List<String>) onDrop;

  const DropTarget({
    Key? key,
    required this.child,
    required this.onDrop,
  }) : super(key: key);

  @override
  State<DropTarget> createState() => _DropTargetState();
}

// Generic type for handling OS drag and drop
class ExternalDragData {
  final List<String> files;
  const ExternalDragData(this.files);
}

/// Material 3 风格的图库管理页面
class M3LibraryManagementPage extends ConsumerStatefulWidget {
  /// 构造函数
  const M3LibraryManagementPage({super.key});

  @override
  ConsumerState<M3LibraryManagementPage> createState() =>
      _M3LibraryManagementPageState();
}

class _DropTargetState extends State<DropTarget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: The content
        widget.child,

        // Layer 2: Drag target for system files
        Positioned.fill(
          child: IgnorePointer(
            // Ignore pointer when not dragging so the child can receive events
            ignoring: !_isDragging,
            child: Builder(builder: (context) {
              return DragTarget<Object>(
                onWillAcceptWithDetails: (details) {
                  print(
                      'onWillAcceptWithDetails: ${details.data.runtimeType} - ${details.data}');
                  setState(() => _isDragging = true);
                  return true; // Accept all drops and handle in onAccept
                },
                onAcceptWithDetails: (details) {
                  setState(() => _isDragging = false);
                  print(
                      'onAcceptWithDetails: ${details.data.runtimeType} - ${details.data}');

                  // Handle different data types
                  if (details.data is List<String>) {
                    // Direct List<String> format
                    widget.onDrop(details.data as List<String>);
                  } else if (details.data is String) {
                    // Single string (file path)
                    widget.onDrop([details.data as String]);
                  } else if (details.data is List) {
                    // Try to convert dynamic list to string list
                    final List<dynamic> dynamicList =
                        details.data as List<dynamic>;
                    final List<String> stringList = dynamicList
                        .whereType<String>()
                        .map((item) => item)
                        .toList();
                    if (stringList.isNotEmpty) {
                      widget.onDrop(stringList);
                    }
                  } else if (details.data is Map) {
                    // Try to extract file paths from map
                    final Map<dynamic, dynamic> dataMap =
                        details.data as Map<dynamic, dynamic>;
                    if (dataMap.containsKey('files') &&
                        dataMap['files'] is List) {
                      final List<dynamic> files =
                          dataMap['files'] as List<dynamic>;
                      final List<String> paths = files
                          .whereType<String>()
                          .map((file) => file)
                          .toList();
                      if (paths.isNotEmpty) {
                        widget.onDrop(paths);
                      }
                    }
                  }
                },
                onLeave: (data) {
                  setState(() => _isDragging = false);
                },
                builder: (context, candidateData, rejectedData) {
                  // Only show overlay when dragging
                  if (!_isDragging && candidateData.isEmpty)
                    return const SizedBox.shrink();

                  return Container(
                    color: Colors.green.withOpacity(0.2),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.file_upload,
                            size: 64,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '释放鼠标以导入图片',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
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
        onAssignCategoryBatch:
            state.selectedItems.isNotEmpty ? _showCategoryBatchDialog : null,
        isGridView: state.viewMode == ViewMode.grid,
        onToggleViewMode: _toggleViewMode,
        onSearch: _handleSearch,
        searchController: _searchController,
        onImportFiles: _handleImportFiles,
        onImportFolder: _handleImportFolder,
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 800,
          minHeight: 600,
        ),
        child: DesktopDropWrapper(
          onFilesDropped: (files) async {
            print('DesktopDropWrapper onFilesDropped: $files');
            if (files.isNotEmpty) {
              for (final file in files) {
                await _importFile(file);
              }
            }
          },
          child: Column(
            children: [
              // Main content area with filter, list and detail panels
              Expanded(
                child: Row(
                  children: [
                    // Left filter panel (resizable)
                    if (_isFilterPanelExpanded)
                      const ResizablePanel(
                        initialWidth: 300,
                        minWidth: 280,
                        maxWidth: 400,
                        isLeftPanel: true,
                        child: M3LibraryFilterPanel(),
                      ),

                    // Filter panel toggle
                    SidebarToggle(
                      isOpen: _isFilterPanelExpanded,
                      onToggle: _toggleFilterPanel,
                      alignRight: false,
                    ),

                    // Main content area
                    Expanded(
                      child: DropTarget(
                        onDrop: (files) async {
                          print('DropTarget onDrop: $files');
                          for (final file in files) {
                            await _importFile(file);
                          }
                        },
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

                    // Right detail panel (resizable)
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

              // Pagination controls
              _buildPaginationControls(state, l10n),
            ],
          ),
        ),
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
        int successCount = 0;
        int failedCount = 0;
        List<String> failedFiles = [];

        for (final file in result.files) {
          if (file.path != null) {
            try {
              print('Processing file: ${file.path}');
              final item = await importService.importFile(file.path!);
              if (item != null) {
                // Add categories if selected
                if (categories.isNotEmpty) {
                  final updatedItem = item.copyWith(categories: categories);
                  await ref.read(libraryRepositoryProvider).update(updatedItem);
                  print(
                      'Added categories to imported file: ${file.path}, categories: $categories');
                }
                successCount++;
                print('Successfully imported file: ${file.path}');
              }
            } catch (e) {
              failedCount++;
              failedFiles.add(file.name);
              print('Failed to import file ${file.name}: $e');
            }
          }
        }

        // Close the dialog before refreshing data
        closeDialog();

        // Refresh data
        await _refreshData();

        if (mounted) {
          if (successCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '成功导入 $successCount 个文件${failedCount > 0 ? '，失败 $failedCount 个文件' : ''}'),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (failedCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('导入失败: ${failedFiles.join(", ")}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        print('Error in import process: $e');

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
      } finally {
        // Ensure dialog is closed in any case
        closeDialog();
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
        print('Importing directory: $result');
        print('Using categories: $categories');

        // Normalize directory path
        final normalizedPath = result.replaceAll(r'\', '/');
        print('Normalized directory path: $normalizedPath');

        // Verify directory exists
        final directory = Directory(normalizedPath);
        if (!await directory.exists()) {
          print('Directory does not exist, trying original path');
          final originalDir = Directory(result);
          if (!await originalDir.exists()) {
            throw Exception('目录不存在或无法访问: $result');
          }
        }

        // Use the directory path that works
        final pathToUse = await directory.exists() ? normalizedPath : result;
        print('Using directory path: $pathToUse');

        // Import directory
        final items = await importService.importDirectory(
          pathToUse,
          recursive: true,
          categories: categories,
        );

        print('Import complete, imported ${items.length} items');

        // Close the dialog before refreshing data
        closeDialog();

        // Refresh data
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
        print('Error importing directory: $e');

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
      } finally {
        // Ensure dialog is closed in any case
        closeDialog();
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

  // Helper method to import a file
  Future<void> _importFile(String filePath) async {
    print('_importFile called with path: $filePath');
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
      print('Normalized path: $normalizedPath');

      final file = File(normalizedPath);
      print('Checking if file exists: $normalizedPath');

      final fileExists = await file.exists();
      if (!fileExists) {
        print('File does not exist, trying original path: $filePath');
        final originalFile = File(filePath);
        if (!await originalFile.exists()) {
          throw Exception('文件不存在或无法访问: $filePath');
        }
        print('File exists with original path, proceeding with import');
      } else {
        print('File exists, proceeding with import');
      }

      // Use the path that worked
      final pathToUse = fileExists ? normalizedPath : filePath;
      print('Using path for import: $pathToUse');

      // Import the file
      final item = await importService.importFile(pathToUse);
      print('Import result: $item');

      // If import successful and categories are specified, update the item
      if (item != null && categories.isNotEmpty) {
        print('Updating item with categories: $categories');
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
      print('Error importing file: $e');

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
    } finally {
      // Ensure dialog is closed in any case
      closeDialog();
    }
  }

  /// 刷新数据
  Future<void> _refreshData() async {
    if (!mounted) return;

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
                Text('正在刷新数据...'),
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
      // Load data
      await ref.read(libraryManagementProvider.notifier).loadData();

      // Reload category counts to ensure "All Categories" count is accurate
      await ref
          .read(libraryManagementProvider.notifier)
          .loadCategoryItemCounts();
    } catch (e) {
      print('Error refreshing data: $e');

      // Close dialog in case of error
      closeDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新数据失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Ensure dialog is closed in any case
      closeDialog();
    }
  }

  /// 显示批量分类对话框
  void _showCategoryBatchDialog() {
    if (!mounted) return;

    final state = ref.read(libraryManagementProvider);

    if (state.selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => CategoryBatchAssignDialog(
        selectedItemIds: state.selectedItems.toList(),
      ),
    );
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
