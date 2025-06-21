import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

import '../../providers/batch_selection_provider.dart';
import '../../../domain/models/import_export/export_data_model.dart';
import '../../../domain/models/import_export/import_data_model.dart';
import '../../../infrastructure/logging/logger.dart';

import 'batch_operations_toolbar.dart';
import 'export_dialog.dart';
import 'import_dialog.dart';
import 'progress_dialog.dart';

/// 批量操作示例页面
/// 展示如何在作品浏览页或集字管理页中集成批量操作功能
class BatchOperationsExamplePage extends ConsumerStatefulWidget {
  /// 页面类型
  final PageType pageType;
  
  /// 页面标题
  final String title;

  const BatchOperationsExamplePage({
    super.key,
    required this.pageType,
    required this.title,
  });

  @override
  ConsumerState<BatchOperationsExamplePage> createState() => _BatchOperationsExamplePageState();
}

class _BatchOperationsExamplePageState extends ConsumerState<BatchOperationsExamplePage> {
  // 模拟数据
  final List<String> _mockItems = List.generate(20, (index) => 'Item ${index + 1}');

  @override
  void initState() {
    super.initState();
    
    // 设置页面类型
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(batchSelectionProvider.notifier).setPageType(widget.pageType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final batchState = ref.watch(batchSelectionProvider);
    final batchNotifier = ref.read(batchSelectionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // 批量操作工具栏
          BatchOperationsToolbar(
            pageType: widget.pageType,
            totalItems: _mockItems.length,
            onImport: _handleImport,
            onBatchImport: _handleBatchImport,
            onExport: batchState.hasSelection ? _handleExport : null,
            onDelete: batchState.hasSelection ? _handleDelete : null,
            onSelectAll: _handleSelectAll,
            onClearSelection: _handleClearSelection,
          ),
          
          // 项目列表
          Expanded(
            child: ListView.builder(
              itemCount: _mockItems.length,
              itemBuilder: (context, index) {
                final itemId = 'item_$index';
                final isSelected = widget.pageType == PageType.works 
                    ? batchState.selectedWorkIds.contains(itemId)
                    : batchState.selectedCharacterIds.contains(itemId);
                
                return ListTile(
                  leading: batchState.isBatchMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            if (widget.pageType == PageType.works) {
                              batchNotifier.toggleWorkSelection(itemId);
                            } else {
                              batchNotifier.toggleCharacterSelection(itemId);
                            }
                          },
                        )
                      : const Icon(Icons.article),
                  title: Text(_mockItems[index]),
                  subtitle: Text('${widget.pageType.name} ${index + 1}'),
                  onTap: batchState.isBatchMode
                      ? () {
                          if (widget.pageType == PageType.works) {
                            batchNotifier.toggleWorkSelection(itemId);
                          } else {
                            batchNotifier.toggleCharacterSelection(itemId);
                          }
                        }
                      : () {
                          // 普通模式下的点击处理
                          AppLogger.debug(
                            '点击项目',
                            data: {
                              'itemId': itemId,
                              'pageType': widget.pageType.name,
                            },
                            tag: 'batch_operations_example',
                          );
                        },
                  selected: isSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 处理导入
  void _handleImport() {
    showDialog(
      context: context,
      builder: (context) => ImportDialog(
        pageType: widget.pageType,
        onImport: _executeImport,
      ),
    );
  }

  /// 处理批量导入
  void _handleBatchImport() {
    final l10n = AppLocalizations.of(context)!;
    
    // 显示批量导入确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.batchImport),
        content: const Text('Confirm batch import?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleImport(); // 复用导入逻辑
            },
            child: Text(l10n.import),
          ),
        ],
      ),
    );
  }

  /// 处理导出
  void _handleExport() {
    final batchState = ref.read(batchSelectionProvider);
    final selectedIds = widget.pageType == PageType.works 
        ? batchState.selectedWorkIds.toList()
        : batchState.selectedCharacterIds.toList();
    
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        pageType: widget.pageType,
        selectedIds: selectedIds,
        onExport: _executeExport,
      ),
    );
  }

  /// 处理删除
  void _handleDelete() {
    final l10n = AppLocalizations.of(context)!;
    final batchState = ref.read(batchSelectionProvider);
    final selectedCount = batchState.selectedCount;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text('Delete $selectedCount items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executeDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  /// 处理全选
  void _handleSelectAll() {
    final batchNotifier = ref.read(batchSelectionProvider.notifier);
    final allItemIds = List.generate(_mockItems.length, (index) => 'item_$index');
    
    batchNotifier.selectAll(allItemIds);
    
    AppLogger.info(
      '全选项目',
      data: {
        'pageType': widget.pageType.name,
        'totalItems': _mockItems.length,
      },
      tag: 'batch_operations_example',
    );
  }

  /// 处理取消选择
  void _handleClearSelection() {
    final batchNotifier = ref.read(batchSelectionProvider.notifier);
    batchNotifier.clearSelection();
    
    AppLogger.info(
      '清除选择',
      data: {
        'pageType': widget.pageType.name,
      },
      tag: 'batch_operations_example',
    );
  }

  /// 执行导入
  void _executeImport(ImportOptions options, String filePath) {
    AppLogger.info(
      '开始执行导入',
      data: {
        'pageType': widget.pageType.name,
        'filePath': filePath,
        'options': {
          'defaultConflictResolution': options.defaultConflictResolution.name,
          'createBackup': options.createBackup,
          'validateFileIntegrity': options.validateFileIntegrity,
        },
      },
      tag: 'batch_operations_example',
    );
    
    // 显示进度对话框
    _showImportProgress();
  }

  /// 执行导出
  void _executeExport(ExportOptions options, String targetPath) {
    final batchState = ref.read(batchSelectionProvider);
    
    AppLogger.info(
      '开始执行导出',
      data: {
        'pageType': widget.pageType.name,
        'selectedCount': batchState.selectedCount,
        'targetPath': targetPath,
        'options': {
          'type': options.type.name,
          'format': options.format.name,
          'includeImages': options.includeImages,
          'includeMetadata': options.includeMetadata,
          'compressData': options.compressData,
        },
      },
      tag: 'batch_operations_example',
    );
    
    // 显示进度对话框
    _showExportProgress();
  }

  /// 执行删除
  void _executeDelete() {
    final batchState = ref.read(batchSelectionProvider);
    final batchNotifier = ref.read(batchSelectionProvider.notifier);
    
    AppLogger.info(
      '开始执行删除',
      data: {
        'pageType': widget.pageType.name,
        'selectedCount': batchState.selectedCount,
        'selectedItems': widget.pageType == PageType.works 
            ? batchState.selectedWorkIds.toList()
            : batchState.selectedCharacterIds.toList(),
      },
      tag: 'batch_operations_example',
    );
    
    // 模拟删除操作
    // 在实际应用中，这里应该调用相应的服务方法
    
    // 清除选择并显示成功消息
    batchNotifier.clearSelection();
    
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deleteSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  /// 显示导入进度
  void _showImportProgress() {
    final controller = ProgressDialogController();
    
    ControlledProgressDialog.show(
      context: context,
      title: '导入进度',
      controller: controller,
      initialMessage: '正在验证数据...',
      canCancel: true,
    );
    
    // 模拟进度更新
    _simulateProgress(controller: controller, isImport: true);
  }

  /// 显示导出进度
  void _showExportProgress() {
    final batchState = ref.read(batchSelectionProvider);
    final controller = ProgressDialogController();
    
    ControlledProgressDialog.show(
      context: context,
      title: '导出进度',
      controller: controller,
      initialMessage: '正在准备导出...',
      canCancel: true,
    );
    
    // 模拟进度更新
    _simulateProgress(controller: controller, isImport: false);
  }

  /// 模拟进度更新
  void _simulateProgress({required ProgressDialogController controller, required bool isImport}) {
    final l10n = AppLocalizations.of(context)!;
    int currentStep = 0;
    final totalSteps = isImport ? 10 : ref.read(batchSelectionProvider).selectedCount;
    
    // 模拟进度更新
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      currentStep++;
      
      final progress = currentStep / totalSteps;
      final message = isImport ? '正在导入第 $currentStep 项...' : '正在导出第 $currentStep 项...';
      
      if (currentStep <= totalSteps && mounted) {
        // 更新进度
        controller.updateProgress(progress, message, {
          'currentStep': currentStep,
          'totalSteps': totalSteps,
          'operation': isImport ? 'import' : 'export',
        });
        return true;
      } else {
        // 完成操作
        controller.complete(isImport ? '导入完成' : '导出完成');
        
        if (mounted) {
          // 显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isImport ? l10n.importSuccess : l10n.exportSuccess),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          
          // 如果是导出，清除选择
          if (!isImport) {
            ref.read(batchSelectionProvider.notifier).clearSelection();
          }
        }
        
        // 清理控制器
        controller.dispose();
        return false;
      }
    });
  }
}

/// 批量操作示例应用
class BatchOperationsExampleApp extends StatelessWidget {
  const BatchOperationsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Batch Operations Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const BatchOperationsExampleHome(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}

/// 示例应用主页
class BatchOperationsExampleHome extends StatelessWidget {
  const BatchOperationsExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Operations Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BatchOperationsExamplePage(
                      pageType: PageType.works,
                      title: 'Works Management',
                    ),
                  ),
                );
              },
              child: Text(l10n.workBrowseTitle),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BatchOperationsExamplePage(
                      pageType: PageType.characters,
                      title: 'Characters Management',
                    ),
                  ),
                );
              },
              child: const Text('Characters Management'),
            ),
          ],
        ),
      ),
    );
  }
} 