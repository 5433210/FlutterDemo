import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../viewmodels/states/work_browse_state.dart';
import '../viewmodels/work_browse_view_model.dart';

final workBrowseProvider =
    StateNotifierProvider<WorkBrowseViewModel, WorkBrowseState>((ref) {
  final asyncViewModel = ref.watch(workBrowseViewModelProvider);
  return asyncViewModel.when(
    data: (viewModel) => viewModel,
    loading: () => throw const AsyncLoading<WorkBrowseViewModel>(),
    error: (error, stackTrace) => throw AsyncError(error, stackTrace),
  );
});

final workBrowseViewModelProvider =
    FutureProvider<WorkBrowseViewModel>((ref) async {
  final workService = await ref.watch(workServiceProvider.future);
  return WorkBrowseViewModel(workService);
});
