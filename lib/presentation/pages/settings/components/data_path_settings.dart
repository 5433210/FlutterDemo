import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/data_path_provider.dart';
import '../../../../application/services/data_migration_service.dart';
import '../../../../application/services/data_path_config_service.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../utils/app_restart_service.dart';
import '../../../widgets/settings/settings_section.dart';

/// 数据路径设置组件
class DataPathSettings extends ConsumerWidget {
  const DataPathSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataPathStatus = ref.watch(dataPathStatusProvider);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: l10n.dataPathSettings,
      icon: Icons.folder_open,
      children: [
        if (dataPathStatus.isLoading)
          const Padding(
            padding: EdgeInsets.all(AppSizes.m),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          // 当前路径状态显示
          ListTile(
            title: Text(l10n.dataPath),
            subtitle: Text(dataPathStatus.isCustomPath
                ? l10n.currentCustomPath
                : l10n.currentDefaultPath),
            leading: Icon(
              dataPathStatus.isCustomPath ? Icons.folder_special : Icons.home,
              color: colorScheme.primary,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => _showDataPathDialog(context),
          ),
        ],
      ],
    );
  }

  /// 显示数据路径配置对话框
  void _showDataPathDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _DataPathConfigDialog(),
    );
  }
}

/// 数据路径配置对话框
class _DataPathConfigDialog extends ConsumerStatefulWidget {
  const _DataPathConfigDialog();

  @override
  ConsumerState<_DataPathConfigDialog> createState() =>
      _DataPathConfigDialogState();
}

class _DataPathConfigDialogState extends ConsumerState<_DataPathConfigDialog> {
  final _pathController = TextEditingController();
  bool _isValidating = false;
  String? _validationError;
  String? _compatibilityWarning;

