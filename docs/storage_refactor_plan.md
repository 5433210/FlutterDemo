# 存储层重构计划

## 1. 现状分析

当前系统存在以下问题：

- PathHelper包含了太多职责
- LocalWorkImageStorage仍然依赖于PathHelper
- 存储相关的功能分散在不同位置

## 2. 重构目标

1. 将PathHelper的功能合理分配到IStorage和IWorkImageStorage
2. 通过依赖注入实现接口解耦
3. 完全移除PathHelper依赖

## 3. 接口设计

### 3.1 IStorage接口

```dart
abstract class IStorage {
  // 基础文件操作
  Future<void> deleteFile(String path);
  Future<bool> fileExists(String path);
  Future<String> saveTempFile(List<int> bytes);

  // 目录操作
  Future<void> cleanupTempDirectory({Duration maxAge});
  Future<void> ensureDirectoryExists(String path);
  Future<void> ensureFileExists(String path);

  // 工具方法
  String generateUniqueFileName({String? prefix, required String extension});
  Uint8List createMinimalPngBytes();
  Future<void> createPlaceholderImage(String path);

  // 路径管理
  Future<String> getAppDataPath();
  Future<Directory> getTempDirectory();
  void validatePathSafety(String path);
}
```

### 3.2 IWorkImageStorage接口

```dart
abstract class IWorkImageStorage {
  // Work图片路径管理
  Future<String> getWorkImageDir(String workId, String imageId);
  Future<String> getWorkOriginalImagePath(String workId, String imageId, String ext);
  Future<String> getWorkImportedImagePath(String workId, String imageId);
  Future<String> getWorkImageThumbnailPath(String workId, String imageId);
  Future<String> getWorkPath(String workId);
  Future<String> getWorkCoverThumbnailPath(String workId);

  // Work图片操作
  Future<void> deleteWorkImage(String workId, String imagePath);
  Future<List<String>> getWorkImages(String workId);
  Future<String> saveWorkImage(String workId, File image);
  Future<void> ensureWorkDirectoryExists(String workId);
  Future<bool> workCoverThumbnailExists(String workId);
}
```

## 4. 实现类

### 4.1 LocalStorageImpl

```dart
class LocalStorageImpl implements IStorage {
  final String _appDataPath;
  
  LocalStorageImpl(this._appDataPath);

  @override
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw StorageException('Failed to delete file', path, e);
    }
  }

  // 实现其他IStorage方法...
}
```

### 4.2 LocalWorkImageStorage

```dart
class LocalWorkImageStorage implements IWorkImageStorage {
  final IStorage _storage;

  LocalWorkImageStorage(this._storage);

  @override
  Future<String> saveWorkImage(String workId, File image) async {
    try {
      final imageId = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(image.path);
      
      // 使用注入的_storage处理基础存储操作
      final imageDir = await getWorkImageDir(workId, imageId);
      await _storage.ensureDirectoryExists(imageDir);
      
      final targetPath = path.join(imageDir, 'original$extension');
      await image.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to save work image',
        workId,
        image.path,
        e,
      );
    }
  }

  // 实现其他IWorkImageStorage方法...
}
```

## 5. 异常处理

```dart
class StorageException implements Exception {
  final String message;
  final String path;
  final dynamic originalError;

  StorageException(this.message, this.path, this.originalError);

  @override
  String toString() => 'StorageException: $message (path: $path)';
}

class WorkImageStorageException implements Exception {
  final String message;
  final String workId;
  final String path;
  final dynamic originalError;

  WorkImageStorageException(
    this.message,
    this.workId,
    this.path,
    this.originalError,
  );

  @override
  String toString() =>
    'WorkImageStorageException: $message (workId: $workId, path: $path)';
}
```

## 6. 依赖注入配置

```dart
// lib/infrastructure/providers/storage_providers.dart
final storageProvider = Provider<IStorage>((ref) {
  return LocalStorageImpl(AppConfig.dataPath);
});

final workImageStorageProvider = Provider<IWorkImageStorage>((ref) {
  final storage = ref.watch(storageProvider);
  return LocalWorkImageStorage(storage);
});
```

## 7. 迁移策略

1. 创建新的实现类
   - 实现LocalStorageImpl
   - 实现LocalWorkImageStorage
   - 完整测试新实现

2. 切换依赖
   - 更新ServiceProvider配置
   - 修改所有使用PathHelper的代码
   - 验证功能完整性

3. 清理代码
   - 删除PathHelper
   - 删除未使用的代码
   - 运行测试确保无异常

## 8. 测试计划

### 8.1 单元测试

1. LocalStorageImpl
   - 文件操作测试
   - 路径管理测试
   - 异常处理测试

2. LocalWorkImageStorage
   - Work图片管理测试
   - 路径生成测试
   - 与IStorage协作测试

### 8.2 集成测试

1. 功能测试
   - 完整的Work图片管理流程
   - 批量操作测试
   - 错误恢复测试

2. 性能测试
   - 并发操作测试
   - 大文件处理测试
   - 批量操作性能测试

## 9. 风险与注意事项

1. 数据安全
   - 确保路径生成逻辑一致
   - 验证文件操作原子性
   - 保护敏感数据

2. 性能优化
   - 减少不必要的IO操作
   - 优化文件操作效率
   - 考虑添加缓存机制

3. 可维护性
   - 保持代码清晰简洁
   - 添加完整的文档
   - 确保测试覆盖率
