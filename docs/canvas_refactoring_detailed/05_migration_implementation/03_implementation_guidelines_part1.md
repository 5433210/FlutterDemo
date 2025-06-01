# Canvas 重构实现指南与最佳实践 (第一部分)

## 1. 概述

本文档提供 Canvas 重构项目的实现指南和最佳实践，帮助开发团队在重构过程中遵循一致的标准和模式。良好的实现指南对于确保代码质量、性能和可维护性至关重要。

## 2. 核心设计原则

### 2.1 关注点分离

**原则**：严格区分渲染、状态管理、交互处理和业务逻辑

**实践**：
- 将系统分为独立的层和模块，每个模块只负责单一职责
- 禁止跨层直接访问，通过定义的接口进行通信
- 视图层只负责渲染，不包含业务逻辑
- 将元素数据与渲染逻辑分离

**示例**：

```dart
// 不推荐：混合关注点
class CanvasElement {
  Rect bounds;
  bool selected = false;
  
  void paint(Canvas canvas) {
    // 渲染逻辑
    if (selected) {
      // 选中状态渲染
    }
  }
  
  bool containsPoint(Offset point) {
    // 点击测试逻辑
    return bounds.contains(point);
  }
  
  void move(Offset delta) {
    // 状态修改逻辑
    bounds = bounds.translate(delta.dx, delta.dy);
  }
}

// 推荐：分离关注点
// 数据模型
class ElementData {
  final String id;
  final Rect bounds;
  
  ElementData({required this.id, required this.bounds});
  
  ElementData copyWith({Rect? bounds}) {
    return ElementData(
      id: this.id,
      bounds: bounds ?? this.bounds,
    );
  }
}

// 渲染器
class ElementRenderer {
  void render(Canvas canvas, ElementData element, bool selected) {
    // 纯渲染逻辑
  }
}

// 交互处理
class ElementInteractionHandler {
  bool hitTest(Offset point, ElementData element) {
    return element.bounds.contains(point);
  }
}

// 状态管理
class ElementCommand {
  final ElementData element;
  final Offset delta;
  
  void execute(CanvasState state) {
    final updatedElement = element.copyWith(
      bounds: element.bounds.translate(delta.dx, delta.dy)
    );
    state.updateElement(updatedElement);
  }
}
```

### 2.2 依赖注入

**原则**：组件间通过接口依赖，而非直接引用实现

**实践**：
- 使用抽象类或接口定义组件契约
- 构造函数注入依赖
- 提供工厂方法创建复杂对象
- 单元测试中使用模拟对象替换真实依赖

**示例**：

```dart
// 定义接口
abstract class RenderingEngine {
  void render(Canvas canvas, Size size);
  void invalidate([Rect? region]);
}

// 实现类
class DefaultRenderingEngine implements RenderingEngine {
  final ElementRegistry _registry;
  final TextureManager _textureManager;
  
  DefaultRenderingEngine(this._registry, this._textureManager);
  
  @override
  void render(Canvas canvas, Size size) {
    // 实现渲染逻辑
  }
  
  @override
  void invalidate([Rect? region]) {
    // 实现重绘请求
  }
}

// 依赖注入
class CanvasWidget extends StatefulWidget {
  final RenderingEngine renderingEngine;
  
  CanvasWidget({required this.renderingEngine});
  
  @override
  _CanvasWidgetState createState() => _CanvasWidgetState();
}

// 测试时可轻松替换
class MockRenderingEngine implements RenderingEngine {
  @override
  void render(Canvas canvas, Size size) {
    // 模拟实现
  }
  
  @override
  void invalidate([Rect? region]) {
    // 模拟实现
  }
}
```

### 2.3 命令模式

**原则**：所有状态变更通过命令对象执行，支持撤销/重做

**实践**：
- 将用户操作封装为命令对象
- 实现统一的命令执行和撤销接口
- 使用命令管理器维护历史记录
- 支持命令合并和批处理

**示例**：

```dart
// 命令接口
abstract class Command {
  void execute(CanvasStateManager stateManager);
  void undo(CanvasStateManager stateManager);
  String get description;
  bool get isMerged;
}

// 具体命令实现
class MoveElementCommand implements Command {
  final String elementId;
  final Offset originalPosition;
  final Offset newPosition;
  
  MoveElementCommand({
    required this.elementId,
    required this.originalPosition,
    required this.newPosition,
  });
  
  @override
  void execute(CanvasStateManager stateManager) {
    final element = stateManager.elementState.getElementById(elementId);
    if (element != null) {
      final delta = newPosition - originalPosition;
      final updatedElement = element.copyWith(
        bounds: element.bounds.translate(delta.dx, delta.dy)
      );
      stateManager.elementState.updateElement(updatedElement);
    }
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    final element = stateManager.elementState.getElementById(elementId);
    if (element != null) {
      final delta = originalPosition - newPosition;
      final updatedElement = element.copyWith(
        bounds: element.bounds.translate(delta.dx, delta.dy)
      );
      stateManager.elementState.updateElement(updatedElement);
    }
  }
  
  @override
  String get description => 'Move element';
  
  @override
  bool get isMerged => false;
}

// 命令管理器
class CommandManager {
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  final CanvasStateManager _stateManager;
  
  CommandManager(this._stateManager);
  
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  
  void executeCommand(Command command) {
    command.execute(_stateManager);
    _undoStack.add(command);
    _redoStack.clear();
  }
  
  void undo() {
    if (canUndo) {
      final command = _undoStack.removeLast();
      command.undo(_stateManager);
      _redoStack.add(command);
    }
  }
  
  void redo() {
    if (canRedo) {
      final command = _redoStack.removeLast();
      command.execute(_stateManager);
      _undoStack.add(command);
    }
  }
}
```

