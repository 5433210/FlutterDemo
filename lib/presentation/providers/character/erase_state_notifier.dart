import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/path_info.dart';
import 'erase_state.dart';
import 'path_manager.dart';

/// 擦除状态管理器
class EraseStateNotifier extends StateNotifier<EraseState> {
  final PathManager _pathManager;

  EraseStateNotifier(this._pathManager) : super(EraseState.initial());

  /// 清除所有路径
  void clear() {
    _pathManager.clear();
    _updateState();
  }

  /// 单击擦除操作
  void clickErase(Offset position) {
    if (state.mode != EraseMode.draw) return;

    // 先创建路径，传入当前笔刷颜色
    _pathManager.startPath(
      position,
      brushSize: state.brushSize,
      brushColor: state.brushColor,
    );
    // 立即完成路径
    _pathManager.completePath();
    // 更新状态
    _updateState();
  }

  /// 完成当前路径
  void completePath() {
    if (state.mode != EraseMode.draw) return;

    // 确保保存颜色信息
    if (_pathManager.currentPath != null) {
      // Always update the color before completing the path
      _pathManager.updateCurrentColor(state.brushColor);
      print('完成路径前设置颜色: ${state.brushColor}');
    }

    _pathManager.completePath();
    _updateState();
  }

  /// 重做上一个撤销的操作
  void redo() {
    if (!state.canRedo) return;

    _pathManager.redoPath();
    _updateState();
  }

  /// 设置笔刷大小
  void setBrushSize(double size) {
    if (size <= 0) return;
    state = state.copyWith(brushSize: size);
  }

  /// 开始一个新的路径
  void startPath(Offset position) {
    if (state.mode != EraseMode.draw) return;

    // 传入当前笔刷颜色
    _pathManager.startPath(
      position,
      brushSize: state.brushSize,
      brushColor: state.brushColor,
    );
    _updateState();
  }

  /// 切换轮廓显示
  void toggleContour() {
    final newValue = !state.showContour;
    print('切换轮廓显示状态: $newValue');

    // 更新状态并立即通知监听者
    state = state.copyWith(showContour: newValue);

    // 添加延迟，确保状态已更新
    Future.delayed(Duration.zero, () {
      // 确保状态更新被广播
      _updateState();
    });
  }

  /// 切换图像反转模式
  void toggleImageInvert() {
    final wasImageInverted = state.imageInvertMode;
    final newImageInverted = !wasImageInverted;

    print('切换图像反转: $wasImageInverted → $newImageInverted');

    // 更新状态 - 只更新当前的设置，不会影响已有路径
    state = state.copyWith(imageInvertMode: newImageInverted);

    // 更新所有路径的颜色，以匹配新的图像反转状态
    _pathManager.updateAllPathsForImageInversion(newImageInverted);

    // 如果有活动路径，保持其颜色不变
    if (_pathManager.currentPath != null) {
      _pathManager.updateCurrentColor(state.brushColor);
    }

    // 日志记录颜色变化
    print(
        '图像反转切换后笔刷颜色: ${state.brushColor}, 反转状态: ${state.isReversed}, 图像反转: ${state.imageInvertMode}');

    // 如果轮廓显示开启，需要强制刷新轮廓
    if (state.showContour) {
      // 临时关闭轮廓显示然后立即重新打开，触发轮廓重新计算
      state = state.copyWith(showContour: false);
      _updateState();

      // 延迟重新开启轮廓显示
      Future.delayed(const Duration(milliseconds: 50), () {
        state = state.copyWith(showContour: true);
        _updateState();
        print('图像反转后强制刷新轮廓');
      });
    } else {
      // 确保状态更新被通知
      _updateState();
    }
  }

  /// 切换绘制/平移模式
  void togglePanMode() {
    state = state.copyWith(
      mode: state.isPanMode ? EraseMode.draw : EraseMode.pan,
    );
  }

  /// 切换颜色反转
  void toggleReverse() {
    final wasReversed = state.isReversed;
    final newReversed = !wasReversed;

    print('切换笔刷反转: $wasReversed → $newReversed');

    // 更新状态 - 只影响未来的路径
    state = state.copyWith(isReversed: newReversed);

    // 如果有活动路径，立即更新其颜色
    if (_pathManager.currentPath != null) {
      _pathManager.updateCurrentColor(state.brushColor);
      print('更新当前路径颜色: ${state.brushColor}');
    }

    // 日志记录颜色变化
    print(
        '笔刷反转切换后颜色: ${state.brushColor}, 反转状态: ${state.isReversed}, 图像反转: ${state.imageInvertMode}');

    // 确保状态更新被通知
    _updateState();
  }

  /// 撤销最后一个操作
  void undo() {
    if (!state.canUndo) return;

    _pathManager.undo();
    _updateState();
  }

  /// 更新当前路径
  void updatePath(Offset position) {
    if (state.mode != EraseMode.draw) return;

    _pathManager.updatePath(position);
    _updateState();
  }

  void _updateState() {
    // 将已完成的路径转换为PathInfo列表，保留每条路径的原始颜色
    final paths = _pathManager.completedPaths.map((pathEntry) {
      return PathInfo(
        path: pathEntry.path,
        brushSize: pathEntry.brushSize,
        brushColor: pathEntry.brushColor,
      );
    }).toList();

    // 将重做路径转换为PathInfo列表，同样保留原始颜色
    final redoPaths = _pathManager.redoPaths.map((pathEntry) {
      return PathInfo(
        path: pathEntry.path,
        brushSize: pathEntry.brushSize,
        brushColor: pathEntry.brushColor,
      );
    }).toList();

    // 转换当前路径（如果存在），使用当前的笔刷颜色
    PathInfo? currentPath;
    if (_pathManager.currentPath != null) {
      currentPath = PathInfo(
        path: _pathManager.currentPath!,
        brushSize: state.brushSize,
        brushColor: _pathManager.currentColor ?? state.brushColor,
      );
    }

    // 更新状态
    state = state.copyWith(
      completedPaths: paths,
      currentPath: currentPath,
      dirtyBounds: _pathManager.dirtyBounds,
      redoPaths: redoPaths,
    );
  }
}
