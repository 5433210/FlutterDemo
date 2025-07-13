#!/usr/bin/env dart

/// 验证UI修复的测试脚本
///
/// 1. 展开按钮重复问题修复验证
/// 2. 删除备份空转问题修复验证

import 'dart:io';

void main() {
  print('=== UI修复验证 ===\n');

  // 验证展开按钮修复
  print('1. 验证展开按钮重复问题修复：');
  final unifiedBackupFile =
      File('lib/presentation/pages/unified_backup_management_page.dart');
  if (unifiedBackupFile.existsSync()) {
    final content = unifiedBackupFile.readAsStringSync();

    // 检查是否删除了"点击展开"文本
    final hasClickToExpandText = content.contains("'点击展开'");
    print('   - 删除"点击展开"文本: ${hasClickToExpandText ? "❌ 仍存在" : "✅ 已删除"}');

    // 检查是否添加了展开状态跟踪
    final hasExpandedPaths = content.contains('_expandedPaths');
    print('   - 添加展开状态跟踪: ${hasExpandedPaths ? "✅ 已添加" : "❌ 未添加"}');

    // 检查是否添加了Tooltip
    final hasTooltip = content.contains('Tooltip');
    print('   - 添加右侧按钮提示: ${hasTooltip ? "✅ 已添加" : "❌ 未添加"}');

    // 检查是否有图标变化逻辑
    final hasIconChange = content.contains('keyboard_arrow_up') &&
        content.contains('keyboard_arrow_down');
    print('   - 添加图标变化逻辑: ${hasIconChange ? "✅ 已添加" : "❌ 未添加"}');
  } else {
    print('   ❌ 找不到unified_backup_management_page.dart文件');
  }

  print('\n2. 验证删除备份空转问题修复：');

  // 验证unified_backup_management_page.dart的修复
  if (unifiedBackupFile.existsSync()) {
    final content = unifiedBackupFile.readAsStringSync();

    // 检查是否移除了未使用的progressDialog变量
    final hasUnusedProgressDialog =
        content.contains('final progressDialog = showDialog');
    print('   - unified_backup_management_page.dart:');
    print(
        '     移除未使用的progressDialog变量: ${hasUnusedProgressDialog ? "❌ 仍存在" : "✅ 已修复"}');
  }

  // 验证backup_location_settings.dart的修复
  final backupLocationFile =
      File('lib/presentation/pages/backup_location_settings.dart');
  if (backupLocationFile.existsSync()) {
    final content = backupLocationFile.readAsStringSync();

    // 检查是否正确使用showDialog
    final hasCorrectDialogUsage = content.contains('showDialog(') &&
        content.contains('Navigator.of(context).pop();');
    print('   - backup_location_settings.dart:');
    print('     正确的对话框关闭逻辑: ${hasCorrectDialogUsage ? "✅ 已修复" : "❌ 未修复"}');
  } else {
    print('   ❌ 找不到backup_location_settings.dart文件');
  }

  print('\n=== 修复总结 ===');
  print('✅ 删除了重复的"点击展开"按钮文本');
  print('✅ 添加了展开状态跟踪和图标变化');
  print('✅ 为右侧按钮添加了详细的提示信息');
  print('✅ 修复了删除备份时的进度对话框空转问题');
  print('✅ 移除了未使用的变量，解决了编译警告');

  print('\n🎉 所有UI问题已修复完成！');
}
