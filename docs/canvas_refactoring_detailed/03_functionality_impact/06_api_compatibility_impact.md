# API与兼容性影响分析

## 1. 概述

本文档分析画布重构对API和兼容性的影响，评估变更范围和程度，并提供迁移建议。影响程度分为：

- **高影响**：API需要完全重写或不兼容变更
- **中影响**：API需要部分重构但可保持兼容性
- **低影响**：API需要小幅调整，易于迁移
- **无影响**：API保持不变或完全兼容

## 2. 公共API影响分析

### 2.1 当前实现

当前系统的公共API主要包括Canvas组件和CanvasController：

```dart
// Canvas组件API
class Canvas extends StatefulWidget {
  final List<CanvasElement> elements;
  final Size size;
  final CanvasOptions? options;
  final Function(CanvasElement)? onElementSelected;
  final Function(CanvasElement)? onElementCreated;
  final Function(CanvasElement)? onElementModified;
  
  const Canvas({
    Key? key,
    required this.elements,
    required this.size,
    this.options,
    this.onElementSelected,
    this.onElementCreated,
    this.onElementModified,
  }) : super(key: key);
  
  @override
  _CanvasState createState() => _CanvasState();
}

// 控制器API
class CanvasController {
  _CanvasState? _canvasState;
  
  void attach(_CanvasState state) {
    _canvasState = state;
  }
  
  void detach() {
    _canvasState = null;
  }
  
  // 元素操作
  void addElement(CanvasElement element) {
    _canvasState?.addElement(element);
  }
  
  void removeElement(String id) {
    _canvasState?.removeElement(id);
  }
  
  void selectElement(String id) {
    _canvasState?.selectElement(id);
  }
  
  void clearSelection() {
    _canvasState?.clearSelection();
  }
  
  // 视图操作
  void zoomTo(double scale) {
    _canvasState?._zoomCanvas(scale, _canvasState!.widget.size.center(Offset.zero));
  }
  
  void resetView() {
    _canvasState?._resetTransform();
  }
  
  // 撤销/重做
  void undo() {
    _canvasState?.undo();
  }
  
  void redo() {
    _canvasState?.redo();
  }
}

// 元素API
abstract class CanvasElement {
  String id;
  Rect bounds;
  bool selected;
  double rotation;
  
  CanvasElement({
    required this.id,
    required this.bounds,
    this.selected = false,
    this.rotation = 0.0,
  });
  
  void paint(Canvas canvas);
  bool containsPoint(Offset point);
  
  void move(Offset delta) {
    bounds = bounds.translate(delta.dx, delta.dy);
  }
  
  void resize(Size newSize) {
    bounds = Rect.fromLTWH(
      bounds.left,
      bounds.top,
      newSize.width,
      newSize.height,
    );
  }
}
```

**主要特点**：
- Widget API直接接收元素列表
- 控制器通过State引用直接操作画布
- 元素API混合数据和行为
- 回调函数用于通知状态变化
- 紧耦合的组件结构

### 2.2 影响分析

**影响程度**：高

**影响详情**：
1. 架构变更：从直接操作到命令模式
2. 数据分离：元素数据与行为分离
3. 控制器重构：基于状态管理器的新控制器
4. 事件模型：从回调到事件流
5. 配置模式：从选项到配置对象

### 2.3 迁移建议

**新的Canvas组件API**：

```dart
class Canvas extends StatefulWidget {
  final CanvasConfiguration configuration;
  final CanvasController? controller;
  final CanvasTheme? theme;
  
  // 观察者模式代替回调
  final Stream<CanvasEvent>? eventStream;
  final void Function(CanvasEvent event)? onEvent;
  
  const Canvas({
    Key? key,
    required this.configuration,
    this.controller,
    this.theme,
    this.eventStream,
    this.onEvent,
  }) : super(key: key);
  
  @override
  _CanvasState createState() => _CanvasState();
}

// 配置对象
class CanvasConfiguration {
  final Size size;
  final List<ElementData> initialElements;
  final bool enableMultiSelection;
  final bool enableHistory;
  final ViewportConfiguration viewport;
  final String? backgroundImageUrl;
  final Color backgroundColor;
  
  const CanvasConfiguration({
    required this.size,
    this.initialElements = const [],
    this.enableMultiSelection = true,
    this.enableHistory = true,
    this.viewport = const ViewportConfiguration(),
    this.backgroundImageUrl,
    this.backgroundColor = Colors.white,
  });
}

// 视口配置
class ViewportConfiguration {
  final double initialScale;
  final Offset initialOffset;
  final double minScale;
  final double maxScale;
  final bool enablePanning;
  final bool enableZooming;
  
  const ViewportConfiguration({
    this.initialScale = 1.0,
    this.initialOffset = Offset.zero,
    this.minScale = 0.1,
    this.maxScale = 10.0,
    this.enablePanning = true,
    this.enableZooming = true,
  });
}
```

