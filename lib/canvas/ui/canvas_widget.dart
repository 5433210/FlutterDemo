// filepath: lib/canvas/ui/canvas_widget.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../compatibility/canvas_controller_adapter.dart';
import '../compatibility/canvas_state_adapter.dart';
import '../core/canvas_state_manager.dart';
import '../interaction/gesture_handler.dart';
import '../monitoring/performance_monitor.dart';
import '../rendering/rendering_engine.dart';
import 'toolbar/tool_state_manager.dart';

/// Canvas组件配置
class CanvasConfiguration {
  final Size size;
  final Color backgroundColor;
  final bool showGrid;
  final double gridSize;
  final Color gridColor;
  final bool enableGestures;
  final bool enablePerformanceMonitoring;

  const CanvasConfiguration({
    this.size = const Size(800, 600),
    this.backgroundColor = Colors.white,
    this.showGrid = false,
    this.gridSize = 20.0,
    this.gridColor = const Color(0xFFE0E0E0),
    this.enableGestures = true,
    this.enablePerformanceMonitoring = true,
  });
}

/// 新Canvas组件 - 基于重构架构的高性能画布
class CanvasWidget extends StatefulWidget {
  final CanvasConfiguration configuration;
  final CanvasControllerAdapter? controller;
  final TransformationController? transformationController;
  final bool isPreviewMode;

  const CanvasWidget({
    super.key,
    required this.configuration,
    this.controller,
    this.transformationController,
    this.isPreviewMode = false,
  });

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

/// Canvas绘制器
class _CanvasPainter extends CustomPainter {
  final RenderingEngine renderingEngine;
  final CanvasConfiguration configuration;
  final CanvasGestureHandler gestureHandler;
  final CanvasPerformanceMonitor? performanceMonitor;

  _CanvasPainter({
    required this.renderingEngine,
    required this.configuration,
    required this.gestureHandler,
    this.performanceMonitor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    performanceMonitor?.startFrame();

    try {
      // 绘制背景
      _drawBackground(canvas, size);

      // 绘制网格
      if (configuration.showGrid) {
        _drawGrid(canvas, size);
      } // 绘制元素 - 委托给渲染引擎
      renderingEngine.renderElements(canvas, size);

      // 绘制选择框（由手势处理器提供的临时选择框）
      _drawSelectionBox(canvas);
    } catch (e) {
      debugPrint('Canvas绘制错误: $e');
    } finally {
      performanceMonitor?.endFrame();
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return renderingEngine != oldDelegate.renderingEngine ||
        configuration != oldDelegate.configuration ||
        gestureHandler != oldDelegate.gestureHandler;
  }

  /// 绘制背景
  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = configuration.backgroundColor;
    canvas.drawRect(Offset.zero & size, paint);
  }

  /// 绘制网格
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = configuration.gridColor
      ..strokeWidth = 0.5;

    final gridSize = configuration.gridSize;

    // 绘制垂直线
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 绘制水平线
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /// 绘制选择框
  void _drawSelectionBox(Canvas canvas) {
    if (!gestureHandler.isSelectionBoxActive) return;

    final rect = gestureHandler.selectionBoxRect;
    if (rect == null) return; // 绘制选择框背景
    final backgroundPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, backgroundPaint);

    // 绘制选择框边框
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);
  }
}

