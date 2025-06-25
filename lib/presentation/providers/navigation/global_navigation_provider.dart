import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/navigation/navigation_history_item.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/providers/shared_preferences_provider.dart';
import 'global_navigation_state.dart';
import 'navigation_history_storage.dart';

/// 全局导航服务提供者
final globalNavigationProvider =
    StateNotifierProvider<GlobalNavigationNotifier, GlobalNavigationState>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return GlobalNavigationNotifier(
      storage: NavigationHistoryStorage(prefs),
    );
  },
);

/// 全局导航状态管理器
class GlobalNavigationNotifier extends StateNotifier<GlobalNavigationState> {
  /// 最大历史记录数量
  static const int maxHistoryItems = 30;

  final NavigationHistoryStorage _storage;

  GlobalNavigationNotifier({
    required NavigationHistoryStorage storage,
  })  : _storage = storage,
        super(const GlobalNavigationState()) {
    _initializeState();
  }

  /// 清空历史记录
  Future<void> clearHistory() async {
    try {
      AppLogger.debug('Clearing navigation history', tag: 'Navigation');
      state = state.copyWith(history: []);
      await _storage.clearNavigationState();
      AppLogger.info('Navigation history cleared', tag: 'Navigation');
    } catch (e, stack) {
      AppLogger.error('Failed to clear navigation history',
          error: e, stackTrace: stack, tag: 'Navigation');
    }
  }

  /// 获取最近的历史记录（不包括当前功能区）
  List<NavigationHistoryItem> getRecentHistory({int limit = 5}) {
    final result = <NavigationHistoryItem>[];
    final seenSections = <int>{state.currentSectionIndex};

    // 从最近的历史记录开始遍历，只保留每个功能区最新一条记录
    for (int i = state.history.length - 1;
        i >= 0 && result.length < limit;
        i--) {
      final item = state.history[i];
      if (!seenSections.contains(item.sectionIndex)) {
        result.add(item);
        seenSections.add(item.sectionIndex);
      }
    }

    return result;
  }

