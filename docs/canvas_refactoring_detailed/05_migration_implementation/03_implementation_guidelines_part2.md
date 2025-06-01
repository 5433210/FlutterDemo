# Canvas 重构实现指南与最佳实践 (第二部分)

## 3. 代码实现最佳实践 (续)

### 3.2 状态管理

**实践原则**：
- 使用 ChangeNotifier 实现细粒度状态变更通知
- 状态对象分割为多个子状态，减少无关更新
- 状态更新仅通过专用方法执行，避免直接修改
- 提供状态流以支持响应式编程模式

**示例**：

```dart
// 状态管理器实现
class CanvasStateManager extends ChangeNotifier {
  // 子状态管理器
  final ElementState elementState;
  final SelectionState selectionState;
  final ViewportState viewportState;
  final ToolState toolState;
  
  CanvasStateManager({
    ElementState? elementState,
    SelectionState? selectionState,
    ViewportState? viewportState,
    ToolState? toolState,
  }) : 
    this.elementState = elementState ?? ElementState(),
    this.selectionState = selectionState ?? SelectionState(),
    this.viewportState = viewportState ?? ViewportState(),
    this.toolState = toolState ?? ToolState() {
    
    // 监听子状态变化
    this.elementState.addListener(_notifyListeners);
    this.selectionState.addListener(_notifyListeners);
    this.viewportState.addListener(_notifyListeners);
    this.toolState.addListener(_notifyListeners);
  }
  
  void _notifyListeners() {
    notifyListeners();
  }
  
  // 应用配置
  void applyConfiguration(CanvasConfiguration configuration) {
    elementState.initializeElements(configuration.initialElements);
    viewportState.setViewport(
      scale: configuration.viewport.initialScale,
      offset: configuration.viewport.initialOffset,
    );
  }
  
  @override
  void dispose() {
    elementState.removeListener(_notifyListeners);
    selectionState.removeListener(_notifyListeners);
    viewportState.removeListener(_notifyListeners);
    toolState.removeListener(_notifyListeners);
    
    elementState.dispose();
    selectionState.dispose();
    viewportState.dispose();
    toolState.dispose();
    
    super.dispose();
  }
}

// 元素状态示例
class ElementState extends ChangeNotifier {
  final Map<String, ElementData> _elements = {};
  
  UnmodifiableMapView<String, ElementData> get elements => 
      UnmodifiableMapView(_elements);
  
  void addElement(ElementData element) {
    _elements[element.id] = element;
    notifyListeners();
  }
  
  void removeElement(String id) {
    if (_elements.containsKey(id)) {
      _elements.remove(id);
      notifyListeners();
    }
  }
  
  void updateElement(ElementData element) {
    if (_elements.containsKey(element.id)) {
      _elements[element.id] = element;
      notifyListeners();
    }
  }
  
  ElementData? getElementById(String id) => _elements[id];
  
  void initializeElements(List<ElementData> elements) {
    _elements.clear();
    for (final element in elements) {
      _elements[element.id] = element;
    }
    notifyListeners();
  }
}

// 在Flutter UI中使用
class CanvasWidget extends StatelessWidget {
  final CanvasStateManager stateManager;
  
  const CanvasWidget({
    Key? key,
    required this.stateManager,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: stateManager,
      child: Consumer<CanvasStateManager>(
        builder: (context, stateManager, child) {
          return CustomPaint(
            painter: CanvasPainter(stateManager: stateManager),
            size: Size(500, 500), // 从配置获取
          );
        },
      ),
    );
  }
}
```

### 3.3 渲染引擎

**实践原则**：
- 使用策略模式实现不同渲染策略(全量、增量、区域)
- 元素渲染器与元素类型解耦，通过工厂获取
- 实现分层渲染以优化Z轴排序和重绘
- 使用缓存避免重复计算和渲染

**示例**：

