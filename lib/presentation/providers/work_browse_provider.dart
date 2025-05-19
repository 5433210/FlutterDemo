import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../viewmodels/states/work_browse_state.dart';
import '../viewmodels/work_browse_view_model.dart';

final workBrowseProvider =
    StateNotifierProvider<WorkBrowseViewModel, WorkBrowseState>((ref) {
  final workService = ref.watch(workServiceProvider);

  return WorkBrowseViewModel(workService);
});
