import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'erase_state.dart';
import 'erase_state_notifier.dart';
import 'path_manager.dart';

// 笔刷配置的provider
final brushConfigProvider = Provider<double>((ref) {
  return ref.watch(eraseStateProvider.select((state) => state.brushSize));
});

// 笔刷大小的专用提供者 - 为滑块专门优化
final brushSizeProvider = Provider<double>((ref) {
  return ref.watch(eraseStateProvider.select((state) => state.brushSize));
});

// 笔刷大小文本格式化提供者 - 用于显示笔刷大小文本而不触发滑块重建
final brushSizeTextProvider = Provider<String>((ref) {
  return ref.watch(brushSizeProvider).toStringAsFixed(1);
});

// 轮廓显示状态的provider
final contourVisibilityProvider = Provider<bool>((ref) {
  return ref.watch(eraseStateProvider.select((state) => state.showContour));
});

// 添加光标位置的provider - add name to allow filtering in logs
final cursorPositionProvider = StateProvider<Offset?>(
  (ref) => null,
  name: 'cursorPosition', // Adding name helps identify in logs for filtering
);

// 模式状态的provider
final eraseModeProvider = Provider<EraseMode>((ref) {
  return ref.watch(eraseStateProvider.select((state) => state.mode));
});

// EraseStateNotifier的provider
final eraseStateProvider =
    StateNotifierProvider<EraseStateNotifier, EraseState>((ref) {
  final pathManager = ref.watch(pathManagerProvider);
  return EraseStateNotifier(pathManager, ref);
});

// 经过记忆化处理的笔刷大小提供者 - 仅当实际值变化时才触发更新
final memoizedBrushSizeProvider = Provider<double>((ref) {
  final value = ref.watch(brushSizeProvider);
  return value;
}, dependencies: [brushSizeProvider]);

// 经过记忆化处理的降噪提供者 - 仅当实际值变化时才触发更新
final memoizedNoiseReductionProvider = Provider<double>((ref) {
  final value = ref.watch(noiseReductionProvider);
  return value;
}, dependencies: [noiseReductionProvider]);

// 经过记忆化处理的完整处理选项 - 仅当选项实际变化时才触发更新
final memoizedProcessingOptionsProvider = Provider((ref) {
  final options = ref.watch(processingOptionsProvider);
  return options;
}, dependencies: [processingOptionsProvider]);

// 经过记忆化处理的阈值提供者 - 仅当实际值变化时才触发更新
final memoizedThresholdProvider = Provider<double>((ref) {
  final value = ref.watch(thresholdProvider);
  return value;
}, dependencies: [thresholdProvider]);

// 降噪的provider - 为滑块专门优化
final noiseReductionProvider = Provider<double>((ref) {
  return ref.watch(eraseStateProvider
      .select((state) => state.processingOptions.noiseReduction));
});

// 降噪文本格式化提供者 - 用于显示降噪文本而不触发滑块重建
final noiseReductionTextProvider = Provider<String>((ref) {
  final value = ref.watch(noiseReductionProvider);
  return value.toStringAsFixed(1);
});

// PathManager的provider
final pathManagerProvider = Provider<PathManager>((ref) {
  return PathManager();
});

// 路径渲染数据的provider
final pathRenderDataProvider = Provider((ref) {
  final state = ref.watch(eraseStateProvider);

  // Explicitly handle current path to ensure its color is correctly set
  final currentPath = state.currentPath;

  return (
    completedPaths: state.completedPaths,
    currentPath: currentPath, // This ensures color updates are reflected
    dirtyBounds: state.dirtyBounds,
    brushSize: state.brushSize,
    isReversed: state.isReversed,
  );
});

// 处理选项的provider
final processingOptionsProvider = Provider((ref) {
  return ref
      .watch(eraseStateProvider.select((state) => state.processingOptions));
});

// 阈值的provider - 为滑块专门优化
final thresholdProvider = Provider<double>((ref) {
  return ref.watch(
      eraseStateProvider.select((state) => state.processingOptions.threshold));
});

// 阈值文本格式化提供者 - 用于显示阈值文本而不触发滑块重建
final thresholdTextProvider = Provider<String>((ref) {
  return ref.watch(thresholdProvider).toStringAsFixed(0);
});
