# Canvas 重构代码文件清单

## 概述

本文档详细列出了字帖编辑页Canvas重构过程中需要增加、修改和删除的代码文件，以及整体文件结构的调整。这份清单将指导开发团队在重构过程中对代码库进行系统性的变更，同时确保系统的稳定性和功能完整性。

**重构范围说明：** 本次重构仅针对字帖编辑页（Practice Edit Page）的画布功能，其他使用画布的页面（如字符编辑页）不在本次重构范围内，但可以在未来阶段逐步迁移到新架构。

## 文件结构变更

### 当前文件结构（实际）

通过分析项目代码，当前画布功能相关代码分散在以下位置：

```
lib/
  ├── presentation/
  │   ├── pages/
  │   │   ├── practices/
  │   │   │   ├── m3_practice_edit_page.dart            # 画布编辑页面
  │   │   │   └── widgets/
  │   │   │       ├── canvas_gesture_handler.dart       # 画布手势处理
  │   │   │       ├── canvas_control_points.dart        # 画布控制点
  │   │   │       └── m3_practice_edit_canvas.dart      # 主画布组件
  │   │   └── library/
  │   │       └── components/
  │   │           └── box_selection_painter.dart        # 框选绘制器
  │   └── widgets/
  │       ├── character_collection/
  │       │   ├── adjustable_region_painter.dart        # 可调整区域绘制器
  │       │   ├── regions_painter.dart                  # 区域绘制器
  │       │   └── selection_painters.dart               # 选择绘制器
  │       └── practice/
  │           ├── practice_edit_controller.dart         # 画布编辑控制器
  │           ├── practice_edit_state.dart              # 画布状态管理
  │           ├── advanced_collection_painter.dart      # 高级集合绘制器
  │           ├── canvas_capture.dart                   # 画布捕获
  │           ├── thumbnail_generator.dart              # 缩略图生成
  │           └── property_panels/                      # 属性面板
  │               ├── justified_text_renderer.dart      # 文本渲染器
  │               ├── m3_practice_property_panel_image.dart # 图像属性面板
  │               └── m3_practice_property_panel_page.dart  # 页面属性面板
  │           └── export/
  │               └── page_renderer.dart                # 页面渲染器
  ├── utils/
  │   ├── coordinate_transformer.dart                   # 坐标转换
  │   └── image/
  │       └── image_utils.dart                          # 图像工具
  ├── tools/
  │   └── image/
  │       └── image_utils.dart                          # 图像工具（重复）
 
```

### 问题分析

当前实现存在以下主要问题：

1. **代码分散**：画布相关功能分散在多个目录，缺乏统一管理
2. **职责混乱**：渲染、状态管理和交互逻辑混杂在一起
3. **状态管理不一致**：多个组件各自管理状态，导致同步困难
4. **缺乏命令模式**：无法支持可靠的撤销/重做功能
5. **紧耦合架构**：组件间依赖关系复杂，难以单独测试和修改
6. **特殊文件问题**：`collection_element_renderer.dart`等文件存在结构性问题

### 重构后文件结构

重构后，将创建专门的`canvas`模块，采用分层架构进行组织：

