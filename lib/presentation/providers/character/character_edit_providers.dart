import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/path_info.dart';

/// 路径渲染状态提供者
final pathRenderDataProvider = StateProvider<PathRenderData>((ref) {
  return const PathRenderData();
});

/// 处理后的图像数据提供者
final processedImageProvider =
    StateNotifierProvider<ProcessedImageNotifier, ProcessedImageData>((ref) {
  return ProcessedImageNotifier();
});

/// 路径渲染数据
class PathRenderData {
  final List<PathInfo> completedPaths;
  final PathInfo? currentPath;
  final ui.Rect? dirtyBounds;

  const PathRenderData({
    this.completedPaths = const [],
    this.currentPath,
    this.dirtyBounds,
  });

  PathRenderData copyWith({
    List<PathInfo>? completedPaths,
    PathInfo? currentPath,
    ui.Rect? dirtyBounds,
  }) {
    return PathRenderData(
      completedPaths: completedPaths ?? this.completedPaths,
      currentPath: currentPath,
      dirtyBounds: dirtyBounds,
    );
  }
}

/// 处理后的图像数据
class ProcessedImageData {
  final ui.Image? image;
  final bool isProcessing;
  final String? error;

  const ProcessedImageData({
    this.image,
    this.isProcessing = false,
    this.error,
  });

  bool get hasError => error != null;

  bool get hasImage => image != null;
  ProcessedImageData copyWith({
    ui.Image? image,
    bool? isProcessing,
    String? error,
  }) {
    return ProcessedImageData(
      image: image ?? this.image,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class ProcessedImageNotifier extends StateNotifier<ProcessedImageData> {
  ProcessedImageNotifier() : super(const ProcessedImageData());

  void clear() {
    state = const ProcessedImageData();
  }

  @override
  void dispose() {
    if (state.image != null) {
      state.image!.dispose();
    }
    super.dispose();
  }

  void setError(String error) {
    state = state.copyWith(
      error: error,
      isProcessing: false,
    );
  }

  void setImage(ui.Image image) {
    state = state.copyWith(
      image: image,
      isProcessing: false,
      error: null,
    );
  }

  void setProcessing(bool isProcessing) {
    state = state.copyWith(isProcessing: isProcessing, error: null);
  }
}
