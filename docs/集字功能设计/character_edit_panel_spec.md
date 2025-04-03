## 8. 详细交互时序

字符编辑面板(CharacterEditPanel)是一个用于编辑和处理单个汉字图像的界面组件。它提供了直观的擦除工具、图像处理选项和实时预览功能。

## 2. 界面结构

### 2.1 整体布局

```mermaid
graph TD
    A[字符编辑面板] --- B[顶部工具栏]
    A --- C[中间编辑区]
    A --- D[底部操作栏]

    B --- B1[笔刷反转]
    B --- B2[图像反转]
    B --- B3[轮廓显示]
    B --- B4[笔刷大小]
    B --- B5[撤销]
    B --- B6[重做]

    C --- C1[图像层]
    C1 --- C11[原始图像]
    C1 --- C12[反转效果]
    C --- C2[擦除层]
    C2 --- C21[笔刷预览]
    C2 --- C22[擦除路径]
    C --- C3[轮廓层]
    C3 --- C31[轮廓线条]

    D --- D1[取消按钮]
    D --- D2[完成按钮]
```

### 2.2 组件详细规格

#### 工具栏 (60px高)

```
┌────────────────────────────────────────────┐
│ ⚫ ⚪ ◯  |====○====| 10 ↩ ↪               │
└────────────────────────────────────────────┘
  ① ② ③     ④      ⑤  ⑥ ⑦

① 笔刷反转按钮    ⑤ 笔刷大小数值
② 图像反转按钮    ⑥ 撤销按钮
③ 轮廓显示按钮    ⑦ 重做按钮
④ 笔刷大小滑块
```

#### 编辑区域

```
┌────────────────────────────────────────────┐
│     缩放范围: 0.1x - 5.0x                 │
│     ┌──────────────────┐                  │
│     │                  │                  │
│     │    图像层        │                  │
│     │    擦除层        │                  │
│     │    轮廓层        │                  │
│     │                  │                  │
│     └──────────────────┘                  │
│                                          │
└────────────────────────────────────────────┘
```

#### 底部操作栏 (60px高)

```
┌────────────────────────────────────────────┐
│ [取消]                            [完成]   │
└────────────────────────────────────────────┘
```

## 3. 详细功能说明

### 3.1 擦除功能

#### 3.1.1 点击擦除

- 触发方式：鼠标左键单击
- 擦除效果：
  - 在点击位置创建圆形擦除区域
  - 圆形直径等于当前笔刷大小
  - 瞬时生效，无过渡动画
- 反馈：
  - 触觉反馈（轻触）
  - 视觉反馈（立即显示擦除效果）
- 撤销/重做：
  - 每次点击作为独立操作
  - 可以单独撤销/重做

```mermaid
sequenceDiagram
    participant U as 用户
    participant P as 面板
    participant C as 画布
    participant E as EraseController
    
    U->>P: 鼠标点击
    P->>C: 传递点击事件
    C->>C: 判断Alt键状态
    C->>C: 触发触觉反馈
    C->>E: handleEraseStart(position)
    E->>E: 创建擦除路径
    E->>E: 记录历史状态
    E->>C: 通知更新
    C->>C: 重绘界面
    C->>E: handleEraseEnd()
    E->>E: 完成擦除操作
    E->>C: 延迟更新轮廓
```

#### 3.1.2 拖动擦除

- 触发方式：鼠标左键按住拖动
- 擦除效果：
  - 生成连续的擦除路径
  - 路径宽度等于笔刷大小
  - 实时显示擦除效果
- 路径优化：
  - 点密度控制：每隔笔刷大小/2采样一个点
  - 路径平滑：自动插入3个插值点
  - 实时绘制：跟随鼠标移动即时显示
- 操作控制：
  - 开始：按下左键
  - 结束：松开左键
  - 中断：按下Alt键
- 撤销/重做：
  - 整段路径作为一个操作
  - 可以完整撤销/重做
  
```mermaid
sequenceDiagram
    participant U as 用户
    participant P as 面板
    participant C as 画布
    participant E as EraseController
    
    U->>P: 按下鼠标
    P->>C: 开始拖动
    C->>E: handleEraseStart(position)
    
    loop 拖动过程
        U->>P: 移动鼠标
        P->>C: 更新位置
        C->>C: 计算插值点
        C->>E: handleEraseUpdate(position)
        E->>E: 更新路径
        E->>C: 通知重绘
    end
    
    U->>P: 释放鼠标
    P->>C: 结束拖动
    C->>E: handleEraseEnd()
    E->>E: 保存路径
    E->>E: 记录历史
    E->>C: 更新轮廓
```

#### 3.1.3 撤销/重做机制

```mermaid
stateDiagram-v2
    [*] --> 初始状态
    初始状态 --> 有修改: 执行操作
    有修改 --> 已撤销: 撤销
    已撤销 --> 有修改: 重做
    有修改 --> 有修改: 新操作
    已撤销 --> 有新修改: 新操作
    有新修改 --> 已撤销: 撤销
    有新修改 --> [*]
```

- 操作历史结构：

```mermaid
classDiagram
    class OperationHistory {
        +List<Operation> undoStack
        +List<Operation> redoStack
        +push(Operation)
        +undo()
        +redo()
        +clear()
    }
    
    class Operation {
        +OperationType type
        +Map<String, dynamic> params
        +DateTime timestamp
        +apply()
        +revert()
    }
    
    class OperationType {
        <<enumeration>>
        CLICK_ERASE
        PATH_ERASE
        MODE_CHANGE
        TRANSFORM
    }
    
    OperationHistory --> Operation
    Operation --> OperationType
```