```dart
// 渲染引擎实现
class CanvasRenderingEngine {
  final CanvasStateManager _stateManager;
  final ElementRendererFactory _rendererFactory;
  final RenderingStrategy _renderingStrategy;
  
  // 缓存相关
  final Map<String, ui.Image> _renderCache = {};
  final Set<String> _dirtyElements = {};
  
  CanvasRenderingEngine(
    this._stateManager, {
    ElementRendererFactory? rendererFactory,
    RenderingStrategy? renderingStrategy,
  }) : 
    _rendererFactory = rendererFactory ?? DefaultElementRendererFactory(),
    _renderingStrategy = renderingStrategy ?? IncrementalRenderingStrategy() {
    
    // 监听状态变化
    _stateManager.elementState.addListener(_handleElementStateChange);
  }
  
  void _handleElementStateChange() {
    // 标记受影响的元素为脏
    final changedElements = _detectChangedElements();
    _dirtyElements.addAll(changedElements);
  }
  
  Set<String> _detectChangedElements() {
    // 检测变化的元素逻辑
    // 简化示例
    return _stateManager.elementState.elements.keys.toSet();
  }
  
  void render(Canvas canvas, Size size) {
    // 应用视口变换
    final viewport = _stateManager.viewportState;
    canvas.save();
    canvas.translate(viewport.offset.dx, viewport.offset.dy);
    canvas.scale(viewport.scale);
    
    // 使用选择的渲染策略渲染
    _renderingStrategy.render(
      canvas,
      size,
      _stateManager.elementState.elements.values.toList(),
      _rendererFactory,
      _stateManager.selectionState.selectedElementIds,
      _dirtyElements,
    );
    
    // 渲染完成后清除脏标记
    _dirtyElements.clear();
    
    canvas.restore();
  }
  
  void invalidate([Rect? region]) {
    if (region == null) {
      // 全部重绘
      _dirtyElements.addAll(_stateManager.elementState.elements.keys);
    } else {
      // 区域重绘，找出与区域相交的元素
      final elementsInRegion = _stateManager.elementState.elements.values
          .where((element) => element.bounds.overlaps(region))
          .map((element) => element.id);
      _dirtyElements.addAll(elementsInRegion);
    }
  }
  
  bool shouldRepaint(CanvasRenderingEngine oldDelegate) {
    return _dirtyElements.isNotEmpty || 
           _stateManager != oldDelegate._stateManager;
  }
  
  void dispose() {
    _stateManager.elementState.removeListener(_handleElementStateChange);
    // 释放缓存资源
    for (final image in _renderCache.values) {
      image.dispose();
    }
    _renderCache.clear();
  }
}

// 渲染策略接口
abstract class RenderingStrategy {
  void render(
    Canvas canvas,
    Size size,
    List<ElementData> elements,
    ElementRendererFactory rendererFactory,
    Set<String> selectedIds,
    Set<String> dirtyElements,
  );
}

// 增量渲染策略
class IncrementalRenderingStrategy implements RenderingStrategy {
  @override
  void render(
    Canvas canvas,
    Size size,
    List<ElementData> elements,
    ElementRendererFactory rendererFactory,
    Set<String> selectedIds,
    Set<String> dirtyElements,
  ) {
    // 按Z序排序元素
    final sortedElements = List<ElementData>.from(elements)
      ..sort((a, b) => (a.zIndex ?? 0).compareTo(b.zIndex ?? 0));
    
    // 仅渲染脏元素或选中状态改变的元素
    for (final element in sortedElements) {
      final isDirty = dirtyElements.contains(element.id);
      final isSelected = selectedIds.contains(element.id);
      
      if (isDirty || isSelected) {
        final renderer = rendererFactory.getRenderer(element.type);
        renderer.render(canvas, element, isSelected);
      }
    }
  }
}

// 元素渲染器工厂
abstract class ElementRendererFactory {
  ElementRenderer getRenderer(String elementType);
}

class DefaultElementRendererFactory implements ElementRendererFactory {
  final Map<String, ElementRenderer> _renderers = {};
  
  DefaultElementRendererFactory() {
    // 注册默认渲染器
    registerRenderer('text', TextElementRenderer());
    registerRenderer('image', ImageElementRenderer());
    registerRenderer('shape', ShapeElementRenderer());
    registerRenderer('group', GroupElementRenderer());
  }
  
  void registerRenderer(String type, ElementRenderer renderer) {
    _renderers[type] = renderer;
  }
  
  @override
  ElementRenderer getRenderer(String elementType) {
    return _renderers[elementType] ?? FallbackElementRenderer();
  }
}
```