class _CanvasWidgetState extends State<CanvasWidget>
    with TickerProviderStateMixin {
  late CanvasStateManager _stateManager;
  late CanvasStateManagerAdapter _stateAdapter;
  late ToolStateManager _toolStateManager;
  late RenderingEngine _renderingEngine;
  late CanvasGestureHandler _gestureHandler;
  late CanvasPerformanceMonitor _performanceMonitor;

  // 变换控制器
  late final TransformationController _transformationController;

  // 焦点节点
  late final FocusNode _focusNode;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        child: Listener(
          onPointerDown: _handlePointerEvent,
          onPointerMove: _handlePointerEvent,
          onPointerUp: _handlePointerEvent,
          onPointerCancel: _handlePointerEvent,
          child: RepaintBoundary(
            child: CustomPaint(
              size: widget.configuration.size,
              painter: _CanvasPainter(
                renderingEngine: _renderingEngine,
                configuration: widget.configuration,
                gestureHandler: _gestureHandler,
                performanceMonitor:
                    widget.configuration.enablePerformanceMonitoring
                        ? _performanceMonitor
                        : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(CanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _detachController(oldWidget.controller);
      _attachController();
    }
  }

  @override
  void dispose() {
    _detachController(widget.controller);
    _gestureHandler.dispose();
    _performanceMonitor.dispose();
    _focusNode.dispose();
    _stateAdapter.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _initializeComponents();
    _setupEventListeners();
    _attachController();
  }

  /// 附加控制器
  void _attachController() {
    if (widget.controller != null) {
      widget.controller!.attach(_stateAdapter);
    }
  }

  /// 分离控制器
  void _detachController(CanvasControllerAdapter? controller) {
    controller?.detach();
  }

  /// 获取输入设备类型
  InputDevice _getInputDevice(PointerEvent event) {
    switch (event.kind) {
      case PointerDeviceKind.mouse:
        return InputDevice.mouse;
      case PointerDeviceKind.touch:
        return InputDevice.touch;
      case PointerDeviceKind.stylus:
        return InputDevice.pen;
      default:
        return InputDevice.unknown;
    }
  }

  /// 处理手势状态变化
  void _handleGestureStateChanged() {
    if (mounted) {
      setState(() {
        // 手势状态变化时重绘
      });
    }
  }

  /// 处理指针事件
  void _handlePointerEvent(PointerEvent event) {
    if (!widget.configuration.enableGestures) return;
    if (widget.isPreviewMode) return;

    // 获取修饰键状态
    final modifiers = HardwareKeyboard.instance.logicalKeysPressed;

    // 转换为输入事件
    InputEvent? inputEvent;
    if (event is PointerDownEvent) {
      inputEvent = InputEvent(
        type: InputEventType.down,
        position: event.localPosition,
        device: _getInputDevice(event),
        pressure: event.pressure,
        pointer: event.pointer,
        modifiers: modifiers,
      );
    } else if (event is PointerMoveEvent) {
      inputEvent = InputEvent(
        type: InputEventType.move,
        position: event.localPosition,
        device: _getInputDevice(event),
        pressure: event.pressure,
        pointer: event.pointer,
        modifiers: modifiers,
      );
    } else if (event is PointerUpEvent) {
      inputEvent = InputEvent(
        type: InputEventType.up,
        position: event.localPosition,
        device: _getInputDevice(event),
        pressure: event.pressure,
        pointer: event.pointer,
        modifiers: modifiers,
      );
    } else if (event is PointerCancelEvent) {
      inputEvent = InputEvent(
        type: InputEventType.cancel,
        position: event.localPosition,
        device: _getInputDevice(event),
        pressure: 0.0,
        pointer: event.pointer,
        modifiers: modifiers,
      );
    }

    // 分发到手势处理器
    if (inputEvent != null) {
      switch (inputEvent.type) {
        case InputEventType.down:
          _gestureHandler.handlePointerDown(inputEvent);
          break;
        case InputEventType.move:
          _gestureHandler.handlePointerMove(inputEvent);
          break;
        case InputEventType.up:
          _gestureHandler.handlePointerUp(inputEvent);
          break;
        case InputEventType.cancel:
          _gestureHandler.handlePointerCancel(inputEvent);
          break;
      }
    }
  }

  /// 处理状态变化
  void _handleStateChanged() {
    if (mounted) {
      setState(() {
        // 状态变化时重绘
      });
    }
  }

  /// 初始化核心组件
  void _initializeComponents() {
    // 状态管理器
    _stateManager = CanvasStateManager();

    // 创建适配器解决类型兼容问题
    _stateAdapter = CanvasStateManagerAdapter(_stateManager);

    // 工具状态管理器
    _toolStateManager = ToolStateManager();

    // 渲染引擎 - 使用原生的状态管理器，因为渲染引擎已经修改为支持两种类型
    _renderingEngine = RenderingEngine(stateManager: _stateManager);

    // 手势处理器 - 使用适配器解决类型兼容问题
    _gestureHandler = CanvasGestureHandler(_stateAdapter, _toolStateManager);

    // 性能监控器
    if (widget.configuration.enablePerformanceMonitoring) {
      _performanceMonitor = CanvasPerformanceMonitor();
      _performanceMonitor.startMonitoring();
    } else {
      _performanceMonitor = CanvasPerformanceMonitor(); // 创建但不启动
    }

    // 变换控制器
    _transformationController =
        widget.transformationController ?? TransformationController();

    // 焦点节点
    _focusNode = FocusNode();
  }

  /// 添加必要的事件监听器
  void _setupEventListeners() {
    // 状态变化监听 - 使用适配器而不是原始管理器
    _stateAdapter.addListener(_handleStateChanged);

    // 手势状态变化监听
    _gestureHandler.addListener(_handleGestureStateChanged);

    // 注意：焦点节点已在_initializeComponents()中初始化
  }
}
