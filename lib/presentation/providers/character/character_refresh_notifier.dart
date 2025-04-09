import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 字符数据刷新通知Provider
/// 用于不同组件间协调字符数据的刷新
final characterRefreshNotifierProvider =
    StateNotifierProvider<CharacterRefreshNotifier, RefreshEvent>((ref) {
  return CharacterRefreshNotifier();
});

/// 刷新通知状态管理
/// 通过刷新事件来触发订阅者刷新
class CharacterRefreshNotifier extends StateNotifier<RefreshEvent> {
  CharacterRefreshNotifier()
      : super(RefreshEvent(
          type: RefreshEventType.none,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));

  /// 获取最后一次事件类型
  RefreshEventType get lastEventType => state.type;

  /// 获取最后一次事件时间戳
  int get lastTimestamp => state.timestamp;

  /// 通知特定类型的刷新事件
  void notifyEvent(RefreshEventType eventType, {Map<String, dynamic>? data}) {
    state = RefreshEvent(
      type: eventType,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: data,
    );
  }
}

/// 刷新事件
class RefreshEvent {
  final RefreshEventType type;
  final int timestamp;
  final Map<String, dynamic>? data;

  RefreshEvent({
    required this.type,
    required this.timestamp,
    this.data,
  });
}

/// 刷新事件类型
enum RefreshEventType {
  none,
  characterSaved,
  characterDeleted,
  regionUpdated,
}