### 3.4 交互处理

**实践原则**：
- 抽象输入事件，统一不同设备的输入处理
- 使用状态模式实现不同交互工具和模式
- 输入处理与命令生成分离
- 实现可组合的交互处理链

**示例**：

```dart
// 输入事件抽象
class InputEvent {
  final InputEventType type;
  final Offset position;
  final InputDevice device;
  final double pressure;
  final Duration timestamp;
  
  InputEvent({
    required this.type,
    required this.position,
    required this.device,
    this.pressure = 1.0,
    Duration? timestamp,
  }) : timestamp = timestamp ?? Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
}

enum InputEventType { down, move, up }
enum InputDevice { mouse, touch, pen, unknown }

// 交互引擎
class CanvasInteractionEngine {
  final CanvasStateManager _stateManager;
  final CommandManager _commandManager;
  final HitTestManager _hitTestManager;
  
  // 当前活动工具
  InteractionTool? _activeTool;
  
  // 交互状态
  InteractionState _interactionState = InteractionState();
  
  CanvasInteractionEngine(
    this._stateManager,
    this._commandManager, {
    HitTestManager? hitTestManager,
  }) : _hitTestManager = hitTestManager ?? DefaultHitTestManager() {
    // 监听工具状态变化
    _stateManager.toolState.addListener(_handleToolChange);
    _updateActiveTool();
  }
  
  void _handleToolChange() {
    _updateActiveTool();
  }
  
  void _updateActiveTool() {
    final toolType = _stateManager.toolState.currentTool;
    _activeTool = _createToolForType(toolType);
  }
  
  InteractionTool _createToolForType(ToolType type) {
    switch (type) {
      case ToolType.select:
        return SelectionTool(_stateManager, _commandManager, _hitTestManager);
      case ToolType.move:
        return MoveTool(_stateManager, _commandManager, _hitTestManager);
      case ToolType.resize:
        return ResizeTool(_stateManager, _commandManager, _hitTestManager);
      case ToolType.text:
        return TextTool(_stateManager, _commandManager);
      case ToolType.shape:
        return ShapeTool(_stateManager, _commandManager);
      default:
        return SelectionTool(_stateManager, _commandManager, _hitTestManager);
    }
  }
  
  void handleInputEvent(InputEvent event) {
    // 转换为视口坐标
    final viewportTransform = _stateManager.viewportState;
    final transformedPosition = _transformPosition(
      event.position, 
      viewportTransform.offset, 
      viewportTransform.scale
    );
    
    final transformedEvent = InputEvent(
      type: event.type,
      position: transformedPosition,
      device: event.device,
      pressure: event.pressure,
      timestamp: event.timestamp,
    );
    
    // 更新交互状态
    _updateInteractionState(transformedEvent);
    
    // 分发到活动工具
    _activeTool?.handleInput(transformedEvent, _interactionState);
  }
  
  Offset _transformPosition(Offset position, Offset viewportOffset, double scale) {
    // 转换屏幕坐标到画布坐标
    return (position - viewportOffset) / scale;
  }
  
  void _updateInteractionState(InputEvent event) {
    switch (event.type) {
      case InputEventType.down:
        _interactionState = _interactionState.copyWith(
          isActive: true,
          startPosition: event.position,
          currentPosition: event.position,
          device: event.device,
        );
        break;
      case InputEventType.move:
        if (_interactionState.isActive) {
          _interactionState = _interactionState.copyWith(
            currentPosition: event.position,
            delta: event.position - _interactionState.currentPosition,
          );
        }
        break;
      case InputEventType.up:
        _interactionState = _interactionState.copyWith(
          isActive: false,
          endPosition: event.position,
        );
        break;
    }
  }
  
  void dispose() {
    _stateManager.toolState.removeListener(_handleToolChange);
    _activeTool?.dispose();
  }
}

// 交互状态
class InteractionState {
  final bool isActive;
  final Offset? startPosition;
  final Offset currentPosition;
  final Offset? endPosition;
  final Offset delta;
  final InputDevice device;
  final Map<String, dynamic> additionalData;
  
  InteractionState({
    this.isActive = false,
    this.startPosition,
    this.currentPosition = Offset.zero,
    this.endPosition,
    this.delta = Offset.zero,
    this.device = InputDevice.unknown,
    Map<String, dynamic>? additionalData,
  }) : additionalData = additionalData ?? {};
  
  InteractionState copyWith({
    bool? isActive,
    Offset? startPosition,
    Offset? currentPosition,
    Offset? endPosition,
    Offset? delta,
    InputDevice? device,
    Map<String, dynamic>? additionalData,
  }) {
    return InteractionState(
      isActive: isActive ?? this.isActive,
      startPosition: startPosition ?? this.startPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      endPosition: endPosition ?? this.endPosition,
      delta: delta ?? this.delta,
      device: device ?? this.device,
      additionalData: additionalData ?? Map.from(this.additionalData),
    );
  }
}

// 交互工具接口
abstract class InteractionTool {
  void handleInput(InputEvent event, InteractionState state);
  void dispose();
}

// 选择工具示例
class SelectionTool implements InteractionTool {
  final CanvasStateManager _stateManager;
  final CommandManager _commandManager;
  final HitTestManager _hitTestManager;
  
  SelectionTool(this._stateManager, this._commandManager, this._hitTestManager);
  
  @override
  void handleInput(InputEvent event, InteractionState state) {
    switch (event.type) {
      case InputEventType.down:
        _handlePointerDown(event, state);
        break;
      case InputEventType.move:
        _handlePointerMove(event, state);
        break;
      case InputEventType.up:
        _handlePointerUp(event, state);
        break;
    }
  }
  
  void _handlePointerDown(InputEvent event, InteractionState state) {
    // 点击测试，查找点击的元素
    final hitElement = _hitTestManager.hitTest(
      event.position,
      _stateManager.elementState.elements.values.toList(),
    );
    
    if (hitElement != null) {
      // 点击到元素，选择它
      _stateManager.selectionState.selectElement(hitElement.id);
      // 记录交互开始信息，用于后续可能的拖动操作
      state.additionalData['selectedElement'] = hitElement.id;
      state.additionalData['initialBounds'] = hitElement.bounds;
    } else {
      // 点击空白区域，清除选择
      _stateManager.selectionState.clearSelection();
    }
  }
  
  void _handlePointerMove(InputEvent event, InteractionState state) {
    // 如果有选中元素且正在拖动，执行移动操作
    if (state.isActive && 
        state.additionalData.containsKey('selectedElement') &&
        state.delta != Offset.zero) {
      
      final elementId = state.additionalData['selectedElement'] as String;
      final element = _stateManager.elementState.getElementById(elementId);
      
      if (element != null) {
        // 创建并执行移动命令
        final command = MoveElementCommand(
          elementId: elementId,
          delta: state.delta,
        );
        _commandManager.executeCommand(command);
      }
    }
  }
  
  void _handlePointerUp(InputEvent event, InteractionState state) {
    // 完成交互，清理状态
    state.additionalData.remove('selectedElement');
    state.additionalData.remove('initialBounds');
  }
  
  @override
  void dispose() {
    // 清理资源
  }
}
```

