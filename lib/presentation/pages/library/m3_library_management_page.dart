import 'package:charasgem/infrastructure/logging/logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../domain/entities/library_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/library/library_management_provider.dart';
import '../../utils/cross_navigation_helper.dart';
import '../../viewmodels/states/library_management_state.dart';
import '../../widgets/library/m3_library_browsing_panel.dart';
import '../../widgets/page_layout.dart';
import 'components/category_batch_assign_dialog.dart';
import 'components/m3_library_detail_panel.dart';
import 'components/m3_library_management_navigation_bar.dart';

/// Image preview visibility state provider
final imagePreviewVisibleProvider = StateProvider<bool>((ref) {
  // Initialize with the same value from library management state
  final libraryState = ref.watch(libraryManagementProvider);
  return libraryState.isImagePreviewOpen;
});

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
  /// Get the current image preview visibility state
  bool get isImagePreviewVisible => ref.watch(imagePreviewVisibleProvider);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryManagementProvider);

    return PageLayout(
      toolbar: M3LibraryManagementNavigationBar(
        isBatchMode: state.isBatchMode,
        onToggleBatchMode: _toggleBatchMode,
        selectedCount: state.selectedItems.length,
        onDeleteSelected:
            state.selectedItems.isNotEmpty ? _handleDeleteSelectedItems : null,
        onDeleteAll: _handleDeleteAllItems,
        onAssignCategoryBatch:
            state.selectedItems.isNotEmpty ? _showCategoryBatchDialog : null,
        onRemoveFromCategory:
            state.selectedCategoryId != null && state.selectedItems.isNotEmpty
                ? () => _handleRemoveFromCategory(state.selectedCategoryId!)
                : null,
        onSelectAll: _handleSelectAll,
        onCancelSelection:
            state.selectedItems.isNotEmpty ? _handleCancelSelection : null,
        onCopySelected:
            state.selectedItems.isNotEmpty || state.selectedItem != null
                ? _handleCopySelectedItems
                : null,
        onCutSelected:
            state.selectedItems.isNotEmpty || state.selectedItem != null
                ? _handleCutSelectedItems
                : null,
        isGridView: state.viewMode == ViewMode.grid,
        onToggleViewMode: _toggleViewMode,
        isImagePreviewOpen: state.isImagePreviewOpen,
        onToggleImagePreview: _toggleImagePreviewPanel,
        onImportFiles: _handleImportFiles,
        onImportFolder: _handleImportFolder,
        onBackPressed: () {
          CrossNavigationHelper.handleBackNavigation(context, ref);
        },
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 800,
          minHeight: 600,
        ),
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: Row(
                children: [
                  // 主内容区域: 图库检索面板
                  Expanded(
                    child: M3LibraryBrowsingPanel(
                      enableFileDrop: true,
                      enableMultiSelect: state.isBatchMode, // 只在批量操作模式时启用多选
                      onItemSelected:
                          _handleImageSelected, // Add handler for image selection
                      imagePreviewVisible: isImagePreviewVisible,
                      onToggleImagePreview: _toggleImagePreviewPanel,
                      selectedItem: state.selectedItem,
                    ),
                  ),

                  // 右侧详情面板
                  if (state.selectedItem != null && state.isDetailOpen)
                    SizedBox(
                      width: 350,
                      child: M3LibraryDetailPanel(
                        item: state.selectedItem!,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 确保初始加载
    Future.microtask(() {
      ref.read(libraryManagementProvider.notifier).loadData();
    });
  }

  /// 处理取消选择
  void _handleCancelSelection() {
    if (!mounted) return;
    ref.read(libraryManagementProvider.notifier).clearSelection();
  }

  /// 处理复制选中项目
  void _handleCopySelectedItems() async {
    // 调用复制功能
    await ref
        .read(libraryManagementProvider.notifier)
        .copySelectedItemsToClipboard();

    // 显示成功提示
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${l10n.selectedCount(ref.read(libraryManagementProvider).selectedItems.length)} 已复制到剪贴板'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 处理剪切选中项目
  void _handleCutSelectedItems() async {
    // 调用剪切功能
    await ref
        .read(libraryManagementProvider.notifier)
        .cutSelectedItemsToClipboard();

    // 显示成功提示
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${l10n.selectedCount(ref.read(libraryManagementProvider).selectedItems.length)} 已剪切到剪贴板'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 处理删除所有项目
  void _handleDeleteAllItems() {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final state = ref.read(libraryManagementProvider);

    if (state.items.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteAll),
        content: Text(l10n.batchDeleteMessage(state.items.length)),
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
                    .deleteAllItemsUnderFilter();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.confirm),
          ),
        ],
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
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteMessage),
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
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _handleImageSelected(LibraryItem item) {
    // Save the selected item for reference
    ref.read(libraryManagementProvider.notifier).setDetailItem(item);

    // Automatically show the preview panel if an image is selected
    if (!ref.read(imagePreviewVisibleProvider)) {
      // Toggle both providers to keep them in sync
      ref.read(imagePreviewVisibleProvider.notifier).state = true;
      ref.read(libraryManagementProvider.notifier).toggleImagePreviewPanel();
    }
  }

  /// 处理导入文件
  Future<void> _handleImportFiles() async {
    final l10n = AppLocalizations.of(context);
    try {
      final importService = ref.read(libraryImportServiceProvider);

      // 使用FilePicker选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        if (!mounted) return;

        // 显示导入进度对话框
        await _showImportProgressDialog(context, () async {
          for (final file in result.files) {
            if (file.path != null) {
              await importService.importFile(file.path!);
            }
          }

          // 刷新数据
          await ref.read(libraryManagementProvider.notifier).loadData();
          await ref
              .read(libraryManagementProvider.notifier)
              .loadCategoryItemCounts();
        }); // 显示导入成功消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.importSuccessMessage(result.files.length)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 处理导入文件夹
  Future<void> _handleImportFolder() async {
    final l10n = AppLocalizations.of(context);
    try {
      final importService = ref.read(libraryImportServiceProvider);

      // 使用FilePicker选择文件夹
      final result = await FilePicker.platform.getDirectoryPath();

      if (result != null) {
        if (!mounted) return;

        // 显示导入进度对话框
        await _showImportProgressDialog(context, () async {
          await importService.importDirectory(
            result,
            recursive: true,
          );

          // 刷新数据
          await ref.read(libraryManagementProvider.notifier).loadData();
          await ref
              .read(libraryManagementProvider.notifier)
              .loadCategoryItemCounts();
        }); // 显示导入成功消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.folderImportComplete),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 处理从分类中移除选中项目
  void _handleRemoveFromCategory(String categoryId) {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final state = ref.read(libraryManagementProvider);

    if (state.selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeFromCategory),
        content:
            Text(l10n.confirmRemoveFromCategory(state.selectedItems.length)),
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
                    .removeSelectedItemsFromCategory(categoryId);
              }
            },
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
  }

  /// 处理全选操作
  void _handleSelectAll() {
    if (!mounted) return;
    ref.read(libraryManagementProvider.notifier).selectAllItems();
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

  /// 显示导入进度对话框
  Future<void> _showImportProgressDialog(
      BuildContext context, Future<void> Function() importFunction) async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    BuildContext? dialogBuilderContext;

    // 显示加载对话框
    showDialog(
      context: context,
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
                Text(l10n.importing),
              ],
            ),
          ),
        );
      },
    );

    // 创建一个安全关闭对话框的函数
    void closeDialog() {
      try {
        if (mounted && dialogBuilderContext != null) {
          Navigator.of(dialogBuilderContext!).pop();
          dialogBuilderContext = null;
        }
      } catch (e) {
        AppLogger.error('Error closing dialog: $e');
      }
    }

    try {
      // 执行导入函数
      await importFunction();

      // 关闭对话框
      closeDialog();
    } catch (e) {
      // 出错时关闭对话框
      closeDialog();
      rethrow;
    }
  }

  void _toggleBatchMode() {
    ref.read(libraryManagementProvider.notifier).toggleBatchMode();
  }

  void _toggleImagePreviewPanel() {
    // Toggle the local provider
    final newValue = !ref.read(imagePreviewVisibleProvider);
    ref.read(imagePreviewVisibleProvider.notifier).state = newValue;

    // Also toggle the main state provider to keep them in sync
    ref.read(libraryManagementProvider.notifier).toggleImagePreviewPanel();
  }

  void _toggleViewMode() {
    ref.read(libraryManagementProvider.notifier).toggleViewMode();
  }
}
