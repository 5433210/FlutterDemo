import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../infrastructure/logging/practice_edit_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/practice/batch_update_options.dart';
import '../../../widgets/practice/drag_state_manager.dart';
import '../../../widgets/practice/guideline_alignment/guideline_types.dart';
import '../../../widgets/practice/performance_monitor.dart' as perf;
import '../../../widgets/practice/performance_monitor.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import '../../../widgets/practice/smart_canvas_gesture_handler.dart';
import '../helpers/element_utils.dart';
import 'canvas/components/canvas_control_point_handlers.dart';
import 'canvas/components/canvas_element_creators.dart';
import 'canvas/components/canvas_layer_builders.dart';
import 'canvas/components/canvas_ui_components.dart';
import 'canvas/components/canvas_view_controllers.dart';
import 'canvas_structure_listener.dart';
import 'content_render_controller.dart';
import 'drag_operation_manager.dart';
import 'layers/layer_render_manager.dart';
import 'layers/layer_types.dart';
import 'state_change_dispatcher.dart';

/// Material 3 canvas widget for practice editing
class M3PracticeEditCanvas extends StatefulWidget {
  final PracticeEditController controller;
  final bool isPreviewMode;
  final TransformationController transformationController;

  const M3PracticeEditCanvas({
    super.key,
    required this.controller,
    required this.isPreviewMode,
    required this.transformationController,
  });

  @override
  State<M3PracticeEditCanvas> createState() => _M3PracticeEditCanvasState();
}

class OptimizedCanvasListener extends StatefulWidget {
  final Widget child;
  final ContentRenderController controller;
  final bool isPreviewMode;

  const OptimizedCanvasListener({
    super.key,
    required this.child,
    required this.controller,
    this.isPreviewMode = false,
  });

  @override
  State<OptimizedCanvasListener> createState() =>
      _OptimizedCanvasListenerState();
}

// 注意：SelectionBoxState 和 GridPainter 已移动到 canvas_ui_components.dart

