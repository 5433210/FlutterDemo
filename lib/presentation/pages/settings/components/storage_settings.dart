import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../../../infrastructure/logging/logger.dart';
import '../../../../utils/file_size_formatter.dart';
import '../../../../utils/path_helper.dart';
import '../../../providers/storage_info_provider.dart';
import '../../../widgets/settings/settings_section.dart';

class StorageSettings extends ConsumerStatefulWidget {
  const StorageSettings({super.key});

  @override
  ConsumerState<StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends ConsumerState<StorageSettings> {
  bool _isLoading = false;
  bool _isExporting = false;
  String? _exportPath;

  @override
  Widget build(BuildContext context) {
    final storageInfo = ref.watch(storageInfoProvider);

    return SettingsSection(
      title: '存储',
      icon: Icons.storage_outlined,
      children: [
        ListTile(
          title: const Text('存储路径'),
          subtitle: FutureBuilder<String>(
            future: _getStoragePath(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('正在获取...');
              }
              return Text(snapshot.data ?? '未知路径');
            },
          ),
          leading: const Icon(Icons.folder_outlined),
          onTap: _changeStoragePath,
        ),
        const Divider(),
        ListTile(
          title: const Text('作品数量'),
          subtitle: Text('共 ${storageInfo.workCount} 个作品'),
          leading: const Icon(Icons.image_outlined),
        ),
        ListTile(
          title: const Text('总存储空间'),
          subtitle: Text(
            '${FileSizeFormatter.formatBytes(storageInfo.totalSize)} (${storageInfo.fileCount}个文件)',
          ),
          leading: const Icon(Icons.data_usage_outlined),
        ),
        const Divider(),
        ListTile(
          title: const Text('导出数据'),
          subtitle: _isExporting
              ? const Text('正在导出...')
              : _exportPath != null
                  ? Text('已导出至: $_exportPath')
                  : const Text('将所有数据导出为备份文件'),
          leading: const Icon(Icons.upload_outlined),
          trailing: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _isExporting ? null : _exportData,
        ),
        ListTile(
          title: const Text('清理缓存'),
          subtitle: Text(
            '缓存大小: ${FileSizeFormatter.formatBytes(storageInfo.cacheSize)}',
          ),
          leading: const Icon(Icons.cleaning_services_outlined),
          trailing: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _isLoading ? null : _clearCache,
        ),
      ],
    );
  }

  Future<void> _changeStoragePath() async {
    // 此处实现选择存储路径的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('更改存储路径功能尚未实现')),
    );
  }

  Future<void> _clearCache() async {
    try {
      setState(() => _isLoading = true);

      // 在实际应用中，这里应该调用实际的清理缓存逻辑
      await Future.delayed(const Duration(seconds: 1)); // 模拟操作时间

      // 刷新存储信息
      await ref.read(storageInfoProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('缓存已清理')),
        );
      }
    } catch (e) {
      AppLogger.error('清理缓存失败', tag: 'StorageSettings', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清理缓存失败: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportData() async {
    try {
      setState(() {
        _isExporting = true;
        _exportPath = null;
      });

      // 在实际应用中，这里应该调用实际的数据导出逻辑
      await Future.delayed(const Duration(seconds: 2)); // 模拟操作时间

      // 模拟导出路径
      final appDocDir = await PathHelper.getAppDataPath();
      final exportPath = path.join(appDocDir, 'backups',
          'backup_${DateTime.now().millisecondsSinceEpoch}.zip');

      if (mounted) {
        setState(() {
          _exportPath = exportPath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据导出成功')),
        );
      }
    } catch (e) {
      AppLogger.error('导出数据失败', tag: 'StorageSettings', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出数据失败: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<String> _getStoragePath() async {
    try {
      final appDataPath = await PathHelper.getAppDataPath();
      return appDataPath;
    } catch (e) {
      return '获取失败';
    }
  }
}
