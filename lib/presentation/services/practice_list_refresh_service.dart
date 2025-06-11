import 'dart:async';

import '../../infrastructure/logging/edit_page_logger_extension.dart';

/// 字帖列表刷新服务
/// 提供全局的字帖列表刷新通知机制
class PracticeListRefreshService {
  static final PracticeListRefreshService _instance = PracticeListRefreshService._internal();
  factory PracticeListRefreshService() => _instance;
  PracticeListRefreshService._internal();

  final StreamController<PracticeListRefreshEvent> _refreshController = 
      StreamController<PracticeListRefreshEvent>.broadcast();

  /// 刷新事件流
  Stream<PracticeListRefreshEvent> get refreshStream => _refreshController.stream;

  /// 通知字帖列表刷新
  void notifyPracticeListRefresh({
    required String practiceId,
    required PracticeRefreshReason reason,
    Map<String, dynamic>? metadata,
  }) {
    final event = PracticeListRefreshEvent(
      practiceId: practiceId,
      reason: reason,
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
    );

    EditPageLogger.performanceInfo(
      '准备发送字帖列表刷新事件',
      data: {
        'practiceId': practiceId,
        'reason': reason.toString(),
        'metadata': metadata,
        'hasListeners': _refreshController.hasListener,
        'streamIsClosed': _refreshController.isClosed,
      },
    );

    try {
      _refreshController.add(event);
      
      EditPageLogger.performanceInfo(
        '字帖列表刷新事件发送成功',
        data: {
          'practiceId': practiceId,
          'reason': reason.toString(),
          'timestamp': event.timestamp.toIso8601String(),
        },
      );
    } catch (e) {
      EditPageLogger.performanceWarning(
        '发送字帖列表刷新事件失败',
        data: {
          'practiceId': practiceId,
          'reason': reason.toString(),
          'error': e.toString(),
        },
      );
    }
  }

  /// 通知字帖保存完成
  void notifyPracticeSaved(String practiceId, {bool hasThumbnail = false}) {
    notifyPracticeListRefresh(
      practiceId: practiceId,
      reason: PracticeRefreshReason.saved,
      metadata: {
        'hasThumbnail': hasThumbnail,
        'operation': 'practice_saved',
      },
    );
  }

  /// 通知字帖删除
  void notifyPracticeDeleted(String practiceId) {
    notifyPracticeListRefresh(
      practiceId: practiceId,
      reason: PracticeRefreshReason.deleted,
      metadata: {
        'operation': 'practice_deleted',
      },
    );
  }

  /// 通知字帖更新
  void notifyPracticeUpdated(String practiceId, {Map<String, dynamic>? changes}) {
    notifyPracticeListRefresh(
      practiceId: practiceId,
      reason: PracticeRefreshReason.updated,
      metadata: {
        'changes': changes,
        'operation': 'practice_updated',
      },
    );
  }

  /// 释放资源
  void dispose() {
    _refreshController.close();
  }
}

/// 字帖列表刷新事件
class PracticeListRefreshEvent {
  final String practiceId;
  final PracticeRefreshReason reason;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const PracticeListRefreshEvent({
    required this.practiceId,
    required this.reason,
    required this.metadata,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PracticeListRefreshEvent{practiceId: $practiceId, reason: $reason, timestamp: $timestamp}';
  }
}

/// 字帖刷新原因
enum PracticeRefreshReason {
  /// 字帖已保存
  saved,
  /// 字帖已删除
  deleted,
  /// 字帖已更新
  updated,
  /// 批量操作
  batchOperation,
} 