```
lib/
  ├── canvas/                        # 新增：统一的画布模块
  │   ├── core/                      # 新增：核心层
  │   │   ├── canvas_state_manager.dart      # 状态管理中心
  │   │   ├── interfaces/                    # 接口定义
  │   │   │   ├── command.dart               # 命令接口
  │   │   │   ├── element_data.dart          # 元素数据接口
  │   │   │   ├── renderer.dart              # 渲染器接口
  │   │   │   └── interaction_tool.dart      # 交互工具接口
  │   │   │
  │   │   ├── models/                        # 数据模型
  │   │   │   ├── element_data.dart          # 元素数据基类
  │   │   │   ├── bounds.dart                # 边界数据模型
  │   │   │   └── styles.dart                # 样式数据模型
  │   │   │
  │   │   └── commands/                      # 命令系统
  │   │       ├── command_manager.dart       # 命令管理器
  │   │       └── batch_command.dart         # 批处理命令
  │   │
  │   ├── state/                     # 新增：状态层
  │   │   ├── element_state.dart             # 元素状态
  │   │   ├── selection_state.dart           # 选择状态
  │   │   ├── viewport_state.dart            # 视口状态
  │   │   ├── grid_state.dart                # 网格状态
  │   │   ├── interaction_state.dart         # 交互状态
  │   │   └── history_state.dart             # 历史记录状态
  │   │
  │   ├── rendering/                 # 新增：渲染引擎
  │   │   ├── rendering_engine.dart          # 渲染引擎
  │   │   ├── element_renderer_factory.dart  # 渲染器工厂
  │   │   ├── element_renderer/              # 元素渲染器
  │   │   │   ├── base_element_renderer.dart # 基础渲染器
  │   │   │   ├── shape_renderer.dart        # 形状渲染器
  │   │   │   ├── text_renderer.dart         # 文本渲染器
  │   │   │   ├── image_renderer.dart        # 图像渲染器
  │   │   │   ├── group_renderer.dart        # 组合渲染器
  │   │   │   └── collection_renderer.dart   # 集合渲染器（替代problematic原文件）
  │   │   │
  │   │   ├── strategies/                    # 渲染策略
  │   │   │   ├── standard_rendering_strategy.dart # 标准渲染
  │   │   │   ├── viewport_clip_strategy.dart     # 视口裁剪
  │   │   │   └── layer_rendering_strategy.dart   # 分层渲染
  │   │   │
  │   │   └── cache/                         # 缓存机制
  │   │       ├── render_cache.dart          # 渲染缓存
  │   │       └── texture_manager.dart       # 纹理管理器
  │   │
  │   ├── interaction/               # 新增：交互引擎
  │   │   ├── interaction_engine.dart        # 交互引擎
  │   │   ├── input_event.dart               # 输入事件
  │   │   ├── tools/                         # 交互工具
  │   │   │   ├── selection_tool.dart        # 选择工具
  │   │   │   ├── move_tool.dart             # 移动工具
  │   │   │   ├── resize_tool.dart           # 缩放工具
  │   │   │   ├── rotation_tool.dart         # 旋转工具
  │   │   │   ├── pan_tool.dart              # 平移工具
  │   │   │   └── zoom_tool.dart             # 缩放工具
  │   │   │
  │   │   ├── handlers/                      # 事件处理器
  │   │   │   ├── control_point_handler.dart # 控制点处理
  │   │   │   ├── keyboard_handler.dart      # 键盘处理
  │   │   │   └── gesture_handler.dart       # 手势处理
  │   │   │
  │   │   └── control_points/                # 控制点
  │   │       ├── control_point.dart         # 控制点基类
  │   │       ├── resize_control_point.dart  # 缩放控制点
  │   │       └── rotation_control_point.dart# 旋转控制点
  │   │
  │   ├── services/                  # 新增：服务层
  │   │   ├── hit_test_service.dart          # 碰撞检测服务
  │   │   ├── clipboard_service.dart         # 剪贴板服务
  │   │   ├── format_painter_service.dart    # 格式刷服务
  │   │   ├── element_repository.dart        # 元素仓库
  │   │   ├── snapshot_service.dart          # 快照服务
  │   │   └── export_service.dart            # 导出服务
  │   │
  │   ├── ui/                        # 新增：UI层
  │   │   ├── canvas_widget.dart             # 画布组件
  │   │   ├── canvas_painter.dart            # 画布绘制器
  │   │   ├── control_panel.dart             # 控制面板
  │   │   ├── property_panel.dart            # 属性面板
  │   │   ├── overlays/                      # 覆盖层
  │   │   │   ├── selection_overlay.dart     # 选择覆盖层
  │   │   │   └── grid_overlay.dart          # 网格覆盖层
  │   │   │
  │   │   └── widgets/                       # 辅助组件
  │   │       ├── tool_button.dart           # 工具按钮
  │   │       └── color_picker.dart          # 颜色选择器
  │   │
  │   ├── compatibility/             # 新增：兼容层
  │   │   ├── legacy_adapter.dart            # 旧API适配器
  │   │   ├── canvas_controller_adapter.dart # 控制器适配器
  │   │   └── migration_utils.dart           # 迁移工具
  │   │
  │   └── utils/                     # 新增：工具类
  │       ├── id_generator.dart              # ID生成
  │       └── geometry_utils.dart            # 几何计算
  │lib/
  ├── presentation/                  # 修改：删除移至canvas模块的代码
  │   ├── pages/
  │   │   └── practices/
  │   │       ├── m3_practice_edit_page.dart # 修改：使用新Canvas API
  │   │       └── widgets/                   # 大部分删除或修改
  │   └── widgets/
  │       └── practice/                      # 大部分删除或修改
  └── ...
```

## 具体文件变更清单

### 新增文件（按模块）

#### 1. 核心层 (lib/canvas/core/)

