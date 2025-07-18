import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/import_export_providers.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/batch_selection_provider.dart';
import '../../../providers/works_providers.dart';
import '../../../viewmodels/states/work_browse_state.dart';
import '../../../widgets/batch_operations/export_dialog.dart';
import '../../../widgets/batch_operations/import_dialog.dart';
import '../../../widgets/batch_operations/progress_dialog.dart';
import '../../../widgets/common/m3_page_navigation_bar.dart';

class M3WorkBrowseNavigationBar extends ConsumerStatefulWidget {
  final ViewMode viewMode;
  final Function(ViewMode) onViewModeChanged;
  final VoidCallback onImport;
  final Function(String) onSearch;
  final bool batchMode;
  final Function(bool) onBatchModeChanged;
  final int selectedCount;
  final Set<String> selectedWorkIds; // 实际选中的作品ID
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onBackPressed;
  final VoidCallback? onAddWork; // 新增：创建新作品的回调
  final List<String>? allWorkIds; // 新增：所有作品ID列表，用于全选
  final VoidCallback? onSelectAll; // 新增：全选回调
  final VoidCallback? onClearSelection; // 新增：取消选择回调

  const M3WorkBrowseNavigationBar({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onImport,
    required this.onSearch,
    required this.batchMode,
    required this.onBatchModeChanged,
    required this.selectedCount,
    required this.selectedWorkIds,
    this.onDeleteSelected,
    this.onBackPressed,
    this.onAddWork, // 新增参数
    this.allWorkIds, // 新增参数
    this.onSelectAll, // 新增参数
    this.onClearSelection, // 新增参数
  });

  @override
  ConsumerState<M3WorkBrowseNavigationBar> createState() =>
      _M3WorkBrowseNavigationBarState();
}

