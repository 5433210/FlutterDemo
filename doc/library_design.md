# 图库功能设计文档

## 1. 功能概述

图库功能主要用于管理和组织图片资源，包括普通图片和纹理图片。这些资源将在字帖编辑过程中使用。功能包括图片的导入、检索、浏览和删除等基本操作。

## 2. 系统架构

### 2.1 数据层

#### 2.1.1 数据库设计

```sql
CREATE TABLE library (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL,  -- 'image' 或 'texture'
    format TEXT NOT NULL,  -- 'png', 'jpg', 'svg' 等
    path TEXT NOT NULL,  -- 本地存储路径
    width INTEGER NOT NULL,  -- 图片宽度
    height INTEGER NOT NULL,  -- 图片高度
    size INTEGER NOT NULL,  -- 文件大小（字节）
    tags TEXT,  -- JSON 格式的标签数组，如 ["风景", "自然", "山水"]
    categories TEXT,  -- JSON 格式的分类数组
    metadata TEXT,  -- JSON 格式的元数据
    is_favorite BOOLEAN NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 图片分类表
CREATE TABLE library_category (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id TEXT,  -- 父分类ID，用于构建分类树
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (parent_id) REFERENCES library_category(id)
);
```

#### 2.1.2 存储结构

```
{app_data}/
  └── library/
      ├── images/
      │   ├── {id}.{format}  -- 原图
      │   └── thumbnails/
      │       └── {id}.jpg   -- 缩略图
      └── textures/
          ├── {id}.{format}  -- 原图
          └── thumbnails/
              └── {id}.jpg   -- 缩略图
```

### 2.2 领域层

#### 2.2.1 实体

```dart
class LibraryItem {
  final String id;
  final String name;
  final String type;
  final String format;
  final String path;
  final int width;
  final int height;
  final int size;
  final List<String> tags;  // 简化为字符串数组
  final List<String> categories;
  final Map<String, dynamic> metadata;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class LibraryCategory {
  final String id;
  final String name;
  final String? parentId;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### 2.2.2 仓储接口

```dart
abstract class ILibraryRepository extends IRepository<LibraryItem> {
  // 继承自通用仓储接口的方法
  Future<List<LibraryItem>> getAll({
    String? type,
    List<String>? tags,
    List<String>? categories,
    String? searchQuery,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool sortDesc = false,
  });
  
  Future<List<LibraryCategory>> getCategories();
  Future<void> addCategory(LibraryCategory category);
  Future<void> updateCategory(LibraryCategory category);
  Future<void> deleteCategory(String id);
  Future<void> toggleFavorite(String id);
}
```

### 2.3 应用层

#### 2.3.1 服务

```dart
class LibraryService {
  final ILibraryRepository _repository;
  final ImageCacheService _imageCache;
  final IStorage _storage;
  
  // 继承自通用服务的方法
  Future<List<LibraryItem>> getItems({
    String? type,
    List<String>? tags,
    List<String>? categories,
    String? searchQuery,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool sortDesc = false,
  });
  
  Future<LibraryItem?> getItem(String id);
  Future<String> addItem(LibraryItem item, Uint8List data);
  Future<void> updateItem(LibraryItem item);
  Future<void> deleteItem(String id);
  Future<void> toggleFavorite(String id);
  
  // 分类管理
  Future<List<LibraryCategory>> getCategories();
  Future<void> addCategory(LibraryCategory category);
  Future<void> updateCategory(LibraryCategory category);
  Future<void> deleteCategory(String id);
  
  // 图片处理
  Future<Uint8List?> getItemData(String id);
  Future<Uint8List?> getThumbnail(String id);
  Future<void> generateThumbnail(String id);
  
  // 数据备份与恢复
  Future<void> backup();
  Future<void> restore(BackupData backup);
}
```

### 2.4 表现层

#### 2.4.1 状态管理

```dart
class LibraryState {
  final List<LibraryItem> items;
  final String? selectedType;
  final List<String> selectedTags;
  final List<String> selectedCategories;
  final String? searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final bool isBatchMode;
  final Set<String> selectedItems;
  final String? selectedItemId;
  final bool isDetailOpen;
  final ViewMode viewMode;
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final String? sortBy;
  final bool sortDesc;
  final List<LibraryCategory> categories;
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final LibraryService _service;
  
