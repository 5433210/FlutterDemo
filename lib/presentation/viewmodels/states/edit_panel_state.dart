import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// 编辑面板状态
class EditPanelState extends Equatable {
  final bool isInverted;
  final bool showOutline;
  final bool isErasing;
  final double zoomLevel;
  final Offset panOffset;
  final double threshold;
  final double noiseReduction;
  final double brushSize;

  const EditPanelState({
    required this.isInverted,
    required this.showOutline,
    required this.isErasing,
    required this.zoomLevel,
    required this.panOffset,
    required this.threshold,
    required this.noiseReduction,
    required this.brushSize,
  });

  // 初始状态
  factory EditPanelState.initial() {
    return const EditPanelState(
      isInverted: false,
      showOutline: false,
      isErasing: false,
      zoomLevel: 1.0,
      panOffset: Offset.zero,
      threshold: 128.0,
      noiseReduction: 0.5,
      brushSize: 10.0,
    );
  }

  @override
  List<Object?> get props => [
        isInverted,
        showOutline,
        isErasing,
        zoomLevel,
        panOffset,
        threshold,
        noiseReduction,
        brushSize,
      ];

  // 视图变换矩阵
  Matrix4 get transform {
    final matrix = Matrix4.identity()
      ..translate(panOffset.dx, panOffset.dy)
      ..scale(zoomLevel);
    return matrix;
  }

  // 创建副本并更新部分属性
  EditPanelState copyWith({
    bool? isInverted,
    bool? showOutline,
    bool? isErasing,
    double? zoomLevel,
    Offset? panOffset,
    double? threshold,
    double? noiseReduction,
    double? brushSize,
  }) {
    return EditPanelState(
      isInverted: isInverted ?? this.isInverted,
      showOutline: showOutline ?? this.showOutline,
      isErasing: isErasing ?? this.isErasing,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      panOffset: panOffset ?? this.panOffset,
      threshold: threshold ?? this.threshold,
      noiseReduction: noiseReduction ?? this.noiseReduction,
      brushSize: brushSize ?? this.brushSize,
    );
  }
}
