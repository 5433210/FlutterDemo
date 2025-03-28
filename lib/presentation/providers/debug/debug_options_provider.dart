import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 调试选项Provider
final debugOptionsProvider =
    StateNotifierProvider<DebugOptionsNotifier, DebugOptions>((ref) {
  return DebugOptionsNotifier();
});

/// 调试选项
class DebugOptions {
  /// 是否启用调试模式
  final bool enabled;

  /// 是否显示网格
  final bool showGrid;

  /// 是否显示坐标
  final bool showCoordinates;

  /// 是否显示详细信息
  final bool showDetails;

  /// 是否显示图像信息
  final bool showImageInfo;

  /// 是否显示区域中心点
  final bool showRegionCenter;

  /// 网格大小（图像坐标系）
  final double gridSize;

  /// 文本大小缩放
  final double textScale;

  /// 是否启用日志记录
  final bool enableLogging;

  /// 调试图层的不透明度
  final double opacity;

  const DebugOptions({
    this.enabled = false,
    this.showGrid = true,
    this.showCoordinates = true,
    this.showDetails = true,
    this.showImageInfo = true,
    this.showRegionCenter = true,
    this.gridSize = 50.0,
    this.textScale = 1.0,
    this.enableLogging = true,
    this.opacity = 0.5,
  });

  /// 创建新的选项实例
  DebugOptions copyWith({
    bool? enabled,
    bool? showGrid,
    bool? showCoordinates,
    bool? showDetails,
    bool? showImageInfo,
    bool? showRegionCenter,
    double? gridSize,
    double? textScale,
    bool? enableLogging,
    double? opacity,
  }) {
    return DebugOptions(
      enabled: enabled ?? this.enabled,
      showGrid: showGrid ?? this.showGrid,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showDetails: showDetails ?? this.showDetails,
      showImageInfo: showImageInfo ?? this.showImageInfo,
      showRegionCenter: showRegionCenter ?? this.showRegionCenter,
      gridSize: gridSize ?? this.gridSize,
      textScale: textScale ?? this.textScale,
      enableLogging: enableLogging ?? this.enableLogging,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// 调试选项管理
class DebugOptionsNotifier extends StateNotifier<DebugOptions> {
  DebugOptionsNotifier() : super(const DebugOptions());

  /// 重置所有选项到默认值
  void resetToDefaults() {
    state = const DebugOptions();
  }

  /// 设置网格大小
  void setGridSize(double size) {
    if (state.enabled) {
      // 限制网格大小在20-100之间
      final newSize = size.clamp(20.0, 100.0);
      state = state.copyWith(gridSize: newSize);
    }
  }

  /// 设置不透明度
  void setOpacity(double value) {
    if (state.enabled) {
      // 限制不透明度在0.1-1.0之间
      final newValue = value.clamp(0.1, 1.0);
      state = state.copyWith(opacity: newValue);
    }
  }

  /// 设置文本缩放
  void setTextScale(double scale) {
    if (state.enabled) {
      // 限制文本缩放在0.5-2.0之间
      final newScale = scale.clamp(0.5, 2.0);
      state = state.copyWith(textScale: newScale);
    }
  }

  /// 切换坐标显示
  void toggleCoordinates() {
    if (state.enabled) {
      state = state.copyWith(showCoordinates: !state.showCoordinates);
    }
  }

  /// 切换调试模式
  void toggleDebugMode() {
    state = state.copyWith(enabled: !state.enabled);
  }

  /// 切换详细信息显示
  void toggleDetails() {
    if (state.enabled) {
      state = state.copyWith(showDetails: !state.showDetails);
    }
  }

  /// 切换网格显示
  void toggleGrid() {
    if (state.enabled) {
      state = state.copyWith(showGrid: !state.showGrid);
    }
  }

  /// 切换图像信息显示
  void toggleImageInfo() {
    if (state.enabled) {
      state = state.copyWith(showImageInfo: !state.showImageInfo);
    }
  }

  /// 切换日志记录
  void toggleLogging() {
    if (state.enabled) {
      state = state.copyWith(enableLogging: !state.enableLogging);
    }
  }

  /// 切换区域中心点显示
  void toggleRegionCenter() {
    if (state.enabled) {
      state = state.copyWith(showRegionCenter: !state.showRegionCenter);
    }
  }
}
