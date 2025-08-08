import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/data_path_provider.dart';
import '../../../../application/services/data_path_config_service.dart';
import '../../../../application/services/unified_path_config_service.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/file_size_formatter.dart';
import '../../data_path_switch_wizard.dart';

/// 新的数据路径管理页面
/// 功能：浏览当前路径和历史路径，显示路径概要信息，支持删除历史路径
class DataPathManagementPage extends ConsumerStatefulWidget {
  const DataPathManagementPage({super.key});

  @override
  ConsumerState<DataPathManagementPage> createState() =>
      _DataPathManagementPageState();
}

class _DataPathManagementPageState
    extends ConsumerState<DataPathManagementPage> {
  bool _isLoading = false;
  String? _currentPath;
  List<PathInfo> _historyPaths = [];

  @override
  void initState() {
    super.initState();
    _loadPathInfo();
  }

  Future<void> _loadPathInfo() async {
    setState(() => _isLoading = true);

    try {
      // 获取当前数据路径
      final dataPathConfig = ref.read(dataPathConfigProvider).value;
      if (dataPathConfig != null) {
        _currentPath = await dataPathConfig.getActualDataPath();
      }

      // 获取历史路径
      _historyPaths = await _getHistoryPaths();

      // 调试信息：打印配置文件内容
      await _debugPrintConfigContent();
    } catch (e) {
      AppLogger.error('加载路径信息失败', error: e, tag: 'DataPathManagement');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 调试方法：打印统一路径配置内容
  Future<void> _debugPrintConfigContent() async {
    try {
      // 检查统一路径配置
      final unifiedConfig = await UnifiedPathConfigService.readConfig();
      AppLogger.debug('统一路径配置内容:', tag: 'DataPathManagement', data: {
        'dataPath': {
          'useDefaultPath': unifiedConfig.dataPath.useDefaultPath,
          'customPath': unifiedConfig.dataPath.customPath,
          'historyPaths': unifiedConfig.dataPath.historyPaths,
          'requiresRestart': unifiedConfig.dataPath.requiresRestart,
        },
        'backupPath': {
          'path': unifiedConfig.backupPath.path,
          'historyPaths': unifiedConfig.backupPath.historyPaths,
        },
        'lastUpdated': unifiedConfig.lastUpdated.toIso8601String(),
      });

      // 特别关注历史路径
      AppLogger.debug('数据路径历史记录:', tag: 'DataPathManagement', data: {
        'historyPaths': unifiedConfig.dataPath.historyPaths,
        'count': unifiedConfig.dataPath.historyPaths.length,
      });

      // 也检查旧配置文件是否存在
      final configPath = await DataPathConfigService.getConfigFilePath();
      final configFile = File(configPath);

      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        AppLogger.debug('旧配置文件仍存在:', tag: 'DataPathManagement', data: {
          'configPath': configPath,
          'content': content,
        });
      } else {
        AppLogger.debug('旧配置文件不存在', tag: 'DataPathManagement', data: {
          'configPath': configPath,
        });
      }
    } catch (e) {
      AppLogger.error('调试打印配置内容失败', error: e, tag: 'DataPathManagement');
    }
  }

  Future<List<PathInfo>> _getHistoryPaths() async {
    try {
      // 从配置中获取真实的历史数据路径
      final historyPathStrings =
          await DataPathConfigService.getHistoryDataPaths();
      final List<PathInfo> historyPaths = [];

      for (final pathStr in historyPathStrings) {
        final pathInfo = await _analyzePathInfo(pathStr);
        historyPaths.add(pathInfo);
      }

      return historyPaths;
    } catch (e) {
      AppLogger.error('获取历史数据路径失败', error: e, tag: 'DataPathManagement');
      return [];
    }
  }

  /// 分析指定路径的详细信息
  Future<PathInfo> _analyzePathInfo(String pathStr) async {
    try {
      final dir = Directory(pathStr);
      final exists = await dir.exists();

      if (!exists) {
        return PathInfo(
          path: pathStr,
          isValid: false,
          size: 0,
          fileCount: 0,
          lastUsed: await _getPathLastUsedTime(pathStr),
        );
      }

      // 路径存在，计算大小和文件数量
      int totalSize = 0;
      int fileCount = 0;

      try {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final stat = await entity.stat();
            totalSize += stat.size;
            fileCount++;
          }
        }
      } catch (e) {
        // 权限不足或其他错误，标记为无效
        AppLogger.warning('无法读取路径内容: $pathStr',
            error: e, tag: 'DataPathManagement');
        return PathInfo(
          path: pathStr,
          isValid: false,
          size: 0,
          fileCount: 0,
          lastUsed: await _getPathLastUsedTime(pathStr),
        );
      }

      return PathInfo(
        path: pathStr,
        isValid: true,
        size: totalSize,
        fileCount: fileCount,
        lastUsed: await _getPathLastUsedTime(pathStr),
      );
    } catch (e) {
      AppLogger.error('分析路径信息失败: $pathStr',
          error: e, tag: 'DataPathManagement');
      return PathInfo(
        path: pathStr,
        isValid: false,
        size: 0,
        fileCount: 0,
        lastUsed: await _getPathLastUsedTime(pathStr),
      );
    }
  }

  /// 获取路径的上次使用时间
  /// 这里使用一个更合理的逻辑来估算上次使用时间
  Future<DateTime> _getPathLastUsedTime(String pathStr) async {
    try {
      // TODO: 理想情况下，应该从SharedPreferences中存储和读取每个路径的真实使用时间
      // 现在先使用一个估算逻辑：查看路径中最近修改的配置文件或数据库文件

      final dir = Directory(pathStr);
      if (!await dir.exists()) {
        // 如果路径不存在，返回一个较早的时间
        return DateTime.now().subtract(const Duration(days: 365));
      }

      DateTime latestTime = DateTime.now().subtract(const Duration(days: 365));

      try {
        // 查找路径中的重要文件（数据库文件、配置文件等）
        await for (final entity in dir.list(recursive: false)) {
          if (entity is File) {
            final fileName =
                entity.path.split(Platform.pathSeparator).last.toLowerCase();
            // 重点关注可能记录使用时间的文件
            if (fileName.contains('.db') ||
                fileName.contains('.sqlite') ||
                fileName.contains('config') ||
                fileName.contains('.json') ||
                fileName.contains('.yaml')) {
              final stat = await entity.stat();
              if (stat.modified.isAfter(latestTime)) {
                latestTime = stat.modified;
              }
            }
          }
        }
      } catch (e) {
        // 如果无法读取，返回默认时间
        AppLogger.warning('无法读取路径文件信息: $pathStr',
            error: e, tag: 'DataPathManagement');
      }

      return latestTime;
    } catch (e) {
      AppLogger.error('获取路径使用时间失败: $pathStr',
          error: e, tag: 'DataPathManagement');
      return DateTime.now().subtract(const Duration(days: 365));
    }
  }

  Future<PathInfo> _analyzeCurrentPath() async {
    if (_currentPath == null) {
      return PathInfo(
        path: '默认路径', // 这里保持硬编码，因为没有context访问l10n
        isValid: false,
        size: 0,
        fileCount: 0,
        lastUsed: DateTime.now(),
      );
    }

    return await _analyzePathInfo(_currentPath!);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dataPathManagementTitle),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPathInfo,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPathInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentPathSection(context, colorScheme),
                    const SizedBox(height: 24),
                    _buildHistoryPathsSection(context, colorScheme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPathSection(
      BuildContext context, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_special, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.currentDataPath,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 路径信息
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: colorScheme.outline.withAlpha((0.2 * 255).round())),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: SelectableText(
                          _currentPath ?? l10n.useDefaultPath,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 使用 FutureBuilder 显示当前路径详细信息
            FutureBuilder<PathInfo>(
              future: _analyzeCurrentPath(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final pathInfo = snapshot.data;
                if (pathInfo == null) {
                  return Text(l10n.getPathInfoFailed);
                }

                return _buildPathInfoDetails(pathInfo, colorScheme,
                    isCurrent: true, context: context);
              },
            ),

            const SizedBox(height: 16),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openPathInExplorer(_currentPath ?? ''),
                    icon: const Icon(Icons.folder_open),
                    label: Text(l10n.browsePath),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      // 直接跳转到数据路径切换向导界面
                      try {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DataPathSwitchWizard(),
                          ),
                        );

                        // 向导完成后刷新数据
                        await _loadPathInfo();
                      } catch (e) {
                        AppLogger.error(l10n.openPathSwitchWizardFailed,
                            error: e, tag: 'DataPathManagement');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '${l10n.openPathSwitchWizardFailed}: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.settings),
                    label: Text(l10n.pathSettings),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPathsSection(
      BuildContext context, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.historyDataPaths,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_historyPaths.length} ${l10n.countUnit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_historyPaths.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_off_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noHistoryPaths,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noHistoryPathsDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _historyPaths.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final pathInfo = _historyPaths[index];
                  return _buildHistoryPathItem(context, pathInfo, colorScheme);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPathItem(
      BuildContext context, PathInfo pathInfo, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 路径头部信息
        Row(
          children: [
            Icon(
              pathInfo.isValid
                  ? Icons.folder_outlined
                  : Icons.folder_off_outlined,
              color: pathInfo.isValid ? colorScheme.primary : colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    pathInfo.path,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pathInfo.isValid ? l10n.validPath : l10n.pathInvalid,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: pathInfo.isValid
                              ? colorScheme.primary
                              : colorScheme.error,
                        ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleHistoryPathAction(value, pathInfo),
              itemBuilder: (context) => [
                if (pathInfo.isValid) ...[
                  PopupMenuItem(
                    value: 'browse',
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open),
                        const SizedBox(width: 8),
                        Text(l10n.browsePath),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'analyze',
                    child: Row(
                      children: [
                        const Icon(Icons.analytics),
                        const SizedBox(width: 8),
                        Text(l10n.pathInfo),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                ],
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(l10n.deletePath,
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 路径详细信息
        _buildPathInfoDetails(pathInfo, colorScheme, context: context),
      ],
    );
  }

  Widget _buildPathInfoDetails(PathInfo pathInfo, ColorScheme colorScheme,
      {bool isCurrent = false, BuildContext? context}) {
    final l10n = context != null ? AppLocalizations.of(context) : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  l10n?.totalSize ?? '总大小',
                  FileSizeFormatter.format(pathInfo.size),
                  Icons.storage,
                  colorScheme,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  l10n?.fileCount ?? '文件数量',
                  '${pathInfo.fileCount}',
                  Icons.insert_drive_file,
                  colorScheme,
                ),
              ),
            ],
          ),
          if (!isCurrent) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    l10n?.lastUsedTime ?? '上次使用',
                    _formatDateTime(pathInfo.lastUsed),
                    Icons.access_time,
                    colorScheme,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    l10n?.statusLabel ?? '状态',
                    pathInfo.isValid
                        ? (l10n?.statusAvailable ?? '可用')
                        : (l10n?.statusUnavailable ?? '不可用'),
                    pathInfo.isValid ? Icons.check_circle : Icons.error,
                    colorScheme,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      String label, String value, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final l10n = AppLocalizations.of(context);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${l10n.monthsAgo}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${l10n.daysAgo}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${l10n.hoursAgo}';
    } else {
      return l10n.justNow;
    }
  }

  Future<void> _handleHistoryPathAction(
      String action, PathInfo pathInfo) async {
    switch (action) {
      case 'browse':
        await _openPathInExplorer(pathInfo.path);
        break;
      case 'analyze':
        await _showPathAnalysis(pathInfo);
        break;
      case 'delete':
        await _deleteHistoryPath(pathInfo);
        break;
    }
  }

  Future<void> _openPathInExplorer(String pathStr) async {
    try {
      if (pathStr.isEmpty) return;
      final l10n = AppLocalizations.of(context);

      final directory = Directory(pathStr);
      if (!await directory.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.pathNotExists)),
          );
        }
        return;
      }

      if (Platform.isWindows) {
        await Process.run('explorer', [pathStr.replaceAll('/', '\\')]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [pathStr]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [pathStr]);
      }
    } catch (e) {
      AppLogger.error('打开路径失败', error: e, tag: 'DataPathManagement');
      final l10n = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.openPathFailed}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showPathAnalysis(PathInfo pathInfo) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pathAnalysis),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.path}: ${pathInfo.path}'),
              const SizedBox(height: 8),
              Text(
                  '${l10n.totalSize}: ${FileSizeFormatter.format(pathInfo.size)}'),
              Text('${l10n.fileCount}: ${pathInfo.fileCount}'),
              Text(
                  '${l10n.lastUsedTime}: ${_formatDateTime(pathInfo.lastUsed)}'),
              Text(
                  '${l10n.statusLabel}: ${pathInfo.isValid ? l10n.statusAvailable : l10n.statusUnavailable}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          if (pathInfo.isValid)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openPathInExplorer(pathInfo.path);
              },
              child: Text(l10n.browse),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteHistoryPath(PathInfo pathInfo) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteHistoryPathRecord),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.confirmDeleteHistoryPath),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                pathInfo.path,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.deleteHistoryPathNote,
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 使用DataPathConfigService删除历史数据路径
        final success =
            await DataPathConfigService.removeHistoryDataPath(pathInfo.path);

        if (success) {
          setState(() {
            _historyPaths.remove(pathInfo);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.historyPathDeleted)),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.deleteFailed('记录不存在'))),
            );
          }
        }
      } catch (e) {
        AppLogger.error('删除历史数据路径失败', error: e, tag: 'DataPathManagement');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
          );
        }
      }
    }
  }
}

/// 路径信息数据模型
class PathInfo {
  final String path;
  final bool isValid;
  final int size;
  final int fileCount;
  final DateTime lastUsed;

  PathInfo({
    required this.path,
    required this.isValid,
    required this.size,
    required this.fileCount,
    required this.lastUsed,
  });
}
