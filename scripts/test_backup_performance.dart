import 'dart:io';

import 'package:path/path.dart' as path;

/// 模拟备份测试工具
/// 创建一些测试数据，然后运行备份流程来测试性能
Future<void> main() async {
  print('=== 备份性能测试工具 ===\n');

  // 创建测试数据目录
  final testDataDir = path.join(Directory.current.path, 'test_data');
  print('📁 创建测试数据目录: $testDataDir');

  // 清理之前的测试数据
  final testDir = Directory(testDataDir);
  if (await testDir.exists()) {
    await testDir.delete(recursive: true);
  }
  await testDir.create(recursive: true);

  // 创建不同类型的测试数据
  await _createTestData(testDataDir);

  // 分析测试数据
  await _analyzeTestData(testDataDir);

  // 模拟备份过程
  await _simulateBackupProcess(testDataDir);

  print('\n✅ 测试完成');
}

/// 创建测试数据
Future<void> _createTestData(String baseDir) async {
  print('\n🔧 创建测试数据...');

  final scenarios = [
    {'name': 'small_files', 'count': 100, 'size': 1024}, // 100个1KB文件
    {'name': 'medium_files', 'count': 50, 'size': 1024 * 1024}, // 50个1MB文件
    {'name': 'large_files', 'count': 5, 'size': 10 * 1024 * 1024}, // 5个10MB文件
    {'name': 'many_small', 'count': 1000, 'size': 512}, // 1000个512B文件
  ];

  for (final scenario in scenarios) {
    final scenarioDir = path.join(baseDir, scenario['name'] as String);
    await Directory(scenarioDir).create();

    final count = scenario['count'] as int;
    final size = scenario['size'] as int;

    print('  📝 创建 ${scenario['name']}: $count 个文件，每个 ${_formatSize(size)}');

    for (int i = 0; i < count; i++) {
      final fileName = 'file_${i.toString().padLeft(4, '0')}.dat';
      final filePath = path.join(scenarioDir, fileName);

      // 创建指定大小的文件
      final file = File(filePath);
      final data = List.filled(size, i % 256);
      await file.writeAsBytes(data);

      // 每100个文件报告一次进度
      if ((i + 1) % 100 == 0 || (i + 1) == count) {
        print('    进度: ${i + 1}/$count');
      }
    }
  }

  // 创建一些子目录结构
  final nestedDir = path.join(baseDir, 'nested_structure');
  await Directory(nestedDir).create();

  for (int level = 0; level < 3; level++) {
    for (int dir = 0; dir < 5; dir++) {
      final dirPath = path.join(nestedDir, 'level_$level', 'dir_$dir');
      await Directory(dirPath).create(recursive: true);

      // 在每个目录中放一些文件
      for (int file = 0; file < 10; file++) {
        final filePath = path.join(dirPath, 'nested_file_$file.txt');
        await File(filePath)
            .writeAsString('Content for level $level, dir $dir, file $file');
      }
    }
  }

  print('  📁 创建嵌套目录结构: 3层 x 5目录 x 10文件');
}

/// 分析测试数据
Future<void> _analyzeTestData(String testDataDir) async {
  print('\n📊 分析测试数据...');

  int totalFiles = 0;
  int totalSize = 0;

  await for (final entity in Directory(testDataDir).list(recursive: true)) {
    if (entity is File) {
      totalFiles++;
      final stat = await entity.stat();
      totalSize += stat.size;
    }
  }

  print('  总文件数: $totalFiles');
  print('  总大小: ${_formatSize(totalSize)}');

  // 预估备份时间
  final estimatedSeconds = _estimateBackupTime(totalFiles, totalSize);
  print('  预估备份时间: ${estimatedSeconds.toStringAsFixed(1)} 秒');

  if (estimatedSeconds > 120) {
    print('  ⚠️ 预估时间超过2分钟，可能会卡顿');
  }
}