## 4. 性能优化

### 4.1 渲染优化

**最佳实践**：
- 实现增量渲染策略，仅重绘变化的部分
- 使用脏区域追踪，避免不必要的重绘
- 实现渲染缓存，缓存复杂或静态内容
- 使用分层渲染，优化渲染路径
- 视口裁剪，仅渲染可见区域内的元素

**示例**：

```dart
// 渲染缓存实现
class RenderCache {
  final LruCache<String, ui.Image> _cache;
  final int _maxSize;
  
  RenderCache({int maxSize = 50}) : 
    _maxSize = maxSize,
    _cache = LruCache<String, ui.Image>(maxSize: maxSize);
  
  ui.Image? getCache(String key) {
    return _cache.get(key);
  }
  
  void setCache(String key, ui.Image image) {
    _cache.put(key, image);
  }
  
  void invalidate(String key) {
    final image = _cache.remove(key);
    if (image != null) {
      image.dispose();
    }
  }
  
  void clear() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }
}

// 视口裁剪优化
class ViewportClipRenderingStrategy implements RenderingStrategy {
  @override
  void render(
    Canvas canvas,
    Size size,
    List<ElementData> elements,
    ElementRendererFactory rendererFactory,
    Set<String> selectedIds,
    Set<String> dirtyElements,
  ) {
    // 计算视口可见区域
    final viewportRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // 过滤出可见区域内的元素
    final visibleElements = elements.where((element) {
      return element.bounds.overlaps(viewportRect);
    }).toList();
    
    // 按Z序排序可见元素
    visibleElements.sort((a, b) => (a.zIndex ?? 0).compareTo(b.zIndex ?? 0));
    
    // 仅渲染可见元素
    for (final element in visibleElements) {
      final isDirty = dirtyElements.contains(element.id);
      final isSelected = selectedIds.contains(element.id);
      
      if (isDirty || isSelected) {
        final renderer = rendererFactory.getRenderer(element.type);
        renderer.render(canvas, element, isSelected);
      }
    }
  }
}

// 缓存渲染器示例
class CachedImageElementRenderer implements ElementRenderer {
  final RenderCache _cache;
  final ImageLoader _imageLoader;
  
  CachedImageElementRenderer(this._cache, this._imageLoader);
  
  @override
  void render(Canvas canvas, ElementData element, bool isSelected) {
    if (element is! ImageElementData) return;
    
    final cacheKey = '${element.id}_${element.imageUrl}_${element.bounds.width.toInt()}x${element.bounds.height.toInt()}';
    
    // 尝试从缓存获取
    ui.Image? cachedImage = _cache.getCache(cacheKey);
    
    if (cachedImage == null) {
      // 缓存未命中，加载图像
      _imageLoader.loadImage(element.imageUrl).then((image) {
        if (image != null) {
          _cache.setCache(cacheKey, image);
        }
      });
      
      // 绘制占位符或加载中状态
      _renderPlaceholder(canvas, element, isSelected);
    } else {
      // 使用缓存的图像渲染
      _renderImage(canvas, element, cachedImage, isSelected);
    }
  }
  
  void _renderImage(Canvas canvas, ImageElementData element, ui.Image image, bool isSelected) {
    // 渲染图像逻辑
    canvas.save();
    
    // 应用变换
    final center = element.bounds.center;
    canvas.translate(center.dx, center.dy);
    canvas.rotate(element.rotation);
    canvas.translate(-center.dx, -center.dy);
    
    // 绘制图像
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      element.bounds,
      Paint(),
    );
    
    // 如果选中，绘制选中效果
    if (isSelected) {
      canvas.drawRect(
        element.bounds,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.blue
          ..strokeWidth = 2.0,
      );
    }
    
    canvas.restore();
  }
  
  void _renderPlaceholder(Canvas canvas, ElementData element, bool isSelected) {
    // 绘制占位符逻辑
    canvas.drawRect(
      element.bounds,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.grey.withOpacity(0.3),
    );
    
    // 如果选中，绘制选中效果
    if (isSelected) {
      canvas.drawRect(
        element.bounds,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.blue
          ..strokeWidth = 2.0,
      );
    }
  }
}
```
