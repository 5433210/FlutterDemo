import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../controllers/erase_tool_controller.dart';
import '../models/erase_mode.dart';
import '../models/erase_operation.dart';
import '../states/erase_layer_state.dart';
import '../states/erase_state_manager.dart';
import '../utils/coordinate_transformer.dart';

/// 擦除工具控制器实现
class EraseToolControllerImpl extends EraseToolController {
  /// 最小笔刷大小
  static const double minBrushSize = 3.0;

  /// 最大笔刷大小
  static const double maxBrushSize = 30.0;

  /// 默认笔刷大小
  static const double defaultBrushSize = 10.0;

  /// 节流计时器延迟(毫秒)
  static const int throttleDelayMs = 32; // 降低到约30fps，减少频繁刷新

  /// 单独处理通知节流的计时器
  static const int notificationThrottleMs = 60; // 进一步限制UI更新频率

  /// 最小重绘点数阈值 - 只有累积足够数量的点后才触发重绘
  static const int minPointsBeforeNotify = 5;

  /// 状态管理器
  final EraseStateManager _stateManager;

  /// 坐标转换器
  final CoordinateTransformer _transformer;

  /// 当前笔刷大小
  double _brushSize = defaultBrushSize;

  /// 当前擦除模式
  EraseMode _mode = EraseMode.normal;

  /// 事件节流计时器
  Timer? _throttleTimer;

  /// 临时擦除点缓存，用于节流处理
  final List<Offset> _pointBuffer = [];

  /// 是否初始化
  bool _isInitialized = false;

  /// 状态事件订阅
  StreamSubscription<EraseStateEvent>? _stateEventSubscription;

  /// 当前视口区域
  Rect _viewport = Rect.zero;

  bool _notificationsEnabled = true;

  bool _pendingNotification = false;
  Timer? _notificationThrottleTimer;
  bool _disposed = false;

  int _pointsAddedSinceLastNotify = 0;

  /// 创建控制器
  EraseToolControllerImpl({
    EraseStateManager? stateManager,
    CoordinateTransformer? transformer,
    double? initialBrushSize,
    EraseMode? initialMode,
  })  : _stateManager = stateManager ?? EraseStateManager(),
        _transformer = transformer ?? CoordinateTransformer() {
    if (initialBrushSize != null) {
      _brushSize = initialBrushSize.clamp(minBrushSize, maxBrushSize);
    }

    if (initialMode != null) {
      _mode = initialMode;
    }

    // 订阅状态变更事件
    _subscribeToStateEvents();
  }

  // EraseToolController接口实现

  @override
  double get brushSize => _brushSize;

  @override
  bool get canRedo => _stateManager.undoManager.canRedo;

  @override
  bool get canUndo => _stateManager.undoManager.canUndo;

  @override
  List<Offset> get currentPoints => _stateManager.layerState.displayPoints;

  @override
  bool get isErasing =>
      _stateManager.layerState.stateType == EraseStateType.erasing;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  @override
  EraseMode get mode => _mode;

  @override
  List<EraseOperation> get operations {
    // 获取所有未撤销的操作
    return _stateManager.undoManager.undoOperations;
  }

  @override
  void cancelErase() {
    if (!_isInitialized || !isErasing) return;

    _pointBuffer.clear();
    _throttleTimer?.cancel();
    _stateManager.cancelErase();
  }

  @override
  void clearAll() {
    if (!_isInitialized || isErasing) return;

    _stateManager.clearAll();
  }

