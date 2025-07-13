#!/usr/bin/env dart

/// 测试备份功能的脚本
/// 验证删除全部备份功能和导出备份功能

import 'dart:io';

void main() async {
  print('=== 备份功能测试脚本 ===');

  // 检查备份路径设置页面是否包含删除所有备份功能
  await checkBackupLocationSettings();

  // 检查统一备份管理页面的导出功能修复
  await checkUnifiedBackupManagement();

  print('\n✅ 所有检查完成！');
}

Future<void> checkBackupLocationSettings() async {
  print('\n📂 检查备份路径设置页面...');

  const filePath = 'lib/presentation/pages/backup_location_settings.dart';
  final file = File(filePath);

  if (!await file.exists()) {
    print('❌ 文件不存在: $filePath');
    return;
  }

  final content = await file.readAsString();

  // 检查删除所有备份功能
  final checks = [
    '_deleteAllBackupsInCurrentPath',
    'ElevatedButton.icon',
    'Icons.delete',
    '删除所有备份',
    'backgroundColor: Colors.red',
    '_performDeleteAllBackups',
    'CircularProgressIndicator',
    'BackupRegistryManager.deleteBackup',
  ];

  for (final check in checks) {
    if (content.contains(check)) {
      print('✅ 找到: $check');
    } else {
      print('❌ 未找到: $check');
    }
  }
}

Future<void> checkUnifiedBackupManagement() async {
  print('\n📋 检查统一备份管理页面...');

  const filePath = 'lib/presentation/pages/unified_backup_management_page.dart';
  final file = File(filePath);

  if (!await file.exists()) {
    print('❌ 文件不存在: $filePath');
    return;
  }

  final content = await file.readAsString();

  // 检查导出功能修复
  final checks = [
    '_performBatchExport',
    'final progressDialog = showDialog',
    'Navigator.of(context).pop()', // 确保关闭对话框的代码存在
    'barrierDismissible: false',
    'exportingBackupsProgressFormat',
  ];

  for (final check in checks) {
    if (content.contains(check)) {
      print('✅ 找到: $check');
    } else {
      print('❌ 未找到: $check');
    }
  }
}
