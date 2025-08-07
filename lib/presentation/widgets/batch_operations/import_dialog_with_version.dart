import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/services/file_picker_service.dart';
import '../../../application/services/import_export_version_mapping_service.dart';
import '../../../application/services/unified_import_export_upgrade_service.dart';
import '../../../domain/models/import_export/import_data_model.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../version_config.dart';
import '../../providers/batch_selection_provider.dart';

/// 带版本兼容性检查的导入对话框
class ImportDialogWithVersion extends ConsumerStatefulWidget {
  /// 页面类型
  final PageType pageType;

  /// 导入回调
  final Function(ImportOptions options, String filePath) onImport;

  const ImportDialogWithVersion({
    super.key,
    required this.pageType,
    required this.onImport,
  });

  @override
  ConsumerState<ImportDialogWithVersion> createState() =>
      _ImportDialogWithVersionState();
}

class _ImportDialogWithVersionState
    extends ConsumerState<ImportDialogWithVersion> {
  String _filePath = '';
  final _pathController = TextEditingController();
  ConflictResolution _conflictResolution = ConflictResolution.skip;
  ImportDataModel? _previewData;
  bool _isLoading = false;

  // 版本兼容性信息
  ImportExportCompatibility? _compatibility;
  String? _sourceVersion;
  String? _targetVersion;
  String? _compatibilityMessage;

  late final UnifiedImportExportUpgradeService _upgradeService;

  @override
  void initState() {
    super.initState();
    _upgradeService = UnifiedImportExportUpgradeService();

    AppLogger.info(
      '打开导入对话框（带版本检查）',
      data: {
        'pageType': widget.pageType.name,
      },
      tag: 'import_dialog_version',
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

              // 版本兼容性信息
              if (_compatibility != null) ...[
                _buildVersionCompatibilitySection(l10n),
                const SizedBox(height: 16),
              ],

              // 冲突处理
              _buildConflictResolutionSection(l10n),

              const SizedBox(height: 16),

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
              tag: 'import_dialog_version',
            );
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _canImport() ? _handleImport : null,
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

  /// 构建版本兼容性信息区域
  Widget _buildVersionCompatibilitySection(AppLocalizations l10n) {
    if (_compatibility == null) return const SizedBox.shrink();

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_compatibility!) {
      case ImportExportCompatibility.compatible:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '兼容';
        break;
      case ImportExportCompatibility.upgradable:
        statusColor = Colors.orange;
        statusIcon = Icons.upgrade;
        statusText = '需要升级';
        break;
      case ImportExportCompatibility.appUpgradeRequired:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        statusText = '需要升级应用';
        break;
      case ImportExportCompatibility.incompatible:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = '不兼容';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '版本兼容性: $statusText',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (_sourceVersion != null && _targetVersion != null) ...[
            const SizedBox(height: 8),
            Text('源版本: $_sourceVersion'),
            Text('目标版本: $_targetVersion'),
          ],
          if (_compatibilityMessage != null) ...[
            const SizedBox(height: 8),
            Text(_compatibilityMessage!),
          ],
        ],
      ),
    );
  }

  /// 构建冲突解决区域
  Widget _buildConflictResolutionSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '冲突处理',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        RadioListTile<ConflictResolution>(
          title: const Text('跳过冲突项'),
          subtitle: const Text('保留现有数据，跳过冲突的导入项'),
          value: ConflictResolution.skip,
          groupValue: _conflictResolution,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _conflictResolution = value;
              });
            }
          },
        ),
        RadioListTile<ConflictResolution>(
          title: const Text('覆盖现有数据'),
          subtitle: const Text('用导入数据覆盖现有的冲突项'),
          value: ConflictResolution.overwrite,
          groupValue: _conflictResolution,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _conflictResolution = value;
              });
            }
          },
        ),
      ],
    );
  }

  /// 构建预览区域
  Widget _buildPreviewSection(AppLocalizations l10n) {
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
            '导入预览',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text('文件: ${_filePath.split('/').last}'),
          // 这里可以添加更多预览信息
        ],
      ),
    );
  }

  /// 检查是否可以导入
  bool _canImport() {
    if (_filePath.isEmpty || _isLoading) return false;

    // 检查版本兼容性
    if (_compatibility == ImportExportCompatibility.incompatible ||
        _compatibility == ImportExportCompatibility.appUpgradeRequired) {
      return false;
    }

    return true;
  }

  /// 选择导入文件
  Future<void> _selectImportFile() async {
    try {
      final filePickerService = FilePickerServiceImpl();
      final selectedFile = await filePickerService.pickFile(
        dialogTitle: AppLocalizations.of(context).selectImportFile,
        allowedExtensions: ['cgw', 'cgc', 'cgb', 'zip'], // 支持新格式和旧格式
      );

      if (selectedFile != null) {
        setState(() {
          _isLoading = true;
          _filePath = selectedFile;
          _pathController.text = selectedFile;
          _compatibility = null;
          _sourceVersion = null;
          _targetVersion = null;
          _compatibilityMessage = null;
        });

        await _checkVersionCompatibility(selectedFile);

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      AppLogger.error(
        '选择导入文件失败',
        error: e,
        tag: 'import_dialog_version',
      );
    }
  }

  /// 检查版本兼容性
  Future<void> _checkVersionCompatibility(String filePath) async {
    try {
      await _upgradeService.initialize();
      final currentAppVersion = _getCurrentAppVersion();

      final compatibility = await _upgradeService.checkImportCompatibility(
          filePath, currentAppVersion);

      setState(() {
        _compatibility = compatibility;
        // 这里可以添加更多版本信息的获取
        _compatibilityMessage = _getCompatibilityMessage(compatibility);
      });

      AppLogger.info(
        '版本兼容性检查完成',
        data: {
          'filePath': filePath,
          'compatibility': compatibility.name,
        },
        tag: 'import_dialog_version',
      );
    } catch (e) {
      AppLogger.error(
        '版本兼容性检查失败',
        error: e,
        tag: 'import_dialog_version',
      );

      setState(() {
        _compatibility = ImportExportCompatibility.incompatible;
        _compatibilityMessage = '无法检查版本兼容性: ${e.toString()}';
      });
    }
  }

  /// 获取兼容性消息
  String _getCompatibilityMessage(ImportExportCompatibility compatibility) {
    switch (compatibility) {
      case ImportExportCompatibility.compatible:
        return '文件版本与当前应用兼容，可以直接导入。';
      case ImportExportCompatibility.upgradable:
        return '文件版本较旧，将自动升级后导入。';
      case ImportExportCompatibility.appUpgradeRequired:
        return '文件版本过新，需要升级应用版本才能导入。';
      case ImportExportCompatibility.incompatible:
        return '文件版本不兼容，无法导入。';
    }
  }

  /// 处理导入
  void _handleImport() {
    final options = ImportOptions(
      defaultConflictResolution: _conflictResolution,
      validateFileIntegrity: true,
      createBackup: false,
      autoFixErrors: true,
      overwriteExisting: _conflictResolution == ConflictResolution.overwrite,
    );

    AppLogger.info(
      '开始导入（带版本检查）',
      data: {
        'pageType': widget.pageType.name,
        'filePath': _filePath,
        'conflictResolution': _conflictResolution.name,
        'compatibility': _compatibility?.name,
      },
      tag: 'import_dialog_version',
    );

    Navigator.of(context).pop();
    widget.onImport(options, _filePath);
  }

  /// 获取当前应用版本
  String _getCurrentAppVersion() {
    try {
      return VersionConfig.versionInfo.shortVersion;
    } catch (e) {
      // 如果VersionConfig未初始化，返回默认版本
      AppLogger.warning('VersionConfig未初始化，使用默认版本', 
          tag: 'ImportDialogWithVersion', data: {'error': e.toString()});
      return '1.3.0'; // 保持与原始硬编码版本一致
    }
  }
}
