import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/providers/storage_providers.dart';
import '../../presentation/viewmodels/states/work_browse_state.dart';
import '../../presentation/viewmodels/work_browse_view_model.dart';
import 'service_providers.dart';

final workBrowseProvider = StateNotifierProvider<WorkBrowseViewModel, WorkBrowseState>((ref) {
  final workService = ref.read(workServiceProvider);
  final paths = ref.watch(storagePathsProvider);
  return WorkBrowseViewModel(workService, paths);
});