| 文件路径 | 核心功能 | 职责说明 |
|---------|---------|----------|
| `core/canvas_state_manager.dart` | 状态管理 | 集中管理和协调各个子状态，为命令系统提供统一接口 |
| `core/interfaces/command.dart` | 接口定义 | 定义命令模式的基础接口和契约 |
| `core/interfaces/element_data.dart` | 接口定义 | 定义元素数据的不可变接口规范 |
| `core/interfaces/renderer.dart` | 接口定义 | 定义渲染器的通用接口和合约 |
| `core/interfaces/interaction_tool.dart` | 接口定义 | 定义交互工具的通用接口和行为规范 |
| `core/models/element_data.dart` | 数据模型 | 实现不可变元素数据基类，支持copyWith模式 |
| `core/models/bounds.dart` | 数据模型 | 定义元素边界的不可变数据结构 |
| `core/models/styles.dart` | 数据模型 | 定义元素样式的不可变数据结构 |
| `core/commands/command_manager.dart` | 命令系统 | 管理命令的执行、撤销和重做队列 |
| `core/commands/batch_command.dart` | 命令系统 | 实现复合命令，支持多个命令作为一个原子操作 |

#### 2. 命令实现 (lib/canvas/core/commands/)

| 文件路径 | 核心功能 | 职责说明 |
|---------|---------|----------|
| `core/commands/element/add_element_command.dart` | 元素命令 | 实现添加元素的命令 |
| `core/commands/element/delete_element_command.dart` | 元素命令 | 实现删除元素的命令 |
| `core/commands/element/update_element_command.dart` | 元素命令 | 实现更新元素属性的命令 |
| `core/commands/element/move_elements_command.dart` | 元素命令 | 实现移动元素的命令 |
| `core/commands/element/resize_elements_command.dart` | 元素命令 | 实现调整元素大小的命令 |
| `core/commands/element/rotate_elements_command.dart` | 元素命令 | 实现旋转元素的命令 |
| `core/commands/element/group_elements_command.dart` | 元素命令 | 实现组合多个元素的命令 |
| `core/commands/element/ungroup_elements_command.dart` | 元素命令 | 实现解组合元素的命令 |
| `core/commands/element/reorder_element_command.dart` | 元素命令 | 实现调整元素层级顺序的命令 |
| `core/commands/selection/select_elements_command.dart` | 选择命令 | 实现选择元素的命令 |
| `core/commands/selection/clear_selection_command.dart` | 选择命令 | 实现清除选择的命令 |
| `core/commands/viewport/pan_canvas_command.dart` | 视图命令 | 实现平移画布的命令 |
| `core/commands/viewport/zoom_canvas_command.dart` | 视图命令 | 实现缩放画布的命令 |
| `core/commands/format/copy_format_command.dart` | 格式命令 | 实现复制元素格式的命令 |
| `core/commands/format/apply_format_command.dart` | 格式命令 | 实现应用元素格式的命令 |

#### 3. 状态层 (lib/canvas/state/)

| 文件路径 | 核心功能 | 职责说明 |
|---------|---------|----------|
| `state/element_state.dart` | 状态管理 | 管理画布上所有元素的状态，支持元素的增删改查 |
| `state/selection_state.dart` | 状态管理 | 管理画布元素的选择状态，支持单选和多选 |
| `state/viewport_state.dart` | 状态管理 | 管理画布视图状态，包括平移、缩放和变换矩阵 |
| `state/grid_state.dart` | 状态管理 | 管理网格显示和贴附设置状态 |
| `state/interaction_state.dart` | 状态管理 | 管理当前交互模式和活动工具的状态 |
| `state/history_state.dart` | 状态管理 | 管理命令历史记录，支持撤销/重做操作 |

#### 4. 渲染引擎 (lib/canvas/rendering/)

| 文件路径 | 核心功能 | 职责说明 |
|---------|---------|----------|
| `rendering/rendering_engine.dart` | 渲染核心 | 协调渲染流程，整合各类渲染器和策略 |
| `rendering/element_renderer_factory.dart` | 渲染核心 | 根据元素类型创建对应的渲染器 |
| `rendering/element_renderer/base_element_renderer.dart` | 元素渲染 | 所有元素渲染器的基类，定义通用渲染接口 |
| `rendering/element_renderer/shape_renderer.dart` | 元素渲染 | 负责渲染各类基础形状元素 |
| `rendering/element_renderer/text_renderer.dart` | 元素渲染 | 负责渲染文本元素，支持富文本 |
| `rendering/element_renderer/image_renderer.dart` | 元素渲染 | 负责渲染图像元素，支持缩放和剪裁 |
| `rendering/element_renderer/group_renderer.dart` | 元素渲染 | 负责渲染组合元素，管理子元素渲染 |
| `rendering/element_renderer/collection_renderer.dart` | 元素渲染 | 负责渲染集合元素，替代原有问题文件 |
| `rendering/strategies/standard_rendering_strategy.dart` | 渲染策略 | 实现标准渲染流程，支持所有元素类型 |
| `rendering/strategies/viewport_clip_strategy.dart` | 渲染策略 | 实现基于视口的渲染裁剪优化 |
| `rendering/strategies/layer_rendering_strategy.dart` | 渲染策略 | 实现基于图层的渲染优化 |
| `rendering/cache/render_cache.dart` | 渲染缓存 | 管理渲染结果缓存，提高渲染性能 |
| `rendering/cache/texture_manager.dart` | 资源管理 | 管理图像资源和纹理，支持预加载和释放 |