**新的控制器API**：

```dart
class CanvasController {
  CanvasStateManager? _stateManager;
  
  void attach(CanvasStateManager stateManager) {
    _stateManager = stateManager;
  }
  
  void detach() {
    _stateManager = null;
  }
  
  // 元素操作 - 命令模式
  void addElement(ElementData element) {
    _executeCommand(AddElementCommand(element: element));
  }
  
  void removeElement(String id) {
    _executeCommand(RemoveElementCommand(elementId: id));
  }
  
  void moveElement(String id, Offset delta) {
    _executeCommand(MoveElementCommand(
      elementId: id,
      delta: delta,
    ));
  }
  
  void resizeElement(String id, Size newSize) {
    _executeCommand(ResizeElementCommand(
      elementId: id,
      newSize: newSize,
    ));
  }
  
  // 选择操作
  void selectElement(String id) {
    _stateManager?.selectionState.selectElement(id);
  }
  
  void addToSelection(String id) {
    _stateManager?.selectionState.addToSelection(id);
  }
  
  void clearSelection() {
    _stateManager?.selectionState.clearSelection();
  }
  
  // 视图操作
  void zoomTo(double scale, {Offset? focalPoint}) {
    _executeCommand(ZoomViewportCommand(
      scale: scale,
      focalPoint: focalPoint ?? _getViewCenter(),
    ));
  }
  
  void panTo(Offset offset) {
    _executeCommand(PanViewportCommand(delta: offset));
  }
  
  void resetView() {
    _executeCommand(ResetViewportCommand());
  }
  
  // 历史操作
  void undo() {
    _stateManager?.commandManager.undo();
  }
  
  void redo() {
    _stateManager?.commandManager.redo();
  }
  
  // 批量操作
  void executeBatch(List<Command> commands) {
    _stateManager?.commandManager.executeCompositeCommand(commands);
  }
  
  // 辅助方法
  void _executeCommand(Command command) {
    _stateManager?.commandManager.executeCommand(command);
  }
  
  Offset _getViewCenter() {
    return _stateManager?.viewportState.visibleRect.center ?? Offset.zero;
  }
}
```

**元素数据模型**：

```dart
// 元素数据基类
class ElementData {
  final String id;
  final String type;
  final Rect bounds;
  final double rotation;
  final Map<String, dynamic> properties;
  
  const ElementData({
    required this.id,
    required this.type,
    required this.bounds,
    this.rotation = 0.0,
    this.properties = const {},
  });
  
  // 创建更新后的副本
  ElementData copyWith({
    String? id,
    String? type,
    Rect? bounds,
    double? rotation,
    Map<String, dynamic>? properties,
  }) {
    return ElementData(
      id: id ?? this.id,
      type: type ?? this.type,
      bounds: bounds ?? this.bounds,
      rotation: rotation ?? this.rotation,
      properties: properties ?? Map.from(this.properties),
    );
  }
}

// 专用元素数据类型
class TextElementData extends ElementData {
  final String text;
  final TextStyle style;
  
  TextElementData({
    required String id,
    required Rect bounds,
    required this.text,
    this.style = const TextStyle(),
    double rotation = 0.0,
    Map<String, dynamic> properties = const {},
  }) : super(
    id: id,
    type: 'text',
    bounds: bounds,
    rotation: rotation,
    properties: properties,
  );
  
  @override
  TextElementData copyWith({
    String? id,
    Rect? bounds,
    double? rotation,
    Map<String, dynamic>? properties,
    String? text,
    TextStyle? style,
  }) {
    return TextElementData(
      id: id ?? this.id,
      bounds: bounds ?? this.bounds,
      rotation: rotation ?? this.rotation,
      properties: properties ?? Map.from(this.properties),
      text: text ?? this.text,
      style: style ?? this.style,
    );
  }
}
```

## 3. 事件系统影响分析

### 3.1 当前实现

当前系统使用回调函数通知外部状态变化：

```dart
class Canvas extends StatefulWidget {
  // 回调函数
  final Function(CanvasElement)? onElementSelected;
  final Function(CanvasElement)? onElementCreated;
  final Function(CanvasElement)? onElementModified;
  
  // ...
}

class _CanvasState extends State<Canvas> {
  // 触发回调
  void _notifyElementSelected(CanvasElement element) {
    widget.onElementSelected?.call(element);
  }
  
  void _notifyElementCreated(CanvasElement element) {
    widget.onElementCreated?.call(element);
  }
  
  void _notifyElementModified(CanvasElement element) {
    widget.onElementModified?.call(element);
  }
}
```

**主要问题**：
- 有限的回调集合
- 无法灵活处理新事件类型
- 事件数据结构不一致
- 事件处理缺乏统一性

