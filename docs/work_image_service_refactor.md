# WorkImageService 重构方案 V2 - 分层接口设计

## 1. 接口分层结构

```mermaid
classDiagram
    class IImageStorage {
        <<interface>>
        +saveTempFile(List<int> bytes): Future<String>
        +deleteFile(String path): Future<void>
    }

    class IImageProcessing {
        <<interface>>
        +optimize(File image): Future<File>
        +resize(File image, Size size): Future<File>
    }

    class IWorkImageStorage {
        <<interface>>
        +saveWorkImage(String workId, File file): Future<String>
        +getWorkImages(String workId): Future<List<String>>
    }

    class IWorkImageProcessing {
        <<interface>>
        +processWorkImages(String workId, List<File> files): Future<List<WorkImage>>
    }

    IImageStorage <|-- IWorkImageStorage
    IImageProcessing <|-- IWorkImageProcessing
2. 通用接口定义
2.1 基础存储接口
abstract class IImageStorage {
  /// 保存临时文件（通用）
  Future<String> saveTempFile(List<int> bytes);
  
  /// 删除文件（通用）
  Future<void> deleteFile(String path);
  
  /// 检查文件是否存在（通用）
  Future<bool> fileExists(String path);
}
2.2 基础处理接口
abstract class IImageProcessing {
  /// 优化图片质量（通用）
  Future<File> optimize(File image, [int quality = 85]);
  
  /// 调整图片尺寸（通用）
  Future<File> resize(File image, {required int width, required int height});
}
3. Work专用接口定义
3.1 Work存储接口
abstract class IWorkImageStorage implements IImageStorage {
  /// 保存作品图片（Work专用）
  Future<String> saveWorkImage(String workId, File image);
  
  /// 获取作品所有图片路径（Work专用）
  Future<List<String>> getWorkImages(String workId);
  
  /// 删除作品图片（Work专用）
  Future<void> deleteWorkImage(String workId, String imagePath);
}
3.2 Work处理接口
abstract class IWorkImageProcessing implements IImageProcessing {
  /// 处理作品图片（Work专用）
  Future<List<WorkImage>> processWorkImages(String workId, List<File> images);
  
  /// 生成作品缩略图（Work专用）
  Future<File> generateWorkThumbnail(File image);
}
4. 实现类结构
4.1 通用实现
class BaseImageStorage implements IImageStorage {
  @override
  Future<String> saveTempFile(List<int> bytes) async {
    // 基础实现...
  }

  // 其他通用方法实现...
}

class BaseImageProcessor implements IImageProcessing {
  @override
  Future<File> optimize(File image, [int quality = 85]) async {
    // 基础优化逻辑...
  }

  // 其他通用方法实现...
}
4.2 Work专用实现
class WorkImageStorage extends BaseImageStorage implements IWorkImageStorage {
  @override
  Future<String> saveWorkImage(String workId, File image) async {
    final workDir = _getWorkDirectory(workId);
    final destPath = '${workDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await image.copy(destPath);
    return destPath;
  }

  // 其他Work专用方法实现...
}

class WorkImageProcessor extends BaseImageProcessor implements IWorkImageProcessing {
  @override
  Future<List<WorkImage>> processWorkImages(String workId, List<File> images) async {
    final processed = <WorkImage>[];
    for (var i = 0; i < images.length; i++) {
      final optimized = await optimize(images[i]);
      final thumbnail = await generateWorkThumbnail(optimized);
      processed.add(WorkImage(
        originalPath: optimized.path,
        thumbnailPath: thumbnail.path,
        index: i,
      ));
    }
    return processed;
  }
}
5. 依赖注入配置
// 通用服务
final baseStorageProvider = Provider<IImageStorage>((ref) => BaseImageStorage());
final baseProcessorProvider = Provider<IImageProcessing>((ref) => BaseImageProcessor());

// Work专用服务
final workStorageProvider = Provider<IWorkImageStorage>((ref) {
  return WorkImageStorage(
    baseStorage: ref.read(baseStorageProvider),
    workConfig: ref.read(workConfigProvider),
  );
});

final workProcessorProvider = Provider<IWorkImageProcessing>((ref) {
  return WorkImageProcessor(
    baseProcessor: ref.read(baseProcessorProvider),
    thumbnailConfig: ref.read(thumbnailConfigProvider),
  );
});
6. 使用示例
class WorkService {
  final IWorkImageStorage storage;
  final IWorkImageProcessing processor;

  WorkService(this.storage, this.processor);

  Future<List<WorkImage>> createWork(String workId, List<List<int>> images) async {
    final processed = <WorkImage>[];
    for (final bytes in images) {
      // 使用通用接口保存临时文件
      final tempPath = await storage.saveTempFile(bytes);
      
      // 使用Work专用接口处理图片
      final workImages = await processor.processWorkImages(
        workId,
        [File(tempPath)],
      );
      
      // 使用Work专用接口保存作品图片
      for (final image in workImages) {
        await storage.saveWorkImage(workId, File(image.originalPath));
      }
      
      processed.addAll(workImages);
    }
    return processed;
  }
}
```