#### 5. 交互引擎 (lib/canvas/interaction/)

| 文件路径 | 核心功能 | 职责说明 |
|---------|---------|----------|
| `interaction/interaction_engine.dart` | 交互核心 | 管理用户输入处理流程，协调各类交互工具 |
| `interaction/input_event.dart` | 输入处理 | 规范化不同平台的输入事件，提供统一接口 |
| `interaction/tools/selection_tool.dart` | 交互工具 | 实现元素选择功能，支持点选和框选 |
| `interaction/tools/move_tool.dart` | 交互工具 | 实现元素移动功能，支持精确定位 |
| `interaction/tools/resize_tool.dart` | 交互工具 | 实现元素缩放功能，支持保持比例 |
| `interaction/tools/rotation_tool.dart` | 交互工具 | 实现元素旋转功能，支持精确角度 |
| `interaction/tools/pan_tool.dart` | 交互工具 | 实现画布平移功能，支持惯性滚动 |
| `interaction/tools/zoom_tool.dart` | 交互工具 | 实现画布缩放功能，支持定点缩放 |
| `interaction/handlers/control_point_handler.dart` | 事件处理 | 处理控制点交互事件，转发到对应工具 |
| `interaction/handlers/keyboard_handler.dart` | 事件处理 | 处理键盘事件，支持快捷键 |
| `interaction/handlers/gesture_handler.dart` | 事件处理 | 处理触摸手势事件，支持多点触控 |
| `interaction/control_points/control_point.dart` | 控制组件 | 控制点基类，定义通用行为 |
| `interaction/control_points/resize_control_point.dart` | 控制组件 | 实现缩放控制点，支持8个方向控制 |
| `interaction/control_points/rotation_control_point.dart` | 控制组件 | 实现旋转控制点，支持角度吸附 |

#### 6. 服务层 (lib/canvas/services/)

| 文件路径 | 核心功能 | 职责说明 |
|---------|---------|----------|
| `services/hit_test_service.dart` | 业务服务 | 处理点击碰撞检测，支持形状精确检测 |
| `services/clipboard_service.dart` | 业务服务 | 处理复制粘贴操作，支持跨画布传输 |
| `services/format_painter_service.dart` | 业务服务 | 处理格式刷功能，管理格式属性 |
| `services/element_repository.dart` | 数据服务 | 管理元素持久化，支持存储和加载 |
| `services/snapshot_service.dart` | 业务服务 | 管理画布状态快照，支持版本对比 |
| `services/export_service.dart` | 业务服务 | 处理画布导出为图像和PDF |

#### 7. UI层 (lib/canvas/ui/)

| 文件路径 | 核心功能 | 职责说明 |
|---------|---------|----------|
| `ui/canvas_widget.dart` | UI组件 | 主画布Widget，整合各层功能 |
| `ui/canvas_painter.dart` | UI组件 | 画布绘制器，负责实际渲染 |
| `ui/control_panel.dart` | UI组件 | 操作工具栏，提供常用功能入口 |
| `ui/property_panel.dart` | UI组件 | 元素属性面板，支持编辑元素属性 |
| `ui/overlays/selection_overlay.dart` | UI覆盖层 | 选择框和控制点覆盖层 |
| `ui/overlays/grid_overlay.dart` | UI覆盖层 | 网格覆盖层，支持贴附指示 |
| `ui/widgets/tool_button.dart` | UI组件 | 自定义工具按钮，支持状态显示 |
| `ui/widgets/color_picker.dart` | UI组件 | 颜色选择器，支持透明度调节 |

#### 8. 兼容层 (lib/canvas/compatibility/)

