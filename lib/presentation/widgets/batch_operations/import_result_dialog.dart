import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/services/import_service.dart';
import '../../../infrastructure/logging/logger.dart';

/// 导入结果汇总对话框
class ImportResultDialog extends StatelessWidget {
  /// 导入结果
  final ImportResult result;
  
  /// 导入的文件路径
  final String filePath;

  const ImportResultDialog({
    super.key,
    required this.result,
    required this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.info(
      '构建导入结果对话框',
      data: {
        'success': result.success,
        'importedWorks': result.importedWorks,
        'importedCharacters': result.importedCharacters,
        'importedImages': result.importedImages,
        'skippedItems': result.skippedItems,
        'filePath': filePath,
      },
      tag: 'import_result_dialog',
    );
    
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            result.success ? Icons.check_circle : Icons.error,
            color: result.success ? Colors.green : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(result.success ? l10n.importSuccess : l10n.importFailed(result.errors.isNotEmpty ? result.errors.first : '未知错误')),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 文件信息
              _buildSection(
                l10n,
                theme,
                Icons.folder,
                l10n.importedFile,
                [_buildInfoRow('文件路径', _getFileName(filePath))],
              ),
              
              const SizedBox(height: 16),
              
              // 导入统计
              _buildSection(
                l10n,
                theme,
                Icons.analytics,
                l10n.importStatistics,
                [
                  _buildStatRow(l10n.works, result.importedWorks, Colors.blue),
                  _buildStatRow(l10n.characters, result.importedCharacters, Colors.orange),
                  _buildStatRow(l10n.images, result.importedImages, Colors.green),
                  if (result.skippedItems > 0)
                    _buildStatRow(l10n.skippedItems, result.skippedItems, Colors.orange),
                ],
              ),
              
              // 错误信息
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(
                  l10n,
                  theme,
                  Icons.error_outline,
                  l10n.errors,
                  result.errors.map((error) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• $error',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ],
              
              // 警告信息
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(
                  l10n,
                  theme,
                  Icons.warning_outlined,
                  l10n.warnings,
                  result.warnings.map((warning) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• $warning',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (result.success && result.skippedItems > 0)
          TextButton.icon(
            onPressed: () => _showDetailedReport(context),
            icon: const Icon(Icons.list_alt),
            label: Text(l10n.viewDetails),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ok),
        ),
      ],
    );
  }

  /// 构建区域
  Widget _buildSection(
    AppLocalizations l10n,
    ThemeData theme,
    IconData icon,
    String title,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// 构建统计行
  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }



  /// 获取文件名
  String _getFileName(String filePath) {
    return filePath.split('/').last.split('\\').last;
  }

  /// 显示详细报告
  void _showDetailedReport(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.detailedReport),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.skippedItems > 0) ...[
                  Text(
                    '${l10n.skippedItems}: ${result.skippedItems}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('跳过了 ${result.skippedItems} 个项目，原因可能是：'),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('• 项目已存在且选择了跳过策略'),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('• 数据格式不兼容'),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('• 文件损坏或缺失'),
                  ),
                  const SizedBox(height: 16),
                ],
                if (result.details.isNotEmpty) ...[
                  Text(
                    '导入详情:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.details.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text('• ${entry.key}: ${entry.value}'),
                  )),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
} 