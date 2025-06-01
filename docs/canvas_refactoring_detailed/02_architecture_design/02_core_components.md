# 核心组件设计

## 1. 画布状态管理器 (CanvasStateManager)

### 1.1 职责

* 集中式状态管理，统一管理画布所有状态
* 分离UI状态和渲染状态，减少不必要的重建
* 实现高效的状态更新通知机制
* 支持状态的序列化与持久化

### 1.2 设计

```dart
class CanvasStateManager extends ChangeNotifier {
  // 画布视口状态
  Matrix4 _transform = Matrix4.identity();
  Size _canvasSize = Size.zero;
  
  // 元素状态管理
  final Map<String, ElementRenderData> _elements = {};
  final Set<String> _selectedElements = {};
  
  // 渲染状态（与UI状态分离）
  final Set<String> _dirtyElements = {};
  final Set<Rect> _dirtyRegions = {};
  bool _needsFullRepaint = false;
  
  // 纹理缓存状态
  final Map<String, TextureRenderData> _textureCache = {};
  
  // 性能监控
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  
  /// 获取脏元素列表用于增量渲染
  List<ElementRenderData> getDirtyElements() {
    return _dirtyElements
        .map((id) => _elements[id])
        .where((data) => data != null)
        .cast<ElementRenderData>()
        .toList();
  }
  
  /// 标记元素为脏状态
  void markElementDirty(String elementId, {Rect? region}) {
    _dirtyElements.add(elementId);
    if (region != null) {
      _dirtyRegions.add(region);
    }
    notifyListeners();
  }
  
  /// 清理脏状态标记
  void clearDirtyFlags() {
    _dirtyElements.clear();
    _dirtyRegions.clear();
    _needsFullRepaint = false;
  }
}
```

### 1.3 关键特性

* **脏区域跟踪**：只更新发生变化的区域
* **元素级状态管理**：精确控制元素状态
* **状态分层**：UI状态与渲染状态分离
* **高效通知机制**：避免重复通知和不必要的重建

## 2. 画布渲染引擎 (CanvasRenderingEngine)

### 2.1 职责

* 高效绘制画布内容
* 管理渲染资源（纹理、字体等）
* 实现渲染优化策略
* 提供抽象渲染接口

### 2.2 设计

```dart
class CanvasRenderingEngine {
  final CanvasStateManager stateManager;
  final Map<String, ElementRenderer> _renderers = {};
  final TextureManager _textureManager;
  final RenderCache _renderCache;
  
  CanvasRenderingEngine(this.stateManager) 
    : _textureManager = TextureManager(),
      _renderCache = RenderCache();
  
  /// 主渲染方法 - 无setState，无scheduleForcedFrame
  void renderToCanvas(Canvas canvas, Size size) {
    // 智能渲染：仅渲染脏区域
    if (stateManager.needsFullRepaint) {
      _renderFullCanvas(canvas, size);
    } else {
      _renderDirtyRegions(canvas, size);
    }
    
    stateManager.clearDirtyFlags();
  }
  
  /// 增量渲染脏区域
  void _renderDirtyRegions(Canvas canvas, Size size) {
    final dirtyElements = stateManager.getDirtyElements();
    
    for (final element in dirtyElements) {
      final renderer = _getRendererForElement(element);
      canvas.save();
      renderer.renderElement(canvas, element);
      canvas.restore();
    }
  }
  
  /// 异步纹理预加载
  Future<void> preloadTextures(List<TextureData> textures) async {
    for (final textureData in textures) {
      await _textureManager.loadTexture(textureData);
    }
  }
  
  /// 获取元素专用渲染器
  ElementRenderer _getRendererForElement(ElementRenderData element) {
    final type = element.type;
    return _renderers[type] ??= _createRenderer(type);
  }
}
```

### 2.3 关键特性

* **智能渲染**：根据脏区域进行增量渲染
* **渲染器工厂**：为不同元素类型创建专用渲染器
* **异步资源管理**：后台线程加载和处理资源
* **缓存策略**：多级缓存提升渲染性能

## 3. 画布交互引擎 (CanvasInteractionEngine)

### 3.1 职责

* 处理复杂的用户交互逻辑
* 将低级事件转换为高级命令
* 实现交互行为（选择、移动、调整大小等）
* 处理手势识别与冲突解决

### 3.2 设计

