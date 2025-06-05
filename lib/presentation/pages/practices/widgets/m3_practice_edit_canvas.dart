import 'dart:math' as math;

import 'package:flutter/material.dart';


import '../../../../l10n/app_localizations.dart';
import '../../../widgets/practice/drag_state_manager.dart';
import '../../../widgets/practice/performance_monitor.dart' as perf;
import '../../../widgets/practice/practice_edit_controller.dart';
import '../../../widgets/practice/smart_canvas_gesture_handler.dart';
import '../helpers/element_utils.dart';
import 'canvas_control_points.dart';
import 'canvas_structure_listener.dart';
import 'content_render_controller.dart';
import 'content_render_layer.dart';
import 'drag_operation_manager.dart';
import 'drag_preview_layer.dart';
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

/// 选择框状态类 - 用于保存和管理选择框的当前状态
class SelectionBoxState {
  final bool isActive;
  final Offset? startPoint;
  final Offset? endPoint;

  SelectionBoxState({
    this.isActive = false,
    this.startPoint,
    this.endPoint,
  });

  SelectionBoxState copyWith({
    bool? isActive,
    Offset? startPoint,
    Offset? endPoint,
  }) {
    return SelectionBoxState(
      isActive: isActive ?? this.isActive,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
    );
  }
}

/// Grid painter
class _GridPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;

  _GridPainter({
    required this.gridSize,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.gridColor != gridColor;
  }
}

class _M3PracticeEditCanvasState extends State<M3PracticeEditCanvas> {
  // Drag state variables
  bool _isDragging = false;
  // ignore: unused_field
  Offset _dragStart = Offset.zero;
  // ignore: unused_field
  Offset _elementStartPosition = Offset.zero;
  final Map<String, Offset> _elementStartPositions = {};
  
  // 手势处理标记：用于控制InteractiveViewer和GestureDetector的竞争
  bool _shouldIgnoreGestureDetector = false;
  
  // 拖拽准备状态：使用普通变量避免setState时序问题
  bool _isReadyForDrag = false;
  // Canvas gesture handler
  late SmartCanvasGestureHandler _gestureHandler;

  // Content render controller for dual-layer architecture
  late ContentRenderController _contentRenderController;
  // Drag state manager for optimized drag handling
  late DragStateManager _dragStateManager;

  // Layer render manager for coordinated layer rendering
  late LayerRenderManager _layerRenderManager;
  // 新增: 分层+元素级混合优化策略核心组件
  // Canvas structure listener for smart layer-specific routing
  late CanvasStructureListener _structureListener;
  // State change dispatcher for unified state management
  late StateChangeDispatcher _stateDispatcher;
  // Drag operation manager for 3-phase drag system
  late DragOperationManager _dragOperationManager;

  // 选择框状态管理 - 使用ValueNotifier<SelectionBoxState>替代原来的布尔值
  final ValueNotifier<SelectionBoxState> _selectionBoxNotifier =
      ValueNotifier(SelectionBoxState());

  // Dedicated GlobalKey for RepaintBoundary (for screenshot functionality)
  // Use the widget's key if provided, otherwise create a new one
  late final GlobalKey _repaintBoundaryKey;