/// 模拟备份过程
Future<void> _simulateBackupProcess(String sourceDir) async {
  print('\n🔄 模拟备份过程...');

  final backupDir = path.join(Directory.current.path, 'test_backup');
  final backupFile = path.join(Directory.current.path, 'test_backup.zip');

  // 清理之前的备份
  if (await Directory(backupDir).exists()) {
    await Directory(backupDir).delete(recursive: true);
  }
  if (await File(backupFile).exists()) {
    await File(backupFile).delete();
  }

  final stopwatch = Stopwatch()..start();

  try {
    // 步骤1: 复制文件
    print('  📂 步骤1: 复制文件...');
    final copyStart = DateTime.now();
    await _copyDirectoryRecursive(sourceDir, backupDir);
    final copyDuration = DateTime.now().difference(copyStart);
    print('    复制完成，耗时: ${copyDuration.inSeconds} 秒');

    // 步骤2: 创建ZIP（模拟）
    print('  📦 步骤2: 创建ZIP文件...');
    final zipStart = DateTime.now();
    await _simulateZipCreation(backupDir, backupFile);
    final zipDuration = DateTime.now().difference(zipStart);
    print('    ZIP创建完成，耗时: ${zipDuration.inSeconds} 秒');
  } catch (e) {
    print('    ❌ 备份过程出错: $e');
  }

  stopwatch.stop();
  print('  ✅ 总备份时间: ${stopwatch.elapsed.inSeconds} 秒');

  if (stopwatch.elapsed.inSeconds > 120) {
    print('  🚨 备份时间超过2分钟，需要优化！');
    _suggestOptimizations(stopwatch.elapsed.inSeconds);
  }

  // 清理测试文件
  print('\n🧹 清理测试文件...');
  if (await Directory(backupDir).exists()) {
    await Directory(backupDir).delete(recursive: true);
  }
  if (await File(backupFile).exists()) {
    await File(backupFile).delete();
  }
  if (await Directory(sourceDir).exists()) {
    await Directory(sourceDir).delete(recursive: true);
  }
}

/// 递归复制目录
Future<void> _copyDirectoryRecursive(String source, String target) async {
  final sourceDir = Directory(source);
  final targetDir = Directory(target);

  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  int processedFiles = 0;

  await for (final entity in sourceDir.list()) {
    final newPath = path.join(target, path.basename(entity.path));

    if (entity is Directory) {
      await _copyDirectoryRecursive(entity.path, newPath);
    } else if (entity is File) {
      await entity.copy(newPath);
      processedFiles++;

      if (processedFiles % 100 == 0) {
        print('    已处理 $processedFiles 个文件');
      }
    }
  }
}

/// 模拟ZIP创建
Future<void> _simulateZipCreation(String sourceDir, String zipFile) async {
  // 计算所有文件大小来模拟压缩时间
  int totalSize = 0;
  int fileCount = 0;

  await for (final entity in Directory(sourceDir).list(recursive: true)) {
    if (entity is File) {
      final stat = await entity.stat();
      totalSize += stat.size;
      fileCount++;
    }
  }

  // 模拟压缩时间（每10MB大约1秒）
  final compressionTimeMs = (totalSize / (10 * 1024 * 1024) * 1000).round();
  if (compressionTimeMs > 100) {
    await Future.delayed(Duration(milliseconds: compressionTimeMs));
  }

  // 创建一个假的ZIP文件
  await File(zipFile).writeAsString(
      'Simulated ZIP file with $fileCount files, total size ${_formatSize(totalSize)}');
}

/// 估算备份时间
double _estimateBackupTime(int fileCount, int totalSize) {
  // 文件处理时间 (每秒500个文件)
  final fileTime = fileCount / 500.0;

  // 数据复制时间 (每秒20MB)
  final dataTime = totalSize / (20 * 1024 * 1024);

  // 压缩时间 (每秒10MB)
  final compressTime = totalSize / (10 * 1024 * 1024);

  return fileTime + dataTime + compressTime;
}

/// 格式化文件大小
String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024)
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// 优化建议
void _suggestOptimizations(int actualSeconds) {
  print('\n💡 优化建议:');
  print('  1. 增加文件大小限制，跳过超大文件');
  print('  2. 批量处理小文件');
  print('  3. 添加更详细的进度报告');
  print('  4. 考虑异步并行处理');
  print('  5. 优化ZIP压缩算法');
}
