import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/services/file_picker_service.dart';
import '../../../domain/models/import_export/export_data_model.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/batch_selection_provider.dart';

/// 导出对话框
class ExportDialog extends ConsumerStatefulWidget {
  /// 页面类型
  final PageType pageType;

  /// 选中的项目ID列表
  final List<String> selectedIds;

  /// 导出回调
  final Function(ExportOptions options, String targetPath) onExport;

  const ExportDialog({
    super.key,
    required this.pageType,
    required this.selectedIds,
    required this.onExport,
  });

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  late ExportType _exportType;
  late ExportFormat _exportFormat;
  bool _includeImages = true;
  bool _includeMetadata = true;
  bool _compressData = true;
  String _targetPath = '';
  final _pathController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 根据页面类型设置默认导出类型
    switch (widget.pageType) {
      case PageType.works:
        _exportType = ExportType.worksWithCharacters;
        break;
      case PageType.characters:
        _exportType = ExportType.charactersWithWorks;
        break;
    }

    // 默认使用7zip格式（新推荐格式）
    _exportFormat = ExportFormat.sevenZip;

    // 导出选项全选且固定
    _includeImages = true;
    _includeMetadata = true;
    _compressData = true;

    AppLogger.info(
      '打开导出对话框',
      data: {
        'pageType': widget.pageType.name,
        'selectedCount': widget.selectedIds.length,
        'defaultExportType': _exportType.name,
        'defaultFormat': _exportFormat.name,
      },
      tag: 'export_dialog',
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
      title: Text(l10n.export),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 导出类型选择
              _buildExportTypeSection(l10n),

              const SizedBox(height: 16),

              // 导出选项（固定为全选，仅显示不可修改）
              _buildExportOptionsSection(l10n),

              const SizedBox(height: 16),

              // 目标路径选择
              _buildTargetPathSection(l10n),

              const SizedBox(height: 16),

              // 导出摘要
              _buildExportSummary(l10n),
            ],
          ),
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
              tag: 'export_dialog',
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
            subtitle: Text(_getExportTypeDescription(l10n, type)),
            value: type,
            groupValue: _exportType,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _exportType = value;
                });

                AppLogger.debug(
                  '切换导出类型',
                  data: {
                    'oldType': _exportType.name,
                    'newType': value.name,
                    'pageType': widget.pageType.name,
                  },
                  tag: 'export_dialog',
                );
              }
            },
          );
        }),
      ],
    );
  }

  /// 构建导出选项区域
  Widget _buildExportOptionsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exportOptions,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        // 显示导出选项但设为只读（全选且固定）
        Container(
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
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.includeImages),
                        Text(
                          l10n.includeImagesDescription,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.includeMetadata),
                        Text(
                          l10n.includeMetadataDescription,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.compressData),
                        Text(
                          l10n.compressDataDescription,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建目标路径选择区域
  Widget _buildTargetPathSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectExportLocation,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pathController,
                decoration: InputDecoration(
                  hintText: l10n.selectExportLocationHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: _selectTargetPath,
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

  /// 构建导出摘要区域
  Widget _buildExportSummary(AppLocalizations l10n) {
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
            l10n.exportSummary,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(l10n.selectedItems,
              '${widget.selectedIds.length} 个${_getItemTypeName()}'),
          _buildSummaryRow(
              l10n.exportType, _getExportTypeLabel(l10n, _exportType)),
          if (_targetPath.isNotEmpty)
            _buildSummaryRow(l10n.exportLocation, _targetPath),
        ],
      ),
    );
  }

  /// 构建摘要行
  Widget _buildSummaryRow(String label, String value) {
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
        return l10n.exportWorksOnly;
      case ExportType.worksWithCharacters:
        return l10n.exportWorksWithCharacters;
      case ExportType.charactersOnly:
        return l10n.exportCharactersOnly;
      case ExportType.charactersWithWorks:
        return l10n.exportCharactersWithWorks;
      case ExportType.fullData:
        return l10n.exportFullData;
    }
  }

  /// 获取导出类型描述
  String _getExportTypeDescription(AppLocalizations l10n, ExportType type) {
    switch (type) {
      case ExportType.worksOnly:
        return l10n.exportWorksOnlyDescription;
      case ExportType.worksWithCharacters:
        return l10n.exportWorksWithCharactersDescription;
      case ExportType.charactersOnly:
        return l10n.exportCharactersOnlyDescription;
      case ExportType.charactersWithWorks:
        return l10n.exportCharactersWithWorksDescription;
      case ExportType.fullData:
        return l10n.exportFullDataDescription;
    }
  }

  /// 获取项目类型名称
  String _getItemTypeName() {
    final l10n = AppLocalizations.of(context);
    switch (widget.pageType) {
      case PageType.works:
        return l10n.work;
      case PageType.characters:
        return l10n.character;
    }
  }

  /// 选择目标路径
  Future<void> _selectTargetPath() async {
    try {
      final filePickerService = FilePickerServiceImpl();

      // 根据导出类型选择文件扩展名
      final now = DateTime.now();
      final timestamp =
          '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      // 根据页面类型确定文件扩展名
      String extension;
      switch (widget.pageType) {
        case PageType.works:
          extension = 'cgw';
          break;
        case PageType.characters:
          extension = 'cgc';
          break;
      }

      final suggestedName = 'export_$timestamp.$extension';

      final selectedPath = await filePickerService.pickSaveFile(
        dialogTitle: 'Select Export Location',
        suggestedName: suggestedName,
        allowedExtensions: [extension], // 🔧 移除zip格式，只支持對應的專用格式
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
            'exportFormat': 'zip',
          },
          tag: 'export_dialog',
        );
      }
    } catch (e) {
      AppLogger.error(
        '选择导出路径失败',
        error: e,
        tag: 'export_dialog',
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.selectPathFailed}: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
      '开始导出',
      data: {
        'pageType': widget.pageType.name,
        'selectedCount': widget.selectedIds.length,
        'exportType': _exportType.name,
        'exportFormat': _exportFormat.name,
        'targetPath': _targetPath,
        'options': {
          'includeImages': _includeImages,
          'includeMetadata': _includeMetadata,
          'compressData': _compressData,
        },
      },
      tag: 'export_dialog',
    );

    Navigator.of(context).pop();
    widget.onExport(options, _targetPath);
  }
}
