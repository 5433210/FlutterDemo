import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/providers/state_restoration_provider.dart';
import '../viewmodels/work_browse_view_model.dart';
import '../viewmodels/states/work_browse_state.dart';
import '../../application/providers/service_providers.dart';

final workBrowseProvider = StateNotifierProvider<WorkBrowseViewModel, WorkBrowseState>((ref) {
  final workService = ref.watch(workServiceProvider);
  final stateRestorationService = ref.watch(stateRestorationProvider);
  
  return WorkBrowseViewModel(workService, stateRestorationService);
});

// 添加一些衍生状态的 provider
final selectedWorksCountProvider = Provider<int>((ref) {
  return ref.watch(workBrowseProvider).selectedWorks.length;
});

final hasFilterProvider = Provider<bool>((ref) {
  final state = ref.watch(workBrowseProvider);
  return !state.filter.isEmpty || state.searchQuery.isNotEmpty;
});