  /// 导航到特定的历史记录项
  /// 返回true表示成功导航，false表示导航失败
  Future<bool> navigateToHistoryItem(NavigationHistoryItem item) async {
    AppLogger.debug('Attempting to navigate to specific history item',
        tag: 'Navigation',
        data: {
          'currentSection': state.currentSectionIndex,
          'targetSection': item.sectionIndex,
          'targetRoute': item.routePath,
          'historyCount': state.history.length,
        });

    state = state.copyWith(isNavigating: true);

    try {
      // 在历史记录中找到目标项的位置
      final itemIndex = state.history.indexWhere((historyItem) =>
          historyItem.sectionIndex == item.sectionIndex &&
          historyItem.routePath == item.routePath);

      if (itemIndex == -1) {
        // 如果没有找到符合的项，直接导航到目标功能区
        AppLogger.info(
            'Target item not found in history, navigating to target section directly',
            tag: 'Navigation');
        await navigateToSection(item.sectionIndex);
        return true;
      }

      // 删除从目标项开始的所有历史记录（包括目标项本身）
      final newHistory = List<NavigationHistoryItem>.from(state.history)
        ..removeRange(itemIndex, state.history.length);

      state = state.copyWith(
        currentSectionIndex: item.sectionIndex,
        history: newHistory,
        isNavigating: false,
      );

      // 持久化新状态
      await _storage.saveNavigationState(
        currentSectionIndex: item.sectionIndex,
        history: newHistory,
        sectionRoutes: state.sectionRoutes,
      );

      AppLogger.info('Successfully navigated to specific history item',
          tag: 'Navigation',
          data: {
            'newSection': item.sectionIndex,
            'remainingHistory': newHistory.length,
          });

      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to navigate to specific history item',
          error: e, stackTrace: stack, tag: 'Navigation');
      state = state.copyWith(isNavigating: false);
      return false;
    }
  }

  /// 返回到上一个功能区
  /// 返回true表示成功导航，false表示没有历史记录
  Future<bool> navigateBack() async {
    if (state.history.isEmpty) return false;

    AppLogger.debug('Attempting to navigate back to previous section',
        tag: 'Navigation',
        data: {
          'currentSection': state.currentSectionIndex,
          'historyCount': state.history.length,
        });

    // 获取最后一条历史记录
    final lastItem = state.history.last;
    state = state.copyWith(isNavigating: true);

    try {
      // 更新状态
      final newHistory = List<NavigationHistoryItem>.from(state.history)
        ..removeLast();

      state = state.copyWith(
        currentSectionIndex: lastItem.sectionIndex,
        history: newHistory,
        isNavigating: false,
      );

      // 持久化新状态
      await _storage.saveNavigationState(
        currentSectionIndex: lastItem.sectionIndex,
        history: newHistory,
        sectionRoutes: state.sectionRoutes,
      );

      AppLogger.info('Successfully navigated back to previous section',
          tag: 'Navigation',
          data: {
            'newSection': lastItem.sectionIndex,
            'remainingHistory': newHistory.length,
          });

      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to navigate back',
          error: e, stackTrace: stack, tag: 'Navigation');
      state = state.copyWith(isNavigating: false);
      return false;
    }
  }

  /// 导航到指定功能区
  Future<void> navigateToSection(int sectionIndex) async {
    if (sectionIndex == state.currentSectionIndex) return;

    AppLogger.debug('Attempting to navigate to new section',
        tag: 'Navigation',
        data: {
          'fromSection': state.currentSectionIndex,
          'toSection': sectionIndex,
        });

    state = state.copyWith(isNavigating: true);

    try {
      // 添加当前功能区到历史记录
      final currentRoute = state.sectionRoutes[state.currentSectionIndex];
      final historyItem = NavigationHistoryItem.create(
        sectionIndex: state.currentSectionIndex,
        routePath: currentRoute,
      );

      // 创建新的历史记录，并限制最大长度
      final newHistory = [...state.history, historyItem]..retainWhere((item) =>
          item.timestamp.isAfter(
              DateTime.now().subtract(const Duration(days: 7)))); // 只保留一周内的记录

      if (newHistory.length > maxHistoryItems) {
        newHistory.removeRange(0, newHistory.length - maxHistoryItems);
      }

      // 更新状态
      state = state.copyWith(
        currentSectionIndex: sectionIndex,
        history: newHistory,
        isNavigating: false,
      );

      // 持久化新状态
      await _storage.saveNavigationState(
        currentSectionIndex: sectionIndex,
        history: newHistory,
        sectionRoutes: state.sectionRoutes,
      );

      AppLogger.info('Successfully navigated to new section',
          tag: 'Navigation',
          data: {
            'newSection': sectionIndex,
            'historyCount': newHistory.length,
          });
    } catch (e, stack) {
      AppLogger.error('Failed to navigate to section',
          error: e, stackTrace: stack, tag: 'Navigation');
      state = state.copyWith(isNavigating: false);
    }
  }

  /// 记录功能区内路由变化
  Future<void> recordSectionRoute(
    int sectionIndex,
    String routePath, {
    Map<String, dynamic>? params,
  }) async {
    try {
      AppLogger.debug('Recording section route change',
          tag: 'Navigation',
          data: {
            'section': sectionIndex,
            'route': routePath,
            'params': params,
          });

      final sectionRoutes = Map<int, String?>.from(state.sectionRoutes);
      sectionRoutes[sectionIndex] = routePath;

      state = state.copyWith(sectionRoutes: sectionRoutes);

      // 持久化路由状态
      await _storage.saveNavigationState(
        currentSectionIndex: state.currentSectionIndex,
        history: state.history,
        sectionRoutes: sectionRoutes,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to record route change',
          error: e, stackTrace: stack, tag: 'Navigation');
    }
  }

  /// 保存并恢复导航状态
  Future<void> saveNavigationState() async {
    try {
      AppLogger.debug('Saving navigation state', tag: 'Navigation');
      await _storage.saveNavigationState(
        currentSectionIndex: state.currentSectionIndex,
        history: state.history,
        sectionRoutes: state.sectionRoutes,
      );
      AppLogger.info('Navigation state saved', tag: 'Navigation');
    } catch (e, stack) {
      AppLogger.error('Failed to save navigation state',
          error: e, stackTrace: stack, tag: 'Navigation');
    }
  }

  /// 切换导航区域展开状态
  void toggleNavigationExtended() {
    state = state.copyWith(isNavigationExtended: !state.isNavigationExtended);
    AppLogger.debug('Toggled navigation bar expanded state',
        tag: 'Navigation',
        data: {
          'newState': state.isNavigationExtended ? 'expanded' : 'collapsed',
        });
  }

  /// 初始化状态，从存储恢复
  Future<void> _initializeState() async {
    try {
      final savedState = _storage.loadNavigationState();
      state = GlobalNavigationState(
        currentSectionIndex: savedState.currentSectionIndex,
        history: savedState.history,
        sectionRoutes: savedState.sectionRoutes,
      );
      AppLogger.info('Navigation state restored from storage',
          tag: 'Navigation',
          data: {
            'currentSectionIndex': savedState.currentSectionIndex,
            'historyCount': savedState.history.length,
            'sectionRoutes': savedState.sectionRoutes,
          });
    } catch (e, stack) {
      AppLogger.error('Failed to restore navigation state',
          error: e, stackTrace: stack, tag: 'Navigation');
      state = const GlobalNavigationState();
    }
  }
}
