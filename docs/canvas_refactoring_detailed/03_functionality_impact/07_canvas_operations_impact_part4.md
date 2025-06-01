## 二、画布操作功能影响分析

### 1. 画布归位（位置重置）

**现有实现**:
- 重置缩放和平移状态
- 通知UI更新

**重构影响**:
- **修改**: 画布归位操作改为命令模式
- **删除**: 直接修改画布变换状态的代码
- **新增**: `ResetCanvasViewCommand`命令类和专用视口状态管理器
- **保留**: 默认视图计算逻辑

**调整方案**:
```dart
// 旧实现
void resetCanvasView() {
  _canvasScale = 1.0;
  _canvasOffset = Offset.zero;
  notifyListeners();
}

// 新实现
void resetCanvasView() {
  final command = ResetCanvasViewCommand();
  commandManager.executeCommand(command);
}

// 新增的命令实现
class ResetCanvasViewCommand implements Command {
  double? _previousScale;
  Offset? _previousOffset;
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 保存当前视图状态
    _previousScale = stateManager.viewportState.scale;
    _previousOffset = stateManager.viewportState.offset;
    
    // 重置到默认视图
    stateManager.viewportState.resetView();
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    if (_previousScale != null && _previousOffset != null) {
      // 恢复之前的视图状态
      stateManager.viewportState.setTransform(_previousScale!, _previousOffset!);
    }
  }
}

// 新增的视口状态管理器
class ViewportState extends ChangeNotifier {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  
  double get scale => _scale;
  Offset get offset => _offset;
  
  void setTransform(double scale, Offset offset) {
    bool changed = false;
    
    if (_scale != scale) {
      _scale = scale;
      changed = true;
    }
    
    if (_offset != offset) {
      _offset = offset;
      changed = true;
    }
    
    if (changed) {
      notifyListeners();
    }
  }
  
  void resetView() {
    setTransform(1.0, Offset.zero);
  }
  
  // 转换全局坐标到本地坐标
  Offset globalToLocal(Offset position) {
    return (position - _offset) / _scale;
  }
  
  // 转换本地坐标到全局坐标
  Offset localToGlobal(Offset position) {
    return position * _scale + _offset;
  }
}
```

### 2. 画布平移

**现有实现**:
- 跟踪拖动事件
- 更新画布偏移量
- 通知UI更新

**重构影响**:
- **修改**: 画布平移操作移至交互引擎，通过命令模式实现
- **删除**: 直接修改画布偏移的代码
- **新增**: `PanCanvasCommand`命令类和专用平移工具
- **保留**: 平移计算逻辑

**调整方案**:
```dart
// 旧实现
void handleCanvasPan(Offset delta) {
  _canvasOffset += delta;
  notifyListeners();
}

// 新实现 - 交互引擎中
class CanvasPanTool implements InteractionTool {
  Offset? _lastPosition;
  PanCanvasCommand? _currentCommand;
  
  @override
  void handleInput(InputEvent event, InteractionState state) {
    // 仅在按下空格键(或中键)时启用平移工具
    final isPanMode = state.currentTool == ToolType.pan || 
                     event.modifiers.contains(ModifierKey.space);
    
    if (!isPanMode) return;
    
    switch (event.type) {
      case InputEventType.down:
        _lastPosition = event.position;
        _currentCommand = null;
        break;
        
      case InputEventType.move:
        if (_lastPosition != null) {
          final delta = event.position - _lastPosition!;
          
          // 如果是第一次移动，创建命令
          if (_currentCommand == null) {
            _currentCommand = PanCanvasCommand(
              initialOffset: stateManager.viewportState.offset,
            );
          }
          
          // 更新命令中的当前偏移
          _currentCommand!.updateDelta(delta);
          
          // 应用平移（不提交命令，只预览）
          _currentCommand!.previewExecute(stateManager);
          
          _lastPosition = event.position;
        }
        break;
        
      case InputEventType.up:
        if (_currentCommand != null) {
          // 提交命令
          commandManager.executeCommand(_currentCommand!);
          _currentCommand = null;
        }
        
        _lastPosition = null;
        break;
    }
  }
}

// 新增的命令实现
class PanCanvasCommand implements Command {
  final Offset initialOffset;
  Offset _currentDelta = Offset.zero;
  
  PanCanvasCommand({required this.initialOffset});
  
  void updateDelta(Offset delta) {
    _currentDelta += delta;
  }
  
  // 用于实时预览
  void previewExecute(CanvasStateManager stateManager) {
    // 计算新的偏移
    final newOffset = initialOffset + _currentDelta;
    
    // 更新视口状态
    stateManager.viewportState.setTransform(
      stateManager.viewportState.scale,
      newOffset,
    );
  }
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 实际执行时使用预览的结果，不需要额外操作
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    // 恢复原始偏移
    stateManager.viewportState.setTransform(
      stateManager.viewportState.scale,
      initialOffset,
    );
  }
}
```

