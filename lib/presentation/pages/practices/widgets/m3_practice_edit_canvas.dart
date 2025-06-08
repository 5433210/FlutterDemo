import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/practice/batch_update_options.dart';
import '../../../widgets/practice/drag_state_manager.dart';
import '../../../widgets/practice/performance_monitor.dart' as perf;
import '../../../widgets/practice/performance_monitor.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import '../../../widgets/practice/smart_canvas_gesture_handler.dart';
import '../helpers/element_utils.dart';
import 'canvas/components/canvas_control_point_handlers.dart';
import 'canvas/components/canvas_element_creators.dart';
import 'canvas/components/canvas_gesture_handlers.dart';
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

// 注意：SelectionBoxState 和 GridPainter 已移动到 canvas_ui_components.dart

class _M3PracticeEditCanvasState extends State<M3PracticeEditCanvas>
    with
        TickerProviderStateMixin,
        CanvasElementCreators,
        CanvasViewControllers,
        CanvasLayerBuilders,
        CanvasControlPointHandlers,
        CanvasGestureHandlers {
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

  // 拖拽相关状态
  Offset _dragStart = Offset.zero;

  Offset _elementStartPosition = Offset.zero;

  // 拖拽准备状态：使用普通变量避免setState时序问题
  bool _isReadyForDrag = false;

  // Canvas gesture handler
  late SmartCanvasGestureHandler _gestureHandler;
  // 选择框状态管理 - 使用ValueNotifier<SelectionBoxState>替代原来的布尔值
  final ValueNotifier<SelectionBoxState> _selectionBoxNotifier =
      ValueNotifier(SelectionBoxState());
  // 跟踪页面变化，用于自动重置视图
  String? _lastPageKey;
  bool _hasInitializedView = false; // 防止重复初始化视图

  @override
  ContentRenderController get contentRenderController =>
      _contentRenderController;
  // 实现 mixin 的抽象方法
  @override
  PracticeEditController get controller => widget.controller;
  @override
  Offset get dragStart => _dragStart;

  // CanvasLayerBuilders 实现
  @override
  DragStateManager get dragStateManager => _dragStateManager;

  @override
  Offset get elementStartPosition => _elementStartPosition;

  // CanvasGestureHandlers 实现
  @override
  SmartCanvasGestureHandler get gestureHandler => _gestureHandler;
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
  void applyGridSnapToSelectedElements() {
    _applyGridSnapToSelectedElements();
  }

  @override
  Widget build(BuildContext context) {
    // 🔍[RESIZE_FIX] Canvas build方法被调用
    AppLogger.debug(
      '画布构建开始',
      tag: 'Canvas',
      data: {
        'selectedCount': widget.controller.state.selectedElementIds.length,
        'isReadyForDrag': _isReadyForDrag,
        'isDragging': _isDragging,
      },
    );

    // Track performance for main canvas rebuilds
    _performanceMonitor.trackWidgetRebuild('M3PracticeEditCanvas');

    // Track frame rendering performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performanceMonitor.trackFrame();
    });

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;

        AppLogger.debug(
          '画布重建',
          tag: 'Canvas',
          data: {
            'currentTool': widget.controller.state.currentTool,
            'selectedElementsCount':
                widget.controller.state.selectedElementIds.length,
            'totalElementsCount':
                widget.controller.state.currentPageElements.length,
          },
        );

        if (widget.controller.state.pages.isEmpty) {
          return Center(
            child: Text(
              'No pages available',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        final currentPage = widget.controller.state.currentPage;
        if (currentPage == null) {
          return Center(
            child: Text(
              'Current page does not exist',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        final elements = widget.controller.state.currentPageElements;
        AppLogger.debug(
          '画布元素状态',
          tag: 'Canvas',
          data: {
            'elementsCount': elements.length,
            'elementsType': elements.runtimeType.toString(),
            'hasElements': elements.isNotEmpty,
            'firstElementPreview': elements.isNotEmpty
                ? elements.first['type'] ?? 'unknown'
                : null,
          },
        );
        // 用性能覆盖层包装画布
        return perf.PerformanceOverlay(
          showOverlay: DragConfig.showPerformanceOverlay,
          child: _buildPageContent(currentPage, elements, colorScheme),
        );
      },
    );
  }

  /// Handle window size changes - automatically trigger reset view position


  @override
  void dispose() {
    // 🔧 窗口大小变化处理已移至页面级别

    // 🔧 移除DragStateManager监听器
    _dragStateManager.removeListener(_onDragStateManagerChanged);

    _selectionBoxNotifier.dispose();
    _contentRenderController.dispose();
    _dragStateManager.dispose();
    _layerRenderManager.dispose();

    // 释放新的混合优化策略组件
    _structureListener.dispose();
    _stateDispatcher.dispose();
    _dragOperationManager.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // 🔧 窗口大小变化处理已移至页面级别

    AppLogger.info(
      '画布组件初始化开始',
      tag: 'Canvas',
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

      AppLogger.info(
        '画布分层和元素级混合优化策略组件初始化完成',
        tag: 'Canvas',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '画布初始化失败',
        tag: 'Canvas',
        error: e,
        stackTrace: stackTrace,
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

    AppLogger.debug(
      '旋转元素',
      tag: 'Canvas',
      data: {
        'elementId': elementId,
        'delta': '$delta',
        'rotationDelta': rotationDelta,
        'newRotation': newRotation,
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

  /// 切换性能监控覆盖层显示
  @override
  void togglePerformanceOverlay() {
    setState(() {
      DragConfig.showPerformanceOverlay = !DragConfig.showPerformanceOverlay;
      AppLogger.debug(
        '切换性能覆盖层显示',
        tag: 'Canvas',
        data: {'enabled': DragConfig.showPerformanceOverlay},
      );
    });
  }

  @override
  void triggerSetState() {
    if (mounted) setState(() {});
  }

  /// 为选中的元素应用网格吸附（只在拖拽结束时调用）
  void _applyGridSnapToSelectedElements() {
    // 只有在启用了网格吸附的情况下才进行网格吸附
    if (!widget.controller.state.snapEnabled) {
      debugPrint('🎯 网格吸附未启用，跳过');
      return;
    }

    final gridSize = widget.controller.state.gridSize;
    final selectedCount = widget.controller.state.selectedElementIds.length;
    debugPrint('🎯 开始应用网格吸附，网格大小: $gridSize, 选中元素数: $selectedCount');

    // 处理所有选中元素
    for (final elementId in widget.controller.state.selectedElementIds) {
      final element = widget.controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == elementId,
        orElse: () => <String, dynamic>{},
      );

      if (element.isEmpty) {
        debugPrint('🎯 元素 $elementId 不存在，跳过');
        continue;
      }

      // 跳过锁定的元素
      final isLocked = element['locked'] as bool? ?? false;
      if (isLocked) {
        debugPrint('🎯 元素 $elementId 已锁定，跳过吸附');
        continue;
      }

      // 跳过锁定图层上的元素
      final layerId = element['layerId'] as String?;
      if (layerId != null && widget.controller.state.isLayerLocked(layerId)) {
        debugPrint('🎯 元素 $elementId 在锁定图层 $layerId 上，跳过吸附');
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
        debugPrint('🎯 网格吸附: $elementId 从 ($x, $y) 到 ($snappedX, $snappedY)');

        AppLogger.debug(
          '网格吸附',
          tag: 'Canvas',
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
      } else {
        debugPrint('🎯 元素 $elementId 位置 ($x, $y) 已在网格线上，无需吸附');
      }
    }

    debugPrint('🎯 网格吸附完成');
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
    print(
        '📋 Canvas: Updating ContentRenderController with ${elements.length} elements');
    // Update content render controller with current elements
    _contentRenderController.initializeElements(elements);

    AppLogger.debug(
      '构建页面内容',
      tag: 'Canvas',
      data: {
        'selectedElementsCount':
            widget.controller.state.selectedElementIds.length
      },
    );

    // Calculate page dimensions for layout purposes
    final pageSize = ElementUtils.calculatePixelSize(page);

    // 🔧 检测页面尺寸变化并自动重置视图
    final pageKey =
        '${page['width']}_${page['height']}_${page['orientation']}_${page['dpi']}';
    if (_lastPageKey != null && _lastPageKey != pageKey) {
      AppLogger.debug(
        '页面变化检测：页面尺寸改变',
        tag: 'Canvas',
        data: {'from': _lastPageKey, 'to': pageKey},
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitPageToScreen();
          AppLogger.debug('页面变化检测：自动重置视图位置', tag: 'Canvas');
        }
      });
    }
    _lastPageKey = pageKey;

    // 🔥 关键修复：移除每次build时的自动变换设置
    // 不再在build方法中强制设置transformationController和调用zoomTo
    // 这些操作现在只在真正需要时进行（如初始化、重置按钮）    debugPrint('🔧【_buildPageContent】保持当前变换状态，不强制重置');

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
                  debugPrint(
                      '🎯 DragTarget.onWillAcceptWithDetails: data=${data.data}');
                  final willAccept =
                      ['text', 'image', 'collection'].contains(data.data);
                  debugPrint('🎯 DragTarget willAccept: $willAccept');
                  return willAccept;
                },
                onAcceptWithDetails: (data) {
                  debugPrint('🎯[DROP] DragTarget.onAcceptWithDetails触发');
                  debugPrint('🎯[DROP]   - 元素类型: ${data.data}');
                  debugPrint('🎯[DROP]   - DragTarget offset: ${data.offset}');
                  
                  // 获取DragTarget的渲染信息
                  final RenderBox? dragTargetBox = context.findRenderObject() as RenderBox?;
                  if (dragTargetBox != null) {
                    final dragTargetSize = dragTargetBox.size;
                    final dragTargetGlobalPos = dragTargetBox.localToGlobal(Offset.zero);
                    debugPrint('🎯[DROP]   - DragTarget尺寸: $dragTargetSize');
                    debugPrint('🎯[DROP]   - DragTarget全局位置: $dragTargetGlobalPos');
                  }
                  
                  _handleElementDrop(data.data, data.offset);
                },
                builder: (context, candidateData, rejectedData) {
                  return GestureDetector(
                    // 🔧 关键修复：使用deferToChild确保空白区域手势能穿透到InteractiveViewer
                    behavior: HitTestBehavior.deferToChild,
                    onTapDown: (details) {
                      debugPrint(
                          '🔥【onTapDown】检测点击位置 - 坐标: ${details.localPosition}');
                      // 检查是否点击在选中元素上，如果是，准备拖拽
                      // 直接设置变量，避免setState时序问题
                      if (shouldHandleAnySpecialGesture(elements)) {
                        debugPrint('🔥【onTapDown】点击在选中元素上，准备拖拽');
                        _isReadyForDrag = true;
                        // 🔍[RESIZE_FIX] 立即重建以禁用InteractiveViewer的panEnabled
                        if (mounted) setState(() {});
                      } else {
                        debugPrint('🔥【onTapDown】点击在空白区域');
                        _isReadyForDrag = false;
                      }

                      // 🔍[RESIZE_FIX] 调试InteractiveViewer状态
                      final panEnabled = !(_isDragging ||
                          _dragStateManager.isDragging ||
                          _isReadyForDrag);
                      debugPrint(
                          '🔍[RESIZE_FIX] InteractiveViewer panEnabled: $panEnabled (isDragging=$_isDragging, dragManagerDragging=${_dragStateManager.isDragging}, isReadyForDrag=$_isReadyForDrag)');

                      // 🔍[RESIZE_FIX] 检查Canvas的onPanStart是否会被设置
                      final shouldHandleGesture =
                          shouldHandleAnySpecialGesture(elements);
                      debugPrint(
                          '🔍[RESIZE_FIX] Canvas onPanStart 是否设置: $shouldHandleGesture');
                    },
                    onTapUp: (details) {
                      // 重置拖拽准备状态
                      _isReadyForDrag = false;

                      // 🔍[RESIZE_FIX] 调试点击和选择过程
                      debugPrint(
                          '🔍[RESIZE_FIX] onTapUp被调用: position=${details.localPosition}');
                      debugPrint(
                          '🔍[RESIZE_FIX] 当前选中元素数: ${widget.controller.state.selectedElementIds.length}');

                      _gestureHandler.handleTapUp(
                          details, elements.cast<Map<String, dynamic>>());

                      // 🔧 关键修复：确保在选择状态变化后立即更新UI状态
                      if (mounted) {
                        setState(() {});
                        // 调试选择状态变化后的情况
                        _debugCanvasState('元素选择后');
                      }

                      // 🔍[RESIZE_FIX] 选择处理后的状态
                      debugPrint(
                          '🔍[RESIZE_FIX] handleTapUp后选中元素数: ${widget.controller.state.selectedElementIds.length}');
                      if (widget
                          .controller.state.selectedElementIds.isNotEmpty) {
                        debugPrint(
                            '🔍[RESIZE_FIX] 选中的元素IDs: ${widget.controller.state.selectedElementIds}');
                      }
                    },
                    // 处理右键点击事件，用于退出select模式
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
                            debugPrint(
                                '[DRAG_DEBUG] ===== Canvas onPanStart被调用 =====');
                            debugPrint(
                                '[DRAG_DEBUG] Canvas - 点击位置: ${details.localPosition}');
                            debugPrint(
                                '[DRAG_DEBUG] Canvas - 当前选中: ${widget.controller.state.selectedElementIds}');
                            debugPrint(
                                '[DRAG_DEBUG] Canvas - 当前工具: ${widget.controller.state.currentTool}');

                            // 动态检查是否需要处理特殊手势
                            final shouldHandle =
                                shouldHandleAnySpecialGesture(elements);
                            debugPrint(
                                '[DRAG_DEBUG] Canvas - shouldHandleAnySpecialGesture结果: $shouldHandle');

                            if (shouldHandle) {
                              debugPrint(
                                  '[DRAG_DEBUG] Canvas - 处理特殊手势，调用_gestureHandler.handlePanStart');
                              _gestureHandler.handlePanStart(details,
                                  elements.cast<Map<String, dynamic>>());
                            } else {
                              debugPrint('[DRAG_DEBUG] Canvas - 空白区域点击，不处理');
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
                            debugPrint(
                                '🔍[RESIZE_FIX] Canvas onPanUpdate被调用: position=${details.localPosition}');

                            // 处理选择框更新
                            if (widget.controller.state.currentTool ==
                                    'select' &&
                                _gestureHandler.isSelectionBoxActive) {
                              debugPrint('🔍[RESIZE_FIX] 处理选择框更新');
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
                              debugPrint('🔍[RESIZE_FIX] 处理元素拖拽');
                              _gestureHandler.handlePanUpdate(details);
                              return;
                            }

                            // 🔧 关键：空白区域不处理，让InteractiveViewer接管
                            debugPrint('🔍[RESIZE_FIX] 空白区域手势，不拦截');
                          }
                        : null, // 🔧 关键：设置为null让InteractiveViewer完全接管
                    onPanEnd: (_isDragging ||
                            _dragStateManager.isDragging ||
                            widget.controller.state.currentTool == 'select' ||
                            widget
                                .controller.state.selectedElementIds.isNotEmpty)
                        ? (details) {
                            debugPrint('🔍[RESIZE_FIX] Canvas onPanEnd被调用');

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
                            debugPrint('🔍[RESIZE_FIX] Canvas onPanCancel被调用');

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
                          // 添加调试信息，检查页面容器的实际渲染尺寸
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              final RenderBox? containerBox =
                                  context.findRenderObject() as RenderBox?;
                              if (containerBox != null) {
                                final containerSize = containerBox.size;
                                debugPrint(
                                    '🔧【页面容器】实际渲染尺寸: ${containerSize.width.toStringAsFixed(1)}x${containerSize.height.toStringAsFixed(1)}, 期望尺寸: ${pageSize.width.toStringAsFixed(1)}x${pageSize.height.toStringAsFixed(1)}');

                                // 获取容器在屏幕中的位置
                                final containerOffset =
                                    containerBox.localToGlobal(Offset.zero);
                                debugPrint(
                                    '🔧【页面容器】屏幕位置: (${containerOffset.dx.toStringAsFixed(1)}, ${containerOffset.dy.toStringAsFixed(1)})');
                              }
                            }
                          });
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
                                    debugPrint('🎨 正在构建LayerRenderManager层级结构');
                                    debugPrint(
                                        '🎨 当前网格状态: ${widget.controller.state.gridVisible}');
                                    final layerStack =
                                        _layerRenderManager.buildLayerStack(
                                      layerOrder: [
                                        RenderLayerType.staticBackground,
                                        RenderLayerType.content,
                                        RenderLayerType.dragPreview,
                                        RenderLayerType.interaction,
                                      ],
                                    );
                                    debugPrint('🎨 LayerRenderManager构建完成');
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
                    ),
                  // Reset position button
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
                                        .canvasResetView,
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
    debugPrint('🔍[CANVAS_STATE] [$context] panEnabled: $panEnabled');
    debugPrint('🔍[CANVAS_STATE] [$context] _isDragging: $_isDragging');
    debugPrint(
        '🔍[CANVAS_STATE] [$context] _dragStateManager.isDragging: ${_dragStateManager.isDragging}');
    debugPrint('🔍[CANVAS_STATE] [$context] _isReadyForDrag: $_isReadyForDrag');
    debugPrint(
        '🔍[CANVAS_STATE] [$context] selectedElementIds: ${widget.controller.state.selectedElementIds}');
    debugPrint(
        '🔍[CANVAS_STATE] [$context] currentTool: ${widget.controller.state.currentTool}');
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
      // _repaintBoundaryKey = GlobalKey();

      // 注册简化的层级
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

      print('🔧 Canvas: 已切换到基础模式');
    } catch (e) {
      debugPrint('❌ Canvas: 基础模式初始化也失败 - $e');
    }
  }

  /// Fit the page content to screen with proper scale and centering
  void _fitPageToScreen() {
    debugPrint('🔧【_fitPageToScreen】重置视图位置');

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
    debugPrint(
        '🔧【Reset View】页面信息: currentPage = ${currentPage['width']}x${currentPage['height']}, 计算出的pageSize = ${pageSize.width}x${pageSize.height}');

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

    debugPrint('🔧【Reset View】应用变换矩阵: ${matrix.toString().split('\n')[0]}...');

    // Notify the controller that zoom has changed
    widget.controller.zoomTo(scale);

    // Verify the transformation was applied correctly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final appliedMatrix = widget.transformationController.value;
        final appliedScale = appliedMatrix.getMaxScaleOnAxis();
        final appliedTranslation = appliedMatrix.getTranslation();
        debugPrint(
            '🔧【Reset View】验证变换应用结果: appliedScale=${appliedScale.toStringAsFixed(3)}, appliedTranslation=(${appliedTranslation.x.toStringAsFixed(1)}, ${appliedTranslation.y.toStringAsFixed(1)})');

        if ((appliedScale - scale).abs() > 0.001 ||
            (appliedTranslation.x - dx).abs() > 1 ||
            (appliedTranslation.y - dy).abs() > 1) {
          debugPrint(
              '⚠️【Reset View】变换应用不正确！期望 scale=${scale.toStringAsFixed(3)}, translation=(${dx.toStringAsFixed(1)}, ${dy.toStringAsFixed(1)})');
        } else {
          debugPrint('✅【Reset View】变换应用正确');
        }
      }
    });

    // Update UI
    // setState(() {});
    debugPrint('🔧【Reset View】计算结果: '
        'pageSize=${pageSize.width.toStringAsFixed(1)}x${pageSize.height.toStringAsFixed(1)}, '
        'viewportSize=${viewportSize.width.toStringAsFixed(1)}x${viewportSize.height.toStringAsFixed(1)}, '
        'paddingFactor=$paddingFactor, '
        'availableSize=${availableWidth.toStringAsFixed(1)}x${availableHeight.toStringAsFixed(1)}, '
        'scale=${scale.toStringAsFixed(3)}, '
        'translation=(${dx.toStringAsFixed(1)}, ${dy.toStringAsFixed(1)})');

    debugPrint(
        '🔧【Reset View】预期效果: 让整个页面在可视区域内居中显示，scale=${scale.toStringAsFixed(3)}');
  }

  /// 处理拖拽结束 - 使用 mixin 方法
  Future<void> _handleDragEnd() async {
    setState(() {
      _isDragging = false;
    });

    // 🔧 拖拽结束时应用网格吸附
    debugPrint('🎯 拖拽结束，开始应用网格吸附，吸附状态: ${widget.controller.state.snapEnabled}');
    _applyGridSnapToSelectedElements();
  }

  /// 处理拖拽开始 - 使用 mixin 方法
  Future<void> _handleDragStart(
    bool isDragging,
    Offset dragStart,
    Offset elementPosition,
    Map<String, Offset> elementPositions,
  ) async {
    setState(() {
      _isDragging = isDragging;
      _dragStart = dragStart;
      _elementStartPosition = elementPosition;
    });

    // 🔧 拖拽开始时不需要立即应用网格吸附
    debugPrint('🎯 拖拽开始，网格吸附状态: ${widget.controller.state.snapEnabled}');
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
    debugPrint('🎯[DROP] _handleElementDrop开始处理');
    debugPrint('🎯[DROP]   - 元素类型: $elementType');
    debugPrint('🎯[DROP]   - 接收到的dropOffset: $dropOffset');
    
    // 获取当前页面和尺寸
    final currentPage = widget.controller.state.currentPage;
    if (currentPage == null) {
      debugPrint('🎯[DROP] ❌ 无法获取当前页面，终止处理');
      return;
    }

    final pageSize = ElementUtils.calculatePixelSize(currentPage);
    debugPrint('🎯[DROP]   - 页面尺寸: ${pageSize.width}x${pageSize.height}');
    
    Offset dropPosition;

    if (dropOffset != null) {
      // 🔧 正确的坐标转换方案（基于用户的精准分析）：
      // 1. DragTarget offset = 鼠标在窗体全局坐标的位置
      // 2. DragTarget全局位置 = 画布视口左上角在窗体全局坐标的位置  
      // 3. DragTarget尺寸 = 画布视口的实际大小
      
      debugPrint('🎯[DROP] 开始坐标处理:');
      debugPrint('🎯[DROP]   - 鼠标全局坐标: $dropOffset');
      
      // 获取画布视口信息
      final RenderBox? dragTargetBox = context.findRenderObject() as RenderBox?;
      if (dragTargetBox == null) {
        debugPrint('🎯[DROP] ❌ 无法获取DragTarget的RenderBox');
        return;
      }
      
      final viewportGlobalPosition = dragTargetBox.localToGlobal(Offset.zero);
      final viewportSize = dragTargetBox.size;
      
      debugPrint('🎯[DROP]   - 画布视口全局位置: $viewportGlobalPosition');
      debugPrint('🎯[DROP]   - 画布视口大小: $viewportSize');
      
      // 第一步：计算鼠标相对于画布视口的坐标
      final relativeX = dropOffset.dx - viewportGlobalPosition.dx;
      final relativeY = dropOffset.dy - viewportGlobalPosition.dy;
      final viewportRelativePosition = Offset(relativeX, relativeY);
      
      debugPrint('🎯[DROP]   - 相对于视口的坐标: $viewportRelativePosition');
      debugPrint('🎯[DROP]     * 计算过程: (${dropOffset.dx} - ${viewportGlobalPosition.dx}, ${dropOffset.dy} - ${viewportGlobalPosition.dy})');
      
      // 第二步：将视口坐标转换为页面逻辑坐标
      // 使用现有的screenToCanvas方法，但传入视口相对坐标
      dropPosition = screenToCanvas(viewportRelativePosition);
      
      debugPrint('🎯[DROP]   - screenToCanvas转换结果: $dropPosition');
      
      // 🔧 验证转换：将转换后的坐标再转换回屏幕坐标，检查是否与原始点击位置一致
      final verifyScreenPosition = canvasToScreen(dropPosition);
      final expectedScreenPosition = Offset(
        viewportGlobalPosition.dx + viewportRelativePosition.dx,
        viewportGlobalPosition.dy + viewportRelativePosition.dy,
      );
      
      debugPrint('🎯[DROP]   - 坐标转换验证:');
      debugPrint('🎯[DROP]     * 原始全局坐标: $dropOffset');
      debugPrint('🎯[DROP]     * 重构全局坐标: $expectedScreenPosition');
      debugPrint('🎯[DROP]     * 逆转换结果: $verifyScreenPosition');
      debugPrint('🎯[DROP]     * 坐标误差: dx=${(verifyScreenPosition.dx - expectedScreenPosition.dx).abs().toStringAsFixed(2)}, dy=${(verifyScreenPosition.dy - expectedScreenPosition.dy).abs().toStringAsFixed(2)}');
      
      // 输出变换矩阵信息用于调试
      final matrix = widget.transformationController.value;
      final scale = matrix.getMaxScaleOnAxis();
      final translation = matrix.getTranslation();
      debugPrint('🎯[DROP]   - 变换矩阵: 缩放=$scale, 平移=(${translation.x}, ${translation.y})');
      
      // 🔧 添加页面边界检查和约束
      final elementDefaultSizes = {
        'text': const Size(200, 100),
        'image': const Size(200, 200),
        'collection': const Size(200, 200),
      };
      
      final elementSize = elementDefaultSizes[elementType] ?? const Size(200, 100);
      final halfWidth = elementSize.width / 2;
      final halfHeight = elementSize.height / 2;
      
      debugPrint('🎯[DROP]   - 元素默认尺寸: ${elementSize.width}x${elementSize.height}');
      
      // 将鼠标点击位置转换为元素左上角位置（元素中心对齐）
      final elementLeftTop = Offset(dropPosition.dx - halfWidth, dropPosition.dy - halfHeight);
      
      debugPrint('🎯[DROP]   - 元素中心对齐转换:');
      debugPrint('🎯[DROP]     * 鼠标点击位置（元素中心）: $dropPosition');
      debugPrint('🎯[DROP]     * 元素左上角位置: $elementLeftTop');
      
      // 约束元素左上角到页面边界内
      final beforeConstraints = elementLeftTop;
      
      final constrainedX = elementLeftTop.dx.clamp(0.0, pageSize.width - elementSize.width);
      final constrainedY = elementLeftTop.dy.clamp(0.0, pageSize.height - elementSize.height);
      
      dropPosition = Offset(constrainedX, constrainedY);
      
      debugPrint('🎯[DROP]   - 边界约束:');
      debugPrint('🎯[DROP]     * 转换前左上角: $beforeConstraints');
      debugPrint('🎯[DROP]     * 约束后左上角: $dropPosition');
      debugPrint('🎯[DROP]     * 是否被约束: X${beforeConstraints.dx != constrainedX ? '✂️' : '✅'} Y${beforeConstraints.dy != constrainedY ? '✂️' : '✅'}');
      
    } else {
      // 回退方案：使用页面中心附近创建元素，添加随机偏移避免重叠
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      dropPosition = Offset(
        pageSize.width / 2 + random - 50,
        pageSize.height / 2 + random - 50,
      );
      debugPrint('🎯[DROP] 使用回退方案，页面中心位置: $dropPosition');
    }

    debugPrint('🎯[DROP] 准备调用handleElementDrop:');
    debugPrint('🎯[DROP]   - 元素类型: $elementType');
    debugPrint('🎯[DROP]   - 最终位置: $dropPosition');
    debugPrint('🎯[DROP]   - 居中偏移: false（已在边界约束中处理）');
    
    // 使用mixin中的方法处理元素拖拽创建
    // 🔧 修复：禁用居中偏移，因为上面的边界约束已经考虑了元素中心对齐
    handleElementDrop(elementType, dropPosition, applyCenteringOffset: false);
    
    debugPrint('🎯[DROP] _handleElementDrop处理完成');
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

    print('🏗️ Canvas: 核心组件初始化完成，三阶段拖拽系统就绪');
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
    print('🏗️ Canvas: CanvasStructureListener initialized');

    // Initialize state change dispatcher for unified state management
    _stateDispatcher =
        StateChangeDispatcher(widget.controller, _structureListener);

    // Set the state dispatcher in the controller for layered state management
    widget.controller.setStateDispatcher(_stateDispatcher);
    print(
        '🏗️ Canvas: StateChangeDispatcher initialized and connected to controller');

    // Initialize drag operation manager for 3-phase drag system
    _dragOperationManager = DragOperationManager(
      widget.controller,
      _dragStateManager,
      _stateDispatcher,
    );
    print('🏗️ Canvas: DragOperationManager initialized');

    // Register layers with the layer render manager
    _initializeLayers();
    print('🏗️ Canvas: Layers registered with LayerRenderManager');
  }

  /// 初始化UI组件
  void _initializeUIComponents() {
    // No need to initialize _repaintBoundaryKey again as it's already initialized in _initializeCoreComponents()

    // 初始化手势处理器 (需要在所有其他组件初始化后)
    _initializeGestureHandler(); // 恢复使用本地方法
    print('🏗️ Canvas: GestureHandler initialized');

    // 🔧 修复：注册画布到控制器，支持reset view功能
    // Register this canvas with the controller for reset view functionality
    widget.controller.setEditCanvas(this);

    // Set the RepaintBoundary key in the controller for screenshot functionality
    widget.controller.setCanvasKey(_repaintBoundaryKey);

    // 🔍 恢复初始化时的reset，用于对比两次调用
    // Schedule initial reset view position on first load (只执行一次)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitializedView) {
        _hasInitializedView = true;
        resetCanvasPosition(); // 使用标准的Reset View Position逻辑
        debugPrint('🔧【initState】首次加载，执行Reset View Position');
      }
    });
  }

  /// 处理DragStateManager状态变化
  void _onDragStateManagerChanged() {}

  /// Reset canvas position to fit the page content within the viewport
  void _resetCanvasPosition() {
    _fitPageToScreen();
  }

  /// 建立组件间连接
  void _setupComponentConnections() {
    // 将拖拽状态管理器与性能监控系统关联
    _performanceMonitor.setDragStateManager(_dragStateManager);
    print('🏗️ Canvas: Connected DragStateManager with PerformanceMonitor');

    // 将拖拽状态管理器与内容渲染控制器关联
    _contentRenderController.setDragStateManager(_dragStateManager);
    print(
        '🏗️ Canvas: Connected DragStateManager with ContentRenderController');

    // 🔧 修复：让Canvas监听DragStateManager变化，确保控制点能跟随元素移动
    _dragStateManager.addListener(_onDragStateManagerChanged);
    print('🏗️ Canvas: 已监听DragStateManager状态变化');

    // 设置结构监听器的层级处理器
    _setupStructureListenerHandlers();
    print('🏗️ Canvas: Structure listener handlers configured');

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
        // 处理网格设置变化
        if (mounted) {
          setState(() {});
        }
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

    // 配置Interaction层级处理器
    _structureListener.registerLayerHandler(RenderLayerType.interaction,
        (event) {
      if (event is SelectionChangeEvent || event is ToolChangeEvent) {
        // 选择或工具变化，重新渲染交互层
        _layerRenderManager.markLayerDirty(RenderLayerType.interaction,
            reason: 'Selection or tool changed');
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  // 手势检查方法已移至 CanvasGestureHandlers mixin
}
