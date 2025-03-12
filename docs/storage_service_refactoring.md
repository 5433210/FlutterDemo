# 存储服务重构设计

## 1. 重构目标

将LocalStorageImpl和StorageService合并，并将Work相关的功能分离到专门的服务中。

## 2. 类设计

### 2.1 StorageService

```typescript
class StorageService implements IStorage {
  final String basePath;

  // 基础存储操作
  Future<String> saveFile(File file, String path);
  Future<void> deleteFile(String path);
  Future<File> getFile(String path);
  Future<bool> exists(String path);
  Future<List<String>> listFiles(String path);
  Future<String> createDirectory(String path);
  Future<void> deleteDirectory(String path);
  Future<void> clearDirectory(String path);
  Future<int> getFileSize(String path);
  Future<Map<String, dynamic>> getFileInfo(String path);
}
```

### 2.2 WorkStorageService

```typescript
class WorkStorageService {
  final StorageService storage;
  final String workBasePath = 'works';

  // 作品存储操作
  Future<String> saveWorkImage(String workId, String imageId, File file);
  Future<String> saveImportedImage(String workId, String imageId, File file);
  Future<String> saveThumbnail(String workId, String imageId, File file);
  Future<void> deleteWorkImage(String workId, String imageId);
  Future<void> deleteWorkDirectory(String workId);
  Future<List<String>> listWorkImages(String workId);
  Future<bool> hasWorkImage(String workId, String imageId);
}
```

### 2.3 WorkImageService

```typescript
class WorkImageService {
  final WorkStorageService storage;
  final ImageProcessor processor;

  // 作品图片处理
  Future<WorkImage> importImage(String workId, File file);
  Future<WorkImage> rotateImage(WorkImage image, int degrees);
  Future<void> updateCover(String workId, String imageId);
  Future<String> generateThumbnail(File file);
  Future<void> processAndSaveImage(String workId, String imageId, File file);
}
```

## 3. 职责分配

### 3.1 StorageService

- 基础文件系统操作
- 路径管理
- 错误处理
- 文件元数据

### 3.2 WorkStorageService

- 作品文件组织
- 作品目录结构维护
- 作品文件命名
- 作品文件管理

### 3.3 WorkImageService

- 图片导入处理
- 图片转换操作
- 缩略图生成
- 封面管理

## 4. 关键变更

1. 删除LocalStorageImpl，将基础功能合并到StorageService
2. 将Work相关存储逻辑移至WorkStorageService
3. 将Work相关图片处理移至WorkImageService
4. 简化Provider配置

## 5. 迁移步骤

1. 创建新的StorageService实现
2. 实现WorkStorageService
3. 更新WorkImageService
4. 更新依赖注入配置
5. 删除LocalStorageImpl
6. 更新使用点的代码

## 6. 注意事项

### 6.1 兼容性

- 保持现有路径结构
- 维护接口稳定性
- 保证数据完整性

### 6.2 性能

- 减少文件操作
- 优化路径生成
- 合理使用缓存

### 6.3 可靠性

- 完善错误处理
- 添加日志记录
- 实现恢复机制
