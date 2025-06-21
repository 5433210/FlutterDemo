import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

import '../../providers/batch_selection_provider.dart';
import '../../../infrastructure/logging/logger.dart';

/// 批量操作工具栏
class BatchOperationsToolbar extends ConsumerWidget {
  /// 页面类型
  final PageType pageType;
  
  /// 总项目数量
  final int totalItems;
  
  /// 导入回调
  final VoidCallback? onImport;
  
  /// 批量导入回调
  final VoidCallback? onBatchImport;
  
  /// 导出回调
  final VoidCallback? onExport;
  
  /// 删除回调
  final VoidCallback? onDelete;
  
  /// 全选回调
  final VoidCallback? onSelectAll;
  
  /// 取消选择回调
  final VoidCallback? onClearSelection;

  const BatchOperationsToolbar({
    super.key,
    required this.pageType,
    required this.totalItems,
    this.onImport,
    this.onBatchImport,
    this.onExport,
    this.onDelete,
    this.onSelectAll,
    this.onClearSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final batchState = ref.watch(batchSelectionProvider);
    final batchNotifier = ref.read(batchSelectionProvider.notifier);
    final operationsAvailable = ref.watch(batchOperationsAvailableProvider);
    final selectionSummary = ref.watch(selectionSummaryProvider);

    // 确保页面类型匹配
    if (batchState.pageType != pageType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        batchNotifier.setPageType(pageType);
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: batchState.isBatchMode
          ? _buildBatchModeToolbar(context, l10n, batchState, batchNotifier, operationsAvailable, selectionSummary)
          : _buildNormalModeToolbar(context, l10n, batchNotifier),
    );
  }

  /// 构建普通模式工具栏
  Widget _buildNormalModeToolbar(
    BuildContext context,
    AppLocalizations l10n,
    BatchSelectionNotifier batchNotifier,
  ) {
    return Row(
      children: [
        // 导入按钮
        if (onImport != null)
          ElevatedButton.icon(
            onPressed: () {
              AppLogger.info(
                '点击导入按钮',
                data: {
                  'pageType': pageType.name,
                  'totalItems': totalItems,
                },
                tag: 'batch_operations',
              );
              onImport?.call();
            },
            icon: const Icon(Icons.file_upload),
            label: Text(l10n.import),
          ),
        
        const SizedBox(width: 12),
        
        // 批量模式按钮
        OutlinedButton.icon(
          onPressed: () {
            AppLogger.info(
              '启用批量模式',
              data: {
                'pageType': pageType.name,
                'totalItems': totalItems,
              },
              tag: 'batch_operations',
            );
            batchNotifier.toggleBatchMode();
          },
          icon: const Icon(Icons.checklist),
          label: Text(l10n.batchMode),
        ),
        
        const Spacer(),
        
        // 项目计数
        Text(
          _getItemCountText(l10n),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 构建批量模式工具栏
  Widget _buildBatchModeToolbar(
    BuildContext context,
    AppLocalizations l10n,
    BatchSelectionState batchState,
    BatchSelectionNotifier batchNotifier,
    Map<BatchOperation, bool> operationsAvailable,
    String selectionSummary,
  ) {
    return Column(
      children: [
        // 第一行：导入和批量模式切换
        Row(
          children: [
            // 导入按钮
            if (onImport != null)
              ElevatedButton.icon(
                onPressed: () {
                  AppLogger.info(
                    '批量模式下点击导入按钮',
                    data: {
                      'pageType': pageType.name,
                      'selectedCount': batchState.selectedCount,
                    },
                    tag: 'batch_operations',
                  );
                  onImport?.call();
                },
                icon: const Icon(Icons.file_upload),
                label: Text(l10n.import),
              ),
            
            const SizedBox(width: 12),
            
            // 退出批量模式按钮
            OutlinedButton.icon(
              onPressed: () {
                AppLogger.info(
                  '退出批量模式',
                  data: {
                    'pageType': pageType.name,
                    'selectedCount': batchState.selectedCount,
                  },
                  tag: 'batch_operations',
                );
                batchNotifier.toggleBatchMode();
              },
              icon: const Icon(Icons.close),
              label: Text(l10n.exitBatchMode),
            ),
            
            const Spacer(),
            
            // 项目计数
            Text(
              _getItemCountText(l10n),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 第二行：选择状态和批量操作按钮
        Row(
          children: [
            // 选择状态文本
            Expanded(
              child: Text(
                selectionSummary.isEmpty ? l10n.noItemsSelected : selectionSummary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: batchState.hasSelection 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            
            // 批量操作按钮组
            if (batchState.hasSelection) ...[
              // 批量导入按钮（仅在有选择时显示）
              if (onBatchImport != null)
                TextButton.icon(
                  onPressed: () {
                    AppLogger.info(
                      '点击批量导入按钮',
                      data: {
                        'pageType': pageType.name,
                        'selectedCount': batchState.selectedCount,
                      },
                      tag: 'batch_operations',
                    );
                    onBatchImport?.call();
                  },
                  icon: const Icon(Icons.file_download_outlined),
                  label: Text(l10n.batchImport),
                ),
              
              const SizedBox(width: 8),
              
              // 全选按钮
              TextButton.icon(
                onPressed: batchState.isAllSelected ? null : () {
                  AppLogger.info(
                    '点击全选按钮',
                    data: {
                      'pageType': pageType.name,
                      'totalItems': totalItems,
                      'currentSelected': batchState.selectedCount,
                    },
                    tag: 'batch_operations',
                  );
                  onSelectAll?.call();
                },
                icon: Icon(
                  batchState.isAllSelected 
                      ? Icons.check_box 
                      : Icons.check_box_outline_blank,
                ),
                label: Text(l10n.selectAll),
              ),
              
              const SizedBox(width: 8),
              
              // 取消选择按钮
              TextButton.icon(
                onPressed: () {
                  AppLogger.info(
                    '点击取消选择按钮',
                    data: {
                      'pageType': pageType.name,
                      'selectedCount': batchState.selectedCount,
                    },
                    tag: 'batch_operations',
                  );
                  onClearSelection?.call();
                },
                icon: const Icon(Icons.clear),
                label: Text(l10n.clearSelection),
              ),
              
              const SizedBox(width: 8),
              
              // 导出按钮
              TextButton.icon(
                onPressed: operationsAvailable[BatchOperation.export] == true ? () {
                  AppLogger.info(
                    '点击导出按钮',
                    data: {
                      'pageType': pageType.name,
                      'selectedCount': batchState.selectedCount,
                    },
                    tag: 'batch_operations',
                  );
                  onExport?.call();
                } : null,
                icon: const Icon(Icons.file_download),
                label: Text(l10n.export),
              ),
              
              const SizedBox(width: 8),
              
              // 删除按钮
              TextButton.icon(
                onPressed: operationsAvailable[BatchOperation.delete] == true ? () {
                  AppLogger.info(
                    '点击删除按钮',
                    data: {
                      'pageType': pageType.name,
                      'selectedCount': batchState.selectedCount,
                    },
                    tag: 'batch_operations',
                  );
                  onDelete?.call();
                } : null,
                icon: const Icon(Icons.delete),
                label: Text(l10n.delete),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ] else ...[
              // 无选择时的提示
              TextButton.icon(
                onPressed: () {
                  AppLogger.debug(
                    '点击全选按钮（无选择状态）',
                    data: {
                      'pageType': pageType.name,
                      'totalItems': totalItems,
                    },
                    tag: 'batch_operations',
                  );
                  onSelectAll?.call();
                },
                icon: const Icon(Icons.check_box_outline_blank),
                label: Text(l10n.selectAll),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 获取项目计数文本
  String _getItemCountText(AppLocalizations l10n) {
    switch (pageType) {
      case PageType.works:
        return l10n.worksCount(totalItems);
      case PageType.characters:
        return l10n.charactersCount(totalItems);
    }
  }
}

/// 批量操作工具栏配置
class BatchOperationsConfig {
  /// 是否显示导入按钮
  final bool showImport;
  
  /// 是否显示批量导入按钮
  final bool showBatchImport;
  
  /// 是否显示导出按钮
  final bool showExport;
  
  /// 是否显示删除按钮
  final bool showDelete;
  
  /// 自定义按钮列表
  final List<BatchOperationButton> customButtons;

  const BatchOperationsConfig({
    this.showImport = true,
    this.showBatchImport = true,
    this.showExport = true,
    this.showDelete = true,
    this.customButtons = const [],
  });
}

/// 自定义批量操作按钮
class BatchOperationButton {
  /// 按钮图标
  final IconData icon;
  
  /// 按钮文本
  final String label;
  
  /// 点击回调
  final VoidCallback onPressed;
  
  /// 是否需要选择项目才能启用
  final bool requiresSelection;
  
  /// 按钮颜色
  final Color? color;

  const BatchOperationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.requiresSelection = true,
    this.color,
  });
} 