  @override
  void continueErase(Offset point) {
    if (!_isInitialized || !isErasing || _disposed) return;

    try {
      // 转换为图像坐标
      final transformedPoint = _transformer.transformPoint(point);

      // 为了提高绘制性能，仅当新点与上一个点间距超过特定阈值时才添加
      const minDistance = 1.5; // 略微增加距离阈值，减少点数

      if (_pointBuffer.isEmpty ||
          (_pointBuffer.isNotEmpty &&
              (transformedPoint - _pointBuffer.last).distance > minDistance)) {
        // 添加到临时缓存
        _pointBuffer.add(transformedPoint);
        _pointsAddedSinceLastNotify++;
      }

      // 应用节流，避免过于频繁的更新
      _throttleTimer?.cancel();
      _throttleTimer = Timer(const Duration(milliseconds: throttleDelayMs), () {
        if (_disposed) return;
        // 处理缓存的点
        _processPointBuffer();
      });

      // 实时添加第一个点，保证立即有反馈
      if (_pointBuffer.length == 1) {
        _stateManager.continueErase(transformedPoint);
        // 暂时禁用通知，减少不必要的重建
        _pauseNotifications();
      } else if (_pointsAddedSinceLastNotify >= minPointsBeforeNotify) {
        // 累积了足够多的点，可以进行一次处理
        _processPointBuffer();
      }
    } catch (e) {
      print('ERROR in continueErase: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _throttleTimer?.cancel();
    _notificationThrottleTimer?.cancel();
    _stateEventSubscription?.cancel();
    _stateManager.dispose();
    super.dispose();
  }

  @override
  void endErase() {
    if (!_isInitialized || !isErasing) return;

    // 处理剩余的点
    _processPointBuffer();

    // 结束擦除操作
    _stateManager.endErase();

    // 恢复通知
    _resumeNotifications();
  }

  /// 初始化控制器
  void initialize({
    required ui.Image originalImage,
    required Matrix4 transformMatrix,
    required Size containerSize,
    required Size imageSize,
    Offset? containerOffset,
    Rect? viewport,
  }) {
    try {
      // 如果已经初始化则忽略
      if (_isInitialized) {
        print('⚠️ 控制器已初始化，忽略重复初始化');
        return;
      }

      print('🔧 初始化控制器: ${imageSize.width}x${imageSize.height}');

      // 使用异步方式更新图层状态，避免阻塞UI线程
      Future.microtask(() {
        if (_disposed) return;

        // 设置原始图像
        _stateManager.layerState.originalImage = originalImage;

        // 初始化坐标转换器
        _transformer.initializeTransform(
          transformMatrix: transformMatrix,
          containerSize: containerSize,
          imageSize: imageSize,
          containerOffset: containerOffset ?? Offset.zero,
          viewport: viewport,
        );

        // 更新图层状态
        _stateManager.updateLayerState(originalImage);

        _isInitialized = true;

        // 触发UI更新
        notifyListeners();
      });
    } catch (e) {
      print('❌ 初始化控制器失败: $e');
    }
  }

  @override
  void notifyListeners() {
    if (_disposed) return;

    if (!_notificationsEnabled) {
      _pendingNotification = true;
      return;
    }

    // 使用更严格的节流控制通知频率
    if (_notificationThrottleTimer?.isActive ?? false) {
      _pendingNotification = true;
      return;
    }

    super.notifyListeners();

    // 延长通知防抖时间，减少UI更新频率
    _notificationThrottleTimer = Timer(
      const Duration(milliseconds: notificationThrottleMs * 2),
      () {
        if (_disposed) return;
        if (_pendingNotification) {
          _pendingNotification = false;
          if (!_disposed) {
            super.notifyListeners();
          }
        }
      },
    );
  }

  @override
  void redo() {
    if (!_isInitialized || isErasing) return;

    _stateManager.redo();
  }

  @override
  void setBrushSize(double size) {
    _brushSize = size.clamp(minBrushSize, maxBrushSize);
    notifyListeners();
  }

  @override
  void setMode(EraseMode mode) {
    _mode = mode;
    notifyListeners();
  }

  @override
  void startErase(Offset point) {
    // 增加详细调试日志
    print('startErase called at $point with brushSize: $_brushSize');

    if (!_isInitialized) {
      print('Warning: Controller not initialized yet');
      // 尝试自动初始化，如果状态允许
      if (_stateManager.layerState.originalImage != null) {
        print('Auto-initializing controller with existing image');
        _isInitialized = true;
      } else {
        print(
            'ERROR: Cannot start erasing - controller not initialized and no image available');
        return;
      }
    }

    try {
      // 转换为图像坐标
      final transformedPoint = _transformer.transformPoint(point);
      print('Transformed point: $transformedPoint (original: $point)');

      // 开始新的擦除操作
      _stateManager.startErase(transformedPoint, _brushSize);
      print('Erase operation started with brush size: $_brushSize');

      // 清除节流缓存
      _pointBuffer.clear();

      // 暂时禁用通知，仅在必要时更新
      _pauseNotifications();

      // 强制更新UI显示初始状态
      notifyListeners();
    } catch (e) {
      print('ERROR in startErase: $e');
    }
  }

  @override
  void undo() {
    if (!_isInitialized || isErasing) return;

    _stateManager.undo();
  }

  /// 更新容器偏移
  void updateContainerOffset(Offset offset) {
    _transformer.updateContainerOffset(offset);
  }

  /// 更新容器大小
  void updateContainerSize(Size size) {
    _transformer.updateContainerSize(size);
  }

  /// 更新图像大小
  void updateImageSize(Size size) {
    _transformer.updateImageSize(size);
  }

  /// 更新变换矩阵
  void updateTransform(Matrix4 transformMatrix) {
    _transformer.updateTransform(transformMatrix);
  }

  /// 更新视口区域
  void updateViewport(Rect viewport) {
    _viewport = viewport;
    _transformer.updateViewport(viewport);
    print(
        '📺 Updated viewport: ${viewport.left},${viewport.top},${viewport.width}x${viewport.height}');
  }

  /// 暂停通知，避免频繁刷新
  void _pauseNotifications() {
    _notificationsEnabled = false;
    _pendingNotification = false;
  }

  /// 处理点缓存，应用平滑化处理
  void _processPointBuffer() {
    if (_disposed || _pointBuffer.isEmpty) return;

    try {
      // 对点进行采样并平滑化处理
      final processedPoints = _processPoints(_pointBuffer);

      // 添加到当前操作，但不触发立即通知
      for (final point in processedPoints) {
        _stateManager.continueErase(point);
        print('➕ Added point: $point');
      }

      // 重置计数器
      _pointsAddedSinceLastNotify = 0;

      print('🔄 Processed ${processedPoints.length} points');

      // 清空缓存
      _pointBuffer.clear();
    } catch (e) {
      print('ERROR in _processPointBuffer: $e');
    }
  }

  /// 处理点序列，进行采样和平滑化
  List<Offset> _processPoints(List<Offset> points) {
    if (points.length <= 2) return List.from(points);

    // 采样率根据模式和点数动态调整
    int sampleRate = 1;
    if (_mode != EraseMode.precise && points.length > 10) {
      sampleRate = 2; // 对于普通模式且点数较多时，进行采样减少点数
    }

    // 采样点
    final sampled = <Offset>[];
    for (int i = 0; i < points.length; i += sampleRate) {
      sampled.add(points[i]);
    }

    // 确保包含最后一个点
    if (points.isNotEmpty && sampled.last != points.last) {
      sampled.add(points.last);
    }

    // 平滑处理(如果有足够的点)
    if (_mode != EraseMode.precise && sampled.length > 3) {
      return _smoothPoints(sampled);
    }

    return sampled;
  }

  /// 恢复通知并触发一次更新
  void _resumeNotifications() {
    _notificationsEnabled = true;
    if (_pendingNotification) {
      _pendingNotification = false;
      notifyListeners();
    }
  }

  /// 平滑点序列，减少抖动，使用高斯加权
  List<Offset> _smoothPoints(List<Offset> points) {
    if (points.length <= 3) return points;

    final result = <Offset>[];

    // 保留首尾点
    result.add(points.first);

    // 对中间点进行平滑处理，使用三点高斯加权
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];

      // 使用高斯加权 [0.25, 0.5, 0.25]
      final smoothedX = prev.dx * 0.25 + current.dx * 0.5 + next.dx * 0.25;
      final smoothedY = prev.dy * 0.25 + current.dy * 0.5 + next.dy * 0.25;

      result.add(Offset(smoothedX, smoothedY));
    }

    // 添加最后一个点
    result.add(points.last);

    return result;
  }

  /// 订阅状态变更事件
  void _subscribeToStateEvents() {
    _stateEventSubscription = _stateManager.stateEvents.listen((event) {
      // 根据事件类型处理状态变更
      switch (event.type) {
        case EraseStateType.idle:
        case EraseStateType.erasing:
        case EraseStateType.committing:
        case EraseStateType.undoing:
        case EraseStateType.redoing:
          // 通知UI更新
          notifyListeners();
          break;
      }
    });
  }
}
