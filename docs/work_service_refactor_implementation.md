# WorkService 重构实现计划 (V2)

## 1. 重构范围调整

### 1.1 WorkImageService 职责

扩展 WorkImageService 以包含：
1. 图片清理逻辑
2. 图片批量处理优化

```dart
class WorkImageService {
  // 已有方法
  Future<List<WorkImage>> processWorkImages(String workId, List<File> files);
  Future<String> saveWorkImage(String workId, File image);
  Future<List<String>> getWorkImages(String workId);
  
  // 新增批量处理方法
  Future<List<WorkImage>> processImagesInBatches(
    String workId,
    List<File> files, {
    int batchSize = 3,
  });
  
  // 新增图片清理方法
  Future<void> cleanupWorkImages(String workId);
}
```

### 1.2 WorkService 职责

专注于业务逻辑处理：
1. 作品数据管理
2. 业务流程编排
3. 错误处理

```dart
class WorkService {
  final WorkRepository _repository;
  final WorkImageService _imageService;
  
  // 核心业务方法
  Future<WorkEntity> importWork(List<File> files, WorkEntity work);
  Future<WorkEntity> updateWork(WorkEntity work);
  Future<void> deleteWork(String workId);
}
```

## 2. 具体实现细节

### 2.1 导入作品流程

```dart
// WorkService
Future<WorkEntity> importWork(List<File> files, WorkEntity work) async {
  return handleOperation('importWork', () async {
    // 1. 前置检查
    if (work.id == null) throw ArgumentError('作品ID不能为空');
    if (files.isEmpty) throw ArgumentError('图片文件不能为空');

    // 2. 处理图片（使用批量处理）
    final images = await _imageService.processImagesInBatches(
      work.id!,
      files,
    );

    // 3. 更新作品信息
    final updatedWork = work.copyWith(
      imageCount: images.length,
      updateTime: DateTime.now(),
    );

    // 4. 保存到数据库
    return await _repository.save(updatedWork);
  });
}
```

### 2.2 删除作品流程

```dart
// WorkService
Future<void> deleteWork(String workId) async {
  return handleOperation('deleteWork', () async {
    // 1. 删除数据
    await _repository.delete(workId);
    
    // 2. 清理图片
    await _imageService.cleanupWorkImages(workId);
  });
}
```

## 3. 错误处理

### 3.1 WorkService 错误处理

```dart
mixin WorkServiceErrorHandler {
  Future<T> handleOperation<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } catch (e, stack) {
      AppLogger.error(
        'Operation failed: $operation',
        tag: 'WorkService',
        error: e,
        stackTrace: stack,
      );
      throw WorkServiceException(operation, e.toString());
    }
  }
}
```

### 3.2 WorkImageService 错误处理

```dart
mixin WorkImageErrorHandler {
  Future<T> handleImageOperation<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } catch (e, stack) {
      AppLogger.error(
        'Image operation failed: $operation',
        tag: 'WorkImageService',
        error: e,
        stackTrace: stack,
      );
      throw WorkImageException(operation, e.toString());
    }
  }
}
```

## 4. 实施步骤

1. 增强 WorkImageService
   - 添加批量处理功能
   - 添加图片清理功能
   - 优化错误处理

2. 简化 WorkService
   - 移除图片处理逻辑
   - 聚焦业务流程
   - 优化错误处理

3. 测试验证
   - 单元测试
   - 集成测试
   - 性能测试

## 5. 预期效果

1. 责任更清晰
   - WorkImageService 处理所有图片相关操作
   - WorkService 专注于业务逻辑

2. 代码更简洁
   - 减少重复代码
   - 统一的错误处理
   - 清晰的接口设计

3. 性能更好
   - 优化的批量处理
   - 更好的资源管理
   - 可靠的错误恢复
