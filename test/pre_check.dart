import 'dart:io';

import 'package:path/path.dart' as path;

void main() async {
  print('\n预检查环境...\n');

  // 1. 检查工作目录
  final currentDir = Directory.current;
  print('当前工作目录: ${currentDir.path}');

  final pubspecFile = File(path.join(currentDir.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    print('错误: 未找到 pubspec.yaml，请确保在项目根目录运行');
    exit(1);
  }

  // 2. 检查 Dart/Flutter 环境
  try {
    final dartVersion = await Process.run('dart', ['--version']);
    print('\nDart 版本:');
    print(dartVersion.stderr ?? dartVersion.stdout);

    final flutterVersion = await Process.run('flutter', ['--version']);
    print('\nFlutter 版本:');
    print(flutterVersion.stdout);
  } catch (e) {
    print('错误: Dart/Flutter 命令不可用');
    print('请确保 Dart 和 Flutter 已正确安装并添加到 PATH');
    exit(1);
  }

  // 3. 检查并创建必要的目录
  final directories = [
    'test/data',
    'coverage',
  ];

  print('\n检查目录结构...');
  for (final dir in directories) {
    final directory = Directory(path.join(currentDir.path, dir));
    if (!directory.existsSync()) {
      print('创建目录: $dir');
      directory.createSync(recursive: true);
    }
  }

  // 4. 检查文件权限
  print('\n检查文件权限...');
  final scriptsToCheck = [
    'test/check_environment.sh',
    'test/run_tests.sh',
  ];

  if (!Platform.isWindows) {
    for (final script in scriptsToCheck) {
      final file = File(path.join(currentDir.path, script));
      if (file.existsSync()) {
        try {
          await Process.run('chmod', ['+x', script]);
          print('设置执行权限: $script');
        } catch (e) {
          print('警告: 无法设置 $script 的执行权限');
        }
      }
    }
  }

  // 5. 备份现有数据
  print('\n备份现有数据...');
  final backupDir = Directory(path.join(currentDir.path, 'test/backup'));
  if (!backupDir.existsSync()) {
    backupDir.createSync(recursive: true);
  }

  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final dataDir = Directory(path.join(currentDir.path, 'test/data'));
  if (dataDir.existsSync() && dataDir.listSync().isNotEmpty) {
    final backupPath = path.join('test/backup', 'data_$timestamp');
    await Process.run(
      Platform.isWindows ? 'xcopy' : 'cp',
      Platform.isWindows
          ? ['/E', '/I', 'test\\data', backupPath]
          : ['-r', 'test/data/', backupPath],
    );
    print('数据已备份到: $backupPath');
  }

  print('\n预检查完成！✓');
  print('你可以继续运行环境检查脚本');
  print(Platform.isWindows
      ? '运行: dart test/run_check.dart'
      : '运行: ./test/run_check.dart');
}