### 3.2 影响分析

**影响程度**：中

**影响详情**：
1. 架构变更：从回调到事件流
2. 事件分类：统一的事件类型系统
3. 订阅模式：支持多观察者模式
4. 事件过滤：支持事件过滤和变换
5. 可测试性：事件流可独立测试

### 3.3 迁移建议

**事件系统实现**：

```dart
// 事件基类
abstract class CanvasEvent {
  final String type;
  final DateTime timestamp;
  
  CanvasEvent(this.type) : timestamp = DateTime.now();
}

// 元素事件
class ElementEvent extends CanvasEvent {
  final String elementId;
  final ElementData? elementData;
  
  ElementEvent({
    required String type,
    required this.elementId,
    this.elementData,
  }) : super(type);
  
  static const String selected = 'element.selected';
  static const String deselected = 'element.deselected';
  static const String created = 'element.created';
  static const String deleted = 'element.deleted';
  static const String modified = 'element.modified';
  static const String moved = 'element.moved';
  static const String resized = 'element.resized';
  static const String rotated = 'element.rotated';
}

// 视图事件
class ViewportEvent extends CanvasEvent {
  final ViewportState viewportState;
  
  ViewportEvent({
    required String type,
    required this.viewportState,
  }) : super(type);
  
  static const String zoomed = 'viewport.zoomed';
  static const String panned = 'viewport.panned';
  static const String reset = 'viewport.reset';
}

// 历史事件
class HistoryEvent extends CanvasEvent {
  final bool canUndo;
  final bool canRedo;
  
  HistoryEvent({
    required String type,
    required this.canUndo,
    required this.canRedo,
  }) : super(type);
  
  static const String undone = 'history.undone';
  static const String redone = 'history.redone';
  static const String changed = 'history.changed';
}

// 事件管理器
class EventManager {
  final StreamController<CanvasEvent> _eventController = 
      StreamController<CanvasEvent>.broadcast();
  
  // 获取事件流
  Stream<CanvasEvent> get eventStream => _eventController.stream;
  
  // 分类事件流
  Stream<T> getEventsByType<T extends CanvasEvent>() {
    return eventStream.where((event) => event is T).cast<T>();
  }
  
  // 按事件类型过滤
  Stream<CanvasEvent> getEventsByTypeName(String typeName) {
    return eventStream.where((event) => event.type == typeName);
  }
  
  // 发布事件
  void publishEvent(CanvasEvent event) {
    _eventController.add(event);
  }
  
  // 释放资源
  void dispose() {
    _eventController.close();
  }
}
```

## 4. 兼容性层实现

### 4.1 兼容性问题

重构后的API与当前API存在显著差异，主要包括：

1. 元素定义：从类继承到数据模型
2. 状态管理：从Widget状态到中心化状态
3. 控制模式：从直接操作到命令模式
4. 事件通知：从回调到事件流
5. 配置方式：从分散参数到配置对象

### 4.2 迁移建议

**兼容性适配器实现**：