  // 继承自通用状态管理的方法
  Future<void> loadInitialData();
  Future<void> loadItems();
  Future<void> addItem(LibraryItem item, Uint8List data);
  Future<void> updateItem(LibraryItem item);
  Future<void> deleteItem(String id);
  Future<void> deleteSelectedItems();
  Future<void> toggleFavorite(String id);
  
  // 分类管理
  Future<void> loadCategories();
  Future<void> addCategory(LibraryCategory category);
  Future<void> updateCategory(LibraryCategory category);
  Future<void> deleteCategory(String id);
  
  // 视图控制
  void selectItem(String id);
  void toggleItemSelection(String id);
  void toggleBatchMode();
  void toggleViewMode();
  void closeDetailPanel();
  void updateFilter(LibraryFilter filter);
  void changePage(int page);
  void updatePageSize(int size);
  void updateSort(String? field, bool desc);
}
```

#### 2.4.2 页面结构

```
lib/
  └── presentation/
      └── pages/
          └── library/
              ├── m3_library_page.dart
              ├── components/
              │   ├── m3_library_grid_view.dart
              │   ├── m3_library_list_view.dart
              │   ├── m3_library_detail_panel.dart
              │   ├── m3_library_filter_panel.dart
              │   ├── m3_library_category_panel.dart
              │   └── m3_library_management_navigation_bar.dart
              └── widgets/
                  └── m3_library_item.dart
```

## 3. 用户界面

### 3.1 主界面布局

- 顶部导航栏：
  - 搜索框
  - 批量模式切换按钮
  - 视图模式切换按钮（网格/列表）
  - 删除选中按钮（批量模式）
  - 导入按钮
  - 备份/恢复按钮

- 左侧面板：
  - 分类管理
    - 新建分类按钮
    - 分类列表
  - 筛选面板
    - 类型筛选（图片/纹理）
    - 尺寸范围筛选
    - 文件大小筛选
    - 日期范围筛选
    - 排序选项
    - 标签筛选（使用多选框）

- 主内容区：
  - 网格视图：显示图片缩略图
  - 列表视图：显示图片详细信息
  - 支持多选操作
  - 支持拖拽导入

- 右侧详情面板：
  - 图片预览（支持缩放）
  - 基本信息（尺寸、大小等）
  - 分类管理
  - 标签编辑（使用输入框+标签显示）
  - 操作按钮（编辑、收藏、删除）

### 3.2 交互设计

- 支持拖拽导入图片
- 支持多选操作
- 支持图片预览和缩放
- 支持分类管理
- 支持标签编辑
- 支持图片信息编辑
- 支持分页加载
- 支持批量删除
- 支持收藏功能

### 3.3 分类管理交互

- **分类显示**
  - 显示分类列表
  - 每个分类显示图片数量
  - 支持两级分类层级

- **分类操作**
  - 新建分类：点击"新建分类"按钮
  - 编辑分类：点击分类右侧的编辑图标
  - 删除分类：点击分类右侧的删除图标
  - 分类排序：通过设置面板调整顺序

- **图片分类操作**
  - 单个图片分类：在详情面板中修改
  - 批量分类：选择多个图片后设置分类

- **分类筛选**
  - 点击分类显示该分类下的图片
  - 支持多选分类

## 4. 技术实现

### 4.1 图片处理

- 使用现有的 `ImageUtils` 类处理图片
- 支持图片格式转换
- 支持图片压缩和优化
- 支持图片预览生成
- 支持缩略图生成

### 4.2 缓存机制

- 使用现有的多级缓存系统
- 实现图片预加载
- 支持缓存清理
- 支持缩略图缓存

### 4.3 错误处理

- 使用现有的 `WorkImageErrorHandler` 处理图片相关错误
- 实现友好的错误提示
- 支持失败重试

### 4.4 数据备份与恢复

- 支持增量备份
- 支持选择性恢复
- 支持备份验证
- 支持自动备份

## 5. 性能优化

### 5.1 图片加载

- 实现图片懒加载
- 使用缩略图预览
- 支持渐进式加载
- 实现分页加载
- 优化缩略图生成

### 5.2 存储优化

- 实现存储空间监控
- 支持自动清理
- 优化存储结构
- 支持文件压缩

### 5.3 检索优化

- 使用索引优化查询
- 支持模糊搜索
- 支持多条件组合搜索
- 支持搜索结果缓存

## 6. 安全性

### 6.1 数据安全

- 实现文件完整性检查
- 支持数据备份
- 防止重复导入
- 支持文件加密

### 6.2 访问控制

- 实现权限检查
- 支持操作日志
- 防止未授权访问
- 支持数据隔离

## 7. 后续优化

### 7.1 功能扩展

- 支持图片编辑
- 支持批量操作
- 支持导入导出
- 支持图片分类管理
- 支持智能分类
- 支持图片分析

### 7.2 性能提升

- 优化搜索算法
- 改进缓存策略
- 优化存储结构
- 优化分页加载
- 优化缩略图生成

## 8. 开发计划

1. 数据库和存储结构实现
2. 核心服务层开发
3. 用户界面实现
4. 功能测试和优化
5. 性能测试和优化
6. 文档完善
您说得对，让我重新设计一个统一的、简化的分类管理交互：

### 分类管理交互设计（统一简化版）

1. **分类显示**

```
左侧面板
└── 分类管理
    ├── 新建分类按钮
    └── 分类列表
        ├── 风景 (12)
        ├── 纹理 (8)
        └── 其他 (5)