```dart
class CanvasInteractionEngine {
  final CanvasStateManager stateManager;
  
  InteractionMode _currentMode = InteractionMode.select;
  
  // 拖拽状态
  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  final Map<String, Offset> _elementStartPositions = {};
  
  // 选择框状态
  bool _isSelectionBoxActive = false;
  Offset? _selectionStart;
  Offset? _selectionEnd;
  
  /// 处理点击手势
  void handleTapDown(TapDownDetails details) {
    final hitElement = _getElementAtPoint(details.localPosition);
    
    switch (_currentMode) {
      case InteractionMode.select:
        _handleSelectMode(hitElement, details);
        break;
      case InteractionMode.draw:
        _handleDrawMode(details);
        break;
      case InteractionMode.pan:
        _handlePanMode(details);
        break;
    }
  }
  
  /// 处理拖拽更新
  void handlePanUpdate(DragUpdateDetails details) {
    if (_isSelectionBoxActive) {
      _updateSelectionBox(details.localPosition);
    } else if (_isDragging) {
      _updateElementPositions(details);
    }
  }
  
  /// 智能元素碰撞检测
  ElementRenderData? _getElementAtPoint(Offset point) {
    final elements = stateManager.getAllElements();
    
    // 从顶层元素开始检查（视觉层级）
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      if (_isPointInElement(point, element)) {
        return element;
      }
    }
    
    return null;
  }
}
```

### 3.3 关键特性

* **模式化交互**：支持不同交互模式（选择、绘制、平移等）
* **智能碰撞检测**：高效的元素命中测试
* **事件委托**：将用户操作转换为状态更新命令
* **状态隔离**：交互状态与渲染状态分离

## 4. 元素渲染系统 (ElementRenderer)

### 4.1 职责

* 提供统一的元素渲染接口
* 实现不同类型元素的专用渲染器
* 优化元素渲染性能
* 支持元素样式与效果

### 4.2 设计

```dart
/// 元素渲染数据基类
abstract class ElementRenderData {
  final String id;
  final String type;
  final Rect bounds;
  final double rotation;
  final Map<String, dynamic> properties;
  
  ElementRenderData({
    required this.id,
    required this.type,
    required this.bounds,
    this.rotation = 0.0,
    Map<String, dynamic>? properties,
  }) : properties = properties ?? {};
  
  /// 深拷贝方法
  ElementRenderData copyWith();
  
  /// 序列化方法
  Map<String, dynamic> toJson();
  
  /// 是否需要重绘
  bool shouldRepaint(ElementRenderData oldData);
}

/// 元素渲染器接口
abstract class ElementRenderer {
  /// 渲染元素到画布
  void renderElement(Canvas canvas, ElementRenderData data);
  
  /// 判断点是否在元素内
  bool isPointInElement(Offset point, ElementRenderData data);
  
  /// 获取元素变换矩阵
  Matrix4 getElementTransform(ElementRenderData data);
  
  /// 预加载元素资源
  Future<void> preloadResources(ElementRenderData data);
}
```

### 4.3 元素渲染器类型

* **TextElementRenderer**：文本元素渲染器
* **ImageElementRenderer**：图像元素渲染器
* **ShapeElementRenderer**：形状元素渲染器
* **CharacterElementRenderer**：字符元素渲染器
* **GroupElementRenderer**：组合元素渲染器

## 5. 纹理管理系统 (TextureManager)

### 5.1 职责

* 异步加载与管理纹理资源
* 实现多级纹理缓存
* 提供纹理预处理功能
* 管理纹理生命周期

### 5.2 设计

```dart
class TextureManager {
  final Map<String, ui.Image> _imageCache = {};
  final Map<String, Completer<ui.Image>> _loadingImages = {};
  
  /// 异步加载纹理
  Future<ui.Image> loadTexture(TextureData data) async {
    final key = data.cacheKey;
    
    // 检查缓存
    if (_imageCache.containsKey(key)) {
      return _imageCache[key]!;
    }
    
    // 检查是否正在加载
    if (_loadingImages.containsKey(key)) {
      return _loadingImages[key]!.future;
    }
    
    // 开始加载
    final completer = Completer<ui.Image>();
    _loadingImages[key] = completer;
    
    try {
      final image = await _loadImageFromSource(data);
      
      // 预处理图像
      final processedImage = await _processImage(image, data);
      
      _imageCache[key] = processedImage;
      completer.complete(processedImage);
      _loadingImages.remove(key);
      
      return processedImage;
    } catch (e) {
      completer.completeError(e);
      _loadingImages.remove(key);
      rethrow;
    }
  }
  
  /// 清理未使用的纹理
  void cleanupUnusedTextures(Set<String> activeTextureKeys) {
    final keysToRemove = _imageCache.keys
        .where((key) => !activeTextureKeys.contains(key))
        .toList();
    
    for (final key in keysToRemove) {
      _imageCache.remove(key);
    }
  }
}
```

