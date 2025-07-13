import 'dart:async';

/// 全局备份进度管理器
/// 用于协调备份进度对话框和实际备份操作之间的状态同步
class BackupProgressManager {
  static final BackupProgressManager _instance =
      BackupProgressManager._internal();
  factory BackupProgressManager() => _instance;
  BackupProgressManager._internal();

  StreamController<BackupProgressState>? _progressController;
  StreamController<String>? _stepController;

  /// 进度状态流
  Stream<BackupProgressState> get progressStream =>
      _progressController?.stream ?? const Stream.empty();

  /// 步骤更新流
  Stream<String> get stepStream =>
      _stepController?.stream ?? const Stream.empty();

  /// 开始备份
  void startBackup() {
    _progressController = StreamController<BackupProgressState>.broadcast();
    _stepController = StreamController<String>.broadcast();

    _progressController?.add(BackupProgressState.started);
    _stepController?.add('准备备份...');
  }

  /// 更新步骤
  void updateStep(String step, {String? detail}) {
    _stepController?.add(detail != null ? '$step\n$detail' : step);
  }

  /// 更新进度
  void updateProgress(int current, int total) {
    if (total > 0) {
      final progressValue = BackupProgressState.withProgress(current / total);
      _progressController?.add(progressValue);
    }
  }

  /// 完成备份
  void completeBackup() {
    _progressController?.add(BackupProgressState.completed);
    _stepController?.add('备份完成');
    _cleanup();
  }

  /// 备份失败
  void failBackup(String error) {
    _progressController?.add(BackupProgressState.failed(error));
    _stepController?.add('备份失败: $error');
    _cleanup();
  }

  /// 取消备份
  void cancelBackup() {
    _progressController?.add(BackupProgressState.cancelled);
    _stepController?.add('备份已取消');
    _cleanup();
  }

  /// 清理资源
  void _cleanup() {
    Future.delayed(const Duration(seconds: 1), () {
      _progressController?.close();
      _stepController?.close();
      _progressController = null;
      _stepController = null;
    });
  }

  /// 重置状态
  void reset() {
    _progressController?.close();
    _stepController?.close();
    _progressController = null;
    _stepController = null;
  }
}

/// 备份进度状态
class BackupProgressState {
  final BackupStatus status;
  final double? progress; // 0.0 - 1.0
  final String? error;

  const BackupProgressState._(this.status, {this.progress, this.error});

  static const BackupProgressState started =
      BackupProgressState._(BackupStatus.started);
  static const BackupProgressState completed =
      BackupProgressState._(BackupStatus.completed);
  static const BackupProgressState cancelled =
      BackupProgressState._(BackupStatus.cancelled);

  static BackupProgressState withProgress(double value) =>
      BackupProgressState._(BackupStatus.inProgress, progress: value);

  static BackupProgressState failed(String error) =>
      BackupProgressState._(BackupStatus.failed, error: error);
}

/// 备份状态枚举
enum BackupStatus {
  started,
  inProgress,
  completed,
  failed,
  cancelled,
}
