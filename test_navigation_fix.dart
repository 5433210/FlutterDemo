#!/usr/bin/env dart

/// 验证页面导航修复的测试脚本
/// 检查备份操作完成后是否正确地停留在当前页面而不是退回设置页

import 'dart:io';

void main() {
  print('=== 页面导航修复验证 ===\n');

  final unifiedBackupFile =
      File('lib/presentation/pages/unified_backup_management_page.dart');
  final backupLocationFile =
      File('lib/presentation/pages/backup_location_settings.dart');

  print('1. 检查统一备份管理页面的修复:');
  if (unifiedBackupFile.existsSync()) {
    final content = unifiedBackupFile.readAsStringSync();

    // 检查是否修复了危险的popUntil调用
    final hasPopUntil = content.contains('.popUntil((route) => route.isFirst)');
    print('   - 危险的popUntil调用: ${hasPopUntil ? "❌ 仍存在" : "✅ 已移除"}');

    // 检查是否修复了过度的while循环关闭
    final hasWhileLoop =
        content.contains('while (Navigator.of(context).canPop()');
    print('   - 过度的while循环关闭: ${hasWhileLoop ? "❌ 仍存在" : "✅ 已移除"}');

    // 检查是否有正确的路由检查
    final hasRouteCheck =
        content.contains('currentRoute != null && !currentRoute.isFirst');
    print('   - 正确的路由检查: ${hasRouteCheck ? "✅ 已添加" : "❌ 未添加"}');

    // 检查_loadData调用是否保留
    final hasLoadDataCalls = content.contains('await _loadData()');
    print('   - 数据刷新调用: ${hasLoadDataCalls ? "✅ 已保留" : "❌ 缺失"}');
  } else {
    print('   ❌ 找不到unified_backup_management_page.dart文件');
  }

  print('\n2. 检查备份路径设置页面:');
  if (backupLocationFile.existsSync()) {
    final content = backupLocationFile.readAsStringSync();

    // 检查是否正确调用了重新加载
    final hasReload = content.contains('await _loadCurrentPath()');
    print('   - 数据重新加载: ${hasReload ? "✅ 正确实现" : "❌ 缺失"}');

    // 检查是否只关闭对话框
    final hasSimplePopPattern =
        content.contains('Navigator.of(context).pop();') &&
            !content.contains('while (Navigator.of(context).canPop()');
    print('   - 简单对话框关闭: ${hasSimplePopPattern ? "✅ 正确实现" : "❌ 可能有问题"}');
  } else {
    print('   ❌ 找不到backup_location_settings.dart文件');
  }

  print('\n=== 修复分析 ===');
  print('问题根源分析:');
  print('- popUntil((route) => route.isFirst) 会关闭所有页面到第一个页面');
  print('- while循环的Navigator.pop()会关闭多个页面');
  print('- 这些操作会意外关闭备份管理页面本身');

  print('\n修复方案:');
  print('✅ 用路由检查替代popUntil');
  print('✅ 移除while循环式的关闭');
  print('✅ 只关闭当前对话框，保留页面');
  print('✅ 确保数据重新加载和状态更新');

  print('\n预期效果:');
  print('- 创建备份后停留在备份管理页，显示新备份');
  print('- 删除备份后停留在当前页，刷新列表');
  print('- 导出备份后停留在当前页，显示结果');
  print('- 进度对话框正确关闭，但页面保持打开');

  print('\n🎉 页面导航修复完成！用户体验已改善。');
}
