import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局导航历史记录
final navigationHistoryProvider =
    StateNotifierProvider<NavigationHistoryNotifier, List<int>>((ref) {
  return NavigationHistoryNotifier();
});

/// 全局当前选中的页面索引
final selectedTabIndexProvider = StateProvider<int>((ref) {
  return 0; // 默认为第一个页面
});

/// 导航历史记录状态管理
class NavigationHistoryNotifier extends StateNotifier<List<int>> {
  NavigationHistoryNotifier() : super([]);

  /// 清空历史记录
  void clear() {
    state = [];
  }

  /// 导航到新页面
  void navigateTo(int currentIndex, int newIndex) {
    if (currentIndex != newIndex) {
      // 记录当前位置
      state = [...state, currentIndex];
    }
  }

  /// 尝试返回到上一个页面
  /// 返回上一个页面的索引，如果没有历史记录则返回null
  int? tryNavigateBack() {
    if (state.isNotEmpty) {
      final history = [...state];
      final previousIndex = history.removeLast();
      state = history;
      return previousIndex;
    }
    return null;
  }
}
