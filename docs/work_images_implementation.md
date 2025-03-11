# Work Images Implementation

## 问题

当前在导入作品时，WorkService的importWork方法没有将处理后的图片信息保存到work_images表中，导致数据不完整。

## 解决方案

### 1. 创建WorkImageRepository接口

在`lib/domain/repositories`目录下创建`work_image_repository.dart`：

```dart
abstract class WorkImageRepository {
  Future<void> saveMany(List<WorkImage> images);
}
```

### 2. 创建WorkImageRepositoryImpl实现

在`lib/infrastructure/repositories`目录下创建`work_image_repository_impl.dart`：

```dart
class WorkImageRepositoryImpl implements WorkImageRepository {
  final DatabaseInterface _db;
  final String _table = 'work_images';

  WorkImageRepositoryImpl(this._db);

  @override
  Future<void> saveMany(List<WorkImage> images) async {
    final batch = <String, Map<String, dynamic>>{};
    for (var i = 0; i < images.length; i++) {
      final image = images[i];
      batch[image.id] = {
        'id': image.id,
        'workId': image.workId,
        'indexInWork': i,
        'path': image.path,
        'width': image.width,
        'height': image.height,
        'format': image.format,
        'size': image.size,
        'thumbnailPath': image.thumbnailPath,
        'createTime': image.createTime.millisecondsSinceEpoch,
        'updateTime': image.updateTime.millisecondsSinceEpoch,
      };
    }
    await _db.saveMany(_table, batch);
  }
}
```

### 3. 修改WorkService构造函数

```dart
class WorkService with WorkServiceErrorHandler {
  final WorkRepository _repository;
  final WorkImageService _imageService;
  final IStorage _storage;
  final IWorkImageStorage _workImageStorage;
  final WorkImageRepository _workImageRepository; // 新增

  WorkService({
    required WorkRepository repository,
    required WorkImageService imageService,
    required IStorage storage,
    required IWorkImageStorage workImageStorage,
    required WorkImageRepository workImageRepository, // 新增
  })  : _repository = repository,
        _imageService = imageService,
        _storage = storage,
        _workImageStorage = workImageStorage,
        _workImageRepository = workImageRepository; // 新增
}
```

### 4. 修改WorkService.importWork方法

```dart
Future<WorkEntity> importWork(List<File> files, WorkEntity work) async {
  return handleOperation(
    'importWork',
    tag: 'WorkService',
    () async {
      // 验证输入
      if (files.isEmpty) throw ArgumentError('图片文件不能为空');

      // 处理图片
      final images = await _imageService.processImagesInBatches(work.id, files);
      
      // 保存图片信息到数据库
      await _workImageRepository.saveMany(images);

      // 确保生成并保存封面缩略图
      if (files.isNotEmpty) {
        final coverThumb = await _imageService.createThumbnail(files[0]);
        final coverPath = await _workImageStorage.getWorkCoverThumbnailPath(work.id);
        await coverThumb.copy(coverPath);
      }

      // 更新作品信息
      final updatedWork = work.copyWith(
        imageCount: images.length,
        updateTime: DateTime.now(),
        createTime: DateTime.now(),
        firstImageId: images.isNotEmpty ? images[0].id : null,
        lastImageUpdateTime: DateTime.now(),
      );

      // 保存到数据库
      return await _repository.create(updatedWork);
    }
  );
}
```

### 5. 更新依赖注入配置

在`lib/infrastructure/providers/database_providers.dart`中添加：

```dart
final workImageRepositoryProvider = Provider<WorkImageRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkImageRepositoryImpl(db);
});

// 更新WorkService的provider
final workServiceProvider = Provider<WorkService>((ref) {
  return WorkService(
    repository: ref.watch(workRepositoryProvider),
    imageService: ref.watch(workImageServiceProvider),
    storage: ref.watch(storageProvider),
    workImageStorage: ref.watch(workImageStorageProvider),
    workImageRepository: ref.watch(workImageRepositoryProvider),
  );
});
```

## 实施步骤

1. 创建WorkImageRepository接口和实现
2. 更新WorkService构造函数和依赖
3. 修改importWork方法以保存图片信息
4. 更新依赖注入配置
5. 测试导入功能，确保图片信息正确保存到数据库

## 预期结果

1. 在导入作品时，图片信息会被正确保存到work_images表中
2. 作品的firstImageId和lastImageUpdateTime字段会被正确更新
3. 系统可以正确追踪和管理作品图片
