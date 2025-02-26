import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/providers/state_restoration_provider.dart';
import '../../presentation/viewmodels/states/work_browse_state.dart';
import '../../presentation/viewmodels/work_browse_view_model.dart';
import 'service_providers.dart';

final workBrowseProvider =
    StateNotifierProvider<WorkBrowseViewModel, WorkBrowseState>((ref) {
  final workService = ref.watch(workServiceProvider);
  final stateRestorationService = ref.watch(stateRestorationProvider);
  return WorkBrowseViewModel(workService, stateRestorationService);
});
