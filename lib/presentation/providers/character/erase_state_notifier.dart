import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/path_info.dart';
import '../../../infrastructure/logging/logger.dart';
import '../user_preferences_provider.dart';
import 'erase_providers.dart';
import 'erase_state.dart';
import 'path_manager.dart';

/// 擦除状态管理器
class EraseStateNotifier extends StateNotifier<EraseState> {
  static const Duration _autoSaveDelay =
      Duration(milliseconds: 1000); // 1 second delay for auto-save
  final PathManager _pathManager;
  final Ref _ref;

  // Default color used for erasing when no color is specified
  final Color _defaultEraseColor = Colors.white;
  // Debouncing state for image updates
  bool _isDelayedUpdatePending = false;

  Timer? _delayedUpdateTimer;
  // Debouncing state for auto-save functionality
  Timer? _autoSaveTimer;

  EraseStateNotifier(this._pathManager, this._ref)
      : super(EraseState.initial());

  /// 清除所有路径
  void clear() {
    AppLogger.debug('清除所有路径');
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
    }

    _pathManager.completePath();
    _updateState();
  }

  /// Dispose method to clean up resources
  @override
  void dispose() {
    _delayedUpdateTimer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  /// 初始化擦除状态，用于加载保存的擦除路径数据
  void initializeWithSavedPaths(List<Map<String, dynamic>> savedPaths) {
    AppLogger.debug('开始初始化擦除状态', data: {
      'pathsCount': savedPaths.length,
    });

    try {
      clear(); // First make sure we start with a clean state

      // Create path objects from saved data
      final paths = <PathInfo>[];

      for (final pathData in savedPaths) {
        final points = pathData['points'] as List<dynamic>;
        final brushSize = (pathData['brushSize'] as num?)?.toDouble() ?? 10.0;
        final brushColorValue = pathData['brushColor'] as int?;
        final color = brushColorValue != null
            ? Color(brushColorValue)
            : _defaultEraseColor;

        // Create a path from points
        final path = _createPathFromPoints(points);

        // Add to paths if valid
        if (!path.getBounds().isEmpty) {
          paths.add(PathInfo(
            path: path,
            brushSize: brushSize,
            brushColor: color,
          ));
        }
      }

      if (paths.isNotEmpty) {
        AppLogger.debug('成功创建路径对象', data: {
          'createdPaths': paths.length,
        });

        // Set the paths as completed
        _pathManager.setCompletedPaths(paths);
        _pathManager.clearUndoRedo();

        // Notify listeners of change
        _updateState();

        AppLogger.debug('初始化擦除状态完成', data: {
          'completedPathsCount': _pathManager.getCompletedPaths().length,
        });
      } else {
        AppLogger.warning('从保存数据创建的路径为空');
      }
    } catch (e) {
      AppLogger.error('初始化擦除状态失败', error: e);
    }
  }

  /// 重做上一个撤销的操作
  void redo() {
    if (!state.canRedo) return;

    _pathManager.redoPath();
    _updateState();

    // 简单地记录日志，不需要复杂的处理
    AppLogger.debug('执行重做操作', data: {
      'totalPaths': _pathManager.completedPaths.length,
    });
  }

  /// 重置图像更新标志
  void resetForceImageUpdate() {
    if (state.forceImageUpdate == true) {
      AppLogger.debug('重置强制图像更新标志');
      state = state.copyWith(forceImageUpdate: false);
    }
  }

  /// 设置笔刷大小
  void setBrushSize(double size) {
    if (size <= 0) return;
    state = state.copyWith(brushSize: size);
  }

  /// 更新噪声消除
  void setNoiseReduction(double value, {bool updateImage = false}) {
    // 如果值没有变化且不需要强制更新图像，则跳过
    if (state.processingOptions.noiseReduction == value && !updateImage) {
      return;
    }

    // 优化: 创建一次临时的处理选项对象, 无论是否更新图像
    final newOptions = state.processingOptions.copyWith(
      noiseReduction: value,
    );

    // 使用临时对象更新状态, 添加forceImageUpdate标志以控制是否触发处理
    state = state.copyWith(
      processingOptions: newOptions,
      // 仅当需要更新图像时设置标志
      forceImageUpdate: updateImage ? true : state.forceImageUpdate,
    );

    // 仅在需要时记录日志
    if (updateImage) {
      AppLogger.debug('噪声消除已更新，正在处理图像', data: {
        'noiseReduction': value,
      });
    }
  }

  /// 更新噪声消除 - 优化版本
  void setNoiseReductionOptimized(double value) {
    // 如果值没有变化，跳过更新
    if (state.processingOptions.noiseReduction == value) {
      return;
    }

    // 直接更新状态，不设置forceImageUpdate标志
    final newOptions = state.processingOptions.copyWith(
      noiseReduction: value,
    );

    state = state.copyWith(
      processingOptions: newOptions,
    );

    // 触发延迟图像更新（防抖处理）
    triggerDelayedImageUpdate();

    // Auto-save the new value to user preferences with debouncing
    _scheduleAutoSave();
  }

  /// 更新阈值
  void setThreshold(double threshold, {bool updateImage = false}) {
    // 如果值没有变化且不需要强制更新图像，则跳过
    if (state.processingOptions.threshold == threshold && !updateImage) {
      return;
    }

    // 优化: 创建一次临时的处理选项对象, 无论是否更新图像
    final newOptions = state.processingOptions.copyWith(
      threshold: threshold,
    );

    // 使用临时对象更新状态, 添加forceImageUpdate标志以控制是否触发处理
    state = state.copyWith(
      processingOptions: newOptions,
      // 仅当需要更新图像时设置标志
      forceImageUpdate: updateImage ? true : state.forceImageUpdate,
    );

    // 仅在需要时记录日志
    if (updateImage) {
      AppLogger.debug('阈值已更新，正在处理图像', data: {
        'threshold': threshold,
      });
    }
  }

  /// 更新阈值 - 优化版本
  void setThresholdOptimized(double threshold) {
    // 如果值没有变化，跳过更新
    if (state.processingOptions.threshold == threshold) {
      return;
    }

    // 直接更新状态，不设置forceImageUpdate标志
    final newOptions = state.processingOptions.copyWith(
      threshold: threshold,
    );

    state = state.copyWith(
      processingOptions: newOptions,
    );

    // 触发延迟图像更新（防抖处理）
    triggerDelayedImageUpdate();

    // Auto-save the new value to user preferences with debouncing
    _scheduleAutoSave();
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
    state = state.copyWith(showContour: !state.showContour);
    AppLogger.debug('轮廓显示状态切换为: ${state.showContour}');
  }

  /// 切换图像反转模式
  void toggleImageInvert() {
    final wasImageInverted = state.imageInvertMode;
    final newImageInverted = !wasImageInverted;

    AppLogger.debug('切换图像反转: $wasImageInverted → $newImageInverted');

    // 更新状态 - 只更新当前的设置，不会影响已有路径
    state = state.copyWith(imageInvertMode: newImageInverted);

    // 更新所有路径的颜色，以匹配新的图像反转状态
    _pathManager.updateAllPathsForImageInversion(newImageInverted);

    // 如果有活动路径，保持其颜色不变
    if (_pathManager.currentPath != null) {
      _pathManager.updateCurrentColor(state.brushColor);
    }

    // 日志记录颜色变化
    AppLogger.debug('图像反转切换后笔刷颜色', data: {
      'brushColor': state.brushColor.toString(),
      'isReversed': state.isReversed,
      'imageInvertMode': state.imageInvertMode,
    });

    // 如果轮廓显示开启，需要强制刷新轮廓
    if (state.showContour) {
      // 临时关闭轮廓显示然后立即重新打开，触发轮廓重新计算
      state = state.copyWith(showContour: false);
      _updateState();

      // 延迟重新开启轮廓显示
      Future.delayed(const Duration(milliseconds: 50), () {
        state = state.copyWith(showContour: true);
        _updateState();
        AppLogger.debug('图像反转后强制刷新轮廓');
      });
    } else {
      // 确保状态更新被通知
      _updateState();
    }
  }

  /// 切换降噪是否开启
  void toggleNoiseReduction(bool enabled) {
    // 如果禁用，将降噪值设为0，否则设为之前的值或默认值0.5
    final newValue = enabled
        ? (state.processingOptions.noiseReduction > 0
            ? state.processingOptions.noiseReduction
            : 0.5)
        : 0.0;

    final newProcessingOptions = state.processingOptions.copyWith(
      noiseReduction: newValue,
    );

    AppLogger.debug('切换降噪状态', data: {
      'enabled': enabled,
      'oldNoiseReduction': state.processingOptions.noiseReduction,
      'newNoiseReduction': newValue,
    });

    // 当开关切换时，总是需要立即更新图像
    state = state.copyWith(
        processingOptions: newProcessingOptions,
        forceImageUpdate: true // 切换开关时立即更新图像
        );
  }

  /// 切换颜色反转
  void toggleReverse() {
    final wasReversed = state.isReversed;
    final newReversed = !wasReversed;

    AppLogger.debug('切换笔刷反转', data: {
      'from': wasReversed,
      'to': newReversed,
    });

    // 更新状态 - 只影响未来的路径
    state = state.copyWith(isReversed: newReversed);

    // 如果有活动路径，立即更新其颜色
    if (_pathManager.currentPath != null) {
      _pathManager.updateCurrentColor(state.brushColor);
      AppLogger.debug('更新当前路径颜色', data: {
        'color': state.brushColor.toString(),
      });
    }

    // 日志记录颜色变化
    AppLogger.debug('笔刷反转切换后颜色', data: {
      'brushColor': state.brushColor.toString(),
      'isReversed': state.isReversed,
      'imageInvertMode': state.imageInvertMode,
    });

    // 确保状态更新被通知
    _updateState();
  }

  /// Trigger a delayed image update with a 500ms debounce
  void triggerDelayedImageUpdate() {
    _isDelayedUpdatePending = true;

    // Cancel existing timer if any
    _delayedUpdateTimer?.cancel();

    // Start a new timer with increased debounce time (500ms instead of 200ms)
    _delayedUpdateTimer = Timer(const Duration(milliseconds: 500), () {
      if (_isDelayedUpdatePending) {
        // Actual update - apply all pending changes at once
        final currentState = state;

        // Force an image update with current values
        state = currentState.copyWith(forceImageUpdate: true);

        // Reset pending flag
        _isDelayedUpdatePending = false;

        AppLogger.debug(
            'Applied batched slider updates with delayed image processing');
      }
    });
  }

  /// 撤销最后一个操作
  void undo() {
    if (!state.canUndo) return;

    _pathManager.undo();
    _updateState();

    // 简单地记录日志，不需要复杂的处理
    AppLogger.debug('执行撤销操作', data: {
      'remainingPaths': _pathManager.completedPaths.length,
    });
  }

  /// 更新路径
  void updatePath(Offset position) {
    if (state.mode != EraseMode.draw) return;

    _pathManager.updatePath(position);
    _updateState();
    // Keep track of the latest position for cursor display
    _ref.read(cursorPositionProvider.notifier).state = position;
  }

  /// Helper to create a path from saved points
  Path _createPathFromPoints(List<dynamic> points) {
    final path = Path();

    if (points.isEmpty) return path;

    try {
      // Get the first point
      final firstPoint = points.first;
      double x = (firstPoint['dx'] as num).toDouble();
      double y = (firstPoint['dy'] as num).toDouble();

      // Move to the first point
      path.moveTo(x, y);

      // Add lines to all other points
      for (int i = 1; i < points.length; i++) {
        final point = points[i];
        x = (point['dx'] as num).toDouble();
        y = (point['dy'] as num).toDouble();
        path.lineTo(x, y);
      }

      return path;
    } catch (e) {
      AppLogger.error('创建路径失败', error: e);
      return path;
    }
  }

  /// Auto-save current processing options to user preferences with debouncing
  void _scheduleAutoSave() {
    // Cancel existing timer if any
    _autoSaveTimer?.cancel();

    // Start a new timer with debounce delay
    _autoSaveTimer = Timer(_autoSaveDelay, () async {
      try {
        final userPreferencesNotifier =
            _ref.read(userPreferencesNotifierProvider.notifier);

        // Save threshold
        await userPreferencesNotifier
            .updateDefaultThreshold(state.processingOptions.threshold);

        // Save noise reduction
        await userPreferencesNotifier.updateDefaultNoiseReduction(
            state.processingOptions.noiseReduction);

        AppLogger.debug('Auto-saved processing options to user preferences',
            data: {
              'threshold': state.processingOptions.threshold,
              'noiseReduction': state.processingOptions.noiseReduction,
            });
      } catch (e) {
        AppLogger.error('Failed to auto-save processing options', error: e);
      }
    });
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
