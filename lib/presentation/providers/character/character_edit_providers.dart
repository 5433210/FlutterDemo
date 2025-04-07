import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/path_info.dart';

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
  bool _disposed = false;

  ProcessedImageNotifier() : super(const ProcessedImageData());

  void clear() {
    if (_disposed) return;
    try {
      if (state.image != null) {
        state.image!.dispose();
      }
      state = const ProcessedImageData();
    } catch (e) {
      // 忽略清理过程中的错误
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    try {
      clear();
    } finally {
      super.dispose();
    }
  }

  void setError(String error) {
    if (_disposed) return;
    try {
      state = state.copyWith(
        error: error,
        isProcessing: false,
      );
    } catch (e) {
      // 忽略在设置错误状态时可能发生的异常
    }
  }

  void setImage(ui.Image image) {
    if (_disposed) return;
    try {
      final oldImage = state.image;
      state = state.copyWith(
        image: image,
        isProcessing: false,
        error: null,
      );
      // 清理旧图像
      if (oldImage != null) {
        oldImage.dispose();
      }
    } catch (e) {
      // 忽略在设置图像时可能发生的异常
    }
  }

  void setProcessing(bool isProcessing) {
    if (_disposed) return;
    try {
      state = state.copyWith(
        isProcessing: isProcessing,
        error: null,
      );
    } catch (e) {
      // 忽略在设置处理状态时可能发生的异常
    }
  }
}
