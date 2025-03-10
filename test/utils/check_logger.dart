import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 日志记录器
class CheckLogger {
  static final _instance = CheckLogger._();
  // 静态访问器以兼容现有代码
  static String? get currentLogPath => instance._currentLogPath;

  static CheckLogger get instance => _instance;
  static LogLevel get logLevel => instance.minLevel;

  static set logLevel(LogLevel level) => instance.minLevel = level;
  final String defaultLogPath = 'logs/test.log';
  String? _currentLogPath;
  final _logs = <LogRecord>[];

  final _sections = <String, DateTime>{};

  final _progress = <String, ProgressContext>{};

  LogLevel minLevel;
  factory CheckLogger() => instance;
  CheckLogger._({
    this.minLevel = LogLevel.debug,
  });

  /// 清理日志
  void clear() {
    _logs.clear();
    _sections.clear();
    _progress.clear();
  }

  /// 创建进度上下文
  ProgressContext createProgress([String name = '', int total = 100]) {
    final ctx = ProgressContext(name, total);
    if (name.isNotEmpty) {
      _progress[name] = ctx;
    }
    return ctx;
  }

  /// 调试日志
  void debug(String message, [dynamic error]) {
    _log(LogLevel.debug, message, error);
  }

  /// 错误日志
  void error(String message, [dynamic error]) {
    _log(LogLevel.error, message, error);
  }

  /// 获取日志记录
  List<LogRecord> getLogs({
    LogLevel? level,
    DateTime? start,
    DateTime? end,
  }) {
    return _logs.where((log) {
      if (level != null && log.level != level) return false;
      if (start != null && log.timestamp.isBefore(start)) return false;
      if (end != null && log.timestamp.isAfter(end)) return false;
      return true;
    }).toList();
  }

  /// 信息日志
  void info(String message, [dynamic error]) {
    _log(LogLevel.info, message, error);
  }

  /// 更新进度
  void progress(
    String name, {
    int? current,
    String? status,
    bool? completed,
  }) {
    final ctx = _progress[name];
    if (ctx == null) return;

    if (current != null) ctx.setCurrent(current);
    if (status != null) ctx.setStatus(status);
    if (completed == true) ctx.complete();

    _printProgress(ctx);
  }

  /// 运行操作
  Future<T> runOperation<T>(
    String name,
    FutureOr<T> Function() operation,
  ) async {
    final context = createProgress(name);
    info('开始操作: $name');

    try {
      final result = await operation();
      if (!context.completed) {
        context.complete();
      }
      _printProgress(context);
      info('完成操作: $name');
      return result;
    } catch (e, stack) {
      error('操作失败: $name', '$e\n$stack');
      rethrow;
    } finally {
      if (name.isNotEmpty) {
        _progress.remove(name);
      }
    }
  }

  /// 保存日志
  Future<void> save([dynamic path, dynamic tag]) async {
    SaveOptions options;
    if (path is SaveOptions) {
      options = path;
    } else if (path is String) {
      options = SaveOptions(path: path, tag: tag?.toString());
    } else {
      options = const SaveOptions();
    }

    final logPath = options.path ?? defaultLogPath;
    final dir = Directory(logPath).parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final logData = {
      'logs': _logs.map((r) => r.toJson()).toList(),
      'metadata': {
        'timestamp': DateTime.now().toIso8601String(),
        if (options.tag != null) 'tag': options.tag,
      }
    };

    await File(logPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(logData),
    );

    _currentLogPath = logPath;
    info('日志已保存: $logPath');
  }

  /// 开始部分
  void section(String name) {
    _sections[name] = DateTime.now();
    info('开始: $name');
  }

  /// 警告日志
  void warn(String message, [dynamic error]) {
    _log(LogLevel.warn, message, error);
  }

  /// 警告（兼容接口）
  void warning(String message, [dynamic error]) {
    warn(message, error);
  }

  /// 记录日志
  void _log(LogLevel level, String message, [dynamic error]) {
    if (level.index < minLevel.index) return;

    final record = LogRecord(
      level: level,
      message: message,
      error: error,
      timestamp: DateTime.now(),
    );

    _logs.add(record);
    _print(record);
  }

  /// 打印日志
  void _print(LogRecord record) {
    final prefix = switch (record.level) {
      LogLevel.debug => '🔍 DEBUG',
      LogLevel.info => '📝 INFO',
      LogLevel.warn => '⚠️ WARN',
      LogLevel.error => '❌ ERROR',
    };

    print('$prefix: ${record.message}');
    if (record.error != null) {
      print('错误详情: ${record.error}');
    }
  }

  /// 打印进度
  void _printProgress(ProgressContext ctx) {
    final percent = (ctx.progress * 100).toStringAsFixed(1);
    final status = ctx.status ?? '';
    final completion = ctx.completed ? '[完成]' : '';

    info('${ctx.name}: $percent% $status $completion');
  }

  /// 适配普通操作
  static Future<T> run<T>(
    String name,
    FutureOr<T> Function() operation,
  ) {
    return instance.runOperation(name, operation);
  }
}

/// 日志级别
enum LogLevel {
  debug,
  info,
  warn,
  error,
}

/// 日志记录
class LogRecord {
  final LogLevel level;
  final String message;
  final dynamic error;
  final DateTime timestamp;

  const LogRecord({
    required this.level,
    required this.message,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'level': level.toString(),
        'message': message,
        'error': error?.toString(),
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 进度接口
abstract class ProgressCallback {
  void complete();
  void increment([int value = 1]);
  void setCurrent(int value);
  void setStatus(String message);
}

/// 进度上下文
class ProgressContext implements ProgressCallback {
  String _name;
  int _total;
  int _current;
  String? status;
  bool _completed;

  // 构造函数保持公开以兼容现有代码
  ProgressContext([String name = '', int total = 100])
      : _name = name,
        _total = total,
        _current = 0,
        _completed = false;

  bool get completed => _completed;
  int get current => _current;
  String get name => _name;
  double get progress => _total > 0 ? _current / _total : 0.0;
  int get total => _total;

  @override
  void complete() {
    _current = _total;
    _completed = true;
  }

  /// 创建子进度
  ProgressContext createChild(String childName, {int? childTotal}) {
    final child = ProgressContext();
    child.setName('$name/$childName');
    child.setTotal(childTotal ?? total);
    return child;
  }

  @override
  void increment([int value = 1]) {
    _current = (_current + value).clamp(0, _total);
    if (_current >= _total) {
      complete();
    }
  }

  @override
  void setCurrent(int value) {
    _current = value.clamp(0, _total);
    if (_current >= _total) {
      complete();
    }
  }

  void setName(String value) => _name = value;

  @override
  void setStatus(String message) {
    status = message;
  }

  void setTotal(int value) => _total = value;
}

/// 保存选项
class SaveOptions {
  final String? path;
  final String? tag;
  final bool overwrite;

  const SaveOptions({
    this.path,
    this.tag,
    this.overwrite = false,
  });
}

/// 日志操作扩展
extension LogOperationExt<T> on Future<T> Function() {
  Future<T> withLog(String name) => CheckLogger.run(name, this);
}
