import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/services/file_picker_service.dart';
import '../../../application/services/import_export_version_mapping_service.dart';
import '../../../domain/models/import_export/export_data_model.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../version_config.dart';
import '../../providers/batch_selection_provider.dart';

/// 带版本信息的导出对话框
class ExportDialogWithVersion extends ConsumerStatefulWidget {
  /// 页面类型
  final PageType pageType;

  /// 选中的ID列表
  final List<String> selectedIds;

  /// 导出回调
  final Function(ExportOptions options, String targetPath) onExport;

  const ExportDialogWithVersion({
    super.key,
    required this.pageType,
    required this.selectedIds,
    required this.onExport,
  });

  @override
  ConsumerState<ExportDialogWithVersion> createState() =>
      _ExportDialogWithVersionState();
}

class _ExportDialogWithVersionState
    extends ConsumerState<ExportDialogWithVersion> {
  ExportType _exportType = ExportType.worksOnly;
  final ExportFormat _exportFormat = ExportFormat.sevenZip;
  bool _includeImages = true;
  bool _includeMetadata = true;
  bool _compressData = true;
  String _targetPath = '';
  final _pathController = TextEditingController();

  // 版本信息
  String? _currentDataVersion;
  String? _currentAppVersion;

  @override
  void initState() {
    super.initState();
    _initializeVersionInfo();

    AppLogger.info(
      '打开导出对话框（带版本信息）',
      data: {
        'pageType': widget.pageType.name,
        'selectedCount': widget.selectedIds.length,
      },
      tag: 'export_dialog_version',
    );
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  /// 初始化版本信息
  void _initializeVersionInfo() {
    _currentAppVersion = _getCurrentAppVersion(); // 从配置获取
    _currentDataVersion =
        ImportExportVersionMappingService.getDataVersionForApp(
            _currentAppVersion!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.export),
      content: SizedBox(
        width: 800,
        height: 550,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左侧设置区域
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExportTypeSection(l10n),
                    const SizedBox(height: 16),
                    _buildVersionInfoSection(l10n),
                    const SizedBox(height: 16),
                    _buildOutputPathSection(l10n),
                    const SizedBox(height: 16),
                    _buildOptionsSection(l10n),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // 右侧预览区域
            Expanded(
              flex: 3,
              child: _buildPreviewSection(l10n),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            AppLogger.debug(
              '取消导出',
              data: {
                'pageType': widget.pageType.name,
                'selectedCount': widget.selectedIds.length,
              },
              tag: 'export_dialog_version',
            );
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _targetPath.isNotEmpty ? _handleExport : null,
          child: Text(l10n.export),
        ),
      ],
    );
  }

  /// 构建导出类型选择区域
  Widget _buildExportTypeSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exportType,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...ExportType.values.where(_isExportTypeAvailable).map((type) {
          return RadioListTile<ExportType>(
            title: Text(_getExportTypeLabel(l10n, type)),
            subtitle: Text(_getExportTypeDescription(type)),
            value: type,
            groupValue: _exportType,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _exportType = value;
                });
              }
            },
          );
        }),
      ],
    );
  }

  /// 构建版本信息区域
  Widget _buildVersionInfoSection(AppLocalizations l10n) {
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
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '版本信息',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_currentAppVersion != null) Text('应用版本: $_currentAppVersion'),
          if (_currentDataVersion != null) Text('数据版本: $_currentDataVersion'),
          const SizedBox(height: 4),
          Text(
            '导出的文件将包含版本信息，确保导入时的兼容性检查。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// 构建输出路径选择区域
  Widget _buildOutputPathSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导出路径',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pathController,
                decoration: const InputDecoration(
                  hintText: '选择导出文件保存位置',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.folder_open),
                ),
                readOnly: true,
                onTap: _selectTargetPath,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建选项区域
  Widget _buildOptionsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导出选项',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('包含图片'),
          subtitle: const Text('导出相关的图片文件'),
          value: _includeImages,
          onChanged: (value) {
            setState(() {
              _includeImages = value ?? true;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('包含元数据'),
          subtitle: const Text('导出完整的元数据信息'),
          value: _includeMetadata,
          onChanged: (value) {
            setState(() {
              _includeMetadata = value ?? true;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('压缩数据'),
          subtitle: const Text('压缩导出文件以减小体积'),
          value: _compressData,
          onChanged: (value) {
            setState(() {
              _compressData = value ?? true;
            });
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
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '导出预览',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          _buildPreviewItem('导出类型', _getExportTypeLabel(l10n, _exportType)),
          _buildPreviewItem('选中项目', '${widget.selectedIds.length} 项'),
          if (_currentDataVersion != null)
            _buildPreviewItem('数据版本', _currentDataVersion!),
          _buildPreviewItem('包含图片', _includeImages ? '是' : '否'),
          _buildPreviewItem('包含元数据', _includeMetadata ? '是' : '否'),
          _buildPreviewItem('压缩数据', _compressData ? '是' : '否'),
        ],
      ),
    );
  }

  /// 构建预览项
  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// 检查导出类型是否可用
  bool _isExportTypeAvailable(ExportType type) {
    switch (widget.pageType) {
      case PageType.works:
        return type == ExportType.worksOnly ||
            type == ExportType.worksWithCharacters;
      case PageType.characters:
        return type == ExportType.charactersOnly ||
            type == ExportType.charactersWithWorks;
    }
  }

  /// 获取导出类型标签
  String _getExportTypeLabel(AppLocalizations l10n, ExportType type) {
    switch (type) {
      case ExportType.worksOnly:
        return '仅作品';
      case ExportType.charactersOnly:
        return '仅集字';
      case ExportType.worksWithCharacters:
        return '作品和集字';
      case ExportType.charactersWithWorks:
        return '集字和作品';
      case ExportType.fullData:
        return '完整数据';
    }
  }

  /// 获取导出类型描述
  String _getExportTypeDescription(ExportType type) {
    switch (type) {
      case ExportType.worksOnly:
        return '只导出选中的作品数据';
      case ExportType.charactersOnly:
        return '只导出选中的集字数据';
      case ExportType.worksWithCharacters:
        return '导出作品及其相关的集字数据';
      case ExportType.charactersWithWorks:
        return '导出集字及其相关的作品数据';
      case ExportType.fullData:
        return '导出所有数据（作品、集字、设置等）';
    }
  }

  /// 选择目标路径
  Future<void> _selectTargetPath() async {
    try {
      final filePickerService = FilePickerServiceImpl();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // 根據頁面類型確定文件擴展名
      String extension;
      switch (widget.pageType) {
        case PageType.works:
          extension = 'cgw';
          break;
        case PageType.characters:
          extension = 'cgc';
          break;
      }
      
      final suggestedName = 'export_${widget.pageType.name}_$timestamp.$extension';

      final selectedPath = await filePickerService.pickSaveFile(
        dialogTitle: '选择导出位置',
        suggestedName: suggestedName,
        allowedExtensions: [extension], // 🔧 移除zip格式，使用對應的專用格式
      );

      if (selectedPath != null) {
        setState(() {
          _targetPath = selectedPath;
          _pathController.text = selectedPath;
        });

        AppLogger.info(
          '选择导出路径',
          data: {
            'targetPath': selectedPath,
            'pageType': widget.pageType.name,
          },
          tag: 'export_dialog_version',
        );
      }
    } catch (e) {
      AppLogger.error(
        '选择导出路径失败',
        error: e,
        tag: 'export_dialog_version',
      );
    }
  }

  /// 处理导出
  void _handleExport() {
    final options = ExportOptions(
      type: _exportType,
      format: _exportFormat,
      includeImages: _includeImages,
      includeMetadata: _includeMetadata,
      compressData: _compressData,
      version: '1.0',
    );

    AppLogger.info(
      '开始导出（带版本信息）',
      data: {
        'pageType': widget.pageType.name,
        'selectedCount': widget.selectedIds.length,
        'exportType': _exportType.name,
        'targetPath': _targetPath,
        'dataVersion': _currentDataVersion,
        'appVersion': _currentAppVersion,
      },
      tag: 'export_dialog_version',
    );

    Navigator.of(context).pop();
    widget.onExport(options, _targetPath);
  }

  /// 获取当前应用版本
  String _getCurrentAppVersion() {
    try {
      return VersionConfig.versionInfo.shortVersion;
    } catch (e) {
      // 如果VersionConfig未初始化，返回默认版本
      AppLogger.warning('VersionConfig未初始化，使用默认版本', 
          tag: 'ExportDialogWithVersion', data: {'error': e.toString()});
      return '1.3.0'; // 保持与原始硬编码版本一致
    }
  }
}