### 2.4 不可变数据

**原则**：状态对象采用不可变设计，使用 copyWith 模式更新

**实践**：
- 使用 final 字段定义数据模型
- 提供 copyWith 方法创建更新后的副本
- 避免直接修改状态对象的属性
- 使用 equatable 或重写 == 和 hashCode 支持比较

**示例**：

```dart
class TextElementData extends ElementData {
  final String text;
  final TextStyle style;
  
  const TextElementData({
    required String id,
    required Rect bounds,
    required this.text,
    this.style = const TextStyle(),
    double rotation = 0.0,
  }) : super(
    id: id,
    bounds: bounds,
    rotation: rotation,
  );
  
  @override
  TextElementData copyWith({
    String? id,
    Rect? bounds,
    double? rotation,
    String? text,
    TextStyle? style,
  }) {
    return TextElementData(
      id: id ?? this.id,
      bounds: bounds ?? this.bounds,
      rotation: rotation ?? this.rotation,
      text: text ?? this.text,
      style: style ?? this.style,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextElementData &&
        other.id == id &&
        other.bounds == bounds &&
        other.rotation == rotation &&
        other.text == text &&
        other.style == style;
  }
  
  @override
  int get hashCode => Object.hash(id, bounds, rotation, text, style);
}

// 状态更新示例
void updateText(String elementId, String newText) {
  final element = getElementById(elementId);
  if (element is TextElementData) {
    // 创建新副本而非修改原对象
    final updatedElement = element.copyWith(text: newText);
    updateElement(updatedElement);
  }
}
```

### 2.5 分层架构

**原则**：明确的层次结构，确保单向依赖关系

**实践**：
- 建立清晰的层次结构（数据、领域、应用、界面）
- 确保依赖关系单向流动，高层依赖低层
- 使用接口打破循环依赖
- 每层都有明确定义的职责和边界

**示例**：

```
┌──────────────────────────────────────┐
│            界面层 (UI Layer)          │
│  Canvas, CanvasController, Widgets   │
└───────────────────┬──────────────────┘
                    │ 依赖
                    ▼
┌──────────────────────────────────────┐
│          应用层 (Application Layer)    │
│  CommandManager, InteractionEngine   │
└───────────────────┬──────────────────┘
                    │ 依赖
                    ▼
┌──────────────────────────────────────┐
│          领域层 (Domain Layer)         │
│   ElementData, Commands, Services    │
└───────────────────┬──────────────────┘
                    │ 依赖
                    ▼
┌──────────────────────────────────────┐
│          数据层 (Data Layer)           │
│    Repositories, Storage, Models     │
└──────────────────────────────────────┘
```

**代码组织示例**：

```
lib/
├── data/                  # 数据层
│   ├── models/            # 数据模型
│   ├── repositories/      # 数据访问
│   └── storage/           # 存储实现
│
├── domain/                # 领域层
│   ├── commands/          # 命令定义
│   ├── entities/          # 领域实体
│   └── services/          # 领域服务
│
├── application/           # 应用层
│   ├── managers/          # 管理器
│   ├── engines/           # 引擎实现
│   └── state/             # 状态管理
│
├── ui/                    # 界面层
│   ├── widgets/           # UI组件
│   ├── controllers/       # 控制器
│   └── painters/          # 自定义绘制
│
└── utils/                 # 通用工具
    ├── extensions/        # 扩展方法
    └── helpers/           # 辅助函数
```

## 3. 代码实现最佳实践

### 3.1 接口定义

**实践原则**：
- 设计最小化、功能聚焦的接口
- 使用抽象类定义核心契约
- 避免"万能"接口，遵循接口隔离原则
- 为复杂接口提供基础实现类

**示例**：

```dart
// 良好的接口设计
abstract class ElementRenderer {
  // 核心渲染方法
  void render(Canvas canvas, ElementData element);
  
  // 判断是否需要重绘
  bool shouldRepaint(ElementData oldElement, ElementData newElement);
  
  // 获取元素边界
  Rect getElementBounds(ElementData element);
}

// 基础实现类
abstract class BaseElementRenderer implements ElementRenderer {
  @override
  bool shouldRepaint(ElementData oldElement, ElementData newElement) {
    // 默认实现，子类可覆盖以提供更高效的实现
    return oldElement != newElement;
  }
  
  @override
  Rect getElementBounds(ElementData element) {
    return element.bounds;
  }
}

// 具体实现示例
class TextElementRenderer extends BaseElementRenderer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  
  @override
  void render(Canvas canvas, ElementData element) {
    if (element is! TextElementData) return;
    
    // 文本元素渲染实现
    _textPainter.text = TextSpan(
      text: element.text,
      style: element.style,
    );
    
    _textPainter.layout();
    
    canvas.save();
    // 应用变换
    final center = element.bounds.center;
    canvas.translate(center.dx, center.dy);
    canvas.rotate(element.rotation);
    canvas.translate(-center.dx, -center.dy);
    
    // 绘制文本
    _textPainter.paint(
      canvas, 
      Offset(element.bounds.left, element.bounds.top),
    );
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(ElementData oldElement, ElementData newElement) {
    if (oldElement is! TextElementData || newElement is! TextElementData) {
      return true;
    }
    
    return oldElement.text != newElement.text ||
           oldElement.style != newElement.style ||
           oldElement.bounds != newElement.bounds ||
           oldElement.rotation != newElement.rotation;
  }
}
```
