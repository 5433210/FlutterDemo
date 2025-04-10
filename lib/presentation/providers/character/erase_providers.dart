import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'erase_state.dart';
import 'erase_state_notifier.dart';
import 'path_manager.dart';

// 笔刷配置的provider
final brushConfigProvider = Provider<double>((ref) {
  return ref.watch(eraseStateProvider.select((state) => state.brushSize));
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
