// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as p;
import 'directory_analyzer.dart';

void main() async {
  print('开始分析应用数据目录...');

  // 获取应用数据路径 (通常在AppData下)
  final appDataPaths = [
    p.join(Platform.environment['APPDATA'] ?? '', 'CharAsGem'),
    p.join(Platform.environment['LOCALAPPDATA'] ?? '', 'CharAsGem'),
    'C:\\Users\\${Platform.environment['USERNAME'] ?? 'user'}\\AppData\\Roaming\\CharAsGem',
    'C:\\Users\\${Platform.environment['USERNAME'] ?? 'user'}\\AppData\\Local\\CharAsGem',
  ];

  String? appDataPath;
  for (final path in appDataPaths) {
    if (await Directory(path).exists()) {
      appDataPath = path;
      break;
    }
  }

  if (appDataPath == null) {
    print('❌ 未找到应用数据目录');
    print('检查的路径:');
    for (final path in appDataPaths) {
      print('  - $path');
    }
    return;
  }

  print('✅ 找到应用数据目录: $appDataPath');

  // 分析主要数据目录
  final dirsToAnalyze = [
    'works',
    'characters',
    'practices',
    'library',
    'database',
    'cache',
    'temp',
  ];

  int totalFiles = 0;
  int totalSize = 0;

  for (final dirName in dirsToAnalyze) {
    final dirPath = p.join(appDataPath, dirName);
    print('\n正在分析: $dirName...');

    final info = await DirectoryAnalyzer.analyze(dirPath);
    info.printSummary();

    totalFiles += info.totalFiles;
    totalSize += info.totalSize;
  }

  print('\n${'=' * 50}');
  print('📊 总体统计');
  print('总文件数: $totalFiles');
  print('总大小: ${DirectoryAnalyzer.formatSize(totalSize)}');

  // 性能预测
  print('\n⏱️ 备份时间预测');
  if (totalSize > 500 * 1024 * 1024) {
    // >500MB
    print('⚠️  数据量较大，备份可能需要 5-15 分钟');
  } else if (totalSize > 100 * 1024 * 1024) {
    // >100MB
    print('ℹ️  数据量适中，备份可能需要 2-5 分钟');
  } else {
    print('✅ 数据量较小，备份应该在 1-2 分钟内完成');
  }

  if (totalFiles > 10000) {
    print('⚠️  文件数量过多，可能影响备份速度');
  }

  print('\n💡 建议:');
  if (totalSize > 1024 * 1024 * 1024) {
    // >1GB
    print('- 考虑清理不必要的缓存文件');
    print('- 将大文件移动到其他位置');
  }

  final cacheDir = p.join(appDataPath, 'cache');
  if (await Directory(cacheDir).exists()) {
    final cacheInfo = await DirectoryAnalyzer.analyze(cacheDir);
    if (cacheInfo.totalSize > 100 * 1024 * 1024) {
      print('- 可以清理缓存目录以减少备份大小');
    }
  }
}
