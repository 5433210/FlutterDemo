import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局导航历史记录提供者
final navigationHistoryProvider =
    StateNotifierProvider<NavigationHistoryNotifier, NavigationHistoryState>(
        (ref) {
  return NavigationHistoryNotifier();
});

/// 导航历史记录提供者
class NavigationHistoryNotifier extends StateNotifier<NavigationHistoryState> {
  NavigationHistoryNotifier() : super(NavigationHistoryState());

  /// 清空历史记录
  void clearHistory() {
    state = state.copyWith(history: []);
  }

  /// 返回上一个页面
  /// 返回 true 表示成功返回，false 表示历史记录为空
  bool navigateBack() {
    final history = List<int>.from(state.history);

    if (history.isNotEmpty) {
      // 从历史记录中弹出最后一个页面
      final previousIndex = history.removeLast();

      // 更新状态
      state = state.copyWith(
        history: history,
        selectedIndex: previousIndex,
      );

      return true;
    }

    return false;
  }

  /// 导航到指定索引
  void navigateTo(int index) {
    if (state.selectedIndex != index) {
      // 添加当前页面到历史记录
      final updatedHistory = List<int>.from(state.history);
      updatedHistory.add(state.selectedIndex);

      // 更新状态
      state = state.copyWith(
        history: updatedHistory,
        selectedIndex: index,
      );
    }
  }
}

/// 导航历史记录状态
class NavigationHistoryState {
  /// 导航历史记录
  final List<int> history;

  /// 当前选中的索引
  final int selectedIndex;

  /// 构造函数
  NavigationHistoryState({
    this.history = const [],
    this.selectedIndex = 0,
  });

  /// 创建副本
  NavigationHistoryState copyWith({
    List<int>? history,
    int? selectedIndex,
  }) {
    return NavigationHistoryState(
      history: history ?? this.history,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}
