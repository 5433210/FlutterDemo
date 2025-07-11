// 示例：如何使用新的备份系统

import 'package:flutter/material.dart';
// 导入必要的服务和模型
import '../lib/application/services/enhanced_backup_service.dart';
import '../lib/application/services/service_locator.dart';
import '../lib/presentation/pages/backup_management_page.dart';
import '../lib/presentation/pages/backup_location_settings.dart';
import '../lib/presentation/pages/data_path_management_page.dart';

class BackupSystemExample {
  /// 示例：创建备份
  static Future<void> createBackupExample() async {
    try {
      final backupService = ServiceLocator().get<EnhancedBackupService>();
      await backupService.createBackup(description: '重要更新前的备份');
      print('备份创建成功');
    } catch (e) {
      print('备份创建失败: $e');
    }
  }
  
  /// 示例：获取备份列表
  static Future<void> listBackupsExample() async {
    try {
      final backupService = ServiceLocator().get<EnhancedBackupService>();
      final backups = await backupService.getBackups();
      
      for (final backup in backups) {
        print('备份: ${backup.filename}');
        print('  描述: ${backup.description}');
        print('  大小: ${backup.size} 字节');
        print('  创建时间: ${backup.createdTime}');
        print('  位置: ${backup.location}');
      }
    } catch (e) {
      print('获取备份列表失败: $e');
    }
  }
  
  /// 示例：恢复备份
  static Future<void> restoreBackupExample(String backupId) async {
    try {
      final backupService = ServiceLocator().get<EnhancedBackupService>();
      await backupService.restoreBackup(backupId);
      print('备份恢复成功');
    } catch (e) {
      print('备份恢复失败: $e');
    }
  }
}

/// 示例：在设置页面添加备份管理入口
class SettingsPageExample extends StatelessWidget {
  const SettingsPageExample({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 其他设置项...
          
          const Divider(),
          const ListTile(
            title: Text('备份与恢复'),
            subtitle: Text('管理应用数据备份'),
          ),
          
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份管理'),
            subtitle: const Text('创建、恢复和管理备份'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BackupManagementPage(
                  backupService: ServiceLocator().get<EnhancedBackupService>(),
                ),
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('备份位置设置'),
            subtitle: const Text('设置备份文件存储位置'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BackupLocationSettings(),
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('数据路径管理'),
            subtitle: const Text('管理应用数据存储位置'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DataPathManagementPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
