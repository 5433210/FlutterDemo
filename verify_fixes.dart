#!/usr/bin/env dart

/// 验证备份功能修复的简单脚本

import 'dart:io';

void main() async {
  print('=== 验证备份功能修复 ===\n');

  // 检查备份路径设置页面
  await verifyBackupLocationSettings();

  // 检查统一备份管理页面
  await verifyUnifiedBackupManagement();

  print('\n✅ 验证完成');
}

Future<void> verifyBackupLocationSettings() async {
  print('📂 检查 backup_location_settings.dart:');

  final file = File('lib/presentation/pages/backup_location_settings.dart');
  if (!await file.exists()) {
    print('❌ 文件不存在');
    return;
  }

  final content = await file.readAsString();
  final checks = {
    '_deleteAllBackupsInCurrentPath': '删除所有备份功能',
    'ElevatedButton.icon': '删除按钮UI',
    'Icons.delete': '删除图标',
    'backgroundColor: Colors.red': '红色按钮样式',
    '_performDeleteAllBackups': '执行删除功能',
    'import \'dart:io\';': 'File类导入',
  };

  checks.forEach((check, desc) {
    if (content.contains(check)) {
      print('✅ $desc');
    } else {
      print('❌ $desc (未找到: $check)');
    }
  });
}

Future<void> verifyUnifiedBackupManagement() async {
  print('\n📋 检查 unified_backup_management_page.dart:');

  final file =
      File('lib/presentation/pages/unified_backup_management_page.dart');
  if (!await file.exists()) {
    print('❌ 文件不存在');
    return;
  }

  final content = await file.readAsString();
  final checks = {
    'final progressDialog = showDialog': '进度对话框修复',
    'Navigator.of(context).pop()': '对话框关闭',
    'barrierDismissible: false': '禁止点击外部关闭',
  };

  checks.forEach((check, desc) {
    if (content.contains(check)) {
      print('✅ $desc');
    } else {
      print('❌ $desc (未找到: $check)');
    }
  });
}