```

2. **分类操作**
   - **新建分类**
     - 点击"新建分类"按钮
     - 弹出对话框，输入分类名称
     - 选择父分类（可选）
     - 确认后创建新分类

   - **编辑分类**
     - 点击分类右侧的编辑图标
     - 修改分类名称
     - 修改父分类（可选）

   - **删除分类**
     - 点击分类右侧的删除图标
     - 如果分类下有图片，显示确认对话框
     - 确认后删除分类

3. **图片分类操作**
   - **单个图片分类**
     - 在图片详情面板中
     - 显示当前分类
     - 点击修改分类

   - **批量分类**
     - 选择多个图片
     - 点击顶部工具栏的"设置分类"按钮
     - 选择目标分类

4. **分类筛选**
   - 点击分类显示该分类下的图片
   - 支持多选分类（显示多个分类的图片）

5. **分类统计**
   - 每个分类显示图片数量
   - 例如：`风景 (12)`

6. **分类排序**
   - 通过设置面板调整分类顺序
   - 提供简单的上移/下移按钮

7. **分类搜索**
   - 在分类列表上方提供搜索框
   - 输入关键字快速定位分类

8. **分类展开/折叠**
   - 点击分类前的箭头展开/折叠子分类
   - 提供"展开所有"/"折叠所有"按钮

9. **分类导入/导出**
   - 在设置面板中提供导入/导出选项
   - 支持导入/导出分类结构

10. **分类状态显示**
    - 当前选中的分类高亮显示
    - 包含图片的分类显示特殊图标

11. **分类操作反馈**
    - 操作时显示加载动画
    - 操作成功/失败显示提示信息

12. **响应式布局**
    - 根据屏幕尺寸自动调整布局
    - 小屏幕：单列显示
    - 大屏幕：多列显示

13. **性能优化**
    - 分类列表虚拟滚动
    - 图片懒加载
    - 分类数据缓存

主要简化点：

1. 统一使用点击操作，不再区分桌面端和移动端
2. 移除复杂的拖拽操作
3. 移除手势操作
4. 移除快捷键
5. 简化分类层级，最多支持两级分类
6. 统一使用图标按钮，不再使用右键菜单
7. 统一使用弹出对话框，不再使用底部面板
8. 移除复杂的动画效果
9. 移除触觉反馈
10. 简化分类导入/导出功能
