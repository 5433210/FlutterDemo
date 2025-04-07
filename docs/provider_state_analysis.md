# Provider状态分析

## 1. Provider 概览

### 1.1 核心Provider

```mermaid
graph TB
    A[toolModeProvider] -->|影响| B[characterCollectionProvider]
    C[workImageProvider] -->|提供数据| B
    B -->|更新| D[RegionsPainter]
    B -->|更新| E[AdjustableRegionPainter]
    A -->|控制| F[ImageView交互模式]
```

1. toolModeProvider
   - 类型：`StateNotifierProvider<ToolModeNotifier, Tool>`
   - 功能：管理工具模式状态
   - 状态：
     - pan: 拖拽模式
     - select: 框选模式
     - multiSelect: 多选模式
     - erase: 擦除模式

2. characterCollectionProvider
   - 类型：管理字符集合状态
   - 主要数据：
     - regions: 区域列表
     - selectedIds: 选中的区域ID集合
     - modifiedIds: 已修改但未保存的区域ID集合
     - isAdjusting: 是否处于调整状态
   - 功能：
     - 加载工作数据
     - 管理区域选择状态
     - 处理区域修改
     - 保存区域数据

3. workImageProvider
   - 类型：管理工作图像状态
   - 主要数据：
     - imageData: 图像数据
     - workId: 当前工作ID
     - currentPageId: 当前页面ID
     - imageWidth/imageHeight: 图像尺寸
   - 功能：
     - 加载图像数据
     - 管理图像加载状态
     - 处理图像验证

## 2. 状态关系

### 2.1 数据流

```mermaid
sequenceDiagram
    participant Tool as toolModeProvider
    participant Image as workImageProvider
    participant Collection as characterCollectionProvider
    participant View as ImageView
    
    Image->>Collection: 提供图像数据
    Collection->>Collection: 加载区域数据
    Tool->>View: 控制交互模式
    View->>Collection: 触发状态更新
    Collection->>View: 更新视觉展示
```

### 2.2 状态依赖

```mermaid
classDiagram
    class ToolModeState {
        +Tool currentMode
        +Tool previousMode
        +toggleMode()
        +setMode()
    }
    
    class CharacterCollectionState {
        +List~Region~ regions
        +Set~String~ selectedIds
        +Set~String~ modifiedIds
        +bool isAdjusting
        +updateRegion()
        +selectRegion()
    }
    
    class WorkImageState {
        +Uint8List imageData
        +String workId
        +String pageId
        +bool loading
        +loadWorkImage()
    }

    CharacterCollectionState --> ToolModeState
    CharacterCollectionState --> WorkImageState
```

## 3. 状态同步机制

### 3.1 初始化流程

```mermaid
sequenceDiagram
    participant Page as CharacterCollectionPage
    participant Image as workImageProvider
    participant Collection as characterCollectionProvider
    
    Page->>Image: 加载图像
    Image-->>Page: 图像加载完成
    Page->>Collection: 设置图像数据
    Page->>Collection: 加载区域数据
    Collection-->>Page: 更新UI状态
```

### 3.2 状态更新流程

```mermaid
sequenceDiagram
    participant User as 用户操作
    participant View as ImageView
    participant Tool as toolModeProvider
    participant Collection as characterCollectionProvider
    
    User->>Tool: 切换工具模式
    Tool->>View: 更新交互模式
    User->>View: 操作选区
    View->>Collection: 更新选区状态
    Collection->>View: 触发重绘
```

## 4. 错误处理

### 4.1 图像加载错误

- workImageProvider 负责处理:
  - 图像数据验证
  - 加载状态管理
  - 错误信息传递

### 4.2 状态同步错误

- characterCollectionProvider 负责处理:
  - 数据加载失败
  - 状态更新冲突
  - 保存失败处理

## 5. 性能优化

### 5.1 状态更新优化

- 批量更新机制
- 选择性刷新
- 延迟处理

### 5.2 数据加载优化

- 图像数据缓存
- 选区数据延迟加载
- 状态变更防抖

## 6. 调试支持

### 6.1 调试模式

- debugOptionsProvider
  - 控制网格显示
  - 显示坐标信息
  - 显示区域中心点
  - 控制日志级别