| 文件路径 | 核心功能 | 职责说明 |
|---------|---------|----------|
| `compatibility/legacy_adapter.dart` | 兼容适配 | 将旧API调用转换为新架构调用 |
| `compatibility/canvas_controller_adapter.dart` | 兼容适配 | 适配旧控制器接口，转发到新状态管理器 |
| `compatibility/element_adapter.dart` | 兼容适配 | 适配旧元素模型，转换为新数据模型 |
| `compatibility/migration_utils.dart` | 迁移工具 | 辅助旧代码迁移的实用工具 |

### 修改文件清单

| 文件路径 | 修改类型 | 修改内容 |
|---------|---------|----------|
| `presentation/pages/practices/m3_practice_edit_page.dart` | 主要修改 | 使用新Canvas API替代旧直接操作，通过兼容层适配 |
| `presentation/pages/practices/widgets/canvas_control_points.dart` | 部分保留 | 核心逻辑迁移到交互引擎，保留界面部分适配新API |
| `presentation/widgets/practice/practice_edit_controller.dart` | 重构适配 | 重构为通过兼容层调用新命令系统 |
| `presentation/widgets/practice/practice_edit_state.dart` | 重构适配 | 重构为使用新状态管理系统 |
| `presentation/widgets/practice/property_panels/justified_text_renderer.dart` | 功能迁移 | 核心逻辑迁移到渲染引擎，UI部分保留适配 |
| `utils/coordinate_transformer.dart` | 功能增强 | 增强坐标转换功能，并与视口状态管理器集成 |
| `utils/image/image_utils.dart` | 代码整合 | 与tools/image下重复功能整合，消除冗余 |


### 删除文件清单

| 文件路径 | 删除原因 | 替代方案 |
|---------|---------|----------|
| `collection_element_renderer.dart` | 存在严重结构性问题，包括缺失类定义、方法引用错误、缺少shouldRepaint实现等 | 由新的collection_renderer.dart完全替代，不尝试渐进式修复 |
| `presentation/pages/practices/widgets/m3_practice_edit_canvas.dart` | 功能迁移 | 由canvas/ui/canvas_widget.dart替代 |
| `presentation/pages/practices/widgets/canvas_gesture_handler.dart` | 功能迁移 | 由交互引擎的事件处理器替代 |
| `presentation/widgets/practice/advanced_collection_painter.dart` | 功能迁移 | 由渲染引擎的集合渲染器替代 |
| `presentation/widgets/practice/canvas_capture.dart` | 功能迁移 | 由export_service服务替代 |
| `tools/image/image_utils.dart` | 功能重复 | 由utils/image/image_utils.dart替代并增强 |

## 新增文件清单

### 1. 核心层 (lib/canvas/core/)

| 文件路径 | 用途描述 | 功能与职责 |
{{ ... }}
|---------|---------|------------|
| `core/canvas_state_manager.dart` | 状态管理中心 | 集中管理和协调各个子状态，作为命令执行的目标 |
| `core/interfaces/command.dart` | 命令接口 | 定义命令模式的基础接口 |
| `core/interfaces/element_data.dart` | 元素数据接口 | 定义不可变元素数据的通用接口 |
| `core/interfaces/renderer.dart` | 渲染器接口 | 定义元素渲染器的通用接口 |
| `core/interfaces/interaction_tool.dart` | 交互工具接口 | 定义交互工具的通用接口 |
| `core/models/element_data.dart` | 元素数据基类 | 实现不可变元素数据模型 |
| `core/models/bounds.dart` | 边界数据模型 | 定义元素边界的不可变模型 |
| `core/models/styles.dart` | 样式数据模型 | 定义元素样式的不可变模型 |
| `core/commands/command_manager.dart` | 命令管理器 | 管理命令执行、撤销和重做 |
| `core/commands/batch_command.dart` | 批处理命令 | 支持将多个命令作为一个单元执行 |

### 2. 状态管理层 (lib/canvas/state/)

| 文件路径 | 用途描述 | 功能与职责 |
|---------|---------|------------|
| `state/element_state.dart` | 元素状态管理器 | 管理所有元素的状态 |
| `state/selection_state.dart` | 选择状态管理器 | 管理元素选择状态 |
| `state/viewport_state.dart` | 视口状态管理器 | 管理画布视图变换（平移、缩放） |
| `state/grid_state.dart` | 网格状态管理器 | 管理网格显示和贴附设置 |
| `state/interaction_state.dart` | 交互状态管理器 | 管理当前交互模式和工具状态 |
| `state/history_state.dart` | 历史记录状态 | 维护操作历史记录 |

### 3. 命令实现 (lib/canvas/core/commands/)

