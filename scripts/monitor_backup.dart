import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('=== 备份监控工具 ===');
  print('实时监控备份过程中的日志输出');
  print('按 Ctrl+C 退出监控\n');

  // 可能的日志文件路径
  final possibleLogPaths = [
    'logs/app.log',
    'logs/debug.log',
    '../storage/logs/app.log',
    '../temp/backup_debug.log',
  ];

  File? logFile;
  for (final logPath in possibleLogPaths) {
    final file = File(logPath);
    if (await file.exists()) {
      logFile = file;
      print('📁 找到日志文件: $logPath');
      break;
    }
  }

  if (logFile == null) {
    print('❌ 未找到日志文件，尝试监控标准输出...');
    print('建议在另一个终端运行备份操作\n');
    return;
  }

  // 获取文件初始大小
  final initialSize = await logFile.length();
  print('📊 开始监控日志文件 (当前大小: $initialSize 字节)\n');

  // 监控文件变化
  int lastSize = initialSize;

  while (true) {
    try {
      final currentSize = await logFile.length();

      if (currentSize > lastSize) {
        // 读取新增内容
        final file = await logFile.open();
        await file.setPosition(lastSize);
        final newBytes = await file.read(currentSize - lastSize);
        await file.close();

        final newContent = utf8.decode(newBytes);
        final lines = newContent.split('\n');

        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            // 过滤备份相关的日志
            if (line.contains('BackupService') ||
                line.contains('备份') ||
                line.contains('复制') ||
                line.contains('目录') ||
                line.contains('进度')) {
              // 简化输出格式
              final timestamp = _extractTimestamp(line);
              final message = _extractMessage(line);
              final level = _extractLevel(line);

              final levelIcon = _getLevelIcon(level);
              print('$timestamp $levelIcon $message');
            }
          }
        }

        lastSize = currentSize;
      }

      // 每秒检查一次
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      print('❌ 监控过程中出错: $e');
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}

String _extractTimestamp(String logLine) {
  // 尝试提取时间戳
  final timeRegex = RegExp(r'\d{2}:\d{2}:\d{2}');
  final match = timeRegex.firstMatch(logLine);
  return match?.group(0) ?? DateTime.now().toString().substring(11, 19);
}

String _extractMessage(String logLine) {
  // 提取主要消息内容
  if (logLine.contains(']: ')) {
    return logLine.split(']: ').last;
  } else if (logLine.contains(' - ')) {
    return logLine.split(' - ').last;
  }
  return logLine;
}

String _extractLevel(String logLine) {
  if (logLine.contains('ERROR') || logLine.contains('错误')) return 'ERROR';
  if (logLine.contains('WARN') || logLine.contains('警告')) return 'WARN';
  if (logLine.contains('INFO') || logLine.contains('信息')) return 'INFO';
  if (logLine.contains('DEBUG') || logLine.contains('调试')) return 'DEBUG';
  return 'INFO';
}

String _getLevelIcon(String level) {
  switch (level) {
    case 'ERROR':
      return '❌';
    case 'WARN':
      return '⚠️';
    case 'INFO':
      return '📝';
    case 'DEBUG':
      return '🔍';
    default:
      return '📝';
  }
}