class _M3WorkBrowseNavigationBarState
    extends ConsumerState<M3WorkBrowseNavigationBar> {
  void _showDeleteConfirmation() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.batchDeleteMessage(widget.selectedCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDeleteSelected?.call();
            },
            child: Text(l10n.confirmDelete),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    final l10n = AppLocalizations.of(context);

    // 检查服务是否就绪
    final services = ref.read(batchOperationsServicesProvider);
    if (!services.isReady) {
      AppLogger.warning(
        '导出服务未就绪',
        data: services.serviceStatus,
        tag: 'work_browse_navigation',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.serviceNotReady),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    AppLogger.info(
      '显示批量导出对话框',
      data: {
        'selectedCount': widget.selectedCount,
        'serviceReady': services.isReady,
      },
      tag: 'work_browse_navigation',
    );

    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        pageType: PageType.works,
        selectedIds: widget.selectedWorkIds.toList(), // 使用实际选中的作品ID
        onExport: (options, targetPath) async {
          // 显示进度对话框
          final progressController = ProgressDialogController();

          // 显示进度对话框，不等待用户交互
          final progressFuture = ControlledProgressDialog.show(
            context: context,
            title: l10n.export,
            controller: progressController,
            initialMessage: l10n.exporting,
            canCancel: false,
          );

          try {
            AppLogger.info(
              '开始执行作品导出',
              data: {
                'targetPath': targetPath,
                'selectedCount': widget.selectedCount,
                'options': {
                  'type': options.type.name,
                  'format': options.format.name,
                  'includeImages': options.includeImages,
                  'includeMetadata': options.includeMetadata,
                },
              },
              tag: 'work_browse_navigation',
            );

            final exportService = services.exportService;
            await exportService.exportWorks(
              widget.selectedWorkIds.toList(), // 使用实际的作品ID列表
              options.type, // 使用用户选择的导出类型
              options,
              targetPath,
              progressCallback: (progress, message, data) {
                // 实时更新进度
                progressController.updateProgress(progress, message, data);

                AppLogger.debug(
                  '导出进度更新',
                  data: {
                    'progress': progress,
                    'message': message,
                    'additionalData': data,
                  },
                  tag: 'work_browse_navigation',
                );
              },
            );

            // 标记完成
            progressController.complete(l10n.exportSuccess);

            AppLogger.info(
              '作品导出成功完成',
              data: {
                'targetPath': targetPath,
                'selectedCount': widget.selectedCount,
              },
              tag: 'work_browse_navigation',
            );

            // 等待进度对话框关闭，然后显示成功消息
            await progressFuture;

            // 使用延迟检查确保组件仍然活跃
            if (mounted && context.mounted) {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.exportSuccess),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: '查看文件',
                      onPressed: () {
                        // 这里可以添加打开文件位置的功能
                        AppLogger.info(
                          '用户请求查看导出文件',
                          data: {'targetPath': targetPath},
                          tag: 'work_browse_navigation',
                        );
                      },
                    ),
                  ),
                );
              } catch (e) {
                // 如果显示SnackBar失败，记录日志但不重新抛出异常
                AppLogger.warning(
                  '显示导出成功消息失败，可能是因为页面已关闭',
                  data: {'error': e.toString()},
                  tag: 'work_browse_navigation',
                );
              }
            }
          } catch (e, stackTrace) {
            // 显示错误
            progressController.showError('导出失败: ${e.toString()}');

            AppLogger.error(
              '作品导出失败',
              error: e,
              stackTrace: stackTrace,
              data: {
                'targetPath': targetPath,
                'selectedCount': widget.selectedCount,
              },
              tag: 'work_browse_navigation',
            );

            // 等待错误对话框关闭
            await progressFuture;

            // 使用延迟检查确保组件仍然活跃
            if (mounted && context.mounted) {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n.exportFailed}: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: l10n.retry,
                      onPressed: () => _showExportDialog(),
                    ),
                  ),
                );
              } catch (snackBarError) {
                // 如果显示SnackBar失败，记录日志但不重新抛出异常
                AppLogger.warning(
                  '显示导出失败消息失败，可能是因为页面已关闭',
                  data: {
                    'originalError': e.toString(),
                    'snackBarError': snackBarError.toString()
                  },
                  tag: 'work_browse_navigation',
                );
              }
            }
          } finally {
            progressController.dispose();
          }
        },
      ),
    );
  }

  void _showImportDialog() {
    final l10n = AppLocalizations.of(context);

    // 检查服务是否就绪
    final services = ref.read(batchOperationsServicesProvider);
    if (!services.isReady) {
      AppLogger.warning(
        '导入服务未就绪',
        data: services.serviceStatus,
        tag: 'work_browse_navigation',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.serviceNotReady),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    AppLogger.info(
      '显示批量导入对话框',
      tag: 'work_browse_navigation',
    );

    showDialog(
      context: context,
      builder: (context) => ImportDialog(
        pageType: PageType.works,
        onImport: (options, filePath) async {
          // 保存Navigator状态，用于后续对话框显示
          final navigatorState = Navigator.of(context);

          // 显示进度对话框
          final progressController = ProgressDialogController();

          // 显示进度对话框
          final progressFuture = ControlledProgressDialog.show(
            context: context,
            title: l10n.import,
            controller: progressController,
            initialMessage: l10n.importing,
            canCancel: false,
          );

          try {
            AppLogger.info(
              '开始执行作品导入',
              data: {
                'filePath': filePath,
                'options': {
                  'conflictResolution': options.defaultConflictResolution.name,
                  'validateFileIntegrity': options.validateFileIntegrity,
                  'createBackup': options.createBackup,
                },
              },
              tag: 'work_browse_navigation',
            );

            final importService = services.importService;

            // 第一步：验证文件
            progressController.updateProgress(
                0.1, l10n.validatingImportFile, null);
            final result =
                await importService.validateImportFile(filePath, options);

            if (!result.isValid) {
              throw Exception(result.messages.map((m) => m.message).join(', '));
            }

            // 第二步：解析数据
            progressController.updateProgress(
                0.3, l10n.parsingImportData, null);
            final importData =
                await importService.parseImportData(filePath, options);

            // 第三步：执行导入
            progressController
                .updateProgress(0.5, l10n.executingImportOperation, {
              'itemCount': importData.exportData.works.length,
            });

            final importResult = await importService.performImport(
              importData,
              sourceFilePath: filePath,
            );

            AppLogger.info(
              '导入结果检查',
              data: {
                'success': importResult.success,
                'importedWorks': importResult.importedWorks,
                'importedCharacters': importResult.importedCharacters,
                'importedImages': importResult.importedImages,
                'skippedItems': importResult.skippedItems,
                'errors': importResult.errors,
                'warnings': importResult.warnings,
              },
              tag: 'work_browse_navigation',
            );

            if (!importResult.success) {
              throw Exception(importResult.errors.join(', '));
            }

            AppLogger.info(
              '作品导入成功完成',
              data: {
                'filePath': filePath,
                'importedWorks': importResult.importedWorks,
                'importedCharacters': importResult.importedCharacters,
                'importedImages': importResult.importedImages,
                'skippedItems': importResult.skippedItems,
              },
              tag: 'work_browse_navigation',
            );

            // 在进度对话框中显示导入结果
            progressController.showImportResult(importResult, filePath);

            AppLogger.info(
              '已在进度对话框中显示导入结果',
              tag: 'work_browse_navigation',
            );

            // 等待进度对话框关闭
            await progressFuture;

            // 进度对话框关闭后刷新页面数据
            if (mounted) {
              ref.read(worksNeedsRefreshProvider.notifier).state =
                  RefreshInfo.importCompleted();

              AppLogger.info(
                '导入完成，已触发作品列表刷新',
                tag: 'work_browse_navigation',
              );
            }
          } catch (e, stackTrace) {
            // 显示错误
            progressController.showError('导入失败: ${e.toString()}');

            AppLogger.error(
              '作品导入失败',
              error: e,
              stackTrace: stackTrace,
              data: {
                'filePath': filePath,
              },
              tag: 'work_browse_navigation',
            );

            // 等待错误对话框关闭
            await progressFuture;

            // 使用延迟检查确保组件仍然活跃
            if (mounted && context.mounted) {
              try {
                // 根据错误类型提供更友好的消息
                String userFriendlyMessage;
                String actionLabel = '重试';
                VoidCallback? actionCallback = () => _showImportDialog();

                if (e.toString().contains('Missing extension byte') ||
                    e.toString().contains('UTF-8') ||
                    e.toString().contains('字符编码')) {
                  userFriendlyMessage =
                      '导入文件包含损坏的字符数据，可能是由于字符编码问题导致的。建议重新导出文件后再试。';
                  actionLabel = '了解更多';
                  actionCallback = () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.importError),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.importErrorCauses),
                            const SizedBox(height: 8),
                            Text(l10n.exportEncodingIssue),
                            Text(l10n.fileCorrupted),
                            Text(l10n.incompatibleCharset),
                            const SizedBox(height: 16),
                            Text(l10n.suggestedSolutions),
                            const SizedBox(height: 8),
                            Text(l10n.reExportWork),
                            Text(l10n.checkSpecialChars),
                            Text(l10n.ensureCompleteTransfer),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(l10n.close),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showImportDialog();
                            },
                            child: Text(l10n.reselectFile),
                          ),
                        ],
                      ),
                    );
                  };
                } else if (e.toString().contains('找不到导出数据文件') ||
                    e.toString().contains('ZIP文件格式无效')) {
                  userFriendlyMessage = '导入文件格式不正确或文件已损坏，请确保选择的是有效的导出文件。';
                } else if (e.toString().contains('缺少')) {
                  userFriendlyMessage = '导入文件不完整，缺少必要的数据文件。请重新导出完整的文件。';
                } else {
                  userFriendlyMessage = '导入失败: ${e.toString()}';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(userFriendlyMessage),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 6), // 给用户更多时间阅读
                    action: SnackBarAction(
                      label: actionLabel,
                      onPressed: actionCallback,
                    ),
                  ),
                );
              } catch (snackBarError) {
                // 如果显示SnackBar失败，记录日志但不重新抛出异常
                AppLogger.warning(
                  '显示导入失败消息失败，可能是因为页面已关闭',
                  data: {
                    'originalError': e.toString(),
                    'snackBarError': snackBarError.toString()
                  },
                  tag: 'work_browse_navigation',
                );
              }
            }
          } finally {
            progressController.dispose();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return M3PageNavigationBar(
      title: l10n.workBrowseTitle,
      showBackButton: true,
      onBackPressed: widget.onBackPressed,
      titleActions: widget.batchMode
          ? [
              Text(
                l10n.selectedCount(widget.selectedCount),
                style: theme.textTheme.bodyMedium,
              ),
            ]
          : null,
      actions: [
        // 批量模式下的操作按钮
        if (widget.batchMode) ...[
          // 批量模式下的选择操作按钮
          if (widget.selectedCount > 0) ...[
            // 批量导出按钮
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: l10n.export,
              onPressed: _showExportDialog,
            ),
            // 批量删除按钮
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: l10n.deleteSelected,
              onPressed: _showDeleteConfirmation,
            ),
            // 取消选择按钮
            if (widget.onClearSelection != null)
              IconButton(
                icon: const Icon(Icons.deselect),
                tooltip: l10n.deselectAll,
                onPressed: widget.onClearSelection,
              ),
          ] else ...[
            // 无选择时显示全选按钮
            if (widget.onSelectAll != null)
              IconButton(
                icon: const Icon(Icons.select_all),
                tooltip: l10n.selectAll,
                onPressed: widget.onSelectAll,
              ),
          ],
        ]
        // 非批量模式下的操作按钮
        else ...[
          // 新增作品按钮
          if (widget.onAddWork != null)
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.add),
              onPressed: widget.onAddWork,
            ),

          const SizedBox(width: AppSizes.s),

          // 导入按钮
          FilledButton.icon(
            icon: const Icon(Icons.file_upload),
            label: Text(l10n.import),
            onPressed: _showImportDialog,
          ),
        ],

        const SizedBox(width: AppSizes.s),

        // 批量模式切换按钮
        IconButton(
          icon: Icon(widget.batchMode ? Icons.close : Icons.checklist),
          tooltip: widget.batchMode ? l10n.done : l10n.batchMode,
          onPressed: () => widget.onBatchModeChanged(!widget.batchMode),
        ),

        const SizedBox(width: AppSizes.s),

        // 视图切换按钮
        IconButton(
          icon: Icon(widget.viewMode == ViewMode.grid
              ? Icons.view_list
              : Icons.grid_view),
          tooltip:
              widget.viewMode == ViewMode.grid ? l10n.listView : l10n.gridView,
          onPressed: () => widget.onViewModeChanged(
              widget.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid),
        ),
      ],
    );
  }
}