```dart
// 旧API适配器
class LegacyCanvasAdapter extends StatefulWidget {
  // 旧API参数
  final List<CanvasElement> elements;
  final Size size;
  final CanvasOptions? options;
  final Function(CanvasElement)? onElementSelected;
  final Function(CanvasElement)? onElementCreated;
  final Function(CanvasElement)? onElementModified;
  
  const LegacyCanvasAdapter({
    Key? key,
    required this.elements,
    required this.size,
    this.options,
    this.onElementSelected,
    this.onElementCreated,
    this.onElementModified,
  }) : super(key: key);
  
  @override
  _LegacyCanvasAdapterState createState() => _LegacyCanvasAdapterState();
}

class _LegacyCanvasAdapterState extends State<LegacyCanvasAdapter> {
  late CanvasController _controller;
  late List<ElementData> _convertedElements;
  
  @override
  void initState() {
    super.initState();
    _controller = CanvasController();
    _convertedElements = _convertElements(widget.elements);
  }
  
  @override
  void didUpdateWidget(LegacyCanvasAdapter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.elements != oldWidget.elements) {
      // 元素变化，更新转换的元素
      _convertedElements = _convertElements(widget.elements);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 创建配置对象
    final configuration = CanvasConfiguration(
      size: widget.size,
      initialElements: _convertedElements,
      enableMultiSelection: widget.options?.enableMultiSelection ?? true,
      enableHistory: widget.options?.enableHistory ?? true,
      backgroundColor: widget.options?.backgroundColor ?? Colors.white,
    );
    
    // 返回新的Canvas组件
    return Canvas(
      configuration: configuration,
      controller: _controller,
      onEvent: _handleCanvasEvent,
    );
  }
  
  // 处理事件
  void _handleCanvasEvent(CanvasEvent event) {
    if (event is ElementEvent) {
      final legacyElement = _findLegacyElement(event.elementId);
      
      switch (event.type) {
        case ElementEvent.selected:
          if (legacyElement != null) {
            widget.onElementSelected?.call(legacyElement);
          }
          break;
          
        case ElementEvent.created:
          if (event.elementData != null) {
            final newElement = _createLegacyElement(event.elementData!);
            widget.onElementCreated?.call(newElement);
          }
          break;
          
        case ElementEvent.modified:
          if (legacyElement != null && event.elementData != null) {
            _updateLegacyElement(legacyElement, event.elementData!);
            widget.onElementModified?.call(legacyElement);
          }
          break;
      }
    }
  }
  
  // 查找对应的旧元素
  CanvasElement? _findLegacyElement(String id) {
    return widget.elements.firstWhere(
      (element) => element.id == id,
      orElse: () => null,
    );
  }
  
  // 转换元素列表
  List<ElementData> _convertElements(List<CanvasElement> elements) {
    return elements.map(_convertElement).toList();
  }
  
  // 转换单个元素
  ElementData _convertElement(CanvasElement element) {
    if (element is TextElement) {
      return TextElementData(
        id: element.id,
        bounds: element.bounds,
        text: element.text,
        style: element.style,
        rotation: element.rotation,
      );
    } else if (element is ImageElement) {
      return ImageElementData(
        id: element.id,
        bounds: element.bounds,
        imageUrl: element.imagePath,
        rotation: element.rotation,
      );
    } else {
      // 通用元素转换
      return ElementData(
        id: element.id,
        type: element.runtimeType.toString(),
        bounds: element.bounds,
        rotation: element.rotation,
      );
    }
  }
  
  // 创建旧元素
  CanvasElement _createLegacyElement(ElementData data) {
    // 根据类型创建相应的旧元素
    if (data is TextElementData) {
      return TextElement(
        id: data.id,
        bounds: data.bounds,
        text: data.text,
        style: data.style,
      );
    } else if (data is ImageElementData) {
      return ImageElement(
        id: data.id,
        bounds: data.bounds,
        imagePath: data.imageUrl,
      );
    } else {
      // 创建通用元素
      return GenericElement(
        id: data.id,
        bounds: data.bounds,
      );
    }
  }
  
  // 更新旧元素
  void _updateLegacyElement(CanvasElement element, ElementData data) {
    element.bounds = data.bounds;
    element.rotation = data.rotation;
    
    // 更新特定类型的属性
    if (element is TextElement && data is TextElementData) {
      element.text = data.text;
      element.style = data.style;
    } else if (element is ImageElement && data is ImageElementData) {
      element.imagePath = data.imageUrl;
    }
  }
}
```

**控制器兼容性适配器**：

```dart
// 旧控制器适配器
class LegacyCanvasControllerAdapter implements CanvasController {
  final CanvasController _newController = CanvasController();
  
  @override
  void attach(CanvasStateManager stateManager) {
    _newController.attach(stateManager);
  }
  
  @override
  void detach() {
    _newController.detach();
  }
  
  // 旧API方法
  void addElement(CanvasElement element) {
    // 转换为新元素数据
    final elementData = _convertElement(element);
    _newController.addElement(elementData);
  }
  
  void removeElement(String id) {
    _newController.removeElement(id);
  }
  
  void selectElement(String id) {
    _newController.selectElement(id);
  }
  
  void clearSelection() {
    _newController.clearSelection();
  }
  
  void zoomTo(double scale) {
    _newController.zoomTo(scale);
  }
  
  void resetView() {
    _newController.resetView();
  }
  
  void undo() {
    _newController.undo();
  }
  
  void redo() {
    _newController.redo();
  }
  
  // 转换旧元素为新元素数据
  ElementData _convertElement(CanvasElement element) {
    // 转换逻辑...
    return ElementData(
      id: element.id,
      type: element.runtimeType.toString(),
      bounds: element.bounds,
      rotation: element.rotation,
    );
  }
}
```

## 5. 总体迁移策略

1. **分阶段迁移**：
   - 第一阶段：实现新API和兼容性层
   - 第二阶段：在新项目中使用新API
   - 第三阶段：逐步迁移现有代码
   - 第四阶段：移除兼容性层

2. **向后兼容性策略**：
   - 提供明确的API版本标识
   - 保持核心功能兼容性
   - 提供详细的迁移指南
   - 实现双向数据转换

3. **渐进式采用**：
   - 支持混合使用新旧API
   - 提供功能等价性保证
   - 保持行为一致性
   - 提供迁移工具

4. **测试策略**：
   - API兼容性测试
   - 迁移路径测试
   - 性能比较测试
   - 用户体验一致性测试
