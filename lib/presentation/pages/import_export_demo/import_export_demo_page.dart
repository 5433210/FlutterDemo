import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/import_export/export_data_model.dart';
import '../../../domain/models/import_export/import_data_model.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/batch_selection_provider.dart';
import '../../widgets/batch_operations/export_dialog_with_version.dart';
import '../../widgets/batch_operations/import_dialog_with_version.dart';

/// 导入导出功能演示页面
class ImportExportDemoPage extends ConsumerStatefulWidget {
  const ImportExportDemoPage({super.key});

  @override
  ConsumerState<ImportExportDemoPage> createState() =>
      _ImportExportDemoPageState();
}

class _ImportExportDemoPageState extends ConsumerState<ImportExportDemoPage> {
  final List<String> _selectedIds = ['demo1', 'demo2', 'demo3'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('导入导出功能演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '版本管理导入导出功能',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Text(
              '这个演示页面展示了带版本兼容性检查的导入导出功能。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // 功能特性列表
            _buildFeaturesList(),

            const SizedBox(height: 32),

            // 操作按钮
            _buildActionButtons(l10n),

            const SizedBox(height: 32),

            // 状态信息
            _buildStatusInfo(),
          ],
        ),
      ),
    );
  }

  /// 构建功能特性列表
  Widget _buildFeaturesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '新功能特性',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.check_circle,
              '版本兼容性检查',
              '自动检测导入文件的版本兼容性',
              Colors.green,
            ),
            _buildFeatureItem(
              Icons.upgrade,
              '自动版本升级',
              '支持跨版本数据升级（如 ie_v1 → ie_v3）',
              Colors.blue,
            ),
            _buildFeatureItem(
              Icons.info,
              '版本信息显示',
              '在导出时显示当前应用和数据版本',
              Colors.orange,
            ),
            _buildFeatureItem(
              Icons.warning,
              '兼容性警告',
              '对不兼容的文件显示明确的警告信息',
              Colors.red,
            ),
            _buildFeatureItem(
              Icons.speed,
              '性能优化',
              '优化的适配器链和缓存机制',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建功能特性项
  Widget _buildFeatureItem(
      IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '操作演示',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showImportDialog,
                    icon: const Icon(Icons.file_download),
                    label: const Text('演示导入功能'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showExportDialog,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('演示导出功能'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showWorksImportDialog,
                    icon: const Icon(Icons.article),
                    label: const Text('作品导入'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showCharactersExportDialog,
                    icon: const Icon(Icons.text_fields),
                    label: const Text('集字导出'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建状态信息
  Widget _buildStatusInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前状态',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildStatusItem('应用版本', '1.3.0'),
            _buildStatusItem('数据版本', 'ie_v4'),
            _buildStatusItem('选中项目', '${_selectedIds.length} 项'),
            _buildStatusItem('支持格式', 'ZIP (推荐), JSON'),
            _buildStatusItem('兼容性', '向下兼容 ie_v1, ie_v2, ie_v3'),
          ],
        ),
      ),
    );
  }

  /// 构建状态项
  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  /// 显示导入对话框
  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => ImportDialogWithVersion(
        pageType: PageType.works,
        onImport: _handleImport,
      ),
    );
  }

  /// 显示导出对话框
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialogWithVersion(
        pageType: PageType.works,
        selectedIds: _selectedIds,
        onExport: _handleExport,
      ),
    );
  }

  /// 显示作品导入对话框
  void _showWorksImportDialog() {
    showDialog(
      context: context,
      builder: (context) => ImportDialogWithVersion(
        pageType: PageType.characters,
        onImport: _handleImport,
      ),
    );
  }

  /// 显示集字导出对话框
  void _showCharactersExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportDialogWithVersion(
        pageType: PageType.characters,
        selectedIds: _selectedIds,
        onExport: _handleExport,
      ),
    );
  }

  /// 处理导入
  void _handleImport(ImportOptions options, String filePath) {
    AppLogger.info(
      '演示导入操作',
      data: {
        'filePath': filePath,
        'options': {
          'conflictResolution': options.defaultConflictResolution.name,
          'validateFileIntegrity': options.validateFileIntegrity,
          'createBackup': options.createBackup,
        },
      },
      tag: 'import_export_demo',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('导入操作已启动: ${filePath.split('/').last}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 处理导出
  void _handleExport(ExportOptions options, String targetPath) {
    AppLogger.info(
      '演示导出操作',
      data: {
        'targetPath': targetPath,
        'selectedCount': _selectedIds.length,
        'options': {
          'type': options.type.name,
          'format': options.format.name,
          'includeImages': options.includeImages,
          'includeMetadata': options.includeMetadata,
        },
      },
      tag: 'import_export_demo',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('导出操作已启动: ${targetPath.split('/').last}'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
