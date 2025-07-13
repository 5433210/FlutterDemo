import 'dart:io';
import 'lib/application/services/backup_registry_manager.dart';

/// 测试重复检查功能
void main() async {
  print('=== 备份重复检查功能测试 ===\n');

  try {
    // 测试1: 检查文件是否存在
    print('测试1: 检查文件存在性');
    const testPath = 'test_file.txt';
    final exists = await BackupRegistryManager.checkFileExistsAtPath(testPath);
    print('文件 $testPath 是否存在: $exists\n');

    // 测试2: 生成唯一文件名
    print('测试2: 生成唯一文件名');
    const originalName = 'backup.db';
    const targetDir = './test_directory';

    // 创建测试目录
    final dir = Directory(targetDir);
    if (!await dir.exists()) {
      await dir.create();
    }

    // 创建一个测试文件
    final testFile = File('$targetDir/$originalName');
    if (!await testFile.exists()) {
      await testFile.writeAsString('test content');
    }

    final uniqueName = await BackupRegistryManager.generateUniqueFilename(
        targetDir, originalName);
    print('原始文件名: $originalName');
    print('生成的唯一文件名: $uniqueName\n');

    // 测试3: 校验和计算
    print('测试3: 计算文件校验和');
    if (await testFile.exists()) {
      final checksum = await BackupRegistryManager.calculateChecksum(testFile);
      print('文件校验和: $checksum\n');
    }

    print('=== 测试完成 ===');

    // 清理测试文件
    if (await testFile.exists()) {
      await testFile.delete();
    }
    if (await dir.exists()) {
      await dir.delete();
    }
  } catch (e, stack) {
    print('测试失败: $e');
    print('Stack trace: $stack');
  }
}
