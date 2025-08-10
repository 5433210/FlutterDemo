import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/repositories/pagination_settings_repository_impl.dart';
import '../../application/services/pagination_settings_service.dart';
import '../../domain/repositories/pagination_settings_repository.dart';
import '../../infrastructure/providers/shared_preferences_provider.dart';

/// 分页设置仓库提供者
final paginationSettingsRepositoryProvider = Provider<PaginationSettingsRepository>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return PaginationSettingsRepositoryImpl(prefs: sharedPreferences);
});

/// 分页设置服务提供者
final paginationSettingsServiceProvider = Provider<PaginationSettingsService>((ref) {
  final repository = ref.watch(paginationSettingsRepositoryProvider);
  return PaginationSettingsService(repository: repository);
});

/// 特定页面的分页设置提供者
final pageSizeProvider = FutureProvider.family<int, String>((ref, pageId) async {
  final service = ref.watch(paginationSettingsServiceProvider);
  return await service.getPageSize(pageId, defaultSize: 20);
});

/// 分页设置状态管理器
class PaginationSettingsNotifier extends StateNotifier<Map<String, int>> {
  final PaginationSettingsService _service;

  PaginationSettingsNotifier(this._service) : super({});

  /// 获取指定页面的页面大小
  Future<int> getPageSize(String pageId, {int defaultSize = 20}) async {
    // 先从本地状态获取
    if (state.containsKey(pageId)) {
      return state[pageId]!;
    }

    // 从持久化存储获取
    final size = await _service.getPageSize(pageId, defaultSize: defaultSize);
    
    // 更新本地状态
    state = {...state, pageId: size};
    
    return size;
  }

  /// 设置指定页面的页面大小
  Future<void> setPageSize(String pageId, int pageSize) async {
    // 更新持久化存储
    await _service.setPageSize(pageId, pageSize);
    
    // 更新本地状态
    state = {...state, pageId: pageSize};
  }

  /// 重置指定页面的设置
  Future<void> resetPageSettings(String pageId) async {
    await _service.resetPageSettings(pageId);
    
    // 从本地状态中移除
    final newState = Map<String, int>.from(state);
    newState.remove(pageId);
    state = newState;
  }

  /// 预加载指定页面的设置
  Future<void> preloadPageSettings(String pageId, {int defaultSize = 20}) async {
    if (!state.containsKey(pageId)) {
      final size = await _service.getPageSize(pageId, defaultSize: defaultSize);
      state = {...state, pageId: size};
    }
  }
}

/// 分页设置状态提供者
final paginationSettingsNotifierProvider = 
    StateNotifierProvider<PaginationSettingsNotifier, Map<String, int>>((ref) {
  final service = ref.watch(paginationSettingsServiceProvider);
  return PaginationSettingsNotifier(service);
});

/// 用于获取特定页面页面大小的便捷提供者
final pageSpecificSizeProvider = Provider.family<AsyncValue<int>, String>((ref, pageId) {
  return ref.watch(pageSizeProvider(pageId));
});

/// 用于获取和设置页面大小的便捷类
class PageSizeHelper {
  final Ref _ref;
  final String _pageId;

  PageSizeHelper(this._ref, this._pageId);

  /// 获取当前页面的页面大小
  Future<int> get pageSize async {
    final notifier = _ref.read(paginationSettingsNotifierProvider.notifier);
    return await notifier.getPageSize(_pageId);
  }

  /// 设置当前页面的页面大小
  Future<void> setPageSize(int size) async {
    final notifier = _ref.read(paginationSettingsNotifierProvider.notifier);
    await notifier.setPageSize(_pageId, size);
  }

  /// 获取当前页面大小的响应式值
  int? get currentPageSize {
    final state = _ref.watch(paginationSettingsNotifierProvider);
    return state[_pageId];
  }
}

/// 创建页面大小助手的扩展方法
extension PageSizeProviderExtension on Ref {
  PageSizeHelper pageSizeHelper(String pageId) {
    return PageSizeHelper(this, pageId);
  }
}