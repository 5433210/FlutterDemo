# 存储系统重构实现计划

## 1. 重构步骤

### 1.1 StorageService 实现

```dart
// 1. 创建新的StorageService类
class StorageService implements IStorage {
  final String basePath;
  final ImageProcessor imageProcessor;
  
  // 基础存储操作
  Future<String> saveFile(File file, String path);
  Future<void> deleteFile(String path);
  Future<File> getFile(String path);
  Future<bool> exists(String path);
  
  // 图片处理集成
  Future<File> processImage(File file, ImageConfig config);
  Future<File> createThumbnail(File file);
}
```

### 1.2 WorkStorageService 实现

```dart
// 2. 创建WorkStorageService类
class WorkStorageService {
  final StorageService storage;
  
  // 作品文件管理
  Future<String> saveWorkImage(String workId, String imageId, File file);
  Future<File> getWorkImage(String workId, String imageId);
  Future<void> deleteWorkImage(String workId, String imageId);
  Future<List<String>> listWorkImages(String workId);
  
  // 封面处理
  Future<void> updateWorkCover(String workId, String imageId);
  Future<File> getWorkCover(String workId);
}
```

### 1.3 WorkImageService 实现

```dart
// 3. 更新WorkImageService类
class WorkImageService {
  final WorkStorageService storage;
  final WorkImageRepository repository;
  
  // 图片管理
  Future<WorkImage> importImage(String workId, File file);
  Future<WorkImage> updateImage(WorkImage image, File file);
  Future<void> deleteImage(WorkImage image);
  
  // 图片处理
  Future<WorkImage> rotateImage(WorkImage image, int degrees);
  Future<void> generateThumbnail(WorkImage image);
}
```

## 2. 重构顺序

1. StorageService实现
   - 删除LocalStorageImpl
   - 创建新的StorageService
   - 迁移基础存储功能
   - 添加图片处理集成

2. WorkStorageService实现
   - 创建新的WorkStorageService
   - 实现作品存储逻辑
   - 实现目录管理
   - 实现文件命名规则

3. WorkImageService更新
   - 更新构造函数
   - 重构图片处理方法
   - 添加数据库同步
   - 优化错误处理

4. Provider配置更新
   - 更新StorageProvider
   - 配置WorkStorageProvider
   - 更新WorkImageProvider
   - 删除旧的Provider

## 3. 文件变更

### 3.1 需要删除的文件

- lib/infrastructure/storage/local_storage_impl.dart

### 3.2 需要创建的文件

- lib/application/services/storage/storage_service.dart
- lib/application/services/storage/work_storage_service.dart

### 3.3 需要更新的文件

- lib/application/services/work/work_image_service.dart
- lib/application/providers/storage_providers.dart
- lib/application/providers/service_providers.dart

## 4. 测试计划

1. StorageService测试
   - 基础文件操作测试
   - 图片处理测试
   - 错误处理测试

2. WorkStorageService测试
   - 作品文件管理测试
   - 目录结构测试
   - 文件命名测试

3. WorkImageService测试
   - 图片导入测试
   - 数据同步测试
   - 错误恢复测试

## 5. 重构检查清单

- [ ] 删除LocalStorageImpl
- [ ] 实现新的StorageService
- [ ] 实现WorkStorageService
- [ ] 更新WorkImageService
- [ ] 更新Provider配置
- [ ] 添加单元测试
- [ ] 更新文档
- [ ] 进行集成测试
