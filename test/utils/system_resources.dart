import 'dart:io';

/// CPU统计信息
class CpuStats {
  final int idle;
  final int total;

  CpuStats(this.idle, this.total);
}

/// 资源检查结果
class ResourceCheckResult {
  int availableMemoryMB = 0;
  bool memoryCheckPassed = false;

  int availableDiskSpaceMB = 0;
  bool diskCheckPassed = false;

  double cpuUsagePercent = 0;
  bool cpuCheckPassed = false;

  Map<String, bool> dependencyCheckResult = {};
  String? error;

  bool get passed =>
      memoryCheckPassed &&
      diskCheckPassed &&
      cpuCheckPassed &&
      dependencyCheckResult.values.every((passed) => passed);

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('系统资源检查结果:');
    buffer.writeln(
        '- 可用内存: ${availableMemoryMB}MB (${memoryCheckPassed ? '通过' : '不足'})');
    buffer.writeln(
        '- 可用磁盘: ${availableDiskSpaceMB}MB (${diskCheckPassed ? '通过' : '不足'})');
    buffer.writeln(
        '- CPU使用率: ${cpuUsagePercent.toStringAsFixed(1)}% (${cpuCheckPassed ? '正常' : '过高'})');
    buffer.writeln('- 依赖检查:');
    for (final entry in dependencyCheckResult.entries) {
      buffer.writeln('  * ${entry.key}: ${entry.value ? '已安装' : '未安装'}');
    }
    if (error != null) {
      buffer.writeln('错误: $error');
    }
    return buffer.toString();
  }
}

class SystemResources {
  /// 最小可用内存要求（MB）
  static const minMemoryMB = 512;

  /// 最小可用磁盘空间（MB）
  static const minDiskSpaceMB = 1024;

  /// 检查系统资源
  static Future<ResourceCheckResult> checkResources() async {
    final result = ResourceCheckResult();

    try {
      // 检查内存
      result.availableMemoryMB = _getAvailableMemory();
      result.memoryCheckPassed = result.availableMemoryMB >= minMemoryMB;

      // 检查磁盘空间
      result.availableDiskSpaceMB = await _getAvailableDiskSpace();
      result.diskCheckPassed = result.availableDiskSpaceMB >= minDiskSpaceMB;

      // 检查CPU负载
      result.cpuUsagePercent = await _getCpuUsage();
      result.cpuCheckPassed = result.cpuUsagePercent < 80; // 低于80%认为可用

      // 检查必要的依赖
      result.dependencyCheckResult = await _checkDependencies();
    } catch (e) {
      result.error = e.toString();
    }

    return result;
  }

  /// 检查必要的依赖
  static Future<Map<String, bool>> _checkDependencies() async {
    final results = <String, bool>{};

    // 检查Flutter
    try {
      final flutter = await Process.run('flutter', ['--version']);
      results['flutter'] = flutter.exitCode == 0;
    } catch (_) {
      results['flutter'] = false;
    }

    // 检查Dart
    try {
      final dart = await Process.run('dart', ['--version']);
      results['dart'] = dart.exitCode == 0;
    } catch (_) {
      results['dart'] = false;
    }

    // 检查SQLite
    try {
      if (Platform.isWindows) {
        results['sqlite'] = true; // Windows使用sqflite_common_ffi
      } else {
        final sqlite = await Process.run('sqlite3', ['--version']);
        results['sqlite'] = sqlite.exitCode == 0;
      }
    } catch (_) {
      results['sqlite'] = false;
    }

    return results;
  }

  /// 获取可用磁盘空间（MB）
  static Future<int> _getAvailableDiskSpace() async {
    final dir = Directory.current;
    if (Platform.isWindows) {
      final result = await Process.run('cmd', ['/c', 'dir', dir.path]);
      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.contains('bytes free')) {
          final parts = line.trim().split(' ');
          final bytes = int.tryParse(parts[0].replaceAll(',', ''));
          if (bytes != null) {
            return bytes ~/ (1024 * 1024);
          }
        }
      }
    } else {
      final result = await Process.run('df', ['-m', dir.path]);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          return int.tryParse(parts[3]) ?? -1;
        }
      }
    }
    return -1;
  }

  /// 获取可用内存（MB）
  static int _getAvailableMemory() {
    if (Platform.isWindows) {
      // Windows: 使用wmic命令
      final result =
          Process.runSync('wmic', ['OS', 'get', 'FreePhysicalMemory']);
      final lines = result.stdout.toString().split('\n');
      if (lines.length >= 2) {
        final memory = int.tryParse(lines[1].trim());
        if (memory != null) {
          return memory ~/ 1024; // 转换为MB
        }
      }
    } else if (Platform.isLinux) {
      // Linux: 读取/proc/meminfo
      final meminfo = File('/proc/meminfo').readAsStringSync();
      final available = RegExp(r'MemAvailable:\s+(\d+)').firstMatch(meminfo);
      if (available != null) {
        return int.parse(available.group(1)!) ~/ 1024;
      }
    }
    return -1; // 无法获取
  }

  /// 获取CPU使用率（%）
  static Future<double> _getCpuUsage() async {
    if (Platform.isWindows) {
      final result =
          await Process.run('wmic', ['cpu', 'get', 'loadpercentage']);
      final lines = result.stdout.toString().split('\n');
      if (lines.length >= 2) {
        return double.tryParse(lines[1].trim()) ?? -1;
      }
    } else if (Platform.isLinux) {
      final before = _readCpuStats();
      await Future.delayed(const Duration(seconds: 1));
      final after = _readCpuStats();

      final totalDiff = after.total - before.total;
      final idleDiff = after.idle - before.idle;

      if (totalDiff > 0) {
        return 100 * (1 - idleDiff / totalDiff);
      }
    }
    return -1;
  }

  /// 读取CPU统计信息
  static CpuStats _readCpuStats() {
    final stats = File('/proc/stat').readAsLinesSync().first;
    final values = stats
        .split(' ')
        .where((s) => s.isNotEmpty)
        .skip(1)
        .map(int.parse)
        .toList();
    final idle = values[3];
    final total = values.reduce((a, b) => a + b);
    return CpuStats(idle, total);
  }
}
