# 选区状态和切换分析

## 1. 选区状态概念

### 1.1 基本概念区分

- `Selecting`（选择过程）
  - 表示正在进行的选择动作
  - 包含鼠标拖动过程中的状态
  - 由 `_selectionStart` 和 `_selectionCurrent` 两个点定义
  - 显示为实时更新的矩形框

- `Selection`（选择结果）
  - 表示已完成的选择结果
  - 是一个确定的矩形区域
  - 存储在 `_lastCompletedSelection` 中
  - 可以进入调整模式（Adjusting）

### 1.2 模式差异

1. 框选模式 (Select)
   - Selecting: 显示蓝色半透明框，跟随鼠标实时更新
   - Selection: 完成后显示蓝色边框，可进入调整状态
   - 特点：单次选择，自动进入调整模式

2. 多选模式 (MultiSelect)
   - Selecting: 点击已有区域进行选择
   - Selection: 选中区域显示红色，可以累积多个选区
   - 特点：无调整状态，专注于多个区域的选择

3. 拖拽模式 (Pan)
   - 无 Selecting 状态
   - Selection: 点击区域时显示灰色，纯展示状态
   - 特点：不影响选区，专注于视图操作

### 1.3 状态转换

```mermaid
stateDiagram-v2
    [*] --> Idle: 初始状态
    
    state Select {
        Idle --> Selecting: 开始拖动
        Selecting --> Selection: 释放鼠标
        Selection --> Adjusting: 自动进入
        Adjusting --> Idle: 确认/取消
    }
    
    state MultiSelect {
        Idle --> MultiSelecting: 点击区域
        MultiSelecting --> MultiSelection: 选中叠加
        MultiSelection --> MultiSelecting: 继续选择
        MultiSelection --> Idle: 切换模式
    }
    
    state Pan {
        Idle --> ViewSelection: 点击区域
        ViewSelection --> Idle: 自动恢复
    }
```

## 2. 工具模式分析

### 2.1 工具模式类型

- `pan`: 平移和缩放模式（快捷键V）
  - 主要用于视图操作
  - 选区只读展示
  - 支持缩放和平移

- `select`: 框选工具模式（快捷键R）
  - 用于精确选区创建
  - 支持选区调整
  - 包含旋转功能

- `multiSelect`: 多选工具模式（快捷键M）
  - 用于批量操作
  - 支持多个选区
  - 不支持调整

- `erase`: 擦除模式（快捷键E）
  - 用于删除操作
  - 直接作用于选区

### 2.2 模式状态机

```mermaid
stateDiagram-v2
    [*] --> Pan: 默认模式
    Pan --> Select: 按R键
    Pan --> MultiSelect: 按M键
    Pan --> Erase: 按E键
    Select --> Pan: 按V键
    MultiSelect --> Pan: 按V键
    Erase --> Pan: 按V键
    
    state Pan {
        [*] --> Normal: 初始状态
        Normal --> Dragging: 按住鼠标
        Dragging --> Normal: 释放鼠标
        Normal --> Zooming: 滚轮缩放
        Zooming --> Normal: 缩放结束
    }
    
    state Select {
        [*] --> Idle: 初始状态
        Idle --> Selecting: 开始框选
        Selecting --> Selection: 完成框选
        Selection --> Adjusting: 进入调整
        Adjusting --> Idle: ESC/确认
    }
    
    state MultiSelect {
        [*] --> Idle: 初始状态
        Idle --> Selecting: 点击选择
        Selecting --> Multiple: 继续选择
        Multiple --> Idle: 切换工具
    }
```

## 3. 选区系统组件结构

```mermaid
classDiagram
    class ImageView {
        -TransformationController _controller
        -CoordinateTransformer _transformer
        -bool _isInSelectionMode
        -bool _isPanning
        -bool _isZoomed
        -Offset _selectionStart
        -Offset _selectionCurrent
        -Rect _lastCompletedSelection
        +build()
        +handleKeyEvent()
        +handleMouseMove()
    }

    class SelectionState {
        +bool isSelecting
        +bool hasSelection
        +bool isAdjusting
        +String adjustingRegionId
        +Set~String~ selectedIds
        +Set~String~ modifiedIds
    }
    
    class AdjustableRegion {
        +bool isActive
        +bool isAdjusting
        +int activeHandleIndex
        +double currentRotation
        +List~Offset~ guideLines
        +Rect viewportRect
    }

    ImageView --> SelectionState
    ImageView --> AdjustableRegion
```

## 4. 交互状态和行为

### 4.1 选区创建流程

```mermaid
sequenceDiagram
    participant User as 用户
    participant View as ImageView
    participant State as SelectionState
    participant Region as RegionState
    
    User->>View: 按下鼠标(PanStart)
    View->>State: 开始Selecting
    View->>State: 记录起始点
    User->>View: 拖动鼠标(PanUpdate)
    View->>State: 更新当前点
    View->>View: 绘制临时选框
    User->>View: 释放鼠标(PanEnd)
    View->>State: 完成Selection
    State->>Region: 创建新区域
    Region->>View: 进入调整模式
```

### 4.2 选区调整状态

- 调整模式触发条件：
  - 单击已有区域（仅在select模式）
  - 完成新区域创建
  - 通过快捷键选择

- 调整操作类型：
  - 8个方向控制点调整大小
  - 旋转控制点
  - 整体移动
  - 键盘微调（方向键）

### 4.3 快捷键系统

- 工具切换：
  - V：切换到平移模式
  - R：切换到框选模式
  - M：切换到多选模式
  - E：切换到擦除模式

- 选区操作：
  - ESC：取消当前调整
  - Delete/Backspace：删除选中区域
  - 方向键：微调选区位置（1像素）
  - Shift + 方向键：大幅调整选区位置（10像素）

### 4.4 选区状态指示

- 视觉反馈：
  - 多选模式：红色，透明度0.2
  - 拖拽模式：灰色，透明度0.2
  - 调整模式：蓝色，透明度0.2
  - 未保存：蓝色，透明度0.1
  - 已保存：绿色，透明度0.05

- 信息显示：
  - 尺寸信息：宽x高
  - 旋转角度
  - 鼠标位置

## 5. 坐标系统和状态同步

### 5.1 坐标转换

```mermaid
graph LR
    A[图像坐标] -->|imageRectToViewportRect| B[视口坐标]
    B -->|viewportRectToImageRect| A
```

### 5.2 状态同步机制

```mermaid
flowchart TD
    A[用户操作] --> B[本地状态更新]
    B --> C[视觉更新]
    B --> D[Provider状态更新]
    D --> E[持久化]
    D --> F[其他组件更新]
```

## 6. 错误处理和性能优化

### 6.1 错误处理策略

- 选区验证：
  - 最小尺寸限制（20x20像素）
  - 有效范围检查
  - 坐标转换保护

### 6.2 性能优化措施

- 渲染优化：
  - shouldRepaint 条件判断
  - 分层渲染
  - 视口裁剪
- 状态更新优化：
  - 延迟处理
  - 批量更新
  - 防抖动
