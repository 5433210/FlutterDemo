import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/practice_list_view_model.dart';
import '../viewmodels/states/practice_list_state.dart';

/// 字帖练习列表状态提供者
final practiceListProvider =
    StateNotifierProvider<PracticeListViewModel, PracticeListState>((ref) {
  return PracticeListViewModel(ref);
});