### 3.2 图像处理模式

#### 3.2.1 轮廓显示模式

```mermaid
sequenceDiagram
    participant U as 用户
    participant P as 面板
    participant C as 画布
    participant D as 轮廓检测器
    
    U->>P: 点击轮廓按钮
    P->>C: 切换轮廓显示
    C->>C: 延迟处理(100ms)
    C->>D: 请求检测
    D->>D: 处理图像
    D->>C: 返回轮廓数据
    C->>C: 绘制轮廓
    C->>P: 更新按钮状态
```

- 开启效果：
  - 实时检测和显示字符轮廓
  - 轮廓线条使用蓝色显示
  - 更新延迟：100ms（防抖）
- 关闭效果：
  - 隐藏轮廓显示
  - 保持当前擦除状态
- 轮廓检测参数：
  - 阈值：128
  - 降噪：0.5
  - 检测范围：整个可见区域
- 性能优化：
  - 增量更新
  - 仅在必要时重新检测
  - 检测过程不阻塞UI

#### 3.2.2 图像反转模式

```mermaid
sequenceDiagram
    participant U as 用户
    participant P as 面板
    participant C as 画布
    participant E as EraseController
    
    U->>P: 点击反转按钮
    P->>E: 切换反转状态
    E->>E: 更新状态
    E->>C: 请求重绘
    C->>C: 应用反转效果
    C->>C: 更新轮廓
    C->>P: 更新按钮状态
    P->>U: 视觉反馈
```

- 开启效果：
  - 图像明暗反转
  - 实时预览
  - 影响轮廓检测结果
- 关闭效果：
  - 恢复原始明暗
  - 实时预览
  - 重新计算轮廓
- 图像处理：
  - 不修改原始数据
  - 仅影响显示效果
  - 可与擦除效果叠加

#### 3.2.3 笔刷反转模式

- 开启效果：
  - 笔刷由擦除变为填充
  - 视觉效果相反
  - 实时预览
- 关闭效果：
  - 恢复标准擦除模式
  - 保持已有编辑效果
- 操作特点：
  - 可随时切换
  - 不影响已完成的编辑
  - 与其他模式可组合

### 3.3 图像显示控制

#### 3.3.1 缩放操作

```mermaid
stateDiagram-v2
    [*] --> 普通显示
    普通显示 --> 缩放中: 开始缩放
    缩放中 --> 缩放中: 更新比例
    缩放中 --> 已缩放: 结束缩放
    已缩放 --> 缩放中: 继续缩放
    已缩放 --> 适应屏幕: 双击
    适应屏幕 --> 普通显示
    
    note right of 缩放中
        计算新比例
        范围检查(0.1-5.0)
        实时更新显示
    end note
```

- 缩放方式：
  1. 鼠标滚轮
     - 向上：放大
     - 向下：缩小
  2. 手势缩放
     - 双指操作
     - 平滑过渡
- 范围控制：
  - 最小：0.1倍
  - 最大：5.0倍
  - 步进：连续

#### 3.3.2 平移操作

```mermaid
sequenceDiagram
    participant User
    participant Canvas
    participant Transform
    
    User->>Canvas: Alt+鼠标按下
    Canvas->>Canvas: 切换为平移模式
    loop 拖动过程
        User->>Canvas: 鼠标移动
        Canvas->>Transform: 更新位置
        Transform->>Canvas: 应用变换
    end
    User->>Canvas: 释放鼠标
    Canvas->>Canvas: 保存位置
```

- 触发方式：Alt+鼠标拖动
- 响应特点：
  - 实时跟随
  - 无边界限制
  - 惯性滚动
- 状态保持：
  - 记住上次位置
  - 支持回弹
  - 自动边界检查

## 4. 性能优化

### 4.1 路径处理优化

```mermaid
flowchart TB
    A[路径点] --> B{需要插值?}
    B -- 是 --> C[创建插值点]
    B -- 否 --> D[直接使用]
    C --> E[批量更新]
    D --> E
    E --> F[重绘界面]
```

### 4.2 轮廓更新优化

```mermaid
flowchart TB
    A[轮廓更新请求] --> B{是否处理中?}
    B -- 是 --> C[跳过更新]
    B -- 否 --> D[延迟100ms]
    D --> E[开始处理]
    E --> F[更新显示]
```

## 5. 数据流

```mermaid
flowchart LR
    A[用户输入] --> B[CharacterEditPanel]
    B --> C[EraseController]
    C --> D[图像处理]
    D --> E[轮廓检测]
    E --> F[显示更新]
    F --> B
```

## 6. 错误处理

### 6.1 图像处理错误

```mermaid
flowchart TB
    A[图像处理] --> B{是否成功?}
    B -- 是 --> C[更新显示]
    B -- 否 --> D[恢复状态]
    D --> E[显示错误]
```

## 7. 注意事项

1. 图像处理
   - 所有编辑操作在单独图层
   - 保持原始图像不变
   - 确保图像质量不损失

2. 性能考虑
   - 大图像处理优化
   - 内存使用监控
   - 响应时间控制

3. 用户体验
   - 操作连贯性
   - 实时反馈
   - 状态清晰可见