### 5.3 关键特性

* **异步加载**：非阻塞式资源加载
* **智能缓存**：基于使用频率的缓存策略
* **纹理预处理**：调整大小、颜色处理等预处理操作
* **内存管理**：自动清理未使用的资源

## 6. 命令系统 (CommandSystem)

### 6.1 职责

* 实现命令模式支持操作封装
* 提供撤销/重做功能
* 支持操作的序列化与重放
* 实现事务性操作（多命令原子执行）

### 6.2 设计

```dart
/// 画布命令接口
abstract class CanvasCommand {
  /// 执行命令
  CommandResult execute(CanvasStateManager stateManager);
  
  /// 撤销命令
  CommandResult undo(CanvasStateManager stateManager);
  
  /// 命令描述
  String get description;
  
  /// 序列化命令
  Map<String, dynamic> toJson();
}

/// 命令管理器
class CommandManager {
  final CanvasStateManager stateManager;
  final List<CanvasCommand> _undoStack = [];
  final List<CanvasCommand> _redoStack = [];
  
  /// 执行命令
  CommandResult executeCommand(CanvasCommand command) {
    final result = command.execute(stateManager);
    
    if (result.success) {
      _undoStack.add(command);
      _redoStack.clear();
    }
    
    return result;
  }
  
  /// 撤销操作
  CommandResult undo() {
    if (_undoStack.isEmpty) {
      return CommandResult(success: false, message: '没有可撤销的操作');
    }
    
    final command = _undoStack.removeLast();
    final result = command.undo(stateManager);
    
    if (result.success) {
      _redoStack.add(command);
    } else {
      _undoStack.add(command); // 撤销失败，放回栈中
    }
    
    return result;
  }
  
  /// 重做操作
  CommandResult redo() {
    if (_redoStack.isEmpty) {
      return CommandResult(success: false, message: '没有可重做的操作');
    }
    
    final command = _redoStack.removeLast();
    final result = command.execute(stateManager);
    
    if (result.success) {
      _undoStack.add(command);
    } else {
      _redoStack.add(command); // 重做失败，放回栈中
    }
    
    return result;
  }
}
```

### 6.3 命令类型

* **AddElementCommand**：添加元素命令
* **RemoveElementCommand**：删除元素命令
* **UpdateElementCommand**：更新元素属性命令
* **MoveElementCommand**：移动元素命令
* **TransformElementCommand**：变换元素命令
* **BatchCommand**：批量命令（原子操作）

## 7. 组件集成示例

```dart
class M3PracticeEditCanvas extends StatefulWidget {
  @override
  State<M3PracticeEditCanvas> createState() => _M3PracticeEditCanvasState();
}

class _M3PracticeEditCanvasState extends State<M3PracticeEditCanvas> {
  late CanvasStateManager _stateManager;
  late CanvasRenderingEngine _renderingEngine;
  late CanvasInteractionEngine _interactionEngine;
  late CommandManager _commandManager;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化核心组件
    _stateManager = CanvasStateManager();
    _renderingEngine = CanvasRenderingEngine(_stateManager);
    _interactionEngine = CanvasInteractionEngine(_stateManager);
    _commandManager = CommandManager(_stateManager);
    
    // 设置状态监听
    _stateManager.addListener(_handleStateChange);
  }
  
  void _handleStateChange() {
    // 只在状态变化时重建，不直接修改状态
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _interactionEngine.handleTapDown,
      onPanStart: _interactionEngine.handlePanStart,
      onPanUpdate: _interactionEngine.handlePanUpdate,
      onPanEnd: _interactionEngine.handlePanEnd,
      child: CustomPaint(
        painter: CanvasPainter(
          stateManager: _stateManager,
          renderingEngine: _renderingEngine,
        ),
        size: Size.infinite,
      ),
    );
  }
}
```