### 3. 画布缩放

**现有实现**:
- 处理缩放手势或鼠标滚轮事件
- 更新缩放因子
- 可能调整偏移以保持焦点位置
- 通知UI更新

**重构影响**:
- **修改**: 画布缩放操作移至交互引擎，通过命令模式实现
- **删除**: 直接修改画布缩放的代码
- **新增**: `ZoomCanvasCommand`命令类和专用缩放工具
- **保留**: 缩放计算逻辑和边界检查

**调整方案**:
```dart
// 旧实现
void handleCanvasZoom(double scaleDelta, Offset focalPoint) {
  // 计算新的缩放因子
  final newScale = (_canvasScale * scaleDelta).clamp(_minScale, _maxScale);
  
  // 调整偏移以保持焦点位置
  final focalPointDelta = focalPoint - _canvasOffset;
  final newOffset = focalPoint - focalPointDelta * (newScale / _canvasScale);
  
  _canvasScale = newScale;
  _canvasOffset = newOffset;
  
  notifyListeners();
}

// 新实现 - 交互引擎中
class CanvasZoomTool implements InteractionTool {
  @override
  void handleInput(InputEvent event, InteractionState state) {
    if (event.type == InputEventType.zoom) {
      final scaleDelta = event.scaleDelta;
      final focalPoint = event.position;
      
      final command = ZoomCanvasCommand(
        scaleDelta: scaleDelta,
        focalPoint: focalPoint,
        initialScale: stateManager.viewportState.scale,
        initialOffset: stateManager.viewportState.offset,
      );
      
      commandManager.executeCommand(command);
    }
  }
}

// 新增的命令实现
class ZoomCanvasCommand implements Command {
  final double scaleDelta;
  final Offset focalPoint;
  final double initialScale;
  final Offset initialOffset;
  
  static const double minScale = 0.1;
  static const double maxScale = 10.0;
  
  ZoomCanvasCommand({
    required this.scaleDelta,
    required this.focalPoint,
    required this.initialScale,
    required this.initialOffset,
  });
  
  @override
  void execute(CanvasStateManager stateManager) {
    // 计算新的缩放因子
    final newScale = (initialScale * scaleDelta).clamp(minScale, maxScale);
    
    // 调整偏移以保持焦点位置
    final focalPointDelta = focalPoint - initialOffset;
    final newOffset = focalPoint - focalPointDelta * (newScale / initialScale);
    
    // 更新视口状态
    stateManager.viewportState.setTransform(newScale, newOffset);
  }
  
  @override
  void undo(CanvasStateManager stateManager) {
    // 恢复原始变换
    stateManager.viewportState.setTransform(initialScale, initialOffset);
  }
}
```

## 三、功能迁移清单与实施计划

### 1. 代码修改分类

#### 1.1 需要修改的组件

| 组件                 | 修改内容                                  | 优先级 |
|---------------------|------------------------------------------|--------|
| 元素基本操作处理器      | 改为使用命令模式和不可变数据                | 高     |
| 元素组合操作处理器      | 改为使用命令模式和适当的数据模型            | 高     |
| 选择机制              | 迁移至交互引擎和选择状态管理器              | 高     |
| 元素控制点处理         | 迁移至交互引擎，创建专用的控制点类          | 高     |
| 层级操作处理器         | 改为使用命令模式和Z索引管理                | 中     |
| 辅助功能处理器         | 改为使用命令模式和专用服务                 | 中     |
| 画布视图操作处理器      | 迁移至交互引擎和视口状态管理器             | 高     |

