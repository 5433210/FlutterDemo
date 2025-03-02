import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/entities/work.dart';
import '../../infrastructure/logging/logger.dart';
import '../models/work_filter.dart';

// 默认刷新信息
final defaultRefreshInfo = const RefreshInfo(reason: 'unknown');

// 筛选后的作品列表提供器
final filteredWorksProvider = FutureProvider.autoDispose
    .family<List<Work>, WorkFilter>((ref, filter) async {
  AppLogger.debug('加载筛选后的作品列表', tag: 'WorksProvider', data: {'filter': filter});

  // 监听刷新标记
  ref.listen(worksNeedsRefreshProvider, (_, needsRefresh) {
    if (needsRefresh!.force) {
      ref.invalidateSelf();
    }
  });

  final workService = ref.watch(workServiceProvider);
  return await workService.queryWorks(filter: filter);
});

// 修改为刷新信息提供器
final worksNeedsRefreshProvider = StateProvider<RefreshInfo?>((ref) => null);

// 作品列表提供器
final worksProvider = FutureProvider.autoDispose<List<Work>>((ref) async {
  AppLogger.debug('加载作品列表', tag: 'WorksProvider');

  // 监听刷新标记，当标记变化时，自动重新获取数据
  ref.listen(worksNeedsRefreshProvider, (_, needsRefresh) {
    if (needsRefresh!.force) {
      // 如果需要刷新，则重载数据并重置标记
      ref.invalidateSelf();
    }
  });

  // 设置缓存策略，使列表能够在返回时保留
  ref.keepAlive();

  final workService = ref.watch(workServiceProvider);
  return await workService.getAllWorks();
});

// 增强刷新标志，添加刷新原因和优先级信息
class RefreshInfo {
  final String reason;
  final int priority;
  final bool force;

  const RefreshInfo({
    required this.reason,
    this.priority = 0,
    this.force = false,
  });

  // 添加常用刷新原因作为工厂构造函数:
  factory RefreshInfo.appResume() =>
      const RefreshInfo(reason: '应用恢复', priority: 1);

  factory RefreshInfo.dataChanged() =>
      const RefreshInfo(reason: '数据变更', priority: 10, force: true);

  factory RefreshInfo.importCompleted() =>
      const RefreshInfo(reason: '导入完成', priority: 9, force: true);

  factory RefreshInfo.userInitiated() =>
      const RefreshInfo(reason: '用户请求', priority: 8, force: true);

  // 用于创建更高优先级的请求
  RefreshInfo asHighPriority() =>
      RefreshInfo(reason: reason, priority: priority + 5, force: true);

  // 比较优先级方法
  bool hasHigherPriorityThan(RefreshInfo other) => priority > other.priority;
}
