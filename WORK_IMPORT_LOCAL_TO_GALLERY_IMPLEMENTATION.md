# 作品导入对话框本地图片先入图库功能实现总结

## 功能需求
作品导入对话框中，用户选择导入时，如果图片是用户选择从本地导入的，要先将图片添加到图库后，再进行导入处理（与从图库导入保持一致）。

## 实现方案

### 1. 数据结构优化
在`WorkImportState`中新增`imageFromGallery`字段来跟踪每张图片的来源：
- `true`: 来自图库
- `false`: 来自本地文件系统

```dart
class WorkImportState {
  /// 跟踪图片来源：如果为true表示来自图库，false表示来自本地文件
  final List<bool> imageFromGallery;
  // ...
}
```

### 2. 图片添加逻辑
#### 2.1 本地图片添加 (`addImages`)
- 通过文件选择器或传入的文件列表添加图片
- 自动标记为本地文件：`imageFromGallery.add(false)`

#### 2.2 图库图片添加 (`addImagesFromGallery`)
- 通过图库选择对话框添加图片
- 自动标记为图库文件：`imageFromGallery.add(true)`

### 3. 核心导入逻辑 (`importWork`)

```dart
Future<bool> importWork() async {
  // 1. 检测本地图片
  final localImageIndexes = <int>[];
  for (int i = 0; i < state.images.length; i++) {
    if (i < state.imageFromGallery.length && !state.imageFromGallery[i]) {
      localImageIndexes.add(i);
    }
  }

  // 2. 将本地图片添加到图库
  for (final index in localImageIndexes) {
    try {
      final file = state.images[index];
      await _libraryImportService.importFile(file.path);
    } catch (e) {
      // 记录错误但继续处理
    }
  }

  // 3. 执行正常的作品导入流程
  await _workService.importWork(state.images, work);
}
```

### 4. 状态维护和同步

#### 4.1 删除操作 (`removeImage`)
- 同时删除图片和对应的来源标记
- 确保两个列表长度保持一致

#### 4.2 重新排序操作 (`reorderImages`)
- 同时对图片列表和来源标记列表进行重新排序
- 保持索引对应关系

#### 4.3 状态重置 (`reset` / `clean`)
- 重置所有状态，包括`imageFromGallery`字段

### 5. 服务集成

#### 5.1 `LibraryImportService`
- 提供`importFile`方法将本地文件添加到图库
- 处理文件复制、缩略图生成、数据库存储等

#### 5.2 依赖注入
在`WorkImportProvider`中注入`LibraryImportService`：
```dart
Provider<WorkImportViewModel>((ref) {
  final workService = ref.read(workServiceProvider);
  final libraryImportService = ref.read(libraryImportServiceProvider);
  return WorkImportViewModel(workService, libraryImportService);
});
```

## 测试验证

创建了测试脚本验证整个流程：
- ✅ 本地图片正确标记为 `false`
- ✅ 图库图片正确标记为 `true`
- ✅ 删除和重排序操作正确同步 `imageFromGallery`
- ✅ 导入时能正确识别需要先添加到图库的本地图片

## 实现文件列表

### 核心修改文件
1. `lib/presentation/viewmodels/states/work_import_state.dart`
   - 新增`imageFromGallery`字段
   - 更新`copyWith`、`clean`、`initial`方法

2. `lib/presentation/viewmodels/work_import_view_model.dart`
   - 实现本地图片先入图库的导入逻辑
   - 修复`reorderImages`方法同步问题
   - 所有操作方法都正确维护`imageFromGallery`

3. `lib/presentation/providers/work_import_provider.dart`
   - 注入`libraryImportServiceProvider`

### 支持服务
4. `lib/application/services/library_import_service.dart`
   - 提供`importFile`方法支持单文件导入

## 用户体验

1. **透明体验**：用户无需感知本地图片会先添加到图库，整个过程自动完成
2. **一致性**：本地图片导入后的处理流程与直接从图库导入完全一致
3. **错误处理**：即使某些图片添加到图库失败，也不会阻止整个导入流程
4. **性能优化**：只有本地图片才会执行添加到图库的操作

## 总结

该功能已完整实现，确保了：
- 本地图片在作品导入前会先添加到图库
- 所有图片操作（删除、重排序）都正确维护来源信息
- 导入流程统一，提供一致的用户体验
- 代码结构清晰，易于维护和扩展
