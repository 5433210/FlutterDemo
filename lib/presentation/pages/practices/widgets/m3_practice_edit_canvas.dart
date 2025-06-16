import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
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
  // 🔍[TRACKING] 静态重建计数器
  static int _buildCount = 0;

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
  bool _hasInitializedView = false; // 防止重复初始化视图

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
    // 🔍[TRACKING] Canvas重建跟踪 - 记录重建触发原因
    final buildStartTime = DateTime.now();
    _buildCount++;

    // 🔧 CRITICAL FIX: 缓存controller状态，避免在build中访问controller.state触发依赖
    final selectedElementIds = widget.controller.state.selectedElementIds;

    EditPageLogger.canvasDebug(
      '🚨 Canvas开始重建 - 主Widget.build()被调用',
      data: {
        'buildNumber': _buildCount,
        'selectedCount': selectedElementIds.length,
        'isReadyForDrag': _isReadyForDrag,
        'isDragging': _isDragging,
        'timestamp': buildStartTime.toIso8601String(),
        'optimization': 'canvas_rebuild_tracking',
        'cachedState': 'avoiding_controller_access_in_build',
        'stackTrace':
            StackTrace.current.toString().split('\n').take(5).join('\n'),
      },
    );

    // Track performance for main canvas rebuilds
    _performanceMonitor.trackWidgetRebuild('M3PracticeEditCanvas');

    // 🚀 移除PostFrameCallback机制 - 在图层级架构下已无意义
    // 现在使用智能状态分发器和图层级性能监控，不再需要Canvas级别的PostFrameCallback
    EditPageLogger.canvasDebug(
      '🎯 Canvas构建完成 - 图层级架构',
      data: {
        'buildNumber': _buildCount,
        'buildDuration':
            '${DateTime.now().difference(buildStartTime).inMilliseconds}ms',
        'architecture': 'layer_based_rendering',
        'optimization': 'no_postframe_callback_needed',
      },
    );

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

      // 阶段4: 初始化UI和手势处理
      _initializeUIComponents();

      EditPageLogger.editPageInfo(
        '画布分层和元素级混合优化策略组件初始化完成',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          'operation': 'canvas_init_complete',
          'components': ['core', 'optimization', 'connections', 'ui'],
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

    EditPageLogger.canvasDebug(
      '旋转元素',
      data: {
        'elementId': elementId,
        'delta': '$delta',
        'rotationDelta': rotationDelta,
        'newRotation': newRotation,
        'operation': 'element_rotation',
        'timestamp': DateTime.now().toIso8601String(),
      },
    ); // Update rotation
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
    EditPageLogger.canvasDebug(
      '检查是否需要处理特殊手势',
      data: {
        'isPreview': controller.state.isPreviewMode,
        'currentTool': controller.state.currentTool,
        'selectedElementsCount': controller.state.selectedElementIds.length,
        'isDragging': isDragging,
        'dragManagerDragging': dragStateManager.isDragging,
        'operation': 'gesture_check',
      },
    );

    // 如果在预览模式，不处理任何手势
    if (controller.state.isPreviewMode) {
      EditPageLogger.canvasDebug(
        '预览模式，不处理手势',
        data: {
          'operation': 'gesture_handling_decision',
          'reason': 'preview_mode',
          'result': false,
        },
      );
      return false;
    }

    // 如果在select模式下，需要处理选择框
    if (controller.state.currentTool == 'select') {
      EditPageLogger.canvasDebug(
        'select模式，需要处理选择框',
        data: {
          'operation': 'gesture_handling_decision',
          'reason': 'select_mode',
          'result': true,
        },
      );
      return true;
    }

    // 如果正在进行拖拽操作，需要处理
    if (isDragging || dragStateManager.isDragging) {
      EditPageLogger.canvasDebug(
        '正在拖拽，需要处理',
        data: {
          'operation': 'gesture_handling_decision',
          'reason': 'drag_in_progress',
          'isDragging': isDragging,
          'dragManagerDragging': dragStateManager.isDragging,
          'result': true,
        },
      );
      return true;
    }

    // 只有在有选中元素时才可能需要处理元素拖拽
    if (controller.state.selectedElementIds.isNotEmpty) {
      EditPageLogger.canvasDebug(
        '有选中元素，可能需要处理拖拽',
        data: {
          'operation': 'gesture_handling_decision',
          'reason': 'elements_selected',
          'selectedCount': controller.state.selectedElementIds.length,
          'result': true,
        },
      );
      return true;
    }

    // 其他情况让InteractiveViewer完全接管
    EditPageLogger.canvasDebug(
      '无特殊手势需求，让InteractiveViewer处理',
      data: {
        'operation': 'gesture_handling_decision',
        'reason': 'no_special_conditions',
        'result': false,
      },
    );
    return false;
  }

  /// 切换性能监控覆盖层显示
  @override
  void togglePerformanceOverlay() {
    setState(() {
      DragConfig.showPerformanceOverlay = !DragConfig.showPerformanceOverlay;
      EditPageLogger.canvasDebug(
        '切换性能覆盖层显示',
        data: {
          'operation': 'toggle_performance_overlay',
          'enabled': DragConfig.showPerformanceOverlay,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    });
  }

  void triggerSetState() {
    // 🚀 优化：避免Canvas整体重建，使用分层架构
    EditPageLogger.canvasDebug(
      '跳过triggerSetState - 使用分层架构',
      data: {
        'optimization': 'avoid_trigger_setstate',
        'reason': '分层架构会自动处理必要的重建',
      },
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
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(double.infinity),
              // 🔍[RESIZE_FIX] 在元素拖拽时禁用InteractiveViewer的平移，避免手势冲突
              // 使用_isReadyForDrag提前禁用，避免InteractiveViewer拦截手势
              panEnabled: !(_isDragging ||
                  _dragStateManager.isDragging ||
                  _isReadyForDrag),
              scaleEnabled: true,
              minScale: 0.1,
              maxScale: 15.0,
              scaleFactor:
                  600.0, // Increased scale factor to make zooming more gradual
              transformationController: widget.transformationController,
              onInteractionStart: (ScaleStartDetails details) {},
              onInteractionUpdate: (ScaleUpdateDetails details) {
                // Status bar uses real-time calculation, no setState needed during update
              },
              onInteractionEnd: (ScaleEndDetails details) {
                // Update final zoom value through controller
                final scale =
                    widget.transformationController.value.getMaxScaleOnAxis();
                widget.controller.zoomTo(scale);
                // Status bar uses real-time calculation, no explicit setState needed
              },
              constrained: false, // Allow content to be unconstrained
              child: DragTarget<String>(
                onWillAcceptWithDetails: (data) {
                  // 只接受工具栏拖拽的元素类型
                  return ['text', 'image', 'collection'].contains(data.data);
                },
                onAcceptWithDetails: (data) {
                  _handleElementDrop(data.data, data.offset);
                },
                builder: (context, candidateData, rejectedData) {
                  return GestureDetector(
                    // 🔧 关键修复：使用deferToChild确保空白区域手势能穿透到InteractiveViewer
                    behavior: HitTestBehavior.deferToChild,
                    onTapDown: (details) {
                      // 🔧 CRITICAL FIX: 只设置状态，不立即setState，避免时序问题
                      // setState将在onPanStart中进行，确保拖拽状态设置后再重建
                      if (shouldHandleAnySpecialGesture(elements)) {
                        _isReadyForDrag = true;
                        // 移除立即setState，避免Canvas在拖拽状态设置前重建
                      } else {
                        _isReadyForDrag = false;
                      }
                    },
                    onTapUp: (details) {
                      // 重置拖拽准备状态
                      _isReadyForDrag = false;

                      _gestureHandler.handleTapUp(
                          details,
                          elements.cast<
                              Map<String,
                                  dynamic>>()); // 🔧 CRITICAL FIX: 移除不必要的setState，避免触发Canvas重建
                      // 选择状态变化会通过智能状态分发器自动处理，不需要全局重建

                      // 调试选择状态变化后的情况（不触发重建）
                      _debugCanvasState('元素选择后');
                    },
                    // 处理右键点击事件，用于上下文菜单等功能
                    onSecondaryTapDown: (details) =>
                        _gestureHandler.handleSecondaryTapDown(details),
                    onSecondaryTapUp: (details) =>
                        _gestureHandler.handleSecondaryTapUp(
                            details, elements.cast<Map<String, dynamic>>()),
                    // 🔧 关键修复：在有选中元素、select模式或正在拖拽时设置onPanStart回调
                    onPanStart: (_isDragging ||
                            _dragStateManager.isDragging ||
                            widget.controller.state.currentTool == 'select' ||
                            widget
                                .controller.state.selectedElementIds.isNotEmpty)
                        ? (details) {
                            final gestureStartTime = DateTime.now();
                            EditPageLogger.canvasDebug(
                              '画布拖拽开始',
                              data: {
                                'position':
                                    '${details.globalPosition.dx.toStringAsFixed(1)},${details.globalPosition.dy.toStringAsFixed(1)}',
                                'localPosition':
                                    '${details.localPosition.dx.toStringAsFixed(1)},${details.localPosition.dy.toStringAsFixed(1)}',
                                'currentTool':
                                    widget.controller.state.currentTool,
                                'selectedCount': widget
                                    .controller.state.selectedElementIds.length,
                                'isDragging': _isDragging,
                                'dragManagerState':
                                    _dragStateManager.isDragging,
                              },
                            );

                            // 动态检查是否需要处理特殊手势
                            final shouldHandle =
                                shouldHandleAnySpecialGesture(elements);

                            if (shouldHandle) {
                              _gestureHandler.handlePanStart(details,
                                  elements.cast<Map<String, dynamic>>());

                              // 🔧 CRITICAL FIX: 在拖拽真正开始后，立即重建以禁用panEnabled
                              // 这确保了拖拽状态设置后，InteractiveViewer才禁用平移
                              if (mounted &&
                                  (_isDragging ||
                                      _dragStateManager.isDragging)) {
                                setState(() {});
                              }

                              final gestureProcessTime =
                                  DateTime.now().difference(gestureStartTime);
                              EditPageLogger.canvasDebug(
                                '手势处理完成',
                                data: {
                                  'gestureType': 'panStart',
                                  'processingTimeMs':
                                      gestureProcessTime.inMilliseconds,
                                  'elementsCount': elements.length,
                                },
                              );
                            } else {
                              EditPageLogger.canvasDebug('画布空白区域点击，不处理');
                              // 🔧 关键：不调用任何处理逻辑，让手势穿透
                            }
                          }
                        : null, // 🔧 关键：当不需要时，设置为null让InteractiveViewer完全接管
                    onPanUpdate: (_isDragging ||
                            _dragStateManager.isDragging ||
                            widget.controller.state.currentTool == 'select' ||
                            widget
                                .controller.state.selectedElementIds.isNotEmpty)
                        ? (details) {
                            // 处理选择框更新
                            if (widget.controller.state.currentTool ==
                                    'select' &&
                                _gestureHandler.isSelectionBoxActive) {
                              _gestureHandler.handlePanUpdate(details);
                              _selectionBoxNotifier.value = SelectionBoxState(
                                isActive: true,
                                startPoint: _gestureHandler.selectionBoxStart,
                                endPoint: _gestureHandler.selectionBoxEnd,
                              );
                              return;
                            }

                            // 处理元素拖拽
                            if (_isDragging || _dragStateManager.isDragging) {
                              _gestureHandler.handlePanUpdate(details);
                              return;
                            }
                          }
                        : null, // 🔧 关键：设置为null让InteractiveViewer完全接管
                    onPanEnd: (_isDragging ||
                            _dragStateManager.isDragging ||
                            widget.controller.state.currentTool == 'select' ||
                            widget
                                .controller.state.selectedElementIds.isNotEmpty)
                        ? (details) {
                            EditPageLogger.canvasDebug('画布拖拽结束');

                            // 重置选择框状态
                            if (widget.controller.state.currentTool ==
                                    'select' &&
                                _gestureHandler.isSelectionBoxActive) {
                              _selectionBoxNotifier.value = SelectionBoxState();
                            }

                            // 处理手势结束
                            if (_isDragging ||
                                _dragStateManager.isDragging ||
                                _gestureHandler.isSelectionBoxActive) {
                              _gestureHandler.handlePanEnd(details);
                            }

                            // 重置状态
                            _isReadyForDrag = false;
                          }
                        : null,
                    onPanCancel: (_isDragging ||
                            _dragStateManager.isDragging ||
                            widget.controller.state.currentTool == 'select' ||
                            widget
                                .controller.state.selectedElementIds.isNotEmpty)
                        ? () {
                            EditPageLogger.canvasDebug('画布拖拽取消');

                            // 重置选择框状态
                            if (widget.controller.state.currentTool ==
                                    'select' &&
                                _gestureHandler.isSelectionBoxActive) {
                              _selectionBoxNotifier.value = SelectionBoxState();
                            }

                            // 处理手势取消
                            if (_isDragging ||
                                _dragStateManager.isDragging ||
                                _gestureHandler.isSelectionBoxActive) {
                              _gestureHandler.handlePanCancel();
                            }

                            // 重置状态
                            _isReadyForDrag = false;
                          }
                        : null,
                    child: Container(
                      width: pageSize.width,
                      height: pageSize.height,
                      // 🔧 关键修复：添加透明背景确保手势检测正常工作
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.red, width: 2),
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
        ),

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
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 4.0,
                runSpacing: 4.0,
                children: [
                  // Debug indicator showing current tool
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '当前工具: ${widget.controller.state.currentTool}',
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
                            '选择模式',
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
                            constraints: const BoxConstraints(maxWidth: 120),
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
            ),
          ),
      ],
    );
  }

  /// 🔧 调试方法：检查当前状态，帮助诊断画布平移问题
  void _debugCanvasState(String context) {
    final panEnabled =
        !(_isDragging || _dragStateManager.isDragging || _isReadyForDrag);
    EditPageLogger.canvasDebug(
      '画布状态检查',
      data: {
        'context': context,
        'panEnabled': panEnabled,
        'isDragging': _isDragging,
        'dragStateManagerIsDragging': _dragStateManager.isDragging,
        'isReadyForDrag': _isReadyForDrag,
      },
    );
    EditPageLogger.canvasDebug(
      '画布状态详情',
      data: {
        'context': context,
        'selectedElementIds':
            widget.controller.state.selectedElementIds.toList(),
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
            setState(() {});
            EditPageLogger.canvasDebug('Canvas UI监听器触发重建');
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

      // 不要重新初始化_repaintBoundaryKey，因为它已经在_initializeCoreComponents()中初始化了
      // _repaintBoundaryKey = GlobalKey();      // 注册简化的层级
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

      // 注册参考线层（基础模式也需要支持参考线）
      // _layerRenderManager.registerLayer(
      //   type: RenderLayerType.guideline,
      //   config: const LayerConfig(
      //     type: RenderLayerType.guideline,
      //     priority: LayerPriority.medium,
      //     enableCaching: false, // 禁用缓存避免潜在问题
      //     useRepaintBoundary: true,
      //   ),
      //   builder: (config) =>
      //       _buildLayerWidget(RenderLayerType.guideline, config),
      // );

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

    // 只在变换应用失败时记录错误日志
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        final appliedMatrix = widget.transformationController.value;
        final appliedScale = appliedMatrix.getMaxScaleOnAxis();
        final appliedTranslation = appliedMatrix.getTranslation();

        if ((appliedScale - scale).abs() > 0.001 ||
            (appliedTranslation.x - dx).abs() > 1 ||
            (appliedTranslation.y - dy).abs() > 1) {
          EditPageLogger.canvasError(
            '画布视图重置失败',
            data: {
              'expectedScale': scale.toStringAsFixed(3),
              'actualScale': appliedScale.toStringAsFixed(3),
              'expectedTranslation':
                  '(${dx.toStringAsFixed(1)}, ${dy.toStringAsFixed(1)})',
              'actualTranslation':
                  '(${appliedTranslation.x.toStringAsFixed(1)}, ${appliedTranslation.y.toStringAsFixed(1)})',
            },
          );
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
      }

      // 处理边界约束
      final elementDefaultSizes = {
        'text': const Size(200, 100),
        'image': const Size(200, 200),
        'collection': const Size(200, 200),
      };

      final elementSize =
          elementDefaultSizes[elementType] ?? const Size(200, 100);
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

    EditPageLogger.canvasDebug('画布核心组件初始化完成，三阶段拖拽系统就绪');
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
    EditPageLogger.canvasDebug('画布结构监听器初始化完成');

    // Initialize state change dispatcher for unified state management
    _stateDispatcher =
        StateChangeDispatcher(widget.controller, _structureListener);

    // Set the state dispatcher in the controller for layered state management
    widget.controller.setStateDispatcher(_stateDispatcher);
    EditPageLogger.canvasDebug(
      '状态分发器初始化并连接到控制器',
      data: {
        'operation': 'state_dispatcher_initialization',
        'component': 'StateChangeDispatcher',
      },
    );

    // Initialize drag operation manager for 3-phase drag system
    _dragOperationManager = DragOperationManager(
      widget.controller,
      _dragStateManager,
      _stateDispatcher,
    );
    EditPageLogger.canvasDebug('拖拽操作管理器初始化完成');

    // Register layers with the layer render manager
    _initializeLayers();
    EditPageLogger.canvasDebug('图层注册到图层渲染管理器完成'); // ✅ 新添加：注册Canvas到智能状态分发器
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
    // No need to initialize _repaintBoundaryKey again as it's already initialized in _initializeCoreComponents()

    // 初始化手势处理器 (需要在所有其他组件初始化后)
    _initializeGestureHandler(); // 恢复使用本地方法
    EditPageLogger.canvasDebug('手势处理器初始化完成');

    // 🔧 修复：注册画布到控制器，支持reset view功能
    // Register this canvas with the controller for reset view functionality
    widget.controller.setEditCanvas(this);

    // Set the RepaintBoundary key in the controller for screenshot functionality
    widget.controller.setCanvasKey(_repaintBoundaryKey);

    // 🔍 恢复初始化时的reset，用于对比两次调用
    // Schedule initial reset view position on first load (只执行一次)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitializedView && !_isDisposed) {
        _hasInitializedView = true;
        resetCanvasPosition(); // 使用标准的Reset View Position逻辑
      }
    });
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
          }
        };
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
                    setState(() {});
                    EditPageLogger.canvasDebug('Canvas UI监听器触发重建(重试)');
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

        EditPageLogger.canvasDebug(
          '交互层状态变化处理（优化版）',
          data: {
            'eventType': event.runtimeType.toString(),
            'optimization': 'interaction_layer_only_rebuild',
            'avoidedCanvasRebuild': true,
          },
        );

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
