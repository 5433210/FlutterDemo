import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

import '../../providers/batch_selection_provider.dart';
import '../../../application/services/file_picker_service.dart';
import '../../../domain/models/import_export/import_data_model.dart';
import '../../../domain/models/import_export/export_data_model.dart';
import '../../../infrastructure/logging/logger.dart';
import 'progress_dialog.dart';

/// 导入对话框
class ImportDialog extends ConsumerStatefulWidget {
  /// 页面类型
  final PageType pageType;
  
  /// 导入回调
  final Function(ImportOptions options, String filePath) onImport;

  const ImportDialog({
    super.key,
    required this.pageType,
    required this.onImport,
  });

  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> {
  String _filePath = '';
  final _pathController = TextEditingController();
  ConflictResolution _conflictResolution = ConflictResolution.skip;
  bool _validateData = true;
  bool _createBackup = true;
  bool _preserveMetadata = true;
  ImportDataModel? _previewData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    AppLogger.info(
      '打开导入对话框',
      data: {
        'pageType': widget.pageType.name,
      },
      tag: 'import_dialog',
    );
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(l10n.import),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 文件选择
              _buildFileSelectionSection(l10n),
              
              const SizedBox(height: 16),
              
              // 导入选项
              _buildImportOptionsSection(l10n),
              
              const SizedBox(height: 16),
              
              // 冲突处理
              _buildConflictResolutionSection(l10n),
              
              if (_previewData != null) ...[
                const SizedBox(height: 16),
                // 预览信息
                _buildPreviewSection(l10n),
              ],
              
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            AppLogger.debug(
              '取消导入',
              data: {
                'pageType': widget.pageType.name,
              },
              tag: 'import_dialog',
            );
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _filePath.isNotEmpty && !_isLoading ? _handleImport : null,
          child: Text(l10n.import),
        ),
      ],
    );
  }

  /// 构建文件选择区域
  Widget _buildFileSelectionSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectImportFile,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pathController,
                decoration: InputDecoration(
                  hintText: 'Select import file...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: _selectImportFile,
                  ),
                ),
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建导入选项区域
  Widget _buildImportOptionsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import Options',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Validate Data'),
          subtitle: const Text('Verify data integrity before import'),
          value: _validateData,
          onChanged: (value) {
            setState(() {
              _validateData = value ?? true;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Create Backup'),
          subtitle: const Text('Create backup before import'),
          value: _createBackup,
          onChanged: (value) {
            setState(() {
              _createBackup = value ?? true;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Preserve Metadata'),
          subtitle: const Text('Keep original creation time and metadata'),
          value: _preserveMetadata,
          onChanged: (value) {
            setState(() {
              _preserveMetadata = value ?? true;
            });
          },
        ),
      ],
    );
  }

  /// 构建冲突处理区域
  Widget _buildConflictResolutionSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conflict Resolution',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...ConflictResolution.values.map((resolution) {
          return RadioListTile<ConflictResolution>(
            title: Text(_getConflictResolutionLabel(l10n, resolution)),
            subtitle: Text(_getConflictResolutionDescription(l10n, resolution)),
            value: resolution,
            groupValue: _conflictResolution,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _conflictResolution = value;
                });
                
                AppLogger.debug(
                  '切换冲突处理策略',
                  data: {
                    'oldResolution': _conflictResolution.name,
                    'newResolution': value.name,
                    'pageType': widget.pageType.name,
                  },
                  tag: 'import_dialog',
                );
              }
            },
          );
        }),
      ],
    );
  }

  /// 构建预览区域
  Widget _buildPreviewSection(AppLocalizations l10n) {
    if (_previewData == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import Preview',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _buildPreviewRow('Works', '${_previewData!.exportData.works.length}'),
          _buildPreviewRow('Characters', '${_previewData!.exportData.characters.length}'),
          _buildPreviewRow('Images', '${_previewData!.exportData.workImages.length}'),
          if (_previewData!.conflicts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Conflicts Found',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            Text(
              '${_previewData!.conflicts.length} conflicts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建预览行
  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取冲突处理策略标签
  String _getConflictResolutionLabel(AppLocalizations l10n, ConflictResolution resolution) {
    switch (resolution) {
      case ConflictResolution.skip:
        return 'Skip Conflicts';
      case ConflictResolution.overwrite:
        return 'Overwrite Existing';
      case ConflictResolution.merge:
        return 'Merge Data';
      case ConflictResolution.rename:
        return 'Rename Duplicates';
      case ConflictResolution.ask:
        return 'Ask User';
      case ConflictResolution.keepExisting:
        return 'Keep Existing';
    }
  }

  /// 获取冲突处理策略描述
  String _getConflictResolutionDescription(AppLocalizations l10n, ConflictResolution resolution) {
    switch (resolution) {
      case ConflictResolution.skip:
        return 'Skip items that already exist';
      case ConflictResolution.overwrite:
        return 'Replace existing items with imported data';
      case ConflictResolution.merge:
        return 'Combine existing and imported data';
      case ConflictResolution.rename:
        return 'Rename imported items to avoid conflicts';
      case ConflictResolution.ask:
        return 'Ask user for each conflict';
      case ConflictResolution.keepExisting:
        return 'Keep existing data, skip import';
    }
  }

  /// 选择导入文件
  Future<void> _selectImportFile() async {
    try {
      final filePickerService = FilePickerServiceImpl();
      final selectedFile = await filePickerService.pickFile(
        dialogTitle: 'Select Import File',
        allowedExtensions: ['zip', 'json'],
      );
      
      if (selectedFile != null) {
        setState(() {
          _isLoading = true;
          _filePath = selectedFile;
          _pathController.text = selectedFile;
        });
        
        AppLogger.info(
          '选择导入文件',
          data: {
            'filePath': selectedFile,
            'pageType': widget.pageType.name,
          },
          tag: 'import_dialog',
        );
        
        // 模拟文件预览加载
        await Future.delayed(const Duration(seconds: 1));
        
        // 模拟预览数据 - 实际实现中应该调用导入服务解析文件
        setState(() {
          _isLoading = false;
          _previewData = ImportDataModel(
            exportData: ExportDataModel(
              metadata: ExportMetadata(
                exportTime: DateTime.now(),
                exportType: ExportType.worksWithCharacters,
                options: ExportOptions(
                  type: ExportType.worksWithCharacters,
                  format: ExportFormat.json,
                ),
                appVersion: '1.0.0',
                platform: 'Android',
                compatibility: CompatibilityInfo(
                  minSupportedVersion: '1.0.0',
                  recommendedVersion: '1.0.0',
                ),
              ),
              works: [], // 模拟数据
              characters: [], // 模拟数据
              workImages: [], // 模拟数据
              manifest: ExportManifest(
                summary: ExportSummary(),
                files: [],
                statistics: ExportStatistics(
                  customConfigs: CustomConfigStatistics(),
                ),
                validations: [],
              ),
            ),
            validation: ImportValidationResult(
              status: ValidationStatus.passed,
              isValid: true,
              statistics: ImportDataStatistics(),
              compatibility: CompatibilityCheckResult(
                dataFormatVersion: '1.0.0',
                appVersion: '1.0.0',
                level: CompatibilityLevel.fullCompatible,
              ),
              fileIntegrity: FileIntegrityResult(),
              dataIntegrity: DataIntegrityResult(),
            ),
            conflicts: [], // 模拟冲突数据
            options: ImportOptions(
              defaultConflictResolution: _conflictResolution,
              createBackup: _createBackup,
              validateFileIntegrity: _validateData,
            ),
          );
        });
      }
    } catch (e) {
      AppLogger.error(
        '选择文件失败',
        error: e,
        tag: 'import_dialog',
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 处理导入
  void _handleImport() {
    final options = ImportOptions(
      defaultConflictResolution: _conflictResolution,
      validateFileIntegrity: _validateData,
      createBackup: _createBackup,
    );
    
    AppLogger.info(
      '开始导入',
      data: {
        'pageType': widget.pageType.name,
        'filePath': _filePath,
        'conflictResolution': _conflictResolution.name,
        'options': {
          'validateData': _validateData,
          'createBackup': _createBackup,
          'preserveMetadata': _preserveMetadata,
        },
      },
      tag: 'import_dialog',
    );
    
    Navigator.of(context).pop();
    widget.onImport(options, _filePath);
  }

  /// 创建带进度回调的导入函数
  static Future<void> Function(ImportOptions, String) createProgressImportFunction({
    required BuildContext context,
    required Future<void> Function(ImportOptions options, String filePath, ProgressDialogController progressController) onImportWithProgress,
  }) {
    return (ImportOptions options, String filePath) async {
      // 显示进度对话框
      final progressController = ProgressDialogController();
      
      // 显示进度对话框
      final progressFuture = ControlledProgressDialog.show(
        context: context,
        title: AppLocalizations.of(context).import,
        controller: progressController,
        initialMessage: AppLocalizations.of(context).importing,
        canCancel: false,
      );

      try {
        // 执行导入
        await onImportWithProgress(options, filePath, progressController);
      } catch (e) {
        progressController.showError('导入失败: ${e.toString()}');
      } finally {
        progressController.dispose();
      }

      await progressFuture;
    };
  }
} 