| 文件路径 | 用途描述 | 功能与职责 |
|---------|---------|------------|
| `core/commands/element/add_element_command.dart` | 添加元素命令 | 实现元素添加操作 |
| `core/commands/element/delete_element_command.dart` | 删除元素命令 | 实现元素删除操作 |
| `core/commands/element/update_element_command.dart` | 更新元素命令 | 实现元素属性更新操作 |
| `core/commands/element/move_elements_command.dart` | 移动元素命令 | 实现元素平移操作 |
| `core/commands/element/resize_elements_command.dart` | 调整大小命令 | 实现元素缩放操作 |
| `core/commands/element/rotate_elements_command.dart` | 旋转元素命令 | 实现元素旋转操作 |
| `core/commands/element/group_elements_command.dart` | 组合元素命令 | 实现元素组合操作 |
| `core/commands/element/ungroup_elements_command.dart` | 解组合命令 | 实现元素解组合操作 |
| `core/commands/element/reorder_element_command.dart` | 元素重排序命令 | 实现元素层级调整操作 |
| `core/commands/selection/select_elements_command.dart` | 选择元素命令 | 实现元素选择操作 |
| `core/commands/selection/clear_selection_command.dart` | 清除选择命令 | 实现清除选择操作 |
| `core/commands/viewport/pan_canvas_command.dart` | 画布平移命令 | 实现画布平移操作 |
| `core/commands/viewport/zoom_canvas_command.dart` | 画布缩放命令 | 实现画布缩放操作 |
| `core/commands/format/copy_format_command.dart` | 复制格式命令 | 实现格式刷复制操作 |
| `core/commands/format/apply_format_command.dart` | 应用格式命令 | 实现格式刷应用操作 |

### 4. 渲染引擎 (lib/canvas/rendering/)

| 文件路径 | 用途描述 | 功能与职责 |
|---------|---------|------------|
| `rendering/rendering_engine.dart` | 渲染引擎主类 | 协调整体渲染流程 |
| `rendering/element_renderer_factory.dart` | 渲染器工厂 | 创建适合不同元素类型的渲染器 |
| `rendering/element_renderer/base_element_renderer.dart` | 基础渲染器 | 定义渲染器基础实现 |
| `rendering/element_renderer/shape_renderer.dart` | 形状渲染器 | 渲染各类基础形状 |
| `rendering/element_renderer/text_renderer.dart` | 文本渲染器 | 渲染文本元素 |
| `rendering/element_renderer/image_renderer.dart` | 图像渲染器 | 渲染图像元素 |
| `rendering/element_renderer/group_renderer.dart` | 组合渲染器 | 渲染组合元素 |
| `rendering/strategies/standard_rendering_strategy.dart` | 标准渲染策略 | 实现基础渲染策略 |
| `rendering/strategies/viewport_clip_strategy.dart` | 视口裁剪策略 | 实现基于视口的渲染优化 |
| `rendering/strategies/layer_rendering_strategy.dart` | 分层渲染策略 | 实现基于层的渲染优化 |
| `rendering/cache/render_cache.dart` | 渲染缓存 | 管理渲染结果缓存 |
| `rendering/cache/texture_manager.dart` | 纹理管理器 | 管理图像资源 |

### 5. 交互引擎 (lib/canvas/interaction/)

| 文件路径 | 用途描述 | 功能与职责 |
|---------|---------|------------|
| `interaction/interaction_engine.dart` | 交互引擎主类 | 协调用户输入处理 |
| `interaction/input_event.dart` | 输入事件 | 规范化不同平台的输入事件 |
| `interaction/tools/selection_tool.dart` | 选择工具 | 实现元素选择交互 |
| `interaction/tools/move_tool.dart` | 移动工具 | 实现元素移动交互 |
| `interaction/tools/resize_tool.dart` | 缩放工具 | 实现元素缩放交互 |
| `interaction/tools/rotation_tool.dart` | 旋转工具 | 实现元素旋转交互 |
| `interaction/tools/pan_tool.dart` | 平移工具 | 实现画布平移交互 |
| `interaction/tools/zoom_tool.dart` | 缩放工具 | 实现画布缩放交互 |
| `interaction/handlers/control_point_handler.dart` | 控制点处理器 | 处理控制点交互 |
| `interaction/handlers/keyboard_handler.dart` | 键盘处理器 | 处理键盘输入 |
| `interaction/handlers/gesture_handler.dart` | 手势处理器 | 处理触摸手势 |
| `interaction/control_points/control_point.dart` | 控制点 | 定义控制点基类 |
| `interaction/control_points/resize_control_point.dart` | 缩放控制点 | 实现缩放控制点 |
| `interaction/control_points/rotation_control_point.dart` | 旋转控制点 | 实现旋转控制点 |

