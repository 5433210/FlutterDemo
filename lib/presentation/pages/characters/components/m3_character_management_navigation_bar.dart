import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/import_export_providers.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/batch_selection_provider.dart';
import '../../../widgets/batch_operations/export_dialog.dart';
import '../../../widgets/batch_operations/import_dialog.dart';
import '../../../widgets/batch_operations/progress_dialog.dart';
import '../../../widgets/common/m3_page_navigation_bar.dart';

class M3CharacterManagementNavigationBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final bool isBatchMode;
  final VoidCallback onToggleBatchMode;
  final int selectedCount;
  final Set<String> selectedCharacterIds;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onCopySelected;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final bool isGridView;
  final VoidCallback onToggleViewMode;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;
  final VoidCallback? onBackPressed;
  final VoidCallback? onImport;

  const M3CharacterManagementNavigationBar({
    super.key,
    required this.isBatchMode,
    required this.onToggleBatchMode,
    required this.selectedCount,
    required this.selectedCharacterIds,
    this.onDeleteSelected,
    this.onCopySelected,
    this.onSelectAll,
    this.onClearSelection,
    required this.isGridView,
    required this.onToggleViewMode,
    required this.onSearch,
    required this.searchController,
    this.onBackPressed,
    this.onImport,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  ConsumerState<M3CharacterManagementNavigationBar> createState() =>
      _M3CharacterManagementNavigationBarState();
}

class _M3CharacterManagementNavigationBarState
    extends ConsumerState<M3CharacterManagementNavigationBar> {
  void _showExportDialog() {
    final l10n = AppLocalizations.of(context);

    final services = ref.read(batchOperationsServicesProvider);
    if (!services.isReady) {
      AppLogger.warning(
        '导出服务未就绪',
        data: services.serviceStatus,
        tag: 'character_management_navigation',
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
      '显示集字批量导出对话框',
      data: {
        'selectedCount': widget.selectedCount,
        'serviceReady': services.isReady,
      },
      tag: 'character_management_navigation',
    );

    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        pageType: PageType.characters,
        selectedIds: widget.selectedCharacterIds.toList(),
        onExport: (options, targetPath) async {
          // 显示进度对话框
          final progressController = ProgressDialogController();

          final progressFuture = ControlledProgressDialog.show(
            context: context,
            title: l10n.export,
            controller: progressController,
            initialMessage: l10n.exporting,
            canCancel: false,
          );

          try {
            AppLogger.info(
              '开始执行集字导出',
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
              tag: 'character_management_navigation',
            );

            final exportService = services.exportService;
            await exportService.exportCharacters(
              widget.selectedCharacterIds.toList(),
              options.type, // 使用用户选择的导出类型
              options,
              targetPath,
              progressCallback: (progress, message, data) {
                progressController.updateProgress(progress, message, data);

                AppLogger.debug(
                  '集字导出进度更新',
                  data: {
                    'progress': progress,
                    'message': message,
                    'additionalData': data,
                  },
                  tag: 'character_management_navigation',
                );
              },
            );

            progressController.complete(l10n.exportSuccess);

            AppLogger.info(
              '集字导出成功完成',
              data: {
                'targetPath': targetPath,
                'selectedCount': widget.selectedCount,
              },
              tag: 'character_management_navigation',
            );

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
                        AppLogger.info(
                          '用户请求查看导出文件',
                          data: {'targetPath': targetPath},
                          tag: 'character_management_navigation',
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
                  tag: 'character_management_navigation',
                );
              }
            }
          } catch (e, stackTrace) {
            progressController.showError(l10n.exportFailedWith(e.toString()));

            AppLogger.error(
              'Character export failed',
              error: e,
              stackTrace: stackTrace,
              data: {
                'targetPath': targetPath,
                'selectedCount': widget.selectedCount,
              },
              tag: 'character_management_navigation',
            );

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
                  tag: 'character_management_navigation',
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

    final services = ref.read(batchOperationsServicesProvider);
    if (!services.isReady) {
      AppLogger.warning(
        '导入服务未就绪',
        data: services.serviceStatus,
        tag: 'character_management_navigation',
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
      '显示集字批量导入对话框',
      tag: 'character_management_navigation',
    );

    showDialog(
      context: context,
      builder: (context) => ImportDialog(
        pageType: PageType.characters,
        onImport: (options, filePath) async {
          // 显示进度对话框
          final progressController = ProgressDialogController();

          final progressFuture = ControlledProgressDialog.show(
            context: context,
            title: l10n.import,
            controller: progressController,
            initialMessage: l10n.importing,
            canCancel: false,
          );

          try {
            AppLogger.info(
              '开始执行集字导入',
              data: {
                'filePath': filePath,
                'options': {
                  'conflictResolution': options.defaultConflictResolution.name,
                  'validateFileIntegrity': options.validateFileIntegrity,
                  'createBackup': options.createBackup,
                },
              },
              tag: 'character_management_navigation',
            );

            final importService = services.importService; // 第一步：验证文件
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
              'characterCount': importData.exportData.characters.length,
            });

            final importResult = await importService.performImport(
              importData,
              sourceFilePath: filePath,
            );

            if (!importResult.success) {
              throw Exception(importResult.errors.join(', '));
            }

            // 完成
            progressController.complete(l10n.importSuccess);

            AppLogger.info(
              '集字导入成功完成',
              data: {
                'filePath': filePath,
                'importedWorks': importResult.importedWorks,
                'importedCharacters': importResult.importedCharacters,
                'importedImages': importResult.importedImages,
                'skippedItems': importResult.skippedItems,
              },
              tag: 'character_management_navigation',
            );

            await progressFuture;

            // 使用延迟检查确保组件仍然活跃
            if (mounted && context.mounted) {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.importSuccess),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: l10n.showDetails,
                      onPressed: () {
                        AppLogger.info(
                          '用户请求查看导入结果',
                          data: {'filePath': filePath},
                          tag: 'character_management_navigation',
                        );
                      },
                    ),
                  ),
                );

                // 触发页面刷新
                widget.onImport?.call();
              } catch (e) {
                // 如果显示SnackBar失败，记录日志但不重新抛出异常
                AppLogger.warning(
                  '显示导入成功消息失败，可能是因为页面已关闭',
                  data: {'error': e.toString()},
                  tag: 'character_management_navigation',
                );

                // 即使SnackBar显示失败，仍然尝试触发页面刷新
                try {
                  widget.onImport?.call();
                } catch (refreshError) {
                  AppLogger.warning(
                    '触发页面刷新失败',
                    data: {'error': refreshError.toString()},
                    tag: 'character_management_navigation',
                  );
                }
              }
            }
          } catch (e, stackTrace) {
            progressController.showError(l10n.importFailed(e.toString()));

            AppLogger.error(
              'Character import failed',
              error: e,
              stackTrace: stackTrace,
              data: {
                'filePath': filePath,
              },
              tag: 'character_management_navigation',
            );

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
                      onPressed: () => _showImportDialog(),
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
                  tag: 'character_management_navigation',
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
      title: l10n.characterCollection,
      onBackPressed: widget.onBackPressed,
      titleActions: widget.isBatchMode
          ? [
              const SizedBox(width: AppSizes.m),
              Text(
                l10n.selectedCount(widget.selectedCount),
                style: theme.textTheme.bodyMedium,
              ),
            ]
          : null,
      actions: [
        if (widget.isBatchMode && widget.selectedCount > 0) ...[
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: l10n.export,
            onPressed: _showExportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: l10n.deleteSelected,
            onPressed: widget.onDeleteSelected,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: l10n.copy,
            onPressed: widget.onCopySelected,
          ),
        ] else if (!widget.isBatchMode) ...[
          // 导入按钮
          FilledButton.icon(
            icon: const Icon(Icons.file_upload),
            label: Text(l10n.import),
            onPressed: _showImportDialog,
          ),
        ],
        if (widget.isBatchMode) ...[
          if (widget.onSelectAll != null)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: l10n.selectAll,
              onPressed: widget.onSelectAll,
            ),
          if (widget.selectedCount > 0 && widget.onClearSelection != null)
            IconButton(
              icon: const Icon(Icons.deselect),
              tooltip: l10n.deselectAll,
              onPressed: widget.onClearSelection,
            ),
        ],
        const SizedBox(width: AppSizes.s),
        IconButton(
          icon: Icon(widget.isBatchMode ? Icons.close : Icons.checklist),
          tooltip:
              widget.isBatchMode ? l10n.exitBatchMode : l10n.batchOperations,
          onPressed: widget.onToggleBatchMode,
        ),
        const SizedBox(width: AppSizes.s),
        IconButton(
          icon: Icon(widget.isGridView ? Icons.view_list : Icons.grid_view),
          tooltip: widget.isGridView ? l10n.listView : l10n.gridView,
          onPressed: widget.onToggleViewMode,
        ),
      ],
    );
  }
}