  /// 处理控制点拖拽结束事件
  // 存储原始元素属性，用于撤销/重做
  Map<String, dynamic>? _originalElementProperties;
  bool _isResizing = false;
  bool _isRotating = false;
  bool _hasInitializedView = false; // 防止重复初始化视图
  String? _lastPageKey; // 跟踪页面变化，用于自动重置视图
  // Performance monitoring
  final perf.PerformanceMonitor _performanceMonitor = perf.PerformanceMonitor();
  @override
  Widget build(BuildContext context) {
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

        print('🔄 Canvas: build() called');
        print(
            '🔄 Canvas: Current tool: ${widget.controller.state.currentTool}');
        print(
            '🔄 Canvas: Selected elements: ${widget.controller.state.selectedElementIds.length}');
        print(
            '🔄 Canvas: Total elements: ${widget.controller.state.currentPageElements.length}');
        debugPrint('Canvas rebuild');

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
        print(
            '🔍 Canvas: ListenableBuilder - elements.length = ${elements.length}');
        print(
            '🔍 Canvas: ListenableBuilder - elements.runtimeType = ${elements.runtimeType}');
        if (elements.isNotEmpty) {
          print(
              '🔍 Canvas: ListenableBuilder - first element: ${elements.first}');
        }
        // 用性能覆盖层包装画布
        return perf.PerformanceOverlay(
          showOverlay: DragConfig.showPerformanceOverlay,
          child: _buildPageContent(currentPage, elements, colorScheme),
        );
      },
    );
  }

  @override
  void dispose() {
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
    print('🏗️ Canvas: initState called');

    try {
      // 阶段1: 初始化核心组件
      _initializeCoreComponents();
      
      // 阶段2: 初始化混合优化策略组件
      _initializeOptimizationComponents();
      
      // 阶段3: 建立组件间连接
      _setupComponentConnections();
      
      // 阶段4: 初始化UI和手势处理
      _initializeUIComponents();
      
      print('🏗️ Canvas: 分层+元素级混合优化策略组件初始化完成');
    } catch (e, stackTrace) {
      debugPrint('❌ Canvas: 初始化失败 - $e');
      debugPrint('Stack trace: $stackTrace');
      // 回退到基础模式
      _fallbackToBasicMode();
    }
  }

  /// 初始化核心组件
  void _initializeCoreComponents() {
    // Initialize content render controller for dual-layer architecture
    _contentRenderController = ContentRenderController();
    print('🏗️ Canvas: ContentRenderController initialized');

    // Initialize drag state manager for optimized drag handling
    _dragStateManager = DragStateManager();
    print('🏗️ Canvas: DragStateManager initialized');

    // Initialize layer render manager for coordinated layer rendering
    _layerRenderManager = LayerRenderManager();
    print('🏗️ Canvas: LayerRenderManager initialized');
  }

  /// 初始化优化策略组件
  void _initializeOptimizationComponents() {
    // Initialize canvas structure listener for smart layer-specific routing
    _structureListener = CanvasStructureListener(widget.controller);
    print('🏗️ Canvas: CanvasStructureListener initialized');

    // Initialize state change dispatcher for unified state management
    _stateDispatcher = StateChangeDispatcher(widget.controller, _structureListener);

    // Set the state dispatcher in the controller for layered state management
    widget.controller.setStateDispatcher(_stateDispatcher);
    print('🏗️ Canvas: StateChangeDispatcher initialized and connected to controller');

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

  /// 建立组件间连接
  void _setupComponentConnections() {
    // 将拖拽状态管理器与性能监控系统关联
    _performanceMonitor.setDragStateManager(_dragStateManager);
    print('🏗️ Canvas: Connected DragStateManager with PerformanceMonitor');

    // 将拖拽状态管理器与内容渲染控制器关联
    _contentRenderController.setDragStateManager(_dragStateManager);
    print('🏗️ Canvas: Connected DragStateManager with ContentRenderController');

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

  /// 初始化UI组件
  void _initializeUIComponents() {
    // Initialize RepaintBoundary key - always create a new key for screenshot functionality
    _repaintBoundaryKey = GlobalKey();

    // 初始化手势处理器 (需要在所有其他组件初始化后)
    _initializeGestureHandler();
    print('🏗️ Canvas: GestureHandler initialized');

    // 临时禁用画布注册，避免潜在的循环调用问题
    // Register this canvas with the controller for reset view functionality
    // widget.controller.setEditCanvas(this);

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

  /// 回退到基础模式（禁用优化功能）
  void _fallbackToBasicMode() {
    try {
      // 只初始化最基础的组件
      _contentRenderController = ContentRenderController();
      _dragStateManager = DragStateManager();
      _layerRenderManager = LayerRenderManager();
      _repaintBoundaryKey = GlobalKey();
      
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

  /// 检查是否可能需要处理任何特殊手势（用于决定是否设置pan手势回调）
  /// 检查是否需要设置手势回调（更保守的策略）
  bool _shouldHandleAnySpecialGesture(List<Map<String, dynamic>> elements) {
    // 如果在预览模式，不处理任何手势
    if (widget.controller.state.isPreviewMode) {
      return false;
    }

    // 如果在select模式下，需要处理选择框
    if (widget.controller.state.currentTool == 'select') {
      return true;
    }

    // 如果正在进行拖拽操作，需要处理
    if (_isDragging || _dragStateManager.isDragging) {
      return true;
    }

    // 只有在有选中元素时才可能需要处理元素拖拽
    // 这里先返回true，在回调中再精确判断
    if (widget.controller.state.selectedElementIds.isNotEmpty) {
      return true;
    }

    // 其他情况让InteractiveViewer完全接管
    return false;
  }

  /// 检查是否需要处理特殊手势（元素拖拽、选择框）
  bool _shouldHandleSpecialGesture(DragStartDetails details, List<Map<String, dynamic>> elements) {
    debugPrint('🔍【_shouldHandleSpecialGesture】开始检查 - 当前选中元素: ${widget.controller.state.selectedElementIds.length}');
    
    // 如果在预览模式，不处理任何手势
    if (widget.controller.state.isPreviewMode) {
      debugPrint('🔍【_shouldHandleSpecialGesture】预览模式，不处理手势');
      return false;
    }

    // 1. 首先检查是否点击在已选中的元素上（元素拖拽 - 在任何工具模式下都可以）
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      final id = element['id'] as String;
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      // Check if element is hidden
      if (element['hidden'] == true) continue;

      // Check if layer is hidden
      final layerId = element['layerId'] as String?;
      bool isLayerHidden = false;
      if (layerId != null) {
        final layer = widget.controller.state.getLayerById(layerId);
        if (layer != null) {
          isLayerHidden = layer['isVisible'] == false;
        }
      }
      if (isLayerHidden) continue;

      // Check if clicking inside element
      final bool isInside = details.localPosition.dx >= x &&
          details.localPosition.dx <= x + width &&
          details.localPosition.dy >= y &&
          details.localPosition.dy <= y + height;

      if (isInside && widget.controller.state.selectedElementIds.contains(id)) {
        // 点击在已选中的元素上，需要处理元素拖拽（任何工具模式下都可以）
        debugPrint('【手势检测】点击在已选中元素上，需要处理元素拖拽: $id (工具: ${widget.controller.state.currentTool})');
        debugPrint('🔍【_shouldHandleSpecialGesture】检测到元素拖拽需求 - 当前选中元素: ${widget.controller.state.selectedElementIds.length}');
        return true;
      }
    }

    // 2. 如果在select模式下，处理选择框（框选模式）
    if (widget.controller.state.currentTool == 'select') {
      debugPrint('【手势检测】在select模式下，需要处理选择框（框选模式）');
      debugPrint('🔍【_shouldHandleSpecialGesture】检测到选择框需求');
      return true;
    }

    // 3. 其他情况不处理，让InteractiveViewer处理画布平移
    debugPrint('【手势检测】让InteractiveViewer处理画布平移');
    debugPrint('🔍【_shouldHandleSpecialGesture】无特殊手势需求');
    return false;
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

    debugPrint(
        'Rotating element $elementId: delta=$delta, rotationDelta=$rotationDelta, newRotation=$newRotation'); // Update rotation
    widget.controller
        .updateElementProperties(elementId, {'rotation': newRotation});
  }

  void resetCanvasPosition() {
    _resetCanvasPosition();
  }

  /// 切换性能监控覆盖层显示
  void togglePerformanceOverlay() {
    setState(() {
      DragConfig.showPerformanceOverlay = !DragConfig.showPerformanceOverlay;
      debugPrint('性能覆盖层显示: ${DragConfig.showPerformanceOverlay ? '开启' : '关闭'}');
    });
  }

  /// 为所有选中的元素应用网格吸附  /// 为选中的元素应用网格吸附（只在拖拽结束时调用）
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

      if (element.isEmpty) continue;

      // 跳过锁定的元素
      final isLocked = element['locked'] as bool? ?? false;
      if (isLocked) continue;

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
        debugPrint(
            '网格吸附: 元素 $elementId 位置从 ($x, $y) 吸附到 ($snappedX, $snappedY)');

        widget.controller.updateElementProperties(elementId, {
          'x': snappedX,
          'y': snappedY,
        });
      }
    }
  }

  /// Build background layer (grid, page background)
  Widget _buildBackgroundLayer(LayerConfig config) {
    final currentPage = widget.controller.state.currentPage;
    if (currentPage == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Color(currentPage['backgroundColor'] as int? ?? Colors.white.value),
      ),
      child: widget.controller.state.gridVisible
          ? CustomPaint(
              painter: _GridPainter(
                gridSize: widget.controller.state.gridSize,
                gridColor: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
              ),
              child: Container(),
            )
          : null,
    );
  }

  /// Build content layer (elements rendering)
  Widget _buildContentLayer(LayerConfig config) {
    final currentPage = widget.controller.state.currentPage;
    final elements = widget.controller.state.currentPageElements;

    if (currentPage == null) {
      return const SizedBox.shrink();
    }

    final pageSize = ElementUtils.calculatePixelSize(currentPage);
    Color backgroundColor = Colors.white;

    try {
      final background = currentPage['background'] as Map<String, dynamic>?;
      if (background != null && background['type'] == 'color') {
        final colorStr = background['value'] as String? ?? '#FFFFFF';
        backgroundColor = ElementUtils.parseColor(colorStr);
      }
    } catch (e) {
      debugPrint('Error parsing background color: $e');
    }
    
    return ContentRenderLayer.withFullParams(
      elements: elements,
      layers: widget.controller.state.layers,
      renderController: _contentRenderController,
      isPreviewMode: widget.isPreviewMode,
      pageSize: pageSize,
      backgroundColor: backgroundColor,
      selectedElementIds: widget.controller.state.selectedElementIds.toSet(),
    );
  }

  /// Build control points for selected element
  Widget _buildControlPoints(
    String elementId,
    double x,
    double y,
    double width,
    double height,
    double rotation,
  ) {
    // 添加日志，跟踪控制点构建
    debugPrint(
        '⚙️ 构建控制点 - 元素ID: $elementId, 类型: ${widget.controller.state.selectedElement?['type'] ?? '未知'}, 坐标: ($x, $y), 尺寸: ${width}x$height, 旋转: $rotation');
    // Use absolute positioning for control points to ensure they're always visible
    return AbsorbPointer(
      absorbing: false, // Ensure control points can receive events
      child: GestureDetector(
        // onTapDown: (details) {},
        // onTap: () {
        //   // Clear selection when tapping on empty area
        //   // widget.controller.clearSelection();
        // },
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Transparent overlay to ensure control points receive events
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ), // Actual control points
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                bottom: 0,
                child: RepaintBoundary(
                  key: ValueKey(
                      'control_points_repaint_${elementId}_${(x * 1000).toInt()}_${(y * 1000).toInt()}_${(width * 100).toInt()}_${(height * 100).toInt()}'),
                  child: Builder(builder: (context) {
                    // 获取当前缩放值
                    final scale = widget.transformationController.value
                        .getMaxScaleOnAxis();
                    return CanvasControlPoints(
                      key: ValueKey(
                          'control_points_${elementId}_${scale.toStringAsFixed(2)}'),
                      elementId: elementId,
                      x: x,
                      y: y,
                      width: width,
                      height: height,
                      rotation: rotation,
                      initialScale:
                          scale, // Pass the current scale to ensure proper control point sizing
                      onControlPointUpdate: _handleControlPointUpdate,
                      onControlPointDragEnd: _handleControlPointDragEnd,
                      onControlPointDragStart: _handleControlPointDragStart,
                    );
                  }),
                ),
              ),

              // Add a transparent overlay to ensure control points can immediately respond to events
              Positioned.fill(
                child: IgnorePointer(
                  ignoring:
                      true, // Ignore pointer events, let control points receive events
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build drag preview layer
  Widget _buildDragPreviewLayer(LayerConfig config) {
    if (!config.shouldRender ||
        !DragConfig.enableDragPreview ||
        widget.isPreviewMode) {
      return const SizedBox.shrink();
    }

    return DragPreviewLayer(
      dragStateManager: _dragStateManager,
      elements: widget.controller.state.currentPageElements,
    );
  }

  /// Build interaction layer (selection box, control points)
  Widget _buildInteractionLayer(LayerConfig config) {
    if (!config.shouldRender || widget.isPreviewMode) {
      return const SizedBox.shrink();
    }

    // Get selected element for control points
    String? selectedElementId;
    double x = 0, y = 0, width = 0, height = 0, rotation = 0;
    final elements = widget.controller.state.currentPageElements;

    if (widget.controller.state.selectedElementIds.length == 1) {
      selectedElementId = widget.controller.state.selectedElementIds.first;
      final selectedElement = elements.firstWhere(
        (e) => e['id'] == selectedElementId,
        orElse: () => <String, dynamic>{},
      );

      if (selectedElement.isNotEmpty) {
        x = (selectedElement['x'] as num?)?.toDouble() ?? 0.0;
        y = (selectedElement['y'] as num?)?.toDouble() ?? 0.0;
        width = (selectedElement['width'] as num?)?.toDouble() ?? 0.0;
        height = (selectedElement['height'] as num?)?.toDouble() ?? 0.0;
        rotation = (selectedElement['rotation'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Selection box
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              key: const ValueKey('selection_box_repaint_boundary'),
              child: ValueListenableBuilder<SelectionBoxState>(
                valueListenable: _selectionBoxNotifier,
                builder: (context, selectionBoxState, child) {
                  if (widget.controller.state.currentTool == 'select' &&
                      selectionBoxState.isActive &&
                      selectionBoxState.startPoint != null &&
                      selectionBoxState.endPoint != null) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _SelectionBoxPainter(
                        startPoint: selectionBoxState.startPoint!,
                        endPoint: selectionBoxState.endPoint!,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
        // Control points
        if (selectedElementId != null)
          Positioned.fill(
            child: _buildControlPoints(
                selectedElementId, x, y, width, height, rotation),
          ),
      ],
    );
  }

  /// Build widget for specific layer type
  Widget _buildLayerWidget(RenderLayerType layerType, LayerConfig config) {
    switch (layerType) {
      case RenderLayerType.staticBackground:
        return _buildBackgroundLayer(config);
      case RenderLayerType.content:
        return _buildContentLayer(config);
      case RenderLayerType.dragPreview:
        return _buildDragPreviewLayer(config);
      case RenderLayerType.interaction:
        return _buildInteractionLayer(config);
      case RenderLayerType.uiOverlay:
        return _buildUIOverlayLayer(config);
    }
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

    print(
        '🔍 Canvas: Selected elements count: ${widget.controller.state.selectedElementIds.length}');
    debugPrint(
        '🔍 构建页面内容 - 选中元素数: ${widget.controller.state.selectedElementIds.length}');
    
    // Calculate page dimensions for layout purposes
    final pageSize = ElementUtils.calculatePixelSize(page);

    // 🔧 检测页面尺寸变化并自动重置视图
    final pageKey = '${page['width']}_${page['height']}_${page['orientation']}_${page['dpi']}';
    if (_lastPageKey != null && _lastPageKey != pageKey) {
      debugPrint('🔧【页面变化检测】页面尺寸改变: $_lastPageKey -> $pageKey');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitPageToScreen();
          debugPrint('🔧【页面变化检测】自动重置视图位置');
        }
      });
    }
    _lastPageKey = pageKey;

    // 🔥 关键修复：移除每次build时的自动变换设置
    // 不再在build方法中强制设置transformationController和调用zoomTo
    // 这些操作现在只在真正需要时进行（如初始化、重置按钮）
    
    debugPrint('🔧【_buildPageContent】保持当前变换状态，不强制重置');

    // Get current zoom level for status bar (calculated dynamically each time)  
    final currentZoomScale = widget.transformationController.value.getMaxScaleOnAxis();
    final zoomPercentage = (currentZoomScale * 100).toInt();

    return Stack(
      children: [
        Container(
          color: colorScheme.inverseSurface.withAlpha(26), // Canvas outer background
          // 使用RepaintBoundary包装InteractiveViewer，防止缩放和平移触发整个画布重建
          child: RepaintBoundary(
            key: const ValueKey('interactive_viewer_repaint_boundary'),
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(double.infinity),
              // 在元素拖拽时禁用InteractiveViewer的平移，避免手势冲突
              panEnabled: !(_isDragging || _dragStateManager.isDragging),
              scaleEnabled: true,
              minScale: 0.1,
              maxScale: 15.0,
              scaleFactor: 600.0, // Increased scale factor to make zooming more gradual
              transformationController: widget.transformationController,
              onInteractionStart: (ScaleStartDetails details) {},
              onInteractionUpdate: (ScaleUpdateDetails details) {
                // Status bar uses real-time calculation, no setState needed during update
              },
              onInteractionEnd: (ScaleEndDetails details) {
                // Update final zoom value through controller
                final scale = widget.transformationController.value.getMaxScaleOnAxis();
                widget.controller.zoomTo(scale);
                // Status bar uses real-time calculation, no explicit setState needed
              },
              constrained: false, // Allow content to be unconstrained
              child: Listener(
                onPointerDown: (_) {
                  // Add this empty listener to properly initialize mouse tracking
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    debugPrint('🔥【onTapDown】检测点击位置 - 坐标: ${details.localPosition}');
                    // 检查是否点击在选中元素上，如果是，准备拖拽
                    // 直接设置变量，避免setState时序问题
                    if (_shouldHandleSpecialGesture(DragStartDetails(localPosition: details.localPosition), elements)) {
                      debugPrint('🔥【onTapDown】点击在选中元素上，准备拖拽');
                      _isReadyForDrag = true;
                    } else {
                      debugPrint('🔥【onTapDown】点击在空白区域');
                      _isReadyForDrag = false;
                    }
                  },
                  onTapUp: (details) {
                    // 重置拖拽准备状态
                    _isReadyForDrag = false;
                    _gestureHandler.handleTapUp(details, elements.cast<Map<String, dynamic>>());
                  },
                  // 处理右键点击事件，用于退出select模式
                  onSecondaryTapDown: (details) =>
                      _gestureHandler.handleSecondaryTapDown(details),
                  onSecondaryTapUp: (details) =>
                      _gestureHandler.handleSecondaryTapUp(
                          details, elements.cast<Map<String, dynamic>>()),
                  // 智能手势处理：只在需要时设置回调
                  onPanStart: _shouldHandleAnySpecialGesture(elements) ? (details) {
                    debugPrint('🔍【onPanStart】回调被调用 - 当前选中元素: ${widget.controller.state.selectedElementIds.length}');
                    
                    // 动态检查是否需要处理特殊手势（元素拖拽、选择框等）
                    if (_shouldHandleSpecialGesture(details, elements)) {
                      debugPrint('🔍【onPanStart】需要特殊处理，调用SmartCanvasGestureHandler');
                      _gestureHandler.handlePanStart(
                          details, elements.cast<Map<String, dynamic>>());
                    } else if (widget.controller.state.currentTool == 'select') {
                      debugPrint('🔍【onPanStart】select模式，处理选择框');
                      _gestureHandler.handlePanStart(
                          details, elements.cast<Map<String, dynamic>>());
                    } else {
                      debugPrint('🔍【onPanStart】点击空白区域，不处理，让InteractiveViewer处理画布平移');
                      // 不调用手势处理器，让InteractiveViewer接管
                    }
                  } : null,
                  onPanUpdate: _shouldHandleAnySpecialGesture(elements) ? (details) {
                    // 先处理选择框更新，这优先级最高
                    if (widget.controller.state.currentTool == 'select' &&
                        _gestureHandler.isSelectionBoxActive) {
                      _gestureHandler.handlePanUpdate(details);
                      _selectionBoxNotifier.value = SelectionBoxState(
                        isActive: true,
                        startPoint: _gestureHandler.selectionBoxStart,
                        endPoint: _gestureHandler.selectionBoxEnd,
                      );
                      return;
                    }

                    // Handle element dragging - 检查DragStateManager的拖拽状态
                    if (_isDragging || _dragStateManager.isDragging || 
                        (_isReadyForDrag && widget.controller.state.selectedElementIds.isNotEmpty)) {
                      _gestureHandler.handlePanUpdate(details);
                      debugPrint('【元素拖拽】SmartCanvasGestureHandler正在处理元素拖拽');
                      return;
                    }
                    
                    // 如果不需要特殊处理，则不调用手势处理器，让InteractiveViewer处理
                    debugPrint('🔍【onPanUpdate】不处理，让InteractiveViewer处理画布平移');
                  } : null,
                  onPanEnd: _shouldHandleAnySpecialGesture(elements) ? (details) {
                    // 检查是否需要处理手势结束
                    bool shouldHandleEnd = _gestureHandler.isSelectionBoxActive || 
                                         _isDragging || 
                                         _dragStateManager.isDragging ||
                                         _isReadyForDrag;

                    // 重置拖拽准备状态
                    _isReadyForDrag = false;

                    // 只有在真正处理了手势的情况下才调用handlePanEnd
                    if (shouldHandleEnd) {
                      // 重置选择框状态
                      if (widget.controller.state.currentTool == 'select' &&
                          _gestureHandler.isSelectionBoxActive) {
                        _selectionBoxNotifier.value = SelectionBoxState();
                      }
                      _gestureHandler.handlePanEnd(details);
                    }
                  } : null,
                  onPanCancel: _shouldHandleAnySpecialGesture(elements) ? () {
                    // 检查是否需要处理手势取消
                    bool shouldHandleCancel = _gestureHandler.isSelectionBoxActive || 
                                            _isDragging || 
                                            _dragStateManager.isDragging ||
                                            _isReadyForDrag;

                    // 重置拖拽准备状态
                    _isReadyForDrag = false;

                    // 只有在真正处理了手势的情况下才调用handlePanCancel
                    if (shouldHandleCancel) {
                      // 重置选择框状态
                      if (widget.controller.state.currentTool == 'select' &&
                          _gestureHandler.isSelectionBoxActive) {
                        _selectionBoxNotifier.value = SelectionBoxState();
                      }
                      _gestureHandler.handlePanCancel();
                    }
                  } : null,
                                    child: Container(
                    width: pageSize.width,
                    height: pageSize.height,
                    // 临时调试：添加红色边框，看看页面实际渲染区域
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Builder(
                      builder: (context) {
                        // 添加调试信息，检查页面容器的实际渲染尺寸
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            final RenderBox? containerBox = context.findRenderObject() as RenderBox?;
                            if (containerBox != null) {
                              final containerSize = containerBox.size;
                              debugPrint('🔧【页面容器】实际渲染尺寸: ${containerSize.width.toStringAsFixed(1)}x${containerSize.height.toStringAsFixed(1)}, 期望尺寸: ${pageSize.width.toStringAsFixed(1)}x${pageSize.height.toStringAsFixed(1)}');
                              
                              // 获取容器在屏幕中的位置
                              final containerOffset = containerBox.localToGlobal(Offset.zero);
                              debugPrint('🔧【页面容器】屏幕位置: (${containerOffset.dx.toStringAsFixed(1)}, ${containerOffset.dy.toStringAsFixed(1)})');
                            }
                          }
                                                 });
                                                   return Stack(
                          fit: StackFit.expand, // Use expand to fill the container
                          clipBehavior:
                              Clip.none, // Allow control points to extend beyond page boundaries
                          children: [
                            // Use LayerRenderManager to build coordinated layer stack
                            RepaintBoundary(
                              key: _repaintBoundaryKey, // Use dedicated key for RepaintBoundary
                              child: _layerRenderManager.buildLayerStack(
                                layerOrder: [
                                  RenderLayerType.staticBackground,
                                  RenderLayerType.content,
                                  RenderLayerType.dragPreview,
                                  RenderLayerType.interaction,
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
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
                    message: AppLocalizations.of(context).canvasResetViewTooltip,
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
                                    AppLocalizations.of(context).canvasResetView,
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

  /// Build UI overlay layer (for future use)
  Widget _buildUIOverlayLayer(LayerConfig config) {
    return const SizedBox.shrink();
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
    debugPrint('🔧【Reset View】页面信息: currentPage = ${currentPage['width']}x${currentPage['height']}, 计算出的pageSize = ${pageSize.width}x${pageSize.height}');
    
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
        debugPrint('🔧【Reset View】验证变换应用结果: appliedScale=${appliedScale.toStringAsFixed(3)}, appliedTranslation=(${appliedTranslation.x.toStringAsFixed(1)}, ${appliedTranslation.y.toStringAsFixed(1)})');
        
        if ((appliedScale - scale).abs() > 0.001 || 
            (appliedTranslation.x - dx).abs() > 1 || 
            (appliedTranslation.y - dy).abs() > 1) {
          debugPrint('⚠️【Reset View】变换应用不正确！期望 scale=${scale.toStringAsFixed(3)}, translation=(${dx.toStringAsFixed(1)}, ${dy.toStringAsFixed(1)})');
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

    debugPrint('🔧【Reset View】预期效果: 让整个页面在可视区域内居中显示，scale=${scale.toStringAsFixed(3)}');
  }

  /// 处理控制点拖拽结束事件
  void _handleControlPointDragEnd(int controlPointIndex) {
    debugPrint('控制点 $controlPointIndex 拖拽结束');

    if (widget.controller.state.selectedElementIds.isEmpty ||
        _originalElementProperties == null) {
      return;
    }

    final elementId = widget.controller.state.selectedElementIds.first;

    // 获取当前元素属性
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    // 处理旋转控制点
    if (_isRotating) {
      debugPrint('旋转控制点拖拽结束');

      // 获取原始旋转值和当前旋转值
      final oldRotation =
          (_originalElementProperties!['rotation'] as num?)?.toDouble() ?? 0.0;
      final newRotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

      // 如果旋转值有变化，创建旋转操作
      if (oldRotation != newRotation) {
        widget.controller.createElementRotationOperation(
          elementIds: [elementId],
          oldRotations: [oldRotation],
          newRotations: [newRotation],
        );
      }

      _isRotating = false;
      _originalElementProperties = null;
      return;
    }

    // 处理调整大小控制点
    if (_isResizing) {
      // 创建旧尺寸对象
      final oldSize = {
        'x': (_originalElementProperties!['x'] as num).toDouble(),
        'y': (_originalElementProperties!['y'] as num).toDouble(),
        'width': (_originalElementProperties!['width'] as num).toDouble(),
        'height': (_originalElementProperties!['height'] as num).toDouble(),
      };

      // 创建新尺寸对象
      final newSize = {
        'x': (element['x'] as num).toDouble(),
        'y': (element['y'] as num).toDouble(),
        'width': (element['width'] as num).toDouble(),
        'height': (element['height'] as num).toDouble(),
      };

      // 只有在尺寸或位置有变化时才创建操作
      if (oldSize['x'] != newSize['x'] ||
          oldSize['y'] != newSize['y'] ||
          oldSize['width'] != newSize['width'] ||
          oldSize['height'] != newSize['height']) {
        // 只有在启用了网格吸附的情况下才进行网格吸附
        if (widget.controller.state.snapEnabled) {
          final gridSize = widget.controller.state.gridSize;

          // 计算吸附后的位置和尺寸（向最近的网格线吸附）
          final snappedX = (newSize['x']! / gridSize).round() * gridSize;
          final snappedY = (newSize['y']! / gridSize).round() * gridSize;
          final snappedWidth =
              (newSize['width']! / gridSize).round() * gridSize;
          final snappedHeight =
              (newSize['height']! / gridSize).round() * gridSize;

          // 确保尺寸不小于最小值
          final finalWidth = math.max(snappedWidth, 10.0);
          final finalHeight = math.max(snappedHeight, 10.0);

          // 更新为吸附后的值
          newSize['x'] = snappedX;
          newSize['y'] = snappedY;
          newSize['width'] = finalWidth;
          newSize['height'] = finalHeight;

          // 直接应用网格吸附更新
          element['x'] = snappedX;
          element['y'] = snappedY;
          element['width'] = finalWidth;
          element['height'] = finalHeight;

          debugPrint(
              '网格吸附: 元素 $elementId 位置从 (${oldSize['x']}, ${oldSize['y']}) 吸附到 ($snappedX, $snappedY)');
          debugPrint(
              '网格吸附: 元素 $elementId 尺寸从 (${oldSize['width']}, ${oldSize['height']}) 吸附到 ($finalWidth, $finalHeight)');
        }

        // 创建调整大小操作
        widget.controller.createElementResizeOperation(
          elementIds: [elementId],
          oldSizes: [oldSize],
          newSizes: [newSize],
        );

        // 确保UI更新
        widget.controller.notifyListeners();
      }

      _isResizing = false;
      _originalElementProperties = null;
    }
  }

  /// 处理控制点拖拽开始事件
  void _handleControlPointDragStart(int controlPointIndex) {
    debugPrint('控制点 $controlPointIndex 拖拽开始');

    if (widget.controller.state.selectedElementIds.isEmpty) {
      return;
    }

    final elementId = widget.controller.state.selectedElementIds.first;

    // 获取当前元素属性并保存，用于稍后创建撤销操作
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    // 保存元素的原始属性
    _originalElementProperties = Map<String, dynamic>.from(element);

    // 记录当前是调整大小还是旋转
    _isRotating = (controlPointIndex == 8);
    _isResizing = !_isRotating;

    debugPrint('保存元素 $elementId 的原始属性: $_originalElementProperties');
  }

  /// Handle control point updates
  void _handleControlPointUpdate(int controlPointIndex, Offset delta) {
    // 获取当前缩放比例
    final scale = widget.transformationController.value.getMaxScaleOnAxis();

    // 调整增量，考虑当前缩放比例
    // 注意：在高缩放比例下，小的物理移动会导致很小的逻辑移动，
    // 而在低缩放比例下，相同的物理移动会导致较大的逻辑移动
    final adjustedDelta = Offset(delta.dx / scale, delta.dy / scale);
    delta = adjustedDelta;

    if (widget.controller.state.selectedElementIds.isEmpty) {
      return;
    }

    final elementId = widget.controller.state.selectedElementIds.first;

    // Get current element properties
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );
    if (element.isEmpty) {
      return;
    } // Recreate the SnapManager with current settings
    // _snapManager.updateSettings(
    //   gridSize: widget.controller.state.gridSize,
    //   enabled: widget.controller.state.snapEnabled,
    //   snapThreshold: 10.0,
    // );

    // Check if element's layer is locked
    final layerId = element['layerId'] as String?;
    if (layerId != null && widget.controller.state.isLayerLocked(layerId)) {
      return; // Skip if layer is locked
    }

    // Check if element itself is locked
    final isLocked = element['locked'] as bool? ?? false;
    if (isLocked) {
      debugPrint('跳过控制点更新：元素已锁定 id=$elementId');
      return; // Skip if element is locked
    }

    try {
      // Process control point update immediately
      if (controlPointIndex == 8) {
        // Rotation control point
        _handleRotation(elementId, delta);
      } else {
        // Resize control point
        _handleResize(elementId, controlPointIndex, delta);
      }
    } catch (e) {
      debugPrint('Control point update failed: $e');
    }
  }

  /// Handle element resize
  void _handleResize(String elementId, int controlPointIndex, Offset delta) {
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    // Get current element properties
    double x = (element['x'] as num).toDouble();
    double y = (element['y'] as num).toDouble();
    double width = (element['width'] as num).toDouble();
    double height = (element['height'] as num).toDouble();
    double rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    debugPrint(
        '调整元素大小: 控制点=$controlPointIndex, delta=$delta, 当前属性: x=$x, y=$y, width=$width, height=$height, rotation=$rotation');

    // 如果元素有旋转，我们需要考虑旋转后的坐标系中的调整
    // 但为了简化，我们先在原始坐标系中进行调整

    // 根据控制点索引计算新的位置和大小
    switch (controlPointIndex) {
      case 0: // 左上角
        x += delta.dx;
        y += delta.dy;
        width -= delta.dx;
        height -= delta.dy;
        break;
      case 1: // 上中
        y += delta.dy;
        height -= delta.dy;
        break;
      case 2: // 右上角
        y += delta.dy;
        width += delta.dx;
        height -= delta.dy;
        break;
      case 3: // 右中
        width += delta.dx;
        break;
      case 4: // 右下角
        width += delta.dx;
        height += delta.dy;
        break;
      case 5: // 下中
        height += delta.dy;
        break;
      case 6: // 左下角
        x += delta.dx;
        width -= delta.dx;
        height += delta.dy;
        break;
      case 7: // 左中
        x += delta.dx;
        width -= delta.dx;
        break;
    } // 确保最小尺寸
    width = width.clamp(10.0, double.infinity);
    height =
        height.clamp(10.0, double.infinity); // 注释掉拖拽过程中的平滑吸附，改为只在拖拽结束时应用网格吸附
    // 应用平滑吸附 - 使用SnapManager
    // if (widget.controller.state.snapEnabled) {
    //   // 确保使用最新的网格设置更新SnapManager
    //   _snapManager.updateSettings(
    //     gridSize: widget.controller.state.gridSize,
    //     enabled: widget.controller.state.snapEnabled,
    //     snapThreshold: 10.0,
    //   );

    //   // 创建一个临时的元素位置供SnapManager使用
    //   final tempElement = {
    //     'id': elementId,
    //     'x': x,
    //     'y': y,
    //     'width': width,
    //     'height': height,
    //   }; // 应用平滑吸附到网格 - 在拖拽过程中使用 snapFactor=0.3 实现平滑效果
    //   final snappedPosition = _snapManager.snapPosition(
    //     Offset(x, y),
    //     [tempElement],
    //     elementId,
    //     isDragging: true,
    //     snapFactor: 0.3,
    //   );

    //   // 确保位置有变化 - 避免卡住不动
    //   if ((snappedPosition.dx - x).abs() > 0.001 ||
    //       (snappedPosition.dy - y).abs() > 0.001) {
    //     // 更新位置，但保持原来计算的宽高
    //     x = snappedPosition.dx;
    //     y = snappedPosition.dy;

    //     debugPrint('吸附后的位置: x=$x, y=$y');
    //   } else {
    //     debugPrint('跳过吸附: 位置变化太小');
    //   }
    // }

    // 更新元素属性
    final updates = {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };

    debugPrint('更新元素属性: $updates');
    widget.controller.updateElementProperties(elementId, updates);
  }

  /// Handle element rotation
  void _handleRotation(String elementId, Offset delta) {
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

    debugPrint(
        'Rotating element $elementId: delta=$delta, rotationDelta=$rotationDelta, newRotation=$newRotation'); // Update rotation
    widget.controller
        .updateElementProperties(elementId, {'rotation': newRotation});
  } // Removed unused _handleTransformationChange method

  /// 初始化手势处理器
  void _initializeGestureHandler() {
    _gestureHandler = SmartCanvasGestureHandler(
      controller: widget.controller,
      dragStateManager: _dragStateManager,
      onDragStart:
          (isDragging, dragStart, elementPosition, elementPositions) async {
        debugPrint('🎯【OnDragStart】开始 - 当前选中元素: ${widget.controller.state.selectedElementIds.length}');
        
        setState(() {
          _isDragging = isDragging;
          _dragStart = dragStart;
          _elementStartPosition = elementPosition;
        });

        debugPrint('🎯【OnDragStart】setState后 - 当前选中元素: ${widget.controller.state.selectedElementIds.length}');

        // 使用新的DragOperationManager处理拖拽开始
        if (isDragging &&
            widget.controller.state.selectedElementIds.isNotEmpty) {
          debugPrint('🎯【OnDragStart】启动DragOperationManager前 - 当前选中元素: ${widget.controller.state.selectedElementIds.length}');
          
          final success = await _dragOperationManager.startDragOperation(
            DragStartInfo(
              elementIds: widget.controller.state.selectedElementIds.toList(),
              startPosition: dragStart,
            ),
          );

          debugPrint('🎯【OnDragStart】DragOperationManager启动后 - 成功: $success, 当前选中元素: ${widget.controller.state.selectedElementIds.length}');

          if (success) {
            debugPrint('🎯 拖拽操作成功启动');
          } else {
            debugPrint('🎯 拖拽操作启动失败');
          }

          // Notify content render controller about potential changes
          for (final elementId in widget.controller.state.selectedElementIds) {
            final element =
                widget.controller.state.currentPageElements.firstWhere(
              (e) => e['id'] == elementId,
              orElse: () => <String, dynamic>{},
            );
            if (element.isNotEmpty) {
              _contentRenderController.initializeElement(
                elementId: elementId,
                properties: element,
              );
            }
          }
        } else {
          debugPrint('🎯【OnDragStart】跳过DragOperationManager - isDragging: $isDragging, 选中元素数: ${widget.controller.state.selectedElementIds.length}');
        }
        
        debugPrint('🎯【OnDragStart】结束 - 当前选中元素: ${widget.controller.state.selectedElementIds.length}');
      },
      onDragUpdate: () {
        // 如果是选择框更新，使用ValueNotifier而不是setState
        if (_gestureHandler.isSelectionBoxActive) {
          _selectionBoxNotifier.value = SelectionBoxState(
            isActive: _gestureHandler.isSelectionBoxActive,
            startPoint: _gestureHandler.selectionBoxStart,
            endPoint: _gestureHandler.selectionBoxEnd,
          );
        } else {
          // 对于元素拖拽，使用ContentRenderController通知而不是setState
          if (widget.controller.state.selectedElementIds.isNotEmpty) {
            for (final elementId
                in widget.controller.state.selectedElementIds) {
              final element =
                  widget.controller.state.currentPageElements.firstWhere(
                (e) => e['id'] == elementId,
                orElse: () => <String, dynamic>{},
              );
              if (element.isNotEmpty) {
                _contentRenderController.notifyElementChanged(
                  elementId: elementId,
                  newProperties: element,
                );
              }
            }
          }
        }
      },
      onDragEnd: () async {
        setState(() {
          _isDragging = false;
        });

        // 处理元素平移后的网格吸附
        _applyGridSnapToSelectedElements();

        // Notify content render controller about element changes after drag
        if (widget.controller.state.selectedElementIds.isNotEmpty) {
          for (final elementId in widget.controller.state.selectedElementIds) {
            final element =
                widget.controller.state.currentPageElements.firstWhere(
              (e) => e['id'] == elementId,
              orElse: () => <String, dynamic>{},
            );
            if (element.isNotEmpty) {
              _contentRenderController.notifyElementChanged(
                elementId: elementId,
                newProperties: element,
              );
            }
          }
        }
      },
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



  /// Reset canvas position to fit the page content within the viewport
  void _resetCanvasPosition() {
    _fitPageToScreen();
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
}

/// Custom painter for selection box
class _SelectionBoxPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Color color;

  _SelectionBoxPainter({
    required this.startPoint,
    required this.endPoint,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    // 创建选择框的矩形
    final rect = Rect.fromPoints(startPoint, endPoint);

    // 创建虚线效果的画笔
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 绘制选择框
    canvas.drawRect(rect, paint);

    // 添加半透明填充
    final fillPaint = Paint()
      ..color = color.withValues(alpha: .1)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, fillPaint);
  }

  @override
  bool shouldRepaint(_SelectionBoxPainter oldDelegate) {
    return startPoint != oldDelegate.startPoint ||
        endPoint != oldDelegate.endPoint ||
        color != oldDelegate.color;
  }
}
