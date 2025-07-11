import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/data_path_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../presentation/providers/storage_info_provider.dart';
import '../../../../utils/file_size_formatter.dart';
import '../../../widgets/settings/settings_section.dart';
import '../../data_path_switch_wizard.dart';
import './data_path_management_page.dart';

/// 简化的统一存储设置组件
/// 只包含三个核心入口：数据路径设置、数据路径管理、当前存储信息
class UnifiedStorageSettings extends ConsumerWidget {
  const UnifiedStorageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataPathStatus = ref.watch(dataPathStatusProvider);
    final dataPathConfig = ref.watch(dataPathConfigProvider);
    final storageInfo = ref.watch(storageInfoProvider);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: l10n.storageSettings,
      icon: Icons.storage_outlined,
      children: [
        // 1. 数据路径设置
        ListTile(
          title: Text(l10n.dataPathSettings),
          subtitle: dataPathStatus.isLoading
              ? Text(l10n.loading)
              : dataPathConfig.when(
                  data: (config) => FutureBuilder<String>(
                    future: config.getActualDataPath(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final isCustom = !config.useDefaultPath;
                        return Text(
                          isCustom ? l10n.customPath : l10n.defaultPath,
                          style: TextStyle(
                            color: isCustom
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        );
                      }
                      return Text(l10n.gettingPathInfo);
                    },
                  ),
                  loading: () => Text(l10n.loading),
                  error: (_, __) => Text(
                    l10n.pathConfigError,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
          leading: Icon(
            Icons.folder_outlined,
            color: colorScheme.primary,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => _openDataPathSettings(context),
        ),

        // 2. 数据路径管理
        ListTile(
          title: Text(l10n.dataPathManagement),
          subtitle: Text(l10n.dataPathManagementSubtitle),
          leading: Icon(
            Icons.manage_accounts_outlined,
            color: colorScheme.primary,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => _openDataPathManagement(context),
        ),

        // 3. 当前存储信息
        ListTile(
          title: Text(l10n.currentStorageInfo),
          subtitle: storageInfo.when(
            data: (info) => Text(
              '${l10n.totalSize}: ${FileSizeFormatter.format(info.totalSize)}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            loading: () => Text(l10n.statisticsInProgress),
            error: (_, __) => Text(
              l10n.cannotGetStorageInfo,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
          leading: Icon(
            Icons.analytics_outlined,
            color: colorScheme.primary,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => _openStorageInfo(context, ref),
        ),
      ],
    );
  }

  /// 打开数据路径设置向导
  void _openDataPathSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DataPathSwitchWizard(),
      ),
    );
  }

  /// 打开数据路径管理页面
  void _openDataPathManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DataPathManagementPage(),
      ),
    );
  }

  /// 打开存储信息页面
  void _openStorageInfo(BuildContext context, WidgetRef ref) {
    final storageInfo = ref.read(storageInfoProvider);

    storageInfo.when(
      data: (info) => _showStorageInfoDialog(context, ref, info),
      loading: () => _showLoadingDialog(context),
      error: (error, _) => _showErrorDialog(
        context,
        AppLocalizations.of(context).getStorageInfoFailed,
        error.toString(),
      ),
    );
  }

  /// 显示存储信息对话框
  void _showStorageInfoDialog(
      BuildContext context, WidgetRef ref, StorageInfo info) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(l10n.currentStorageInfoTitle),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 存储位置
              _buildInfoRow(
                l10n.storageLocation,
                info.path,
                Icons.folder_outlined,
                textTheme,
                colorScheme,
                isPath: true,
              ),

              const SizedBox(height: 16),

              // 核心存储统计
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildStatRow(l10n.totalSize,
                        FileSizeFormatter.format(info.usedSize), textTheme),
                    const SizedBox(height: 12),

                    // 作品信息
                    _buildCategoryRow(context, l10n.works, info.workCount,
                        info.workSize, textTheme, colorScheme),
                    const SizedBox(height: 8),

                    // 集字信息
                    _buildCategoryRow(
                        context,
                        l10n.characters,
                        info.characterCount,
                        info.characterSize,
                        textTheme,
                        colorScheme),
                    const SizedBox(height: 8),

                    // 图库信息
                    _buildCategoryRow(context, l10n.library, info.libraryCount,
                        info.librarySize, textTheme, colorScheme),
                    const SizedBox(height: 8),

                    // 数据库信息
                    _buildStatRow(l10n.databaseSize,
                        FileSizeFormatter.format(info.databaseSize), textTheme),

                    // 备份信息（如果有的话）
                    if (info.backupCount > 0) ...[
                      const SizedBox(height: 8),
                      _buildCategoryRow(context, l10n.backups, info.backupCount,
                          info.backupSize, textTheme, colorScheme),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.invalidate(storageInfoProvider);
              _openStorageInfo(context, ref);
            },
            child: Text(l10n.refresh),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    TextTheme textTheme,
    ColorScheme colorScheme, {
    bool isPath = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              isPath
                  ? SelectableText(
                      value,
                      style: textTheme.bodyMedium,
                    )
                  : Text(
                      value,
                      style: textTheme.bodyMedium,
                    ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建统计行
  Widget _buildStatRow(String label, String value, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium,
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// 显示加载对话框
  void _showLoadingDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(l10n.gettingStorageInfo),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  /// 显示错误对话框
  void _showErrorDialog(BuildContext context, String title, String message) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// 构建分类信息行（数量 + 大小）
  Widget _buildCategoryRow(BuildContext context, String label, int count,
      int size, TextTheme textTheme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$count ${l10n.countUnit}',
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              FileSizeFormatter.format(size),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
