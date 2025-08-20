import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/services/file_picker_service.dart';
import '../../../domain/models/import_export/import_data_model.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/batch_selection_provider.dart';
import '../../providers/navigation/global_navigation_provider.dart';

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
  ConflictResolution _conflictResolution = ConflictResolution.skip; // 默认跳过
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
    final l10n = AppLocalizations.of(context);

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

              // 强制选项说明
              _buildMandatoryOptionsSection(l10n),

              const SizedBox(height: 16),

              // 冲突处理（简化为两个选项）
              _buildConflictResolutionSection(l10n),

              const SizedBox(height: 16),

              // 备份跳转按钮
              _buildBackupSection(l10n),

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
                  hintText: l10n.selectImportFile,
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

  /// 构建强制选项说明区域
  Widget _buildMandatoryOptionsSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.importRequirements,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(l10n, Icons.verified_user, l10n.validateData,
              l10n.validateDataMandatory),
          _buildRequirementItem(l10n, Icons.history, l10n.preserveMetadata,
              l10n.preserveMetadataMandatory),
        ],
      ),
    );
  }

  /// 构建要求项
  Widget _buildRequirementItem(
      AppLocalizations l10n, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建冲突处理区域（简化为两个选项）
  Widget _buildConflictResolutionSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.conflictResolution,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        // 只显示跳过和覆盖两个选项
        RadioListTile<ConflictResolution>(
          title: Text(l10n.skipConflicts),
          subtitle: Text(l10n.skipConflictsDescription),
          value: ConflictResolution.skip,
          groupValue: _conflictResolution,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _conflictResolution = value;
              });

              AppLogger.debug(
                '选择冲突处理策略：跳过',
                data: {
                  'resolution': value.name,
                  'pageType': widget.pageType.name,
                },
                tag: 'import_dialog',
              );
            }
          },
        ),
        RadioListTile<ConflictResolution>(
          title: Text(l10n.overwriteExisting),
          subtitle: Text(l10n.overwriteExistingDescription),
          value: ConflictResolution.overwrite,
          groupValue: _conflictResolution,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _conflictResolution = value;
              });

              AppLogger.debug(
                '选择冲突处理策略：覆盖',
                data: {
                  'resolution': value.name,
                  'pageType': widget.pageType.name,
                },
                tag: 'import_dialog',
              );
            }
          },
        ),
      ],
    );
  }

  /// 构建备份区域
  Widget _buildBackupSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.backup,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.backupRecommendation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  l10n.backupRecommendationDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _navigateToBackupSettings,
            icon: const Icon(Icons.settings),
            label: Text(l10n.goToBackup),
          ),
        ],
      ),
    );
  }

  /// 构建预览区域
  Widget _buildPreviewSection(AppLocalizations l10n) {
    if (_previewData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.importPreview,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _buildPreviewRow(
              l10n.works, '${_previewData!.exportData.works.length}'),
          _buildPreviewRow(
              l10n.characters, '${_previewData!.exportData.characters.length}'),
          _buildPreviewRow(
              l10n.images, '${_previewData!.exportData.workImages.length}'),
          if (_previewData!.conflicts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.conflictsFound,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            Text(
              l10n.conflictsCount(_previewData!.conflicts.length),
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

  /// 导航到备份设置
  void _navigateToBackupSettings() {
    AppLogger.info(
      '导航到备份设置',
      data: {
        'pageType': widget.pageType.name,
      },
      tag: 'import_dialog',
    );

    Navigator.of(context).pop(); // 关闭导入对话框

    // 导航到设置功能区（索引为4）
    final ref = ProviderScope.containerOf(context).read;
    ref(globalNavigationProvider.notifier).navigateToSection(4);

    // 显示成功导航的提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).navigatedToBackupSettings),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 选择导入文件
  Future<void> _selectImportFile() async {
    try {
      final filePickerService = FilePickerServiceImpl();
      final selectedFile = await filePickerService.pickFile(
        dialogTitle: AppLocalizations.of(context).selectImportFile,
        allowedExtensions: ['cgw', 'cgc', 'cgb'], // 🔧 移除zip格式，只支持專用格式
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
          // 暂时设为null，避免复杂的模型构造
          _previewData = null;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      AppLogger.error(
        '选择导入文件失败',
        data: {
          'error': e.toString(),
          'pageType': widget.pageType.name,
        },
        tag: 'import_dialog',
        error: e,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).selectFileError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 处理导入
  void _handleImport() {
    AppLocalizations.of(context);

    // 创建简化的导入选项
    final options = ImportOptions(
      defaultConflictResolution: _conflictResolution,
      validateFileIntegrity: true, // 强制验证数据
      createBackup: false, // 不自动创建备份
      autoFixErrors: true,
      overwriteExisting: _conflictResolution == ConflictResolution.overwrite,
    );

    AppLogger.info(
      '开始导入',
      data: {
        'pageType': widget.pageType.name,
        'filePath': _filePath,
        'conflictResolution': _conflictResolution.name,
        'options': {
          'validateFileIntegrity': true,
          'createBackup': false,
          'preserveMetadata': true, // 强制保留元数据
        },
      },
      tag: 'import_dialog',
    );

    Navigator.of(context).pop();
    widget.onImport(options, _filePath);
  }
}
