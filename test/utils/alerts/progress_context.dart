import 'dart:async';

import '../alert_notifier.dart';

/// 进度上下文配置
class ProgressConfig {
  final Duration updateInterval;
  final bool notifyProgress;
  final bool notifyCompletion;
  final bool notifyFailure;
  final AlertLevel progressLevel;
  final AlertLevel completionLevel;
  final AlertLevel failureLevel;

  const ProgressConfig({
    this.updateInterval = const Duration(seconds: 1),
    this.notifyProgress = true,
    this.notifyCompletion = true,
    this.notifyFailure = true,
    this.progressLevel = AlertLevel.info,
    this.completionLevel = AlertLevel.info,
    this.failureLevel = AlertLevel.error,
  });
}

/// 进度上下文
class ProgressContext {
  final String name;
  final AlertNotifier notifier;
  final ProgressConfig config;

  ProgressStatus _status = ProgressStatus.notStarted;
  double _progress = 0.0;
  String? _message;
  Timer? _updateTimer;
  Object? _error;
  StackTrace? _stackTrace;
  final _completer = Completer<void>();

  ProgressContext({
    required this.name,
    required this.notifier,
    ProgressConfig? config,
  }) : config = config ?? const ProgressConfig();

  /// 获取完成器
  Future<void> get done => _completer.future;

  /// 获取错误
  Object? get error => _error;

  /// 获取当前消息
  String? get message => _message;

  /// 获取进度值
  double get progress => _progress;

  /// 获取堆栈跟踪
  StackTrace? get stackTrace => _stackTrace;

  /// 获取进度状态
  ProgressStatus get status => _status;

  /// 取消进度
  void cancel([String? reason]) {
    if (_status != ProgressStatus.running) return;

    _status = ProgressStatus.cancelled;
    _message = reason;
    _stopUpdates();

    notifier.notify(AlertBuilder()
        .message('取消: $name${reason != null ? ' - $reason' : ''}')
        .level(AlertLevel.warning)
        .addData('reason', reason)
        .addData('status', _status.name)
        .build());

    _completer.completeError(
      StateError('Progress cancelled${reason != null ? ': $reason' : ''}'),
    );
  }

  /// 完成进度
  void complete([String? message]) {
    if (_status != ProgressStatus.running) return;

    _status = ProgressStatus.completed;
    _progress = 1.0;
    _message = message;
    _stopUpdates();

    if (config.notifyCompletion) {
      notifier.notify(AlertBuilder()
          .message(message ?? '完成: $name')
          .level(config.completionLevel)
          .addData('progress', 1)
          .addData('status', _status.name)
          .build());
    }

    _completer.complete();
  }

  /// 销毁资源
  void dispose() {
    _stopUpdates();
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  /// 标记失败
  void fail(Object error, [StackTrace? stackTrace]) {
    if (_status != ProgressStatus.running) return;

    _status = ProgressStatus.failed;
    _error = error;
    _stackTrace = stackTrace;
    _stopUpdates();

    if (config.notifyFailure) {
      notifier.notify(AlertBuilder()
          .message('失败: $name - $error')
          .level(config.failureLevel)
          .addData('error', error.toString())
          .addData('stack', stackTrace?.toString())
          .addData('status', _status.name)
          .build());
    }

    _completer.completeError(error, stackTrace);
  }

  /// 启动进度
  void start() {
    if (_status != ProgressStatus.notStarted) return;

    _status = ProgressStatus.running;
    _startUpdates();

    if (config.notifyProgress) {
      notifier.notify(AlertBuilder()
          .message('开始: $name')
          .level(config.progressLevel)
          .addData('progress', 0)
          .addData('status', _status.name)
          .build());
    }
  }

  /// 更新进度
  void update(double progress, [String? message]) {
    if (_status != ProgressStatus.running) return;

    _progress = progress.clamp(0.0, 1.0);
    _message = message;

    if (config.notifyProgress) {
      notifier.notify(AlertBuilder()
          .message(message ?? '进度: $name')
          .level(config.progressLevel)
          .addData('progress', _progress)
          .addData('status', _status.name)
          .build());
    }
  }

  /// 开始定期更新
  void _startUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(config.updateInterval, (_) {
      if (_status == ProgressStatus.running && config.notifyProgress) {
        notifier.notify(AlertBuilder()
            .message('进度: $name')
            .level(config.progressLevel)
            .addData('progress', _progress)
            .addData('status', _status.name)
            .build());
      }
    });
  }

  /// 停止定期更新
  void _stopUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }
}

/// 进度状态
enum ProgressStatus {
  notStarted, // 未开始
  running, // 运行中
  completed, // 已完成
  failed, // 失败
  cancelled // 已取消
}
