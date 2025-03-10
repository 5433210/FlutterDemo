import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'alert_notifier.dart';

/// 备份配置
class BackupConfig {
  final String backupPath;
  final Duration backupInterval;
  final int maxBackups;
  final bool compressBackups;
  final bool encryptBackups;
  final String? encryptionKey;
  final Set<String> includePaths;
  final Set<String> excludePaths;

  const BackupConfig({
    required this.backupPath,
    this.backupInterval = const Duration(hours: 24),
    this.maxBackups = 7,
    this.compressBackups = true,
    this.encryptBackups = false,
    this.encryptionKey,
    this.includePaths = const {},
    this.excludePaths = const {},
  });
}

/// 备份管理器
class BackupManager {
  final AlertNotifier notifier;
  final BackupConfig config;
  Timer? _backupTimer;
  bool _running = false;

  BackupManager({
    required this.notifier,
    required this.config,
  }) {
    if (!Directory(config.backupPath).existsSync()) {
      Directory(config.backupPath).createSync(recursive: true);
    }
  }

  /// 执行备份
  Future<String> backup() async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile = path.join(config.backupPath, 'backup_$timestamp.zip');

    try {
      final archive = Archive();

      // 收集文件
      for (final dir in config.includePaths) {
        await _addDirectoryToArchive(archive, dir);
      }

      // 创建压缩文件
      var bytes = ZipEncoder().encode(archive);
      if (bytes == null) {
        throw Exception('Failed to encode archive');
      }

      // 加密
      if (config.encryptBackups && config.encryptionKey != null) {
        bytes = _encrypt(bytes, config.encryptionKey!);
      }

      // 写入文件
      await File(backupFile).writeAsBytes(bytes);

      // 清理旧备份
      await _cleanOldBackups();

      notifier.notify(AlertBuilder()
          .message('备份完成')
          .level(AlertLevel.info)
          .addData('file', backupFile)
          .addData('size', bytes.length)
          .build());

      return backupFile;
    } catch (e, stack) {
      notifier.notify(AlertBuilder()
          .message('备份失败')
          .level(AlertLevel.error)
          .addData('error', e.toString())
          .addData('stack', stack.toString())
          .build());
      rethrow;
    }
  }

  /// 清理资源
  void dispose() {
    stop();
  }

  /// 还原备份
  Future<void> restore(String backupFile) async {
    try {
      var bytes = await File(backupFile).readAsBytes();

      // 解密
      if (config.encryptBackups && config.encryptionKey != null) {
        bytes = _decrypt(bytes, config.encryptionKey!);
      }

      // 解压
      final archive = ZipDecoder().decodeBytes(bytes);

      // 还原文件
      for (final file in archive.files) {
        if (file.isFile) {
          final outFile = File(file.name);
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(file.content as List<int>);
        }
      }

      notifier.notify(AlertBuilder()
          .message('还原完成')
          .level(AlertLevel.info)
          .addData('file', backupFile)
          .build());
    } catch (e, stack) {
      notifier.notify(AlertBuilder()
          .message('还原失败')
          .level(AlertLevel.error)
          .addData('error', e.toString())
          .addData('stack', stack.toString())
          .build());
      rethrow;
    }
  }

  /// 启动自动备份
  void start() {
    if (_running) return;
    _running = true;

    _backupTimer?.cancel();
    _backupTimer = Timer.periodic(config.backupInterval, (_) => backup());

    notifier.notify(
        AlertBuilder().message('备份管理器启动').level(AlertLevel.info).build());
  }

  /// 停止自动备份
  void stop() {
    _backupTimer?.cancel();
    _running = false;

    notifier.notify(
        AlertBuilder().message('备份管理器停止').level(AlertLevel.info).build());
  }

  /// 添加目录到存档
  Future<void> _addDirectoryToArchive(Archive archive, String dir) async {
    final baseDir = Directory(dir);
    if (!baseDir.existsSync()) return;

    await for (final entity in baseDir.list(recursive: true)) {
      if (entity is! File) continue;

      final relativePath = path.relative(entity.path, from: dir);
      if (_isExcluded(relativePath)) continue;

      final file = ArchiveFile(
        relativePath,
        entity.lengthSync(),
        await entity.readAsBytes(),
      );
      archive.addFile(file);
    }
  }

  /// 清理旧备份
  Future<void> _cleanOldBackups() async {
    final dir = Directory(config.backupPath);
    final files =
        await dir.list().where((f) => f.path.endsWith('.zip')).toList();

    files.sort((a, b) => b.path.compareTo(a.path));

    for (var i = config.maxBackups; i < files.length; i++) {
      await files[i].delete();
    }
  }

  /// 解密数据
  Uint8List _decrypt(List<int> data, String key) {
    // 实现解密逻辑...
    return Uint8List.fromList(data);
  }

  /// 加密数据
  Uint8List _encrypt(List<int> data, String key) {
    // 实现加密逻辑...
    return Uint8List.fromList(data);
  }

  /// 检查是否排除
  bool _isExcluded(String filePath) {
    return config.excludePaths.any((pattern) {
      return filePath.startsWith(pattern) ||
          path.basename(filePath).startsWith(pattern);
    });
  }
}
