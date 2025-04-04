import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 默认的自动保存时间间隔列表
final autoSaveIntervals = [
  const Duration(seconds: 30),
  const Duration(minutes: 1),
  const Duration(minutes: 5),
  const Duration(minutes: 10),
];

/// 自动保存监听器提供者
final autoSaveListenerProvider = Provider((ref) {
  final autoSaveState = ref.watch(autoSaveProvider);

  if (autoSaveState.shouldSave) {
    // 当满足自动保存条件时，返回true
    return true;
  }
  return false;
});

/// 自动保存提供者
final autoSaveProvider =
    StateNotifierProvider<AutoSaveNotifier, AutoSaveState>((ref) {
  return AutoSaveNotifier();
});

/// 自动保存状态管理器
class AutoSaveNotifier extends StateNotifier<AutoSaveState> {
  AutoSaveNotifier() : super(const AutoSaveState());

  void markClean() {
    state = state.copyWith(
      isDirty: false,
      lastSaveTime: DateTime.now(),
    );
  }

  void markDirty() {
    state = state.copyWith(isDirty: true);
  }

  void reset() {
    state = const AutoSaveState();
  }

  void resetLastSaveTime() {
    state = state.copyWith(lastSaveTime: DateTime.now());
  }

  void setEnabled(bool enabled) {
    state = state.copyWith(enabled: enabled);
  }

  void setInterval(Duration interval) {
    state = state.copyWith(interval: interval);
  }
}

class AutoSaveState {
  final Duration interval;
  final DateTime? lastSaveTime;
  final bool enabled;
  final bool isDirty;

  const AutoSaveState({
    this.interval = const Duration(minutes: 1),
    this.lastSaveTime,
    this.enabled = true,
    this.isDirty = false,
  });

  bool get shouldSave {
    if (!enabled || !isDirty) return false;
    if (lastSaveTime == null) return true;

    final now = DateTime.now();
    return now.difference(lastSaveTime!) >= interval;
  }

  AutoSaveState copyWith({
    Duration? interval,
    DateTime? lastSaveTime,
    bool? enabled,
    bool? isDirty,
  }) {
    return AutoSaveState(
      interval: interval ?? this.interval,
      lastSaveTime: lastSaveTime ?? this.lastSaveTime,
      enabled: enabled ?? this.enabled,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