### 6. 服务层 (lib/canvas/services/)

| 文件路径 | 用途描述 | 功能与职责 |
|---------|---------|------------|
| `services/hit_test_service.dart` | 碰撞检测服务 | 处理元素点击和区域选择 |
| `services/clipboard_service.dart` | 剪贴板服务 | 处理复制粘贴操作 |
| `services/format_painter_service.dart` | 格式刷服务 | 处理样式复制应用 |
| `services/element_repository.dart` | 元素仓库 | 管理元素持久化 |
| `services/snapshot_service.dart` | 快照服务 | 管理画布状态快照 |
| `services/export_service.dart` | 导出服务 | 处理画布导出为图像 |

### 7. UI层 (lib/canvas/ui/)

| 文件路径 | 用途描述 | 功能与职责 |
|---------|---------|------------|
| `ui/canvas_widget.dart` | 画布组件 | 主画布UI组件 |
| `ui/canvas_painter.dart` | 画布绘制器 | 自定义绘制器实现 |
| `ui/control_panel.dart` | 控制面板 | 操作工具栏 |
| `ui/property_panel.dart` | 属性面板 | 元素属性编辑器 |
| `ui/overlays/selection_overlay.dart` | 选择覆盖层 | 显示选择框和控制点 |
| `ui/overlays/grid_overlay.dart` | 网格覆盖层 | 显示参考网格 |
| `ui/widgets/tool_button.dart` | 工具按钮 | 自定义工具按钮 |
| `ui/widgets/color_picker.dart` | 颜色选择器 | 自定义颜色选择组件 |

### 8. 兼容层 (lib/canvas/compatibility/)

| 文件路径 | 用途描述 | 功能与职责 |
|---------|---------|------------|
| `compatibility/legacy_adapter.dart` | 旧API适配器 | 将旧API调用转换为新架构 |
| `compatibility/canvas_controller_adapter.dart` | 控制器适配器 | 适配旧控制器接口 |
| `compatibility/element_adapter.dart` | 元素适配器 | 适配旧元素模型 |
| `compatibility/migration_utils.dart` | 迁移工具 | 辅助旧代码迁移的工具 |

## 修改文件清单

| 文件路径 | 修改原因 | 修改内容 |
|---------|---------|---------|
| `canvas/canvas.dart` | 适配新架构 | 重构为使用CanvasStateManager和交互引擎 |
| `canvas/canvas_controller.dart` | 适配新架构 | 重构为使用命令模式和CanvasStateManager |
| `canvas/elements/shape_element.dart` | 适配新数据模型 | 转换为不可变数据模型和工厂模式 |
| `canvas/elements/text_element.dart` | 适配新数据模型 | 转换为不可变数据模型和工厂模式 |
| `canvas/elements/image_element.dart` | 适配新数据模型 | 转换为不可变数据模型和工厂模式 |
| `canvas/elements/group_element.dart` | 适配新数据模型 | 转换为不可变数据模型和工厂模式 |
| `canvas/widgets/canvas_toolbar.dart` | 适配新命令系统 | 修改为触发命令而非直接操作 |
| `canvas/widgets/property_editor.dart` | 适配新数据模型 | 修改为使用不可变数据模型 |
| `canvas/utils/hit_testing.dart` | 迁移到服务层 | 修改为与HitTestService集成 |
| `canvas/utils/geometry.dart` | 功能扩展 | 增强以支持新的交互需求 |

## 删除文件清单

| 文件路径 | 删除原因 | 替代方案 |
|---------|---------|---------|
| `canvas/canvas_selection.dart` | 功能迁移 | 由SelectionState和选择命令取代 |
| `canvas/canvas_painter.dart` | 架构改变 | 由RenderingEngine和元素渲染器取代 |
| `canvas/utils/element_manipulator.dart` | 功能迁移 | 由交互引擎和命令系统取代 |
| `canvas/utils/history_manager.dart` | 功能迁移 | 由CommandManager取代 |
| `canvas/elements/element_factory.dart` | 架构改变 | 由新的工厂模式和状态管理器取代 |
| `canvas/widgets/selection_handles.dart` | 功能迁移 | 由交互引擎的控制点系统取代 |

## 文件结构调整目的与作用

### 1. 分层架构实现

**目的**：实现清晰的关注点分离，降低代码耦合度，提高可维护性和可测试性。

**作用**：
- 核心层定义关键接口和数据模型，是系统的基础
- 状态层管理所有状态，提供一致的状态访问接口
- 命令层实现所有操作，支持撤销/重做
- 服务层提供横切关注点的功能
- UI层仅负责展示和用户输入初始处理

