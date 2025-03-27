import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/states/edit_panel_state.dart';

final editPanelProvider =
    StateNotifierProvider<EditPanelNotifier, EditPanelState>((ref) {
  return EditPanelNotifier();
});

class EditPanelNotifier extends StateNotifier<EditPanelState> {
  EditPanelNotifier() : super(EditPanelState.initial());

  // 减少缩放级别
  void decrementZoom() {
    final newZoom = state.zoomLevel - 0.1;
    setZoom(newZoom);
  }

  // 增加缩放级别
  void incrementZoom() {
    final newZoom = state.zoomLevel + 0.1;
    setZoom(newZoom);
  }

  // 重置编辑状态
  void reset() {
    state = EditPanelState.initial();
  }

  // 重置缩放级别
  void resetZoom() {
    state = state.copyWith(zoomLevel: 1.0, panOffset: Offset.zero);
  }

  // 设置画笔大小
  void setBrushSize(double size) {
    // 限制画笔大小范围
    final clampedSize = size.clamp(1.0, 50.0);
    state = state.copyWith(brushSize: clampedSize);
  }

  // 更新降噪级别
  void setNoiseReduction(double noiseReduction) {
    // 限制降噪范围
    final clampedNoiseReduction = noiseReduction.clamp(0.0, 1.0);
    state = state.copyWith(noiseReduction: clampedNoiseReduction);
  }

  // 设置平移偏移
  void setPan(Offset offset) {
    state = state.copyWith(panOffset: offset);
  }

  // 更新阈值
  void setThreshold(double threshold) {
    // 限制阈值范围
    final clampedThreshold = threshold.clamp(0.0, 255.0);
    state = state.copyWith(threshold: clampedThreshold);
  }

  // 设置缩放级别
  void setZoom(double zoom) {
    // 限制缩放范围
    final clampedZoom = zoom.clamp(0.5, 3.0);
    state = state.copyWith(zoomLevel: clampedZoom);
  }

  // 切换擦除模式
  void toggleErase() {
    state = state.copyWith(isErasing: !state.isErasing);
  }

  // 切换反转状态
  void toggleInvert() {
    state = state.copyWith(isInverted: !state.isInverted);
  }

  // 切换轮廓显示
  void toggleOutline() {
    state = state.copyWith(showOutline: !state.showOutline);
  }

  // 更新平移偏移
  void updatePan(Offset delta) {
    final newOffset = state.panOffset + delta;
    state = state.copyWith(panOffset: newOffset);
  }
}
