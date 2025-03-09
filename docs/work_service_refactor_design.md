# WorkService 重构设计方案

## 1. 问题分析

当前 WorkService 存在以下问题：

1. 职责过重
   - 同时处理数据库操作和文件系统操作
   - 包含复杂的图片处理逻辑
   - 处理对象转换和元数据解析

2. 依赖耦合
   - 直接依赖多个服务
   - 直接调用工具类

3. 错误处理分散
   - 每个方法都有重复的错误处理代码
   - 日志记录模式重复

## 2. 重构目标

1. 简化接口设计
   - 直接使用 WorkRepository
   - 整合图片处理和存储接口
   - 移除冗余的抽象层

2. 依赖关系优化
   - 减少直接依赖
   - 使用已有接口
   - 明确职责边界

3. 统一错误处理
   - 集中的错误处理逻辑
   - 标准化的日志记录
   - 一致的错误返回

## 3. 接口设计

### 3.1 核心业务接口

```dart
abstract class IWorkService {
  /// 获取作品实体
  Future<WorkEntity?> getWorkEntity(String id);
  
  /// 导入作品
  Future<void> importWork(List<File> files, WorkEntity data);
  
  /// 更新作品
  Future<void> updateWork(WorkEntity work);
  
  /// 删除作品
  Future<void> deleteWork(String workId);
  
  /// 查询作品列表
  Future<List<WorkEntity>> queryWorks(WorkFilter filter);
}
```

### 3.2 图片处理和存储服务

```dart
abstract class IWorkImageService {
  /// 处理和保存作品图片
  Future<List<WorkImage>> processWorkImages(String workId, List<File> files);
  
  /// 获取作品图片
  Future<List<WorkImage>> getWorkImages(String workId);
  
  /// 获取作品缩略图
  Future<String?> getWorkThumbnail(String workId);
  
  /// 删除作品相关图片
  Future<void> deleteWorkImages(String workId);
}
```

## 4. 具体实现

### 4.1 工作服务实现

```dart
class WorkService implements IWorkService {
  final WorkRepository _repository;
  final IWorkImageService _imageService;
  
  WorkService(this._repository, this._imageService);
  
  @override
  Future<void> importWork(List<File> files, WorkEntity data) async {
    return handleOperation(
      'importWork',
      () async {
        // 1. 验证数据
        if (data.id == null) throw ArgumentError('作品ID不能为空');
        if (files.isEmpty) throw ArgumentError('图片文件不能为空');
        
        // 2. 处理图片
        final images = await _imageService.processWorkImages(data.id!, files);
        
        // 3. 更新图片数量
        data = data.copyWith(imageCount: images.length);
        
        // 4. 保存作品数据
        await _repository.saveWork(data);
      },
      data: {'workId': data.id},
    );
  }
  
  @override
  Future<void> deleteWork(String workId) async {
    return handleOperation(
      'deleteWork',
      () async {
        // 1. 删除数据库记录
        await _repository.deleteWork(workId);
        
        // 2. 删除相关图片
        await _imageService.deleteWorkImages(workId);
      },
      data: {'workId': workId},
    );
  }
}
```

### 4.2 图片服务实现

```dart
class WorkImageService implements IWorkImageService {
  final IWorkImageStorage _storage;
  final IWorkImageProcessing _processor;

  @override
  Future<List<WorkImage>> processWorkImages(
    String workId,
    List<File> files,
  ) async {
    return handleOperation(
      'processWorkImages',
      () async {
        // 1. 验证并准备目录
        await PathHelper.ensureWorkDirectoryExists(workId);
        
        // 2. 处理每个图片
        final processed = <WorkImage>[];
        for (var i = 0; i < files.length; i++) {
          // 2.1 优化图片
          final optimized = await _processor.optimize(files[i]);
          
          // 2.2 生成缩略图
          final thumbnail = await _processor.generateWorkThumbnail(optimized);
          
          // 2.3 保存到永久存储
          final imagePath = await _storage.saveWorkImage(workId, optimized);
          
          // 2.4 添加到结果
          processed.add(WorkImage.create(path: imagePath, index: i));
        }
        
        return processed;
      },
      data: {'workId': workId, 'fileCount': files.length},
    );
  }
}
```

### 4.3 统一错误处理

```dart
mixin WorkServiceErrorHandler {
  Future<T> handleOperation<T>(
    String operation,
    Future<T> Function() action, {
    Map<String, dynamic>? data,
    bool rethrowError = true,
  }) async {
    try {
      return await action();
    } catch (e, stack) {
      AppLogger.error(
        'Operation failed: $operation',
        tag: runtimeType.toString(),
        error: e,
        stackTrace: stack,
        data: data,
      );
      
      if (rethrowError) {
        if (e is ArgumentError) {
          rethrow; // 参数错误直接抛出
        }
        throw WorkServiceException(operation, e.toString());
      }
      
      return Future.value(); // 如果不重新抛出，返回默认值
    }
  }
}

class WorkServiceException implements Exception {
  final String operation;
  final String message;
  
  WorkServiceException(this.operation, this.message);
  
  @override
  String toString() => 'WorkServiceException: $operation - $message';
}
```

## 5. 依赖注入配置

```dart
final workServiceProvider = Provider<IWorkService>((ref) {
  return WorkService(
    ref.watch(workRepositoryProvider),
    ref.watch(workImageServiceProvider),
  );
});

final workImageServiceProvider = Provider<IWorkImageService>((ref) {
  return WorkImageService(
    ref.watch(workImageStorageProvider),
    ref.watch(workImageProcessorProvider),
  );
});
```

## 6. 重构步骤

1. 创建新的错误处理工具
   - 实现 WorkServiceErrorHandler mixin
   - 创建 WorkServiceException 类

2. 实现核心服务
   - 按新接口实现 WorkService
   - 添加统一错误处理

3. 实现图片服务
   - 整合存储和处理功能
   - 使用错误处理工具

4. 更新依赖注入
   - 配置 Provider
   - 更新现有代码的依赖

5. 迁移和测试
   - 逐步替换现有实现
   - 添加单元测试
   - 验证错误处理

## 7. 预期效果

1. 更清晰的责任划分
2. 统一的错误处理机制
3. 更容易进行测试
4. 更好的可维护性
5. 更简洁的接口设计