### 2. 命令模式实现

**目的**：支持可靠的撤销/重做功能，规范化操作流程。

**作用**：
- 所有操作通过命令类实现，与直接状态操作解耦
- 命令管理器负责命令执行、撤销和重做
- 每个命令负责保存执行前状态以支持撤销
- 批处理命令支持复杂操作的原子性

### 3. 不可变数据模型

**目的**：提高状态管理的可预测性，减少副作用，支持高效比较和缓存。

**作用**：
- 所有数据模型通过copyWith模式更新
- 减少因直接修改对象导致的bug
- 支持更简单的状态比较和变更检测
- 有利于实现响应式UI更新

### 4. 渲染引擎隔离

**目的**：分离渲染逻辑，支持不同渲染策略，提高渲染性能。

**作用**：
- 渲染引擎独立于状态和交互
- 支持多种渲染策略（标准、视口裁剪、分层）
- 元素渲染器专注于单一元素类型的渲染
- 渲染缓存减少不必要的重绘

### 5. 交互引擎模块化

**目的**：统一处理用户输入，支持不同交互模式，提高交互体验。

**作用**：
- 规范化处理来自不同平台的输入事件
- 交互工具模块化实现不同的交互行为
- 控制点系统提供统一的元素操作机制
- 支持自定义的交互模式和快捷键

### 6. 兼容层设计

**目的**：确保现有代码平稳过渡，支持增量迁移。

**作用**：
- 旧API适配器允许旧代码无缝调用新系统
- 元素适配器实现新旧数据模型转换
- 迁移工具辅助开发者将代码迁移到新架构
- 支持两个系统并行运行的过渡期

## 迁移路径与优先级

### 第一阶段：核心基础设施 (优先级最高)

1. 创建核心接口和数据模型
   - Command接口和基础实现
   - ElementData和基础模型类
   - 渲染和交互接口

2. 实现状态管理器
   - CanvasStateManager
   - ElementState
   - ViewportState

3. 实现命令管理器和基础命令
   - CommandManager
   - 基础元素操作命令
   - 批处理命令

### 第二阶段：基础功能实现 (优先级高)

1. 实现元素基本操作
   - 添加、删除元素命令
   - 移动元素命令
   - 修改元素属性命令

2. 实现选择功能
   - 选择状态管理器
   - 选择命令
   - 选择覆盖层

3. 实现画布视图操作
   - 平移、缩放命令
   - 视口状态管理

4. 实现基础渲染器
   - 渲染引擎
   - 基础形状渲染器
   - 渲染策略框架

### 第三阶段：高级功能实现 (优先级中)

1. 实现元素控制点操作
   - 控制点系统
   - 缩放、旋转工具
   - 交互处理器

2. 实现组合/解组合功能
   - 组合元素数据模型
   - 组合/解组合命令
   - 组合元素渲染器

3. 实现层级操作
   - 层级命令
   - Z索引管理

4. 实现渲染优化策略
   - 视口裁剪
   - 分层渲染
   - 缓存机制

### 第四阶段：兼容层和迁移 (优先级低)

1. 实现旧API适配器
   - CanvasController适配器
   - 元素适配器

2. 调整现有UI组件
   - 工具栏
   - 属性面板

3. 性能优化和完善
   - 性能分析和优化
   - 完善异常处理
   - 增强跨平台兼容性

## 特殊注意事项

1. **现有文件 `collection_element_renderer.dart` 的处理**
   - 根据之前的分析，该文件存在严重的结构性问题
   - 迁移策略是创建全新的替代实现，而不是尝试逐步修复
   - 新实现将位于 `rendering/element_renderer/collection_renderer.dart`
   - 实现时需定义所有必要的类和依赖（TextureConfig, _CharacterPosition等）

2. **Windows/Linux开发兼容性考虑**
   - 考虑到需要在Windows上编译Linux版本的需求，项目配置中加入相关支持
   - 文件行尾符号问题：在CI/CD流程中加入自动转换机制
   - 依赖版本兼容性：增加版本限制和检查机制

## 总结

本文档详细列出了Canvas重构过程中的文件调整清单，包括新增、修改和删除的文件，以及文件结构调整的目的与作用。通过这些调整，Canvas系统将获得更好的可维护性、可扩展性和性能，同时支持更丰富的功能和更好的用户体验。

按照本文档的迁移路径进行重构，可以确保在保持系统稳定性的同时，逐步完成架构升级，最终达到重构的目标。
