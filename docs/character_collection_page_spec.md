# 集字管理页面实现方案

## 目录

- [集字管理页面实现方案](#集字管理页面实现方案)
  - [目录](#目录)
  - [概述](#概述)
  - [文件结构](#文件结构)
  - [状态管理](#状态管理)
  - [页面布局](#页面布局)
  - [组件设计](#组件设计)
  - [交互设计](#交互设计)
  - [实现步骤](#实现步骤)

## 概述

集字管理页面负责展示和管理所有已采集的汉字。页面提供网格和列表两种视图模式，支持按简体字和风格进行筛选，并提供批量导出和删除功能。该页面的实现将参考现有的作品浏览页(WorkBrowsePage)架构。

## 文件结构

```
lib/presentation/pages/works/
└── character_collection_page.dart           // 主页面
└── components/                             // 组件目录
    ├── content/                           // 内容展示组件
    │   ├── character_grid_view.dart       // 网格视图
    │   └── character_list_view.dart       // 列表视图
    ├── detail/                           // 详情组件
    │   ├── character_preview.dart        // 集字预览
    │   └── character_info_panel.dart     // 信息面板
    ├── filter/                           // 筛选组件
    │   └── character_filter_panel.dart    // 筛选面板
    └── character_collection_toolbar.dart   // 工具栏
```

## 状态管理

使用Riverpod进行状态管理，主要状态类设计如下：

```dart
class CharacterCollectionState {
  final List<Character> characters;         // 集字列表
  final ViewMode viewMode;                 // 视图模式
  final Set<String> selectedCharacters;     // 已选中的集字ID
  final CharacterFilter filter;            // 筛选条件
  final bool isLoading;                    // 加载状态
  final String? error;                     // 错误信息
  final String? selectedCharacterId;       // 当前选中的集字ID
  
  // 构造函数
  const CharacterCollectionState({
    required this.characters,
    required this.viewMode,
    required this.selectedCharacters,
    required this.filter,
    this.isLoading = false,
    this.error,
    this.selectedCharacterId,
  });

  // copyWith方法用于创建状态副本
  CharacterCollectionState copyWith({...});
}

// 筛选条件
class CharacterFilter {
  final String? searchQuery;              // 搜索关键词
  final List<String> styles;              // 选中的书法风格
  final List<String> tools;               // 选中的书写工具
  final SortOption sortOption;            // 排序选项
  
  // ...构造函数和方法
}
```

## 页面布局

1. 左侧列表区（35%宽度）
   - 顶部工具栏
     - 搜索框：支持简体字/作品名称搜索
     - 筛选按钮组：书法风格、书写工具多选
     - 批量操作按钮：导出、删除
     - 视图模式切换按钮
   - 内容区
     - 网格视图（默认）
       - 集字图片预览
       - 简体字显示
       - 来源作品名称
     - 列表视图
       - 包含完整元数据信息
     - 底部分页/加载更多

2. 右侧详情区（65%宽度）
   - 顶部工具栏
     - 编辑按钮
     - 查看原作按钮
   - 集字预览区
     - 支持缩放平移
     - 显示参考网格（可选）
   - 信息面板（可折叠）
     - 基础信息卡片
       - 简体字
       - 繁体字
       - 风格
       - 书写工具
     - 来源信息卡片
       - 作品名称（可点击跳转）
       - 在原作中位置
     - 关联字帖卡片
       - 使用该集字的字帖列表
       - 点击可跳转至对应字帖

## 组件设计

1. CharacterCollectionToolbar

   ```dart
   CharacterCollectionToolbar({
     required ViewMode viewMode,
     required Function(ViewMode) onViewModeChanged,
     required Function(String) onSearch,
     required bool batchMode,
     required Function(bool) onBatchModeChanged,
     required int selectedCount,
     required VoidCallback onDeleteSelected,
   })
   ```

2. CharacterGridView/ListView

   ```dart
   CharacterGridView({
     required List<Character> characters,
     required bool batchMode,
     required Set<String> selectedCharacters,
     required Function(String, bool) onSelectionChanged,
     required Function(String) onItemTap,
   })
   ```

3. CharacterPreview

   ```dart
   CharacterPreview({
     required Character character,
     required bool showGrid,
     double initialScale = 1.0,
     void Function(double)? onScaleChanged,
   })
   ```

4. CharacterInfoPanel

   ```dart
   CharacterInfoPanel({
     required Character character,
     required List<Practice> relatedPractices,
     required VoidCallback onViewOriginal,
     required VoidCallback onEdit,
   })
   ```

## 交互设计

1. 列表操作
   - 单击列表项：在右侧详情区显示详情
   - Shift/Ctrl多选：支持批量操作
   - 双击预览区：放大至全屏预览
   - 拖拽支持：将集字拖拽到字帖编辑器

2. 批量操作
   - 导出选中项：支持多种格式
   - 删除选中项：二次确认

3. 查看原作
   - 在新窗口打开原作品
   - 自动定位到集字位置
   - 高亮显示集字区域

4. 状态同步
   - 自动保存查看历史
   - 记住上次浏览位置
   - 缓存预览图片

## 实现步骤

1. 创建Model和Repository层
   - Character模型定义
   - CharacterRepository接口
   - CharacterRepositoryImpl实现

2. 状态管理实现
   - CharacterCollectionProvider
   - 状态初始化和更新逻辑
   - 批量操作处理

3. UI组件开发
   - 主页面框架
   - 工具栏组件
   - 列表视图组件
   - 详情展示组件

4. 功能支持
   - 搜索和筛选
   - 视图切换
   - 批量操作
   - 详情预览

5. 性能优化
   - 列表虚拟化
   - 图片延迟加载
   - 状态缓存