  @override
  void initState() {
    super.initState();
    _loadCurrentPath();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  /// 加载当前路径
  void _loadCurrentPath() {
    final configAsync = ref.read(dataPathConfigProvider);
    configAsync.whenData((config) async {
      final actualPath = await config.getActualDataPath();
      if (mounted) {
        _pathController.text = actualPath;
      }
    });
  }

  /// 选择文件夹
  Future<void> _selectFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null && mounted) {
        _pathController.text = result;
        await _validatePath(result);
      }
    } catch (e) {
      AppLogger.error('选择文件夹失败', error: e, tag: 'DataPathSettings');
    }
  }

  /// 验证路径
  Future<void> _validatePath(String path) async {
    if (path.isEmpty) return;

    setState(() {
      _isValidating = true;
      _validationError = null;
      _compatibilityWarning = null;
    });

    try {
      final result = await DataPathConfigService.validatePath(path);
      if (mounted) {
        setState(() {
          _isValidating = false;
          if (!result.isValid) {
            _validationError = result.errorMessage;
          } else {
            // 检查数据兼容性
            _checkCompatibility(path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _validationError = 'pathValidationFailedGeneric';
        });
      }
      AppLogger.error('路径验证失败', error: e, tag: 'DataPathSettings');
    }
  }

  /// 检查数据兼容性
  Future<void> _checkCompatibility(String path) async {
    try {
      final compatibilityResult =
          await DataPathConfigService.checkDataCompatibility(path);
      if (mounted && compatibilityResult.message != null) {
        setState(() {
          _compatibilityWarning = compatibilityResult.message;
        });
      }
    } catch (e) {
      AppLogger.error('兼容性检查失败', error: e, tag: 'DataPathSettings');
    }
  }

  /// 应用新路径
  Future<void> _applyNewPath() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;

    try {
      final confirmed = await _showConfirmDialog();
      if (!confirmed) return;

      // 检查是否需要数据迁移
      bool needsMigration = false;
      String? currentPath;
      final configAsync = ref.read(dataPathConfigProvider);

      configAsync.when(
        data: (config) async {
          currentPath = await config.getActualDataPath();
          needsMigration = currentPath != path && !config.useDefaultPath;
        },
        loading: () {},
        error: (error, stack) =>
            AppLogger.error('获取当前配置失败', error: error, tag: 'DataPathSettings'),
      );

      // 如果需要迁移，显示进度对话框
      if (needsMigration && currentPath != null && mounted) {
        _showMigrationProgressDialog(currentPath!, path);
      }

      // 设置新路径
      final success = await ref
          .read(dataPathConfigProvider.notifier)
          .setCustomDataPath(path);

      // 关闭迁移进度对话框
      if (needsMigration && mounted) {
        Navigator.of(context).pop();
      }

      if (success && mounted) {
        Navigator.of(context).pop(); // 关闭配置对话框
        _showRestartDialog();
      } else if (mounted) {
        _showErrorDialog('setDataPathFailed');
      }
    } catch (e) {
      AppLogger.error('应用新路径失败', error: e, tag: 'DataPathSettings');
      if (mounted) {
        _showErrorDialog('setDataPathFailedWithError');
      }
    }
  }

  /// 重置为默认路径
  Future<void> _resetToDefault() async {
    try {
      final confirmed = await _showResetConfirmDialog();
      if (!confirmed) return;

      final success =
          await ref.read(dataPathConfigProvider.notifier).resetToDefaultPath();

      if (success && mounted) {
        Navigator.of(context).pop(); // 关闭配置对话框
        _showRestartDialog();
      } else if (mounted) {
        _showErrorDialog('resetToDefaultFailed');
      }
    } catch (e) {
      AppLogger.error('重置默认路径失败', error: e, tag: 'DataPathSettings');
      if (mounted) {
        _showErrorDialog('resetToDefaultFailedWithError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.dataPathSettings),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dataPathSettingsDescription,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.m),

            // 路径输入框
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: InputDecoration(
                      labelText: l10n.dataPath,
                      hintText: l10n.dataPathHint,
                      errorText: _validationError != null
                          ? l10n.pathValidationFailedGeneric
                          : null,
                      suffixIcon: _isValidating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      // 清除之前的验证结果
                      if (_validationError != null ||
                          _compatibilityWarning != null) {
                        setState(() {
                          _validationError = null;
                          _compatibilityWarning = null;
                        });
                      }
                    },
                    onSubmitted: (value) => _validatePath(value),
                  ),
                ),
                const SizedBox(width: AppSizes.s),
                IconButton(
                  onPressed: _selectFolder,
                  icon: const Icon(Icons.folder_open),
                  tooltip: l10n.selectFolder,
                ),
              ],
            ),

            // 兼容性警告
            if (_compatibilityWarning != null) ...[
              const SizedBox(height: AppSizes.s),
              Container(
                padding: const EdgeInsets.all(AppSizes.s),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: AppSizes.s),
                    Expanded(
                      child: Text(
                        _compatibilityWarning!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        OutlinedButton(
          onPressed: _resetToDefault,
          child: Text(l10n.resetDataPathToDefault),
        ),
        ElevatedButton(
          onPressed: (_validationError == null && !_isValidating)
              ? _applyNewPath
              : null,
          child: Text(l10n.applyNewPath),
        ),
      ],
    );
  }

  /// 显示确认对话框
  Future<bool> _showConfirmDialog() async {
    final l10n = AppLocalizations.of(context);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.confirmChangeDataPath),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.changeDataPathMessage),
                const SizedBox(height: AppSizes.s),
                if (_compatibilityWarning != null) ...[
                  Text('${l10n.note}:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    _compatibilityWarning!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppSizes.s),
                Text(l10n.confirmContinue),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.ok),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// 显示重置确认对话框
  Future<bool> _showResetConfirmDialog() async {
    final l10n = AppLocalizations.of(context);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.confirmResetToDefaultPath),
            content: Text(l10n.resetToDefaultPathMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.reset),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// 显示重启对话框
  void _showRestartDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.needRestartApp),
        content: Text(l10n.dataPathChangedMessage),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AppRestartService.restartApp(context);
            },
            child: Text(l10n.restartNow),
          ),
        ],
      ),
    );
  }

  /// 显示错误对话框
  void _showErrorDialog(String messageKey) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.error('错误')), // 使用现有的错误函数
        content: Text(_getErrorMessage(l10n, messageKey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  /// 获取错误消息
  String _getErrorMessage(AppLocalizations l10n, String key) {
    switch (key) {
      case 'setDataPathFailed':
        return l10n.setDataPathFailed;
      case 'setDataPathFailedWithError':
        return l10n.setDataPathFailedWithError('未知错误');
      case 'resetToDefaultFailed':
        return l10n.resetToDefaultFailed;
      case 'resetToDefaultFailedWithError':
        return l10n.resetToDefaultFailedWithError('未知错误');
      default:
        return key;
    }
  }

  /// 显示迁移进度对话框
  Future<void> _showMigrationProgressDialog(
      String sourcePath, String targetPath) async {
    final l10n = AppLocalizations.of(context);
    final estimate = await DataMigrationService.estimateMigration(sourcePath);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(l10n.migratingData),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSizes.m),
              Text('${l10n.fileCount}: ${estimate.fileCount}'),
              Text('${l10n.dataSize}: ${estimate.formattedSize}'),
              Text('${l10n.estimatedTime}: ${estimate.formattedDuration}'),
              const SizedBox(height: AppSizes.s),
              Text(
                l10n.doNotCloseApp,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
