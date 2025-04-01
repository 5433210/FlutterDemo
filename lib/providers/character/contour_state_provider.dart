import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 控制描边显示的状态Provider
final contourStateProvider =
    StateNotifierProvider<ContourStateNotifier, bool>((ref) {
  return ContourStateNotifier();
});

class ContourStateNotifier extends StateNotifier<bool> {
  ContourStateNotifier() : super(false);

  void setShowContour(bool show) {
    state = show;
  }

  void toggle() {
    state = !state;
  }
}