class _M3PracticeEditCanvasState extends State<M3PracticeEditCanvas>
    with
        // 先放置与界面显示、创建相关的mixin
        CanvasLayerBuilders,
        CanvasElementCreators,
        // 然后放置与视图控制相关的mixin
        CanvasViewControllers,
        // 最后放置与交互控制相关的mixin
        CanvasControlPointHandlers {
  // 🚀 性能优化相关静态变量
  static int _interactionStateChangeCount = 0;
  static String _lastEventType = '';
  static DateTime _lastInteractionLogTime = DateTime.now();

  // 控制点处理方法已由 CanvasControlPointHandlers mixin 提供

  // 核心组件
  late ContentRenderController _contentRenderController;

  late DragStateManager _dragStateManager;

  late LayerRenderManager _layerRenderManager;

  late PerformanceMonitor _performanceMonitor;

  // 优化组件
  late CanvasStructureListener _structureListener;

  late StateChangeDispatcher _stateDispatcher;

  late DragOperationManager _dragOperationManager;

  // UI组件
  late GlobalKey _repaintBoundaryKey;

  // 状态管理
  bool _isDragging = false;
  bool _isDisposed = false; // 防止PostFrameCallback在dispose后执行
  bool _shouldInterceptNextPanGesture = false; // 🔧 新增：动态决定是否拦截下一个pan手势

  // 移动端手势支持
  bool _isMobile = false;
  bool _isMultiTouchGesture = false;
  int _activePointerCount = 0;
  bool _platformDetected = false; // 🔧 新增：避免重复平台检测

  /// 判断是否应该处理Pan手势
  bool _shouldHandlePanGesture() {
    return _isDragging ||
        _dragStateManager.isDragging ||
        widget.controller.state.currentTool == 'select' ||
        widget.controller.state.selectedElementIds.isNotEmpty;
  }

  /// 获取平台特定的平移启用状态
  bool _getPanEnabled() {
    if (_isMobile) {
      // 移动端：当没有多指触控且没有元素拖拽时启用平移
      return !_isMultiTouchGesture &&
          !(_isDragging || _dragStateManager.isDragging);
    } else {
      // 桌面端：当没有元素拖拽时启用平移
      return !(_isDragging || _dragStateManager.isDragging);
    }
  }

  /// 处理指针按下事件
  void _handlePointerDown(PointerDownEvent event) {
    _activePointerCount++;
    _isMultiTouchGesture = _activePointerCount > 1;

    EditPageLogger.canvasDebug('指针按下', data: {
      'pointerId': event.pointer,
      'activePointers': _activePointerCount,
      'isMultiTouch': _isMultiTouchGesture,
      'isMobile': _isMobile,
    });
  }

  /// 处理指针释放事件
  void _handlePointerUp(PointerUpEvent event) {
    _activePointerCount = math.max(0, _activePointerCount - 1);
    if (_activePointerCount <= 1) {
      _isMultiTouchGesture = false;
    }

    EditPageLogger.canvasDebug('指针释放', data: {
      'pointerId': event.pointer,
      'activePointers': _activePointerCount,
      'isMultiTouch': _isMultiTouchGesture,
    });
  }

  // 拖拽准备状态：使用普通变量避免setState时序问题
  bool _isReadyForDrag = false;
  // Canvas gesture handler
  late SmartCanvasGestureHandler _gestureHandler;

  // 🔧 保存UI监听器回调引用，用于正确注销
  VoidCallback? _canvasUIListener;
  // 选择框状态管理 - 使用ValueNotifier<SelectionBoxState>替代原来的布尔值
  final ValueNotifier<SelectionBoxState> _selectionBoxNotifier =
      ValueNotifier(SelectionBoxState());
  // 跟踪页面变化，用于自动重置视图
  String? _lastPageKey;
  bool _hasInitializedUI = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🔧 修复：在didChangeDependencies中初始化UI组件，此时MediaQuery可用
    if (!_hasInitializedUI && !_isDisposed) {
      try {
        _initializeUIComponents();
        _hasInitializedUI = true;

        EditPageLogger.editPageInfo(
          'UI组件初始化完成',
          data: {
            'timestamp': DateTime.now().toIso8601String(),
            'operation': 'ui_init_complete',
            'isMobile': _isMobile, // 添加平台检测结果
          },
        );
      } catch (e, stackTrace) {
        EditPageLogger.editPageError(
          'UI组件初始化失败',
          error: e,
          stackTrace: stackTrace,
          data: {
            'operation': 'ui_init_failed',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        // 回退到基础模式
        _fallbackToBasicMode();
      }
    }
  }

  // 实现CanvasLayerBuilders要求的抽象属性
  @override
  List<Guideline> get activeGuidelines =>
      widget.controller.state.activeGuidelines;

  @override
  ContentRenderController get contentRenderController =>
      _contentRenderController;

  @override
  PracticeEditController get controller => widget.controller;

  @override
  DragStateManager get dragStateManager => _dragStateManager;

  @override
  bool get isDisposed => _isDisposed;

  @override
  bool get isPreviewMode => widget.isPreviewMode;

  @override
  bool get isReadyForDrag => _isReadyForDrag;

  @override
  ValueNotifier<SelectionBoxState> get selectionBoxNotifier =>
      _selectionBoxNotifier;

  @override
  TransformationController get transformationController =>
      widget.transformationController;

  @override
  Widget build(BuildContext context) {
    // Track performance for main canvas rebuilds
    _performanceMonitor.trackWidgetRebuild('M3PracticeEditCanvas');

    return OptimizedCanvasListener(
      controller: _contentRenderController,
      child: _buildCanvasContent(),
    );
  }

  /// Handle window size changes - automatically trigger reset view position

  @override
  void dispose() {
    // 🔧 CRITICAL FIX: 立即设置dispose标志，防止PostFrameCallback在dispose后执行
    _isDisposed = true;

    try {
      EditPageLogger.editPageDebug(
        '销毁Canvas组件',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          'operation': 'canvas_dispose',
        },
      );
    } catch (e) {
      EditPageLogger.editPageError(
        'Canvas dispose初始日志失败',
        error: e,
        data: {'operation': 'canvas_dispose_logging'},
      );
    }

    try {
      // 使用安全的资源释放方式
      try {
        _gestureHandler.dispose();
        EditPageLogger.editPageDebug(
          'Canvas组件资源释放：手势处理器',
          data: {
            'component': 'gesture_handler',
            'operation': 'dispose',
          },
        );
      } catch (e) {
        EditPageLogger.editPageError(
          '手势处理器释放失败',
          error: e,
          data: {'component': 'gesture_handler'},
        );
      }

      try {
        _contentRenderController.dispose();
        EditPageLogger.editPageDebug(
          'Canvas组件资源释放：内容渲染控制器',
          data: {
            'component': 'content_render_controller',
            'operation': 'dispose',
          },
        );
      } catch (e) {
        EditPageLogger.editPageError(
          '内容渲染控制器释放失败',
          error: e,
          data: {'component': 'content_render_controller'},
        );
      }

      try {
        _dragStateManager.dispose();
        EditPageLogger.editPageDebug(
          'Canvas组件资源释放：拖拽状态管理器',
          data: {
            'component': 'drag_state_manager',
            'operation': 'dispose',
          },
        );
      } catch (e) {
        EditPageLogger.editPageError(
          '拖拽状态管理器释放失败',
          error: e,
          data: {'component': 'drag_state_manager'},
        );
      }

      try {
        _selectionBoxNotifier.dispose();
        EditPageLogger.editPageDebug(
          'Canvas组件资源释放：选择框通知器',
          data: {
            'component': 'selection_box_notifier',
            'operation': 'dispose',
          },
        );
      } catch (e) {
        EditPageLogger.editPageError(
          '选择框通知器释放失败',
          error: e,
          data: {'component': 'selection_box_notifier'},
        );
      }

      try {
        _structureListener.dispose();
        EditPageLogger.editPageDebug(
          'Canvas组件资源释放：结构监听器',
          data: {
            'component': 'structure_listener',
            'operation': 'dispose',
          },
        );
      } catch (e) {
        EditPageLogger.editPageError(
          '结构监听器释放失败',
          error: e,
          data: {'component': 'structure_listener'},
        );
      }

      try {
        _stateDispatcher.dispose();
        EditPageLogger.editPageDebug(
          'Canvas组件资源释放：状态分发器',
          data: {
            'component': 'state_dispatcher',
            'operation': 'dispose',
          },
        );
      } catch (e) {
        EditPageLogger.editPageError(
          '状态分发器释放失败',
          error: e,
          data: {'component': 'state_dispatcher'},
        );
      }

      try {
        _dragOperationManager.dispose();
        EditPageLogger.editPageDebug(
          'Canvas组件资源释放：拖拽操作管理器',
          data: {
            'component': 'drag_operation_manager',
            'operation': 'dispose',
          },
        );
      } catch (e) {
        EditPageLogger.editPageError(
          '拖拽操作管理器释放失败',
          error: e,
          data: {'component': 'drag_operation_manager'},
        );
      }

      try {
        _layerRenderManager.dispose();
        EditPageLogger.editPageDebug(
          'Canvas组件资源释放：图层渲染管理器',
          data: {
            'component': 'layer_render_manager',
            'operation': 'dispose',
          },
        );
      } catch (e) {
        EditPageLogger.editPageError(
          '图层渲染管理器释放失败',
          error: e,
          data: {'component': 'layer_render_manager'},
        );
      }

      // 注销智能状态分发器监听器
      try {
        _unregisterFromIntelligentDispatcher();
        EditPageLogger.editPageDebug(
          'Canvas组件资源释放：智能分发器监听器注销',
          data: {
            'component': 'intelligent_dispatcher',
            'operation': 'unregister',
          },
        );
      } catch (e) {
        EditPageLogger.editPageError(
          '智能分发器监听器注销失败',
          error: e,
          data: {'component': 'intelligent_dispatcher'},
        );
      }

      // 注意：不要 dispose 单例的 PerformanceMonitor
      EditPageLogger.editPageDebug(
        'Canvas组件资源释放：性能监控器引用移除（单例不释放）',
        data: {
          'component': 'performance_monitor',
          'operation': 'reference_removed',
        },
      );
    } finally {
      // 🔧 CRITICAL FIX: 在finally块中调用super.dispose()确保一定会被执行
      EditPageLogger.editPageDebug(
        'Canvas组件即将调用super.dispose()',
        data: {
          'operation': 'super_dispose',
          'stage': 'before',
        },
      );
      super.dispose();
      EditPageLogger.editPageDebug(
        'Canvas组件super.dispose()调用成功',
        data: {
          'operation': 'super_dispose',
          'stage': 'completed',
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // 🔧 窗口大小变化处理已移至页面级别

    EditPageLogger.editPageInfo(
      '画布组件初始化开始',
      data: {
        'timestamp': DateTime.now().toIso8601String(),
        'operation': 'canvas_init',
      },
    );

    try {
      // 阶段1: 初始化核心组件
      _initializeCoreComponents();

      // 阶段2: 初始化混合优化策略组件
      _initializeOptimizationComponents();

      // 阶段3: 建立组件间连接
      _setupComponentConnections();

      // 阶段4: UI组件初始化将在didChangeDependencies中进行
      // _initializeUIComponents(); // 🔧 移到didChangeDependencies中

      EditPageLogger.editPageInfo(
        '画布分层和元素级混合优化策略组件初始化完成',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          'operation': 'canvas_init_complete',
          'components': ['core', 'optimization', 'connections'],
          'note': 'UI组件将在didChangeDependencies中初始化',
        },
      );
    } catch (e, stackTrace) {
      EditPageLogger.editPageError(
        '画布初始化失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'operation': 'canvas_init_failed',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      // 回退到基础模式
      _fallbackToBasicMode();
    }
  }

  void on(String elementId, Offset delta) {
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    // Get current rotation
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    // We'll use a simpler rotation approach that doesn't require center point calculation

    // Improved rotation calculation
    // Use a sensitivity factor to make rotation more controllable
    const rotationSensitivity = 0.5;

    // Calculate rotation based on delta movement
    // Horizontal movement (dx) has more effect on rotation than vertical movement (dy)
    final rotationDelta = (delta.dx * rotationSensitivity);

    // Apply the rotation delta
    final newRotation = rotation + rotationDelta;

    // 🚀 优化：高频拖拽操作只记录重要信息
    PracticeEditLogger.debugDetail(
      '元素旋转: $elementId',
      data: {
        'elementId': elementId,
        'newRotation': newRotation.toStringAsFixed(2),
        'operation': 'element_rotation',
      },
    );

    // Update rotation
    widget.controller
        .updateElementProperties(elementId, {'rotation': newRotation});
  }

  @override
  void resetCanvasPosition() {
    // 使用 CanvasViewControllers mixin 的方法
    super.resetCanvasPosition();
  }

  /// 检查是否可能需要处理任何特殊手势（用于决定是否设置pan手势回调）
  bool shouldHandleAnySpecialGesture(List<Map<String, dynamic>> elements) {
    // 🚀 优化：减少手势检查的日志输出，使用简化信息
    PracticeEditLogger.debugDetail(
      '手势检查',
      data: {
        'currentTool': controller.state.currentTool,
        'selectedCount': controller.state.selectedElementIds.length,
        'isDragging': isDragging,
        'shouldIntercept': _shouldInterceptNextPanGesture,
      },
    );

    // 如果在预览模式，不处理任何手势
    if (controller.state.isPreviewMode) {
      return false;
    }

    // 如果在select模式下，需要处理选择框
    if (controller.state.currentTool == 'select') {
      return true;
    }

    // 如果正在进行拖拽操作，需要处理
    if (isDragging || dragStateManager.isDragging) {
      return true;
    }

    // 🔧 关键修复：如果有选中的元素，就应该准备处理可能的拖拽
    // 不管当前工具是什么，只要有选中元素就可能需要拖拽
    if (controller.state.selectedElementIds.isNotEmpty) {
      return true;
    }

    // 🔧 关键修复：只有明确需要拦截下一个手势时才返回true
    // 这个标志在onTapDown中根据点击位置动态设置
    if (_shouldInterceptNextPanGesture) {
      return true;
    }

    // 其他情况让InteractiveViewer完全接管画布平移和缩放
    return false;
  }

  /// 切换性能监控覆盖层显示
  @override
  void togglePerformanceOverlay() {
    setState(() {
      DragConfig.showPerformanceOverlay = !DragConfig.showPerformanceOverlay;
      // 🚀 优化：用户操作使用专门的用户操作日志
      PracticeEditLogger.logUserAction(
        '切换性能覆盖层',
        data: {'enabled': DragConfig.showPerformanceOverlay},
      );
    });
  }

  void triggerSetState() {
    // 🚀 优化：避免Canvas整体重建，使用分层架构
    PracticeEditLogger.debugDetail(
      '跳过triggerSetState - 使用分层架构',
      data: {'optimization': 'avoid_trigger_setstate'},
    );
  }

  /// 为选中的元素应用网格吸附（只在拖拽结束时调用）
  void _applyGridSnapToSelectedElements() {
    // 只有在启用了网格吸附的情况下才进行网格吸附
    if (!widget.controller.state.snapEnabled) {
      return;
    }

    final gridSize = widget.controller.state.gridSize;

    // 处理所有选中元素
    for (final elementId in widget.controller.state.selectedElementIds) {
      final element = widget.controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == elementId,
        orElse: () => <String, dynamic>{},
      );

      if (element.isEmpty) {
        continue;
      }

      // 跳过锁定的元素
      final isLocked = element['locked'] as bool? ?? false;
      if (isLocked) {
        continue;
      }

      // 跳过锁定图层上的元素
      final layerId = element['layerId'] as String?;
      if (layerId != null && widget.controller.state.isLayerLocked(layerId)) {
        continue;
      }

      // 获取当前位置和尺寸
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();

      // 计算吸附后的位置（向最近的网格线吸附）
      final snappedX = (x / gridSize).round() * gridSize;
      final snappedY = (y / gridSize).round() * gridSize;

      // 如果位置有变化，更新元素属性
      if (snappedX != x || snappedY != y) {
        EditPageLogger.canvasDebug(
          '网格吸附',
          data: {
            'elementId': elementId,
            'from': {'x': x, 'y': y},
            'to': {'x': snappedX, 'y': snappedY},
          },
        );

        widget.controller.updateElementProperties(elementId, {
          'x': snappedX,
          'y': snappedY,
        });
      }
    }
  }

  Widget _buildCanvasContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = widget.controller;

    if (controller.state.pages.isEmpty) {
      return Center(
        child: Text(
          'No pages available',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final currentPage = controller.state.currentPage;
    if (currentPage == null) {
      return Center(
        child: Text(
          'Current page does not exist',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final elements = controller.state.currentPageElements;

    // 用性能覆盖层包装画布
    return perf.PerformanceOverlay(
      showOverlay: DragConfig.showPerformanceOverlay,
      child: _buildPageContent(currentPage, elements, colorScheme),
    );
  }

  /// Build widget for specific layer type
  Widget _buildLayerWidget(RenderLayerType layerType, LayerConfig config) {
    return buildLayerWidget(layerType, config);
  }

  /// Build page content using LayerRenderManager architecture
  Widget _buildPageContent(
    Map<String, dynamic> page,
    List<Map<String, dynamic>> elements,
    ColorScheme colorScheme,
  ) {
    // Update content render controller with current elements
    _contentRenderController.initializeElements(elements);

    // Calculate page dimensions for layout purposes
    final pageSize = ElementUtils.calculatePixelSize(page);

    // 检测页面尺寸变化并自动重置视图
    final pageKey =
        '${page['width']}_${page['height']}_${page['orientation']}_${page['dpi']}';
    if (_lastPageKey != null && _lastPageKey != pageKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          _fitPageToScreen();
        }
      });
    }
    _lastPageKey = pageKey;

    // 🔥 关键修复：移除每次build时的自动变换设置
    // 不再在build方法中强制设置transformationController和调用zoomTo
    // 这些操作现在只在真正需要时进行（如初始化、重置按钮）

    return Stack(
      children: [
        Container(
            color: colorScheme.inverseSurface
                .withAlpha(26), // Canvas outer background
            // 使用RepaintBoundary包装InteractiveViewer，防止缩放和平移触发整个画布重建
            child: RepaintBoundary(
              key: const ValueKey('interactive_viewer_repaint_boundary'),
              child: Listener(
                onPointerDown: _handlePointerDown,
                onPointerUp: _handlePointerUp,
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  // 使用新的平台特定的平移启用逻辑
                  panEnabled: _getPanEnabled(),
                  scaleEnabled: true,
                  minScale: 0.1,
                  maxScale: 15.0,
                  scaleFactor:
                      600.0, // Increased scale factor to make zooming more gradual
                  transformationController: widget.transformationController,
                  onInteractionStart: (ScaleStartDetails details) {
                    EditPageLogger.canvasDebug('InteractiveViewer交互开始', data: {
                      'pointerCount': details.pointerCount,
                      'localFocalPoint': details.localFocalPoint.toString(),
                      'focalPoint': details.focalPoint.toString(),
                    });
                  },
                  onInteractionUpdate: (ScaleUpdateDetails details) {
                    // Status bar uses real-time calculation, no setState needed during update
                  },
                  onInteractionEnd: (ScaleEndDetails details) {
                    // Update final zoom value through controller
                    final scale = widget.transformationController.value
                        .getMaxScaleOnAxis();
                    widget.controller.zoomTo(scale);
                    // Status bar uses real-time calculation, no explicit setState needed
                  },
                  constrained: false, // Allow content to be unconstrained
                  child: DragTarget<String>(
                    onWillAcceptWithDetails: (data) {
                      // 只接受工具栏拖拽的元素类型
                      return ['text', 'image', 'collection']
                          .contains(data.data);
                    },
                    onAcceptWithDetails: (data) {
                      _handleElementDrop(data.data, data.offset);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final needsSpecialGestureHandling =
                          shouldHandleAnySpecialGesture(elements);

                      return GestureDetector(
                        // 🔧 关键修复：移动端智能手势行为 - 始终使用deferToChild让InteractiveViewer处理缩放平移
                        // 只在确实需要拦截时才在onTapDown中动态设置标志
                        behavior: _isMobile
                            ? HitTestBehavior
                                .deferToChild // 移动端：让InteractiveViewer优先处理，支持平移缩放
                            : (needsSpecialGestureHandling
                                ? HitTestBehavior.translucent // 桌面端：需要特殊处理时拦截手势
                                : HitTestBehavior
                                    .deferToChild), // 桌面端：不需要时完全让子组件处理

                        // 🔧 关键修复：在tapDown时检查是否点击在选中元素上，动态决定是否拦截pan手势
                        onTapDown: (details) {
                          // 移动端：如果是多指手势，不处理tapDown
                          if (_isMobile && _isMultiTouchGesture) return;

                          // 重置拦截标志
                          _shouldInterceptNextPanGesture = false;

                          // 检查是否点击在选中元素上
                          if (controller.state.selectedElementIds.isNotEmpty) {
                            for (final element in elements) {
                              final id = element['id'] as String;
                              if (controller.state.selectedElementIds
                                  .contains(id)) {
                                final x = (element['x'] as num).toDouble();
                                final y = (element['y'] as num).toDouble();
                                final width =
                                    (element['width'] as num).toDouble();
                                final height =
                                    (element['height'] as num).toDouble();

                                // 检查是否隐藏或在隐藏的图层中
                                if (element['hidden'] == true) continue;
                                final layerId = element['layerId'] as String?;
                                if (layerId != null) {
                                  final layer =
                                      controller.state.getLayerById(layerId);
                                  if (layer != null &&
                                      layer['isVisible'] == false) continue;
                                }

                                // 检查点击是否在元素内部
                                final bool isInside =
                                    details.localPosition.dx >= x &&
                                        details.localPosition.dx <= x + width &&
                                        details.localPosition.dy >= y &&
                                        details.localPosition.dy <= y + height;

                                if (isInside) {
                                  // 点击在选中元素上，需要拦截后续的pan手势用于拖拽
                                  _shouldInterceptNextPanGesture = true;
                                  break;
                                }
                              }
                            }
                          }

                          // 设置拖拽准备状态
                          if (_shouldInterceptNextPanGesture ||
                              controller.state.currentTool == 'select') {
                            _isReadyForDrag = true;
                          } else {
                            _isReadyForDrag = false;
                          }
                        },

                        onTapUp: (details) {
                          // 移动端：如果是多指手势，不处理tapUp
                          if (_isMobile && _isMultiTouchGesture) return;

                          // 重置拦截标志和拖拽准备状态
                          _shouldInterceptNextPanGesture = false;
                          _isReadyForDrag = false;

                          _gestureHandler.handleTapUp(
                              details, elements.cast<Map<String, dynamic>>());

                          // 调试选择状态变化后的情况（不触发重建）
                          _debugCanvasState('元素选择后');
                        },

                        // 处理右键点击事件，用于上下文菜单等功能
                        onSecondaryTapDown: needsSpecialGestureHandling
                            ? (details) =>
                                _gestureHandler.handleSecondaryTapDown(details)
                            : null,
                        onSecondaryTapUp: needsSpecialGestureHandling
                            ? (details) => _gestureHandler.handleSecondaryTapUp(
                                details, elements.cast<Map<String, dynamic>>())
                            : null,

                        // 🔧 关键修复：移动端和桌面端差异化处理pan手势
                        onPanStart: (_isMobile
                            ? (_shouldInterceptNextPanGesture ||
                                    controller.state.currentTool ==
                                        'select' // 移动端：仅在真正需要时处理
                                ? (details) {
                                    // 移动端：如果是多指手势，让InteractiveViewer处理
                                    if (_isMobile && _isMultiTouchGesture)
                                      return;

                                    // 🔧 修复：优先处理元素拖拽，无论当前工具是什么
                                    if (_shouldInterceptNextPanGesture) {
                                      // 点击在选中元素上，开始元素拖拽（任何工具模式下都可以）
                                      _gestureHandler.handlePanStart(
                                          details,
                                          elements
                                              .cast<Map<String, dynamic>>());

                                      // 如果开始了真正的拖拽，更新panEnabled状态
                                      if (mounted &&
                                          (_isDragging ||
                                              _dragStateManager.isDragging)) {
                                        setState(() {});
                                      }
                                    } else if (controller.state.currentTool ==
                                        'select') {
                                      // 仅在Select工具且不是拖拽元素时：开始选择框
                                      _gestureHandler.handlePanStart(
                                          details,
                                          elements
                                              .cast<Map<String, dynamic>>());
                                    }
                                  }
                                : null) // 移动端：点击空白区域时不设置处理器，让InteractiveViewer处理
                            : (needsSpecialGestureHandling // 桌面端：使用原有逻辑
                                ? (details) {
                                    // 🔧 修复：优先处理元素拖拽，无论当前工具是什么
                                    if (_shouldInterceptNextPanGesture) {
                                      // 点击在选中元素上，开始元素拖拽（任何工具模式下都可以）
                                      _gestureHandler.handlePanStart(
                                          details,
                                          elements
                                              .cast<Map<String, dynamic>>());

                                      // 如果开始了真正的拖拽，更新panEnabled状态
                                      if (mounted &&
                                          (_isDragging ||
                                              _dragStateManager.isDragging)) {
                                        setState(() {});
                                      }
                                    } else if (controller.state.currentTool ==
                                        'select') {
                                      // 仅在Select工具且不是拖拽元素时：开始选择框
                                      _gestureHandler.handlePanStart(
                                          details,
                                          elements
                                              .cast<Map<String, dynamic>>());
                                    }
                                  }
                                : null)),

                        onPanUpdate: (_isMobile
                            ? (_shouldInterceptNextPanGesture ||
                                    controller.state.currentTool == 'select' ||
                                    _isDragging ||
                                    _dragStateManager.isDragging ||
                                    _gestureHandler.isSelectionBoxActive
                                ? (details) {
                                    // 移动端：如果是多指手势，让InteractiveViewer处理
                                    if (_isMobile && _isMultiTouchGesture)
                                      return;

                                    // 只有在真正拖拽时才处理update事件
                                    if (_isDragging ||
                                        _dragStateManager.isDragging) {
                                      _gestureHandler.handlePanUpdate(details);
                                      return;
                                    }

                                    // 处理选择框更新
                                    if (widget.controller.state.currentTool ==
                                            'select' &&
                                        _gestureHandler.isSelectionBoxActive) {
                                      _gestureHandler.handlePanUpdate(details);
                                      _selectionBoxNotifier.value =
                                          SelectionBoxState(
                                        isActive: true,
                                        startPoint:
                                            _gestureHandler.selectionBoxStart,
                                        endPoint:
                                            _gestureHandler.selectionBoxEnd,
                                      );
                                      return;
                                    }
                                  }
                                : null) // 移动端：空白区域不处理update，让InteractiveViewer处理
                            : (needsSpecialGestureHandling // 桌面端：使用原有逻辑
                                ? (details) {
                                    // 只有在真正拖拽时才处理update事件
                                    if (_isDragging ||
                                        _dragStateManager.isDragging) {
                                      _gestureHandler.handlePanUpdate(details);
                                      return;
                                    }

                                    // 处理选择框更新
                                    if (widget.controller.state.currentTool ==
                                            'select' &&
                                        _gestureHandler.isSelectionBoxActive) {
                                      _gestureHandler.handlePanUpdate(details);
                                      _selectionBoxNotifier.value =
                                          SelectionBoxState(
                                        isActive: true,
                                        startPoint:
                                            _gestureHandler.selectionBoxStart,
                                        endPoint:
                                            _gestureHandler.selectionBoxEnd,
                                      );
                                      return;
                                    }
                                  }
                                : null)),

                        onPanEnd: (_isMobile
                            ? (_shouldInterceptNextPanGesture ||
                                    controller.state.currentTool == 'select' ||
                                    _isDragging ||
                                    _dragStateManager.isDragging ||
                                    _gestureHandler.isSelectionBoxActive
                                ? (details) {
                                    // 只有在真正处理拖拽或选择框时才需要结束处理
                                    if (_isDragging ||
                                        _dragStateManager.isDragging ||
                                        _gestureHandler.isSelectionBoxActive) {
                                      // 重置选择框状态
                                      if (widget.controller.state.currentTool ==
                                              'select' &&
                                          _gestureHandler
                                              .isSelectionBoxActive) {
                                        _selectionBoxNotifier.value =
                                            SelectionBoxState();
                                      }

                                      // 处理手势结束
                                      _gestureHandler.handlePanEnd(details);
                                    }

                                    // 总是重置所有状态
                                    _shouldInterceptNextPanGesture = false;
                                    _isReadyForDrag = false;
                                  }
                                : null) // 移动端：空白区域不处理end，让InteractiveViewer处理
                            : (needsSpecialGestureHandling // 桌面端：使用原有逻辑
                                ? (details) {
                                    // 只有在真正处理拖拽或选择框时才需要结束处理
                                    if (_isDragging ||
                                        _dragStateManager.isDragging ||
                                        _gestureHandler.isSelectionBoxActive) {
                                      // 重置选择框状态
                                      if (widget.controller.state.currentTool ==
                                              'select' &&
                                          _gestureHandler
                                              .isSelectionBoxActive) {
                                        _selectionBoxNotifier.value =
                                            SelectionBoxState();
                                      }

                                      // 处理手势结束
                                      _gestureHandler.handlePanEnd(details);
                                    }

                                    // 总是重置所有状态
                                    _shouldInterceptNextPanGesture = false;
                                    _isReadyForDrag = false;
                                  }
                                : null)),

                        onPanCancel: (_isMobile
                            ? (_shouldInterceptNextPanGesture ||
                                    controller.state.currentTool == 'select' ||
                                    _isDragging ||
                                    _dragStateManager.isDragging ||
                                    _gestureHandler.isSelectionBoxActive
                                ? () {
                                    // 重置选择框状态
                                    if (widget.controller.state.currentTool ==
                                            'select' &&
                                        _gestureHandler.isSelectionBoxActive) {
                                      _selectionBoxNotifier.value =
                                          SelectionBoxState();
                                    }

                                    // 处理手势取消
                                    if (_isDragging ||
                                        _dragStateManager.isDragging ||
                                        _gestureHandler.isSelectionBoxActive) {
                                      _gestureHandler.handlePanCancel();
                                    }

                                    // 重置所有状态
                                    _shouldInterceptNextPanGesture = false;
                                    _isReadyForDrag = false;
                                  }
                                : null) // 移动端：空白区域不处理cancel，让InteractiveViewer处理
                            : (needsSpecialGestureHandling // 桌面端：使用原有逻辑
                                ? () {
                                    // 重置选择框状态
                                    if (widget.controller.state.currentTool ==
                                            'select' &&
                                        _gestureHandler.isSelectionBoxActive) {
                                      _selectionBoxNotifier.value =
                                          SelectionBoxState();
                                    }

                                    // 处理手势取消
                                    if (_isDragging ||
                                        _dragStateManager.isDragging ||
                                        _gestureHandler.isSelectionBoxActive) {
                                      _gestureHandler.handlePanCancel();
                                    }

                                    // 重置所有状态
                                    _shouldInterceptNextPanGesture = false;
                                    _isReadyForDrag = false;
                                  }
                                : null)),
                        child: Container(
                          width: pageSize.width,
                          height: pageSize.height,
                          // 🔧 关键修复：添加透明背景确保手势检测正常工作
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Builder(
                            builder: (context) {
                              return Stack(
                                fit: StackFit
                                    .expand, // Use expand to fill the container
                                clipBehavior: Clip
                                    .none, // Allow control points to extend beyond page boundaries
                                children: [
                                  // Use LayerRenderManager to build coordinated layer stack
                                  RepaintBoundary(
                                    key:
                                        _repaintBoundaryKey, // Use dedicated key for RepaintBoundary
                                    child: Builder(
                                      builder: (context) {
                                        final layerStack =
                                            _layerRenderManager.buildLayerStack(
                                          layerOrder: [
                                            RenderLayerType.staticBackground,
                                            RenderLayerType.content,
                                            RenderLayerType.dragPreview,
                                            RenderLayerType.guideline,
                                            RenderLayerType.interaction,
                                          ],
                                        );

                                        return layerStack;
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )),

        // Status bar showing zoom level and tools (only visible in edit mode)
        if (!widget.isPreviewMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: colorScheme.surface
                  .withAlpha(217), // 217 is approximately 85% of 255
              child: Row(
                children: [
                  // Page information on the left side
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.library_books,
                          size: 14,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${AppLocalizations.of(context).pageInfo} ${widget.controller.state.currentPageIndex + 1} / ${widget.controller.state.pages.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Spacer to push right-side elements to the end
                  const Spacer(),
                  // Existing elements wrapped in a Wrap widget for overflow handling
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 4.0,
                    runSpacing: 4.0,
                    children: [
                      // Debug indicator showing current tool
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context).currentTool,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Selection mode indicator
                      if (widget.controller.state.currentTool == 'select')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.select_all,
                                size: 16,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context).selectionMode,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ), // Reset position button
                      Tooltip(
                        message:
                            AppLocalizations.of(context).canvasResetViewTooltip,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _resetCanvasPosition,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 120),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.center_focus_strong,
                                      size: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .canvasResetViewTooltip,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Zoom indicator
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.zoom_in,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${(widget.transformationController.value.getMaxScaleOnAxis() * 100).toInt()}%',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 🔧 调试方法：检查当前状态，帮助诊断画布平移问题
  void _debugCanvasState(String context) {
    // 🚀 优化：只在调试模式下记录详细状态
    PracticeEditLogger.debugDetail(
      '画布状态: $context',
      data: {
        'panEnabled':
            !(_isDragging || _dragStateManager.isDragging || _isReadyForDrag),
        'selectedCount': widget.controller.state.selectedElementIds.length,
        'currentTool': widget.controller.state.currentTool,
      },
    );
  }

  /// 确保Canvas UI组件注册成功
  void _ensureCanvasRegistration() {
    final intelligentDispatcher = widget.controller.intelligentDispatcher;
    if (intelligentDispatcher != null) {
      final isRegistered =
          intelligentDispatcher.hasUIComponentListener('canvas');

      if (!isRegistered) {
        EditPageLogger.performanceWarning(
          '🔧 Canvas UI组件未注册，执行重新注册',
          data: {
            'reason': 'post_frame_registration_check',
            'timing': 'after_widget_build',
          },
        ); // 重新尝试注册（如果还没有创建监听器则创建）
        _canvasUIListener ??= () {
          if (mounted && !_isDisposed) {
            try {
              setState(() {});
              EditPageLogger.canvasDebug('Canvas UI监听器触发重建');
            } catch (e, stackTrace) {
              EditPageLogger.canvasError('Canvas UI监听器setState失败',
                  error: e,
                  stackTrace: stackTrace,
                  data: {'component': 'canvas_ui_listener'});
            }
          }
        };
        intelligentDispatcher.registerUIListener('canvas', _canvasUIListener!);

        // 验证注册成功
        final finalCheck =
            intelligentDispatcher.hasUIComponentListener('canvas');
        EditPageLogger.canvasDebug(
          'PostFrame Canvas注册检查',
          data: {
            'isRegistered': finalCheck,
            'registrationStrategy': 'post_frame_callback',
          },
        );
      } else {
        EditPageLogger.canvasDebug(
          '✅ Canvas UI组件已正确注册',
          data: {
            'checkTiming': 'post_frame_callback',
            'status': 'registration_confirmed',
          },
        );
      }
    }
  }

  /// 回退到基础模式（禁用优化功能）
  void _fallbackToBasicMode() {
    try {
      // 只初始化最基础的组件
      _contentRenderController = ContentRenderController();
      _dragStateManager = DragStateManager();
      _layerRenderManager = LayerRenderManager();
      _performanceMonitor = PerformanceMonitor(); // 🔧 也需要初始化性能监控器

      // 🔧 确保RepaintBoundary key被初始化
      _repaintBoundaryKey = GlobalKey();

      // 注册必要的基础层级
      // 1. 背景层 - 必需的，用于页面背景和网格
      _layerRenderManager.registerLayer(
        type: RenderLayerType.staticBackground,
        config: const LayerConfig(
          type: RenderLayerType.staticBackground,
          priority: LayerPriority.low,
          enableCaching: false, // 禁用缓存避免潜在问题
          useRepaintBoundary: true,
        ),
        builder: (config) =>
            _buildLayerWidget(RenderLayerType.staticBackground, config),
      );

      // 2. 内容层
      _layerRenderManager.registerLayer(
        type: RenderLayerType.content,
        config: const LayerConfig(
          type: RenderLayerType.content,
          priority: LayerPriority.high,
          enableCaching: false, // 禁用缓存避免潜在问题
          useRepaintBoundary: true,
        ),
        builder: (config) => _buildLayerWidget(RenderLayerType.content, config),
      );

      // 3. 交互层 - 用于控制点
      _layerRenderManager.registerLayer(
        type: RenderLayerType.interaction,
        config: const LayerConfig(
          type: RenderLayerType.interaction,
          priority: LayerPriority.critical,
          enableCaching: false,
          useRepaintBoundary: true,
        ),
        builder: (config) =>
            _buildLayerWidget(RenderLayerType.interaction, config),
      );

      EditPageLogger.canvasDebug('画布已切换到基础模式');
    } catch (e) {
      EditPageLogger.canvasError('画布基础模式初始化失败', error: e);
    }
  }

  /// Fit the page content to screen with proper scale and centering
  void _fitPageToScreen() {
    // Ensure we have a current page
    final currentPage = widget.controller.state.currentPage;
    if (currentPage == null) return;

    // Get the viewport size
    if (!mounted) return;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Size viewportSize = renderBox.size;

    // Get the page size (canvas content bounds)
    final Size pageSize = ElementUtils.calculatePixelSize(currentPage);

    // Add some padding around the page (5% on each side for better content visibility)
    const double paddingFactor =
        0.95; // Use 95% of viewport for content, 5% for padding - maximizes content display
    final double availableWidth = viewportSize.width * paddingFactor;
    final double availableHeight = viewportSize.height * paddingFactor;

    // Calculate scale to fit page within available viewport area
    final double scaleX = availableWidth / pageSize.width;
    final double scaleY = availableHeight / pageSize.height;
    final double scale =
        scaleX < scaleY ? scaleX : scaleY; // Use smaller scale to fit entirely

    // Calculate translation to center the scaled page in the viewport
    final double scaledPageWidth = pageSize.width * scale;
    final double scaledPageHeight = pageSize.height * scale;
    final double dx = (viewportSize.width - scaledPageWidth) / 2;
    final double dy = (viewportSize.height - scaledPageHeight) / 2;

    // 确保从干净的状态开始，重置任何现有的变换
    // Reset to identity first to avoid accumulating transformations
    widget.transformationController.value = Matrix4.identity();

    // Create the transformation matrix
    final Matrix4 matrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale, scale);

    // Apply the transformation
    widget.transformationController.value = matrix;

    // Notify the controller that zoom has changed
    widget.controller.zoomTo(scale);

    // 檢查變換应用结果
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        final appliedMatrix = widget.transformationController.value;
        final appliedScale = appliedMatrix.getMaxScaleOnAxis();
        final appliedTranslation = appliedMatrix.getTranslation();

        if ((appliedScale - scale).abs() > 0.001 ||
            (appliedTranslation.x - dx).abs() > 1 ||
            (appliedTranslation.y - dy).abs() > 1) {
          PracticeEditLogger.logError('画布视图重置失败', '变换矩阵应用不正确', context: {
            'expectedScale': scale.toStringAsFixed(3),
            'actualScale': appliedScale.toStringAsFixed(3),
          });
        }
      }
    });
  }

  /// 处理拖拽结束 - 使用 mixin 方法
  Future<void> _handleDragEnd() async {
    // 🚀 优化：避免Canvas整体重建，只更新必要的状态
    _isDragging = false;

    EditPageLogger.canvasDebug(
      '拖拽结束 - 避免Canvas整体重建',
      data: {
        'optimization': 'avoid_canvas_setstate',
        'reason': '内容层应该只在dragEnd时重建一次',
      },
    );

    // 拖拽结束时应用网格吸附
    _applyGridSnapToSelectedElements();
  }

  /// 处理拖拽开始 - 使用 mixin 方法
  Future<void> _handleDragStart(
    bool isDragging,
    Offset dragStart,
    Offset elementPosition,
    Map<String, Offset> elementPositions,
  ) async {
    // 🚀 优化：避免Canvas整体重建，只更新必要的状态
    _isDragging = isDragging;

    EditPageLogger.canvasDebug(
      '拖拽开始 - 避免Canvas整体重建',
      data: {
        'optimization': 'avoid_canvas_setstate',
        'reason': '只有预览层和交互层需要响应拖拽开始',
      },
    );
  }

  /// 处理拖拽更新 - 使用 mixin 方法
  void _handleDragUpdate() {
    // 如果是选择框更新，使用ValueNotifier而不是setState
    if (_gestureHandler.isSelectionBoxActive) {
      _selectionBoxNotifier.value = SelectionBoxState(
        isActive: _gestureHandler.isSelectionBoxActive,
        startPoint: _gestureHandler.selectionBoxStart,
        endPoint: _gestureHandler.selectionBoxEnd,
      );
    }
  }

  /// 处理从工具栏拖拽创建元素
  void _handleElementDrop(String elementType, [Offset? dropOffset]) {
    // 获取当前页面和尺寸
    final currentPage = widget.controller.state.currentPage;
    if (currentPage == null) {
      EditPageLogger.canvasError('无法获取当前页面，终止元素拖放处理');
      return;
    }

    final pageSize = ElementUtils.calculatePixelSize(currentPage);

    Offset dropPosition;

    if (dropOffset != null) {
      // 获取画布视口信息
      final RenderBox? dragTargetBox = context.findRenderObject() as RenderBox?;
      if (dragTargetBox == null) {
        EditPageLogger.canvasError('无法获取画布视口信息，使用默认位置');
        dropPosition = Offset(pageSize.width / 2, pageSize.height / 2);
      } else {
        final viewportGlobalPosition = dragTargetBox.localToGlobal(Offset.zero);

        // 计算鼠标相对于画布视口的坐标
        final relativeX = dropOffset.dx - viewportGlobalPosition.dx;
        final relativeY = dropOffset.dy - viewportGlobalPosition.dy;
        final viewportRelativePosition = Offset(relativeX, relativeY);

        // 将视口坐标转换为页面逻辑坐标
        dropPosition = screenToCanvas(viewportRelativePosition);
      } // 处理边界约束
      final elementDefaultSizes = {
        'text': const Size(400, 200),
        'image': const Size(400, 200),
        'collection': const Size(400, 200),
      };

      final elementSize =
          elementDefaultSizes[elementType] ?? const Size(400, 200);
      final halfWidth = elementSize.width / 2;
      final halfHeight = elementSize.height / 2;

      // 将鼠标点击位置转换为元素左上角位置（元素中心对齐）
      final elementLeftTop =
          Offset(dropPosition.dx - halfWidth, dropPosition.dy - halfHeight);

      // 约束元素左上角到页面边界内
      final constrainedX =
          elementLeftTop.dx.clamp(0.0, pageSize.width - elementSize.width);
      final constrainedY =
          elementLeftTop.dy.clamp(0.0, pageSize.height - elementSize.height);

      dropPosition = Offset(constrainedX, constrainedY);
    } else {
      // 回退方案：使用页面中心附近创建元素，添加随机偏移避免重叠
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      dropPosition = Offset(
        pageSize.width / 2 + random - 50,
        pageSize.height / 2 + random - 50,
      );
    }

    // 使用mixin中的方法处理元素拖拽创建
    handleElementDrop(elementType, dropPosition, applyCenteringOffset: false);
  }

  /// 处理智能状态分发器的内容更新
  void _handleIntelligentDispatcherContentUpdate() {
    if (!mounted) return;

    EditPageLogger.canvasDebug('处理智能状态分发器内容更新', data: {
      'operation': 'intelligent_dispatcher_content_update',
    });

    // 发送元素更新和顺序变化事件，确保所有变化都被正确处理
    _stateDispatcher.dispatch(StateChangeEvent(
      type: StateChangeType.elementUpdate,
      data: {
        'reason': 'intelligent_dispatcher_content_update',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    ));

    // 同时发送元素顺序变化事件，确保顺序变化被正确处理
    _stateDispatcher.dispatch(StateChangeEvent(
      type: StateChangeType.elementOrderChange,
      data: {
        'reason': 'intelligent_dispatcher_order_change',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'elementId': '',
        'oldIndex': 0,
        'newIndex': 0,
      },
    ));
  }

  /// 初始化核心组件
  void _initializeCoreComponents() {
    // 内容渲染控制器 - 用于管理元素渲染和优化
    _contentRenderController = ContentRenderController();

    // 拖拽状态管理器 - 三阶段拖拽系统的核心组件
    // 负责：1. Preview阶段的快照创建 2. Live阶段的状态更新 3. Commit阶段的属性提交
    _dragStateManager = DragStateManager();

    // 图层渲染管理器 - 用于分层渲染策略
    _layerRenderManager = LayerRenderManager();

    // 🔧 性能监控器 - 用于追踪性能指标
    _performanceMonitor = PerformanceMonitor();

    // RepaintBoundary的Key - 用于截图和快照功能
    _repaintBoundaryKey = GlobalKey();

    // 🚀 优化：简化初始化日志
    PracticeEditLogger.debugDetail('核心组件初始化完成');
  }

  /// 初始化手势处理器
  void _initializeGestureHandler() {
    _gestureHandler = SmartCanvasGestureHandler(
      controller: widget.controller,
      dragStateManager: _dragStateManager,
      onDragStart: _handleDragStart,
      onDragUpdate: _handleDragUpdate,
      onDragEnd: _handleDragEnd,
      getScaleFactor: () {
        final Matrix4 matrix = widget.transformationController.value;
        return matrix.getMaxScaleOnAxis();
      },
    );
  }

  /// Initialize and register layers with the LayerRenderManager
  void _initializeLayers() {
    // Register static background layer
    _layerRenderManager.registerLayer(
      type: RenderLayerType.staticBackground,
      config: const LayerConfig(
        type: RenderLayerType.staticBackground,
        priority: LayerPriority.low,
        enableCaching: true,
        useRepaintBoundary: true,
      ),
      builder: (config) =>
          _buildLayerWidget(RenderLayerType.staticBackground, config),
    );

    // Register content layer
    _layerRenderManager.registerLayer(
      type: RenderLayerType.content,
      config: const LayerConfig(
        type: RenderLayerType.content,
        priority: LayerPriority.high,
        enableCaching: true,
        useRepaintBoundary: true,
      ),
      builder: (config) => _buildLayerWidget(RenderLayerType.content, config),
    );

    // Register drag preview layer
    _layerRenderManager.registerLayer(
      type: RenderLayerType.dragPreview,
      config: const LayerConfig(
        type: RenderLayerType.dragPreview,
        priority: LayerPriority.critical,
        enableCaching: false, // Dynamic content, caching less useful
        useRepaintBoundary: true,
      ),
      builder: (config) =>
          _buildLayerWidget(RenderLayerType.dragPreview, config),
    );
    // Register guideline layer (参考线层)
    _layerRenderManager.registerLayer(
      type: RenderLayerType.guideline,
      config: const LayerConfig(
        type: RenderLayerType.guideline,
        priority: LayerPriority.medium,
        enableCaching: false, // High update frequency during drag operations
        useRepaintBoundary: true,
      ),
      builder: (config) => _buildLayerWidget(RenderLayerType.guideline, config),
    );

    // Register interaction layer (selection, control points)
    _layerRenderManager.registerLayer(
      type: RenderLayerType.interaction,
      config: const LayerConfig(
        type: RenderLayerType.interaction,
        priority: LayerPriority.critical,
        enableCaching: false, // Highly dynamic
        useRepaintBoundary: true,
      ),
      builder: (config) =>
          _buildLayerWidget(RenderLayerType.interaction, config),
    );

    // Register UI overlay layer
    _layerRenderManager.registerLayer(
      type: RenderLayerType.uiOverlay,
      config: const LayerConfig(
        type: RenderLayerType.uiOverlay,
        priority: LayerPriority.medium,
        enableCaching: true,
        useRepaintBoundary: true,
      ),
      builder: (config) => _buildLayerWidget(RenderLayerType.uiOverlay, config),
    );
  }

  /// 初始化优化策略组件
  void _initializeOptimizationComponents() {
    // Initialize canvas structure listener for smart layer-specific routing
    _structureListener = CanvasStructureListener(widget.controller);

    // Initialize state change dispatcher for unified state management
    _stateDispatcher =
        StateChangeDispatcher(widget.controller, _structureListener);

    // Set the state dispatcher in the controller for layered state management
    widget.controller.setStateDispatcher(_stateDispatcher);

    // Initialize drag operation manager for 3-phase drag system
    _dragOperationManager = DragOperationManager(
      widget.controller,
      _dragStateManager,
      _stateDispatcher,
    );

    // Register layers with the layer render manager
    _initializeLayers(); // ✅ 新添加：注册Canvas到智能状态分发器
    _registerCanvasToIntelligentDispatcher();

    // 🚀 CRITICAL FIX: 添加PostFrameCallback确保注册在widget完全构建后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _ensureCanvasRegistration();
      }
    });
  }

  /// 初始化UI组件
  void _initializeUIComponents() {
    // 🔧 修复：完全避免Platform API调用，防止MethodChannel错误
    if (!_platformDetected) {
      _isMobile = _detectMobilePlatformByUI();
      _platformDetected = true; // 标记已检测

      EditPageLogger.editPageDebug(
        '检测到平台类型',
        data: {
          'isMobile': _isMobile,
          'detectionMethod': 'ui_based_detection_only',
          'screenWidth': MediaQuery.of(context).size.width,
          'screenHeight': MediaQuery.of(context).size.height,
          'devicePixelRatio': MediaQuery.of(context).devicePixelRatio,
        },
      );
    }

    // No need to initialize _repaintBoundaryKey again as it's already initialized in _initializeCoreComponents()

    // 初始化手勢處理器 (需要在所有其他組件初始化后)
    _initializeGestureHandler();

    // 🔧 修复：注册画布到控制器，支持reset view功能
    // Register this canvas with the controller for reset view functionality
    widget.controller.setEditCanvas(this);

    // Set the RepaintBoundary key in the controller for screenshot functionality
    widget.controller.setCanvasKey(_repaintBoundaryKey);

    // 🔍 恢复初始化时的reset，用于对比两次调用
    // Schedule initial reset view position on first load (只执行一次)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        resetCanvasPosition(); // 使用标准的Reset View Position逻辑
      }
    });
  }

  /// 基于UI特征的移动平台检测（完全避免Platform API）
  bool _detectMobilePlatformByUI() {
    try {
      final mediaQuery = MediaQuery.of(context);
      final screenSize = mediaQuery.size;
      final devicePixelRatio = mediaQuery.devicePixelRatio;
      final viewPadding = mediaQuery.viewPadding;

      // 移动设备的典型特征：
      // 1. 较小的屏幕宽度（通常 < 800px）
      // 2. 较高的像素密度（通常 > 1.5）
      // 3. 有状态栏/导航栏（viewPadding.top > 0）
      // 4. 屏幕宽高比通常更接近 16:9 或更窄

      final aspectRatio = screenSize.width / screenSize.height;
      final hasStatusBar = viewPadding.top > 0;
      final hasHighDensity = devicePixelRatio > 1.5;
      final hasSmallWidth = screenSize.width < 800;
      final hasMobileAspectRatio = aspectRatio < 1.5; // 移动设备通常是竖屏或接近方形

      // 组合判断：满足多个条件的设备很可能是移动设备
      int mobileScore = 0;
      if (hasSmallWidth) mobileScore += 3; // 小屏幕权重最高
      if (hasHighDensity) mobileScore += 2; // 高像素密度
      if (hasStatusBar) mobileScore += 2; // 有状态栏
      if (hasMobileAspectRatio) mobileScore += 1; // 移动设备宽高比

      final isMobile = mobileScore >= 4; // 分数阈值

      EditPageLogger.editPageDebug('UI特征移动设备检测', data: {
        'screenSize': '${screenSize.width}x${screenSize.height}',
        'devicePixelRatio': devicePixelRatio,
        'aspectRatio': aspectRatio.toStringAsFixed(2),
        'hasStatusBar': hasStatusBar,
        'hasHighDensity': hasHighDensity,
        'hasSmallWidth': hasSmallWidth,
        'hasMobileAspectRatio': hasMobileAspectRatio,
        'mobileScore': mobileScore,
        'isMobile': isMobile,
      });

      return isMobile;
    } catch (e) {
      // 最终回退：简单的屏幕宽度检测
      EditPageLogger.editPageDebug('UI检测失败，使用简单回退方案', data: {
        'error': e.toString(),
      });
      return MediaQuery.of(context).size.width < 600;
    }
  }

  /// 处理DragStateManager状态变化
  void _onDragStateManagerChanged() {} // ✅ 新方法：注册Canvas到智能状态分发器

  void _registerCanvasToIntelligentDispatcher() {
    final intelligentDispatcher = widget.controller.intelligentDispatcher;
    if (intelligentDispatcher != null) {
      try {
        // 🚀 关键修复：注册内容层监听器以处理元素顺序变化
        // 这是必需的，因为ContentRenderLayer的didUpdateWidget不能捕获所有变化
        intelligentDispatcher.registerLayerListener('content', () {
          // 检查是否是元素顺序变化，如果是则通过StateChangeDispatcher处理
          _handleIntelligentDispatcherContentUpdate();
        }); // 🚀 CRITICAL FIX: 注册Canvas作为UI组件监听器，以接收参考线更新通知
        // 这解决了参考线UI显示问题: "UI组件没有注册监听器" (component: canvas)
        _canvasUIListener ??= () {
          if (mounted && !_isDisposed) {
            // 重建Canvas以显示参考线更新
            try {
              setState(() {
                // Canvas重建，确保参考线能够显示
              });

              EditPageLogger.canvasDebug(
                'Canvas UI监听器触发重建',
                data: {
                  'reason': 'guideline_or_ui_update',
                  'optimization': 'intelligent_canvas_rebuild',
                },
              );
            } catch (e, stackTrace) {
              EditPageLogger.canvasError('Canvas UI监听器setState失败',
                  error: e,
                  stackTrace: stackTrace,
                  data: {
                    'component': 'canvas_ui_listener',
                    'context': 'guideline_update'
                  });
            }
          }
        };
        intelligentDispatcher.registerUIListener('canvas', _canvasUIListener!);

        // 🔧 修复：注册撤销/重做操作的特殊处理监听器
        intelligentDispatcher.registerOperationListener('undo_force_refresh',
            () {
          if (mounted && !_isDisposed) {
            try {
              setState(() {
                // 撤销操作后强制刷新画布以立即显示透明度等变化
              });

              EditPageLogger.canvasDebug(
                '撤销操作触发Canvas强制刷新',
                data: {
                  'reason': 'undo_operation_force_refresh',
                  'fix': '修复图层透明度撤销后不立即显示的问题',
                },
              );
            } catch (e, stackTrace) {
              EditPageLogger.canvasError('撤销操作Canvas刷新失败',
                  error: e,
                  stackTrace: stackTrace,
                  data: {'operation': 'undo_force_refresh'});
            }
          }
        });

        intelligentDispatcher.registerOperationListener('redo_force_refresh',
            () {
          if (mounted && !_isDisposed) {
            try {
              setState(() {
                // 重做操作后强制刷新画布以立即显示透明度等变化
              });

              EditPageLogger.canvasDebug(
                '重做操作触发Canvas强制刷新',
                data: {
                  'reason': 'redo_operation_force_refresh',
                  'fix': '修复图层透明度重做后不立即显示的问题',
                },
              );
            } catch (e, stackTrace) {
              EditPageLogger.canvasError('重做操作Canvas刷新失败',
                  error: e,
                  stackTrace: stackTrace,
                  data: {'operation': 'redo_force_refresh'});
            }
          }
        });
        intelligentDispatcher.registerUIListener('canvas', _canvasUIListener!);

        // 🔍 验证注册是否成功 - 添加重试机制
        bool isRegistered = false;
        for (int attempt = 0; attempt < 3; attempt++) {
          isRegistered = intelligentDispatcher.hasUIComponentListener('canvas');
          if (isRegistered) break; // 如果注册失败，稍等一下再试
          if (attempt < 2) {
            Future.delayed(const Duration(milliseconds: 10), () {
              if (!_isDisposed) {
                _canvasUIListener ??= () {
                  if (mounted && !_isDisposed) {
                    try {
                      setState(() {});
                      EditPageLogger.canvasDebug('Canvas UI监听器触发重建(重试)');
                    } catch (e, stackTrace) {
                      EditPageLogger.canvasError('Canvas UI监听器setState失败(重试)',
                          error: e,
                          stackTrace: stackTrace,
                          data: {
                            'component': 'canvas_ui_listener',
                            'context': 'retry'
                          });
                    }
                  }
                };
                intelligentDispatcher.registerUIListener(
                    'canvas', _canvasUIListener!);
              }
            });
          }
        }

        EditPageLogger.canvasDebug(
          'Canvas UI组件注册验证',
          data: {
            'isRegistered': isRegistered,
            'registrationTime': DateTime.now().toIso8601String(),
            'retryCount': isRegistered ? 0 : 3,
          },
        );

        if (isRegistered) {
          EditPageLogger.canvasDebug(
            '✅ Canvas组件已成功注册到智能状态分发器',
            data: {
              'layerListeners': 1,
              'uiListeners': 1,
              'purpose': '监听内容层变化和UI组件更新（包括参考线）',
            },
          );
        } else {
          EditPageLogger.performanceWarning(
            '❌ Canvas UI组件注册失败，参考线可能无法显示',
            data: {
              'issue': 'ui_component_registration_failed',
              'fallback': 'traditional_notifications',
            },
          );
        }
      } catch (e) {
        EditPageLogger.performanceWarning(
          '注册Canvas到智能状态分发器时发生异常',
          data: {
            'error': e.toString(),
            'fallback': 'traditional_notifications',
          },
        );
      }
    } else {
      EditPageLogger.canvasDebug(
        '智能状态分发器不存在，无法注册Canvas监听器',
        data: {
          'fallback': 'traditional_notify_listeners',
        },
      );
    }
  }

  /// Reset canvas position to fit the page content within the viewport
  void _resetCanvasPosition() {
    _fitPageToScreen();
  }

  /// 建立组件间连接
  void _setupComponentConnections() {
    // 将拖拽状态管理器与性能监控系统关联
    _performanceMonitor.setDragStateManager(_dragStateManager);
    EditPageLogger.canvasDebug('拖拽状态管理器与性能监控器连接完成');

    // 将拖拽状态管理器与内容渲染控制器关联
    _contentRenderController.setDragStateManager(_dragStateManager);
    EditPageLogger.canvasDebug('拖拽状态管理器与内容渲染控制器连接完成');

    // 🔧 修复：让Canvas监听DragStateManager变化，确保控制点能跟随元素移动
    _dragStateManager.addListener(_onDragStateManagerChanged);
    EditPageLogger.canvasDebug('拖拽状态管理器状态变化监听已配置');

    // 设置结构监听器的层级处理器
    _setupStructureListenerHandlers();
    EditPageLogger.canvasDebug('结构监听器处理器配置完成');

    // Set up drag state manager callbacks
    _dragStateManager.setUpdateCallbacks(
      onBatchUpdate: (batchUpdates) {
        widget.controller.batchUpdateElementProperties(
          batchUpdates,
          options: BatchUpdateOptions.forDragOperation(),
        );
      },
    );
  }

  /// 设置结构监听器的层级处理器
  void _setupStructureListenerHandlers() {
    // 配置StaticBackground层级处理器
    _structureListener.registerLayerHandler(RenderLayerType.staticBackground,
        (event) {
      if (event is PageBackgroundChangeEvent) {
        // 通知LayerRenderManager重新渲染StaticBackground层
        _layerRenderManager.markLayerDirty(RenderLayerType.staticBackground,
            reason: 'Page background changed');
      } else if (event is GridSettingsChangeEvent) {
        // 🚀 优化：只标记背景层为脏，不触发整个Canvas重建
        _layerRenderManager.markLayerDirty(
          RenderLayerType.staticBackground,
          reason: 'Grid settings changed',
        );

        EditPageLogger.canvasDebug(
          '网格设置变化处理（优化版）',
          data: {
            'optimization': 'background_layer_only_rebuild',
            'avoidedCanvasRebuild': true,
          },
        );

        // 🚀 移除setState调用 - 网格设置变化不应该触发整个Canvas重建
        // 网格渲染会通过markLayerDirty机制自动重建背景层
        // if (mounted) {
        //   setState(() {});
        // }
      }
    });

    // 配置Content层级处理器
    _structureListener.registerLayerHandler(RenderLayerType.content, (event) {
      if (event is ElementsChangeEvent) {
        // 更新ContentRenderController
        _contentRenderController.initializeElements(event.elements);
        // 通知LayerRenderManager重新渲染Content层
        _layerRenderManager.markLayerDirty(RenderLayerType.content,
            reason: 'Elements changed');
      } else if (event is LayerVisibilityChangeEvent) {
        EditPageLogger.canvasDebug('🔧 图层可见性变化，强制重建内容层', data: {
          'layerId': event.layerId,
          'visible': event.visible,
          'reason': 'layer_visibility_changed',
          'action': 'force_content_layer_rebuild',
        });

        // 通知LayerRenderManager重新渲染Content层
        _layerRenderManager.markLayerDirty(RenderLayerType.content,
            reason: 'Layer visibility changed: ${event.layerId}');

        // 🔧 关键修复：强制触发Canvas重建以立即显示图层变化效果
        if (mounted) {
          setState(() {
            // 这个setState会触发整个Canvas重建，确保图层变化立即生效
          });
        }
      } else if (event is ElementOrderChangeEvent) {
        EditPageLogger.canvasDebug('收到元素顺序变化事件', data: {
          'elementId': event.elementId,
          'oldIndex': event.oldIndex,
          'newIndex': event.newIndex,
        });

        // 延迟重建，确保操作完成后再处理
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _isDisposed) return;

          // 通知LayerRenderManager重新渲染Content层
          _layerRenderManager.markLayerDirty(RenderLayerType.content,
              reason: 'Element order changed: ${event.elementId}');

          // 强制触发Canvas重建以立即显示元素顺序变化效果
          setState(() {
            // 触发Canvas重建，确保元素顺序变化立即生效
          });
        });
      }
    });

    // 配置DragPreview层级处理器
    _structureListener.registerLayerHandler(RenderLayerType.dragPreview,
        (event) {
      if (event is DragStateChangeEvent) {
        // DragPreviewLayer会自动监听DragStateManager的变化
        _layerRenderManager.markLayerDirty(RenderLayerType.dragPreview,
            reason: 'Drag state changed');
      }
    });

    // 🚀 优化：配置Interaction层级处理器 - 避免触发整个Canvas重建
    _structureListener.registerLayerHandler(RenderLayerType.interaction,
        (event) {
      if (event is SelectionChangeEvent || event is ToolChangeEvent) {
        // 🚀 优化：只标记交互层为脏，不触发整个Canvas重建
        _layerRenderManager.markLayerDirty(RenderLayerType.interaction,
            reason: 'Selection or tool changed');

        // 🚀 优化：减少交互层状态变化的重复日志
        // 只在第一次变化、事件类型变化或时间间隔后记录
        _interactionStateChangeCount++;
        final eventType = event.runtimeType.toString();
        final isNewEventType = eventType != _lastEventType;
        final isMilestone = _interactionStateChangeCount % 100 == 0;
        final now = DateTime.now();
        final isTimeForLog =
            now.difference(_lastInteractionLogTime).inMilliseconds >= 500;

        if (isNewEventType || isMilestone || isTimeForLog) {
          EditPageLogger.canvasDebug(
            '交互层状态变化',
            data: {
              'eventType': eventType,
              'changeCount': _interactionStateChangeCount,
              'changeType': isNewEventType
                  ? 'new_event_type'
                  : isMilestone
                      ? 'milestone'
                      : 'time_interval',
              'intervalMs':
                  now.difference(_lastInteractionLogTime).inMilliseconds,
              'optimization': 'interaction_layer_optimized_v2',
            },
          );

          if (isNewEventType) {
            _lastEventType = eventType;
          }
          _lastInteractionLogTime = now;
        }

        // 🚀 移除setState调用 - 交互层变化不应该触发整个Canvas重建
        // 交互层会通过markLayerDirty机制自动重建
      }
    });
  }

  // ✅ 新方法：注销智能状态分发器监听器
  void _unregisterFromIntelligentDispatcher() {
    try {
      final intelligentDispatcher = widget.controller.intelligentDispatcher;
      if (intelligentDispatcher != null) {
        // 🚀 修复：注销Canvas UI监听器以修复参考线功能
        EditPageLogger.editPageDebug(
          'Canvas组件注销智能状态分发器监听器',
          data: {
            'operation': 'unregister_from_dispatcher',
            'component': 'canvas',
          },
        );

        // 注销UI监听器（参考线更新等）
        if (_canvasUIListener != null) {
          intelligentDispatcher.removeUIListener('canvas', _canvasUIListener!);
          _canvasUIListener = null;
        }

        // 注销层级监听器（内容变化等）
        // Note: 目前的 IntelligentStateDispatcher 实现可能不支持具体的监听器移除
        // 但至少尝试调用以保持代码的完整性
        // intelligentDispatcher.removeLayerListener('content', () {});  // 需要提供回调函数
      }
    } catch (e) {
      EditPageLogger.editPageError(
        '注销智能状态分发器监听器失败',
        error: e,
        data: {
          'operation': 'unregister_from_dispatcher',
          'component': 'canvas',
        },
      );
    }
  }

  // 手势检查方法已移至 CanvasGestureHandlers mixin
}

class _OptimizedCanvasListenerState extends State<OptimizedCanvasListener> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    try {
      widget.controller.removeListener(_onControllerChanged);
    } catch (e) {
      EditPageLogger.editPageError(
        '移除控制器监听器失败',
        error: e,
        data: {
          'component': 'OptimizedCanvasListener',
          'operation': 'remove_listener',
        },
      );
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      try {
        setState(() {});
      } catch (e) {
        EditPageLogger.editPageError(
          'OptimizedCanvasListener setState失败',
          error: e,
          data: {
            'component': 'OptimizedCanvasListener',
            'operation': 'set_state',
          },
        );
      }
    }
  }
}
