import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/work/work_filter.dart';

final workFilterProvider =
    StateNotifierProvider<WorkFilterNotifier, WorkFilter>((ref) {
  return WorkFilterNotifier();
});

class WorkFilterNotifier extends StateNotifier<WorkFilter> {
  WorkFilterNotifier() : super(const WorkFilter());

  void resetFilter() {
    state = const WorkFilter();
  }

  void updateFilter(WorkFilter newFilter) {
    state = newFilter;
  }
}
