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

/// 导航区域名称映射
final sectionNames = {
  0: '作品浏览',
  1: '字符管理',
  2: '字帖列表',
  3: '图库管理',
  4: '设置',
};

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
      AppLogger.debug('清空导航历史记录', tag: 'Navigation');
      state = state.copyWith(history: []);
      await _storage.clearNavigationState();
      AppLogger.info('导航历史记录已清空', tag: 'Navigation');
    } catch (e, stack) {
      AppLogger.error('清空导航历史记录失败',
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

  /// 返回到上一个功能区
  /// 返回true表示成功导航，false表示没有历史记录
  Future<bool> navigateBack() async {
    if (state.history.isEmpty) return false;

    AppLogger.debug('尝试返回上一个功能区', tag: 'Navigation', data: {
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

      AppLogger.info('成功返回到上一个功能区', tag: 'Navigation', data: {
        'newSection': lastItem.sectionIndex,
        'remainingHistory': newHistory.length,
      });

      return true;
    } catch (e, stack) {
      AppLogger.error('返回导航失败', error: e, stackTrace: stack, tag: 'Navigation');
      state = state.copyWith(isNavigating: false);
      return false;
    }
  }

  /// 导航到指定功能区
  Future<void> navigateToSection(int sectionIndex) async {
    if (sectionIndex == state.currentSectionIndex) return;

    AppLogger.debug('尝试导航到新功能区', tag: 'Navigation', data: {
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

      AppLogger.info('成功导航到新功能区', tag: 'Navigation', data: {
        'newSection': sectionIndex,
        'historyCount': newHistory.length,
      });
    } catch (e, stack) {
      AppLogger.error('导航切换失败', error: e, stackTrace: stack, tag: 'Navigation');
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
      AppLogger.debug('记录功能区内路由变化', tag: 'Navigation', data: {
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
      AppLogger.error('记录路由变化失败',
          error: e, stackTrace: stack, tag: 'Navigation');
    }
  }

  /// 保存并恢复导航状态
  Future<void> saveNavigationState() async {
    try {
      AppLogger.debug('保存导航状态', tag: 'Navigation');
      await _storage.saveNavigationState(
        currentSectionIndex: state.currentSectionIndex,
        history: state.history,
        sectionRoutes: state.sectionRoutes,
      );
      AppLogger.info('导航状态已保存', tag: 'Navigation');
    } catch (e, stack) {
      AppLogger.error('保存导航状态失败',
          error: e, stackTrace: stack, tag: 'Navigation');
    }
  }

  /// 切换导航区域展开状态
  void toggleNavigationExtended() {
    state = state.copyWith(isNavigationExtended: !state.isNavigationExtended);
    AppLogger.debug('切换导航栏展开状态', tag: 'Navigation', data: {
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
      AppLogger.info('导航状态已从存储恢复', tag: 'Navigation', data: {
        'currentSectionIndex': savedState.currentSectionIndex,
        'historyCount': savedState.history.length,
        'sectionRoutes': savedState.sectionRoutes,
      });
    } catch (e, stack) {
      AppLogger.error('恢复导航状态失败',
          error: e, stackTrace: stack, tag: 'Navigation');
      state = const GlobalNavigationState();
    }
  }
}
