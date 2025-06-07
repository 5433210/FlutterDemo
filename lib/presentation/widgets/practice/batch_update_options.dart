/// 批量更新选项配置类
class BatchUpdateOptions {
  /// 是否启用延迟提交
  final bool enableDelayedCommit;

  /// 延迟提交的时间间隔（毫秒）
  final int commitDelayMs;

  /// 是否记录撤销操作
  final bool recordUndoOperation;

  /// 是否通知监听器
  final bool notifyListeners;

  /// 最大批次大小
  final int maxBatchSize;
  
  const BatchUpdateOptions({
    this.enableDelayedCommit = false,
    this.commitDelayMs = 50,
    this.recordUndoOperation = true,
    this.notifyListeners = true,
    this.maxBatchSize = 50,
  });

  /// 创建用于拖拽操作的配置
  factory BatchUpdateOptions.forDragOperation() {
    return const BatchUpdateOptions(
      enableDelayedCommit: false, // 改为立即提交，确保拖拽时及时更新
      commitDelayMs: 16,
      recordUndoOperation: false, // 拖拽过程中不记录撤销操作
      notifyListeners: true, // 确保UI及时更新选中状态
      maxBatchSize: 100,
    );
  }

  /// 创建用于属性面板更新的配置
  factory BatchUpdateOptions.forPropertyUpdate() {
    return const BatchUpdateOptions(
      enableDelayedCommit: false,
      commitDelayMs: 16,
      recordUndoOperation: true,
      notifyListeners: true,
      maxBatchSize: 20,
    );
  }

  @override
  String toString() {
    return 'BatchUpdateOptions(enableDelayedCommit: $enableDelayedCommit, '
        'commitDelayMs: $commitDelayMs, recordUndoOperation: $recordUndoOperation, '
        'notifyListeners: $notifyListeners, maxBatchSize: $maxBatchSize)';
  }
} 