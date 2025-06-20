import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 作品删除事件通知
/// 当作品被删除时，该 Provider 的 state 会更新为被删除的 workId
final workDeletedNotifierProvider = StateProvider<String?>((ref) => null);

/// 作品变更事件通知
/// 当作品发生任何变更时，该 Provider 的 state 会更新为当前时间戳
final workChangedNotifierProvider = StateProvider<DateTime?>((ref) => null);

/// 字符数据刷新事件通知
/// 当需要刷新字符数据时，该 Provider 的 state 会更新为当前时间戳
final characterDataRefreshNotifierProvider =
    StateProvider<DateTime?>((ref) => null);
