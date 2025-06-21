# 批量操作功能

这个模块实现了Flutter书法应用的导入导出批量操作功能，支持作品浏览页和集字管理页的数据批量处理。

## 功能概述

### 作品浏览页功能
- **作品导出**：多选操作中增加导出功能，可选择仅导出作品或导出作品+关联集字（默认）
- **作品导入**：批量导入按钮，自动验证有效性，显示进度条
- **批量操作增强**：增加全选和取消选择按钮

### 集字管理页功能
- **集字导出**：多选操作中增加导出功能，可选择仅导出集字或导出集字+来源作品（默认）
- **集字导入**：批量导入按钮，处理仅包含集字数据的情况
- **批量操作增强**：增加全选和取消选择按钮

## 架构设计

### 数据模型层 (`domain/models/import_export/`)

#### 导出数据模型 (`export_data_model.dart`)
- `ExportDataModel`：包含元数据、作品、图片、集字数据和清单
- `ExportMetadata`：导出元数据，包含时间戳、版本、平台信息等
- `ExportManifest`：导出清单，包含汇总、文件列表、统计和验证信息
- `ExportOptions`：导出选项配置
- 相关枚举：`ExportType`、`ExportFormat`等

#### 导入数据模型 (`import_data_model.dart`)
- `ImportDataModel`：包含导出数据、验证结果、冲突信息等
- `ImportValidationResult`：验证结果详情
- `ImportConflictInfo`：冲突信息处理
- `ImportOptions`：导入选项配置
- 相关枚举：`ConflictResolution`、`ImportStatus`等

#### 异常处理 (`import_export_exceptions.dart`)
- `ImportExportException`基类
- `ExportException`和`ImportException`具体异常类
- 详细的错误代码和错误信息处理

### 服务层 (`domain/services/`)

#### 导出服务接口 (`export_service.dart`)
- 导出作品数据、集字数据、完整数据的方法
- 验证、估算大小、检查存储空间等辅助功能
- 进度回调和取消操作支持

#### 导入服务接口 (`import_service.dart`)
- 验证、解析、检查冲突、执行导入等核心方法
- 回滚、预览、估算时间等辅助功能
- 导入历史记录和临时文件清理

#### 事务管理器 (`import_transaction_manager.dart`)
- 完整的事务跟踪和回滚机制
- 数据库操作记录（插入、更新、删除）
- 文件操作记录（创建、复制、移动、备份、删除）
- 支持完整回滚，包括文件和数据库操作的逆向处理

### 状态管理层 (`presentation/providers/`)

#### 批量选择Provider (`batch_selection_provider.dart`)
- `BatchSelectionState`：使用Freezed定义的不可变状态
- 支持作品和集字两种页面类型的选择管理
- 批量模式切换、全选、取消选择等操作
- 详细的日志记录和状态跟踪

### 用户界面层 (`presentation/widgets/batch_operations/`)

#### 批量操作工具栏 (`batch_operations_toolbar.dart`)
- 普通模式和批量模式的双重界面
- 导入、批量导入、导出、删除等操作按钮
- 选择状态显示和项目计数
- 完整的本地化支持

#### 导出对话框 (`export_dialog.dart`)
- 导出类型选择（仅作品、作品+集字等）
- 导出格式选择（JSON、ZIP、备份文件）
- 导出选项配置（包含图片、元数据、压缩等）
- 目标路径选择和导出摘要显示

#### 导入对话框 (`import_dialog.dart`)
- 文件选择和预览功能
- 导入选项配置（验证数据、创建备份等）
- 冲突处理策略选择
- 导入预览和冲突检测显示

#### 进度对话框 (`progress_dialog.dart`)
- 通用进度指示器组件
- 专用的导出和导入进度对话框
- 支持取消操作和详细信息显示

## 使用方法

### 1. 集成到现有页面

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'batch_operations/batch_operations_toolbar.dart';
import 'batch_operations/export_dialog.dart';
import 'batch_operations/import_dialog.dart';

class YourPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchState = ref.watch(batchSelectionProvider);
    
    return Scaffold(
      body: Column(
        children: [
          // 添加批量操作工具栏
          BatchOperationsToolbar(
            pageType: PageType.works, // 或 PageType.characters
            totalItems: yourItems.length,
            onImport: _handleImport,
            onExport: batchState.hasSelection ? _handleExport : null,
            onDelete: batchState.hasSelection ? _handleDelete : null,
            onSelectAll: _handleSelectAll,
            onClearSelection: _handleClearSelection,
          ),
          
          // 您的内容区域
          Expanded(
            child: YourContentWidget(),
          ),
        ],
      ),
    );
  }
}
```

### 2. 实现回调方法

```dart
void _handleImport() {
  showDialog(
    context: context,
    builder: (context) => ImportDialog(
      pageType: PageType.works,
      onImport: (options, filePath) {
        // 执行导入逻辑
        _executeImport(options, filePath);
      },
    ),
  );
}

void _handleExport() {
  final batchState = ref.read(batchSelectionProvider);
  final selectedIds = batchState.selectedWorkIds.toList();
  
  showDialog(
    context: context,
    builder: (context) => ExportDialog(
      pageType: PageType.works,
      selectedIds: selectedIds,
      onExport: (options, targetPath) {
        // 执行导出逻辑
        _executeExport(options, targetPath);
      },
    ),
  );
}
```

### 3. 在列表项中支持批量选择

```dart
ListView.builder(
  itemBuilder: (context, index) {
    final itemId = 'item_$index';
    final isSelected = batchState.selectedWorkIds.contains(itemId);
    
    return ListTile(
      leading: batchState.isBatchMode
          ? Checkbox(
              value: isSelected,
              onChanged: (value) {
                ref.read(batchSelectionProvider.notifier)
                   .toggleWorkSelection(itemId);
              },
            )
          : const Icon(Icons.article),
      title: Text('Item $index'),
      onTap: batchState.isBatchMode
          ? () => ref.read(batchSelectionProvider.notifier)
                     .toggleWorkSelection(itemId)
          : () => _handleItemTap(index),
      selected: isSelected,
    );
  },
)
```

## 本地化支持

所有用户界面文本都支持国际化，相关的本地化字符串已添加到ARB文件中：

### 中文 (`app_zh.arb`)
- `batchImport`：批量导入
- `exportType`：导出格式
- `exportOptions`：导出选项
- `conflictResolution`：冲突处理
- 等等...

### 英文 (`app_en.arb`)
- `batchImport`：Batch Import
- `exportType`：Export Format
- `exportOptions`：Export Options
- `conflictResolution`：Conflict Resolution
- 等等...

## 日志记录

所有操作都遵循项目的日志规范：

```dart
AppLogger.info(
  '开始导出',
  data: {
    'pageType': pageType.name,
    'selectedCount': selectedCount,
    'exportType': exportType.name,
    'targetPath': targetPath,
  },
  tag: 'batch_operations',
);
```

## 示例应用

查看 `batch_operations_example.dart` 文件了解完整的集成示例，包括：
- 如何设置批量选择状态
- 如何处理各种操作回调
- 如何显示进度对话框
- 如何处理错误和成功状态

## 注意事项

1. **状态管理**：确保在页面初始化时设置正确的页面类型
2. **权限处理**：文件导入导出需要适当的存储权限
3. **错误处理**：实现适当的错误处理和用户反馈
4. **性能优化**：大量数据导入导出时考虑分批处理
5. **数据验证**：导入时进行充分的数据验证和冲突检测

## 扩展性

该架构设计考虑了扩展性：
- 可以轻松添加新的导出格式
- 支持自定义冲突处理策略
- 可扩展的验证规则
- 插件化的服务实现

通过实现相应的服务接口，可以轻松集成到现有的数据层和业务逻辑中。 