import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/entities/work.dart';
import '../../infrastructure/logging/logger.dart';
import '../models/work_filter.dart';

// 筛选后的作品列表提供器
final filteredWorksProvider = FutureProvider.autoDispose
    .family<List<Work>, WorkFilter>((ref, filter) async {
  AppLogger.debug('加载筛选后的作品列表', tag: 'WorksProvider', data: {'filter': filter});

  // 监听刷新标记
  ref.listen(worksNeedsRefreshProvider, (_, needsRefresh) {
    if (needsRefresh) {
      ref.invalidateSelf();
    }
  });

  final workService = ref.watch(workServiceProvider);
  return await workService.queryWorks(filter: filter);
});

// 用于标记作品列表需要刷新的状态
final worksNeedsRefreshProvider = StateProvider<bool>((ref) => false);

// 作品列表提供器
final worksProvider = FutureProvider.autoDispose<List<Work>>((ref) async {
  AppLogger.debug('加载作品列表', tag: 'WorksProvider');

  // 监听刷新标记，当标记变化时，自动重新获取数据
  ref.listen(worksNeedsRefreshProvider, (_, needsRefresh) {
    if (needsRefresh) {
      // 如果需要刷新，则重载数据并重置标记
      ref.invalidateSelf();
      ref.read(worksNeedsRefreshProvider.notifier).state = false;
    }
  });

  // 设置缓存策略，使列表能够在返回时保留
  ref.keepAlive();

  final workService = ref.watch(workServiceProvider);
  return await workService.getAllWorks();
});