#### 1.2 需要删除的代码

| 代码部分                   | 删除原因                       | 替代方案                         |
|---------------------------|------------------------------|----------------------------------|
| 直接修改元素集合的代码       | 违反命令模式和不可变数据原则      | 使用命令类和状态管理器               |
| 内联状态管理代码            | 违反关注点分离                 | 使用专用状态管理器                   |
| 直接操作UI更新的代码         | 违反分层架构                   | 使用状态通知机制                     |
| 直接修改选择状态的代码       | 违反命令模式                   | 使用专用选择命令和选择状态管理器         |
| 直接修改画布变换的代码       | 违反命令模式                   | 使用专用视口命令和视口状态管理器         |

#### 1.3 需要保留的代码

| 代码部分                 | 保留原因                     | 调整方式                         |
|------------------------|-----------------------------|---------------------------------|
| 元素数据结构              | 核心业务逻辑                  | 转换为不可变模型，添加copyWith方法   |
| 碰撞检测算法              | 复杂性高且经过优化             | 迁移至专用服务                     |
| 网格贴附算法              | 复杂性高且经过优化             | 迁移至专用网格服务                  |
| 渲染优化代码              | 性能关键部分                  | 迁移至渲染引擎                     |
| 坐标转换工具方法           | 通用工具函数                  | 迁移至工具类或视口状态管理器          |

### 2. 迁移实施计划

#### 2.1 前期准备

1. **创建核心状态管理器**
   - 实现`CanvasStateManager`作为状态的中心存储
   - 实现`ElementState`管理元素数据
   - 实现`SelectionState`管理选择状态
   - 实现`ViewportState`管理视图变换

2. **实现命令系统**
   - 创建`Command`接口和`CommandManager`
   - 实现撤销/重做功能
   - 创建基础命令类

#### 2.2 功能迁移顺序

1. **第一阶段：核心操作**
   - 画布视图操作（平移、缩放、归位）
   - 元素基本操作（添加、删除）
   - 选择操作（单选、框选）

2. **第二阶段：编辑操作**
   - 元素控制点操作（移动、旋转、缩放）
   - 复制/粘贴操作
   - 组合/解组合操作

3. **第三阶段：辅助功能**
   - 层级操作
   - 网格功能
   - 格式刷功能

### 3. 迁移难点与解决方案

#### 3.1 状态一致性

**难点**：确保命令执行、撤销和重做过程中保持状态一致性

**解决方案**：
- 使用严格的不可变数据模型
- 在命令执行前保存完整的相关状态
- 实现验证机制确保状态转换有效
- 为每个命令添加单元测试

#### 3.2 性能优化

**难点**：命令模式可能引入性能开销，特别是对于频繁操作

**解决方案**：
- 对于拖动等高频操作，实现预览机制减少命令创建
- 优化不可变对象的内存使用（如共享不变部分）
- 使用批处理命令合并连续的小操作
- 实现增量渲染减少重绘

#### 3.3 用户体验

**难点**：确保重构后操作的响应性不降低

**解决方案**：
- 使用预览机制提供即时反馈
- 优先处理用户输入事件
- 对大型操作实现进度指示
- 保留关键的操作快捷方式

## 四、总结

本文档分析了Canvas重构对现有功能的影响，包括元素操作和画布操作两大类别。通过引入命令模式、不可变数据和分层架构，新设计将提供更好的可维护性、扩展性和性能。迁移过程将分阶段进行，优先处理核心功能，逐步完成全部功能的重构。

新架构的主要优势：

1. **可靠的撤销/重做**：通过命令模式提供一致的历史记录
2. **状态隔离**：通过状态管理器减少组件间耦合
3. **一致的交互模型**：通过交互引擎统一处理用户输入
4. **清晰的责任分配**：通过分层架构和关注点分离提高可维护性
5. **可测试性**：命令和状态可单独测试，提高代码质量

后续工作应关注性能优化、用户体验改进和完善测试覆盖，确保重构顺利完成并为用户提供更好的画布编辑体验。
