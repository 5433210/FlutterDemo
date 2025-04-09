import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 字符数据刷新通知Provider
/// 用于不同组件间协调字符数据的刷新
final characterRefreshNotifierProvider =
    StateNotifierProvider<RefreshNotifier, int>((ref) {
  return RefreshNotifier();
});

/// 刷新事件类型
enum RefreshEventType {
  /// 字符保存事件
  characterSaved,

  /// 字符删除事件
  characterDeleted,

  /// 字符修改事件
  characterModified,

  /// 字符区域更新事件
  regionUpdated,
}

/// 刷新通知状态管理
/// 通过简单的计数器增长来触发订阅者刷新
class RefreshNotifier extends StateNotifier<int> {
  RefreshNotifier() : super(0);

  /// 通知特定类型的刷新事件
  void notifyEvent(RefreshEventType eventType) => state = state + 1;

  /// 通知所有监听者刷新数据
  void notifyRefresh() => state = state + 1;
}
