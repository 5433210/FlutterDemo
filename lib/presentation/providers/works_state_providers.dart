import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'work_browse_provider.dart';

// 衍生状态 providers，依赖于 workBrowseProvider 但提供更具体的数据视图

/// 作品列表加载是否有错误
final hasErrorProvider = Provider<bool>((ref) {
  final state = ref.watch(workBrowseProvider);
  return !state.isLoading && state.error != null;
});

/// 是否有活动筛选器或搜索
final hasFilterProvider = Provider<bool>((ref) {
  final state = ref.watch(workBrowseProvider);
  return !state.filter.isEmpty || state.searchQuery.isNotEmpty;
});

/// 作品列表是否在加载中
final isLoadingWorksProvider = Provider<bool>((ref) {
  return ref.watch(workBrowseProvider).isLoading;
});

/// 已选择作品数量
final selectedWorksCountProvider = Provider<int>((ref) {
  return ref.watch(workBrowseProvider).selectedWorks.length;
});

/// 是否显示批量操作工具栏
final showBatchActionsProvider = Provider<bool>((ref) {
  final state = ref.watch(workBrowseProvider);
  return state.batchMode && state.selectedWorks.isNotEmpty;
});

/// 作品列表是否为空
final worksEmptyProvider = Provider<bool>((ref) {
  final state = ref.watch(workBrowseProvider);
  return !state.isLoading && state.works.isEmpty;
});
