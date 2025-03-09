# 存储策略实现方案

## 目录结构

```
lib/
├── domain/
│   ├── services/
│   │   ├── storage/
│   │   │   ├── storage_strategy_interface.dart
│   │   │   ├── local_storage_strategy.dart
│   │   │   ├── cloud_storage_strategy.dart
│   │   │   └── cloud/
│   │   │       ├── cloud_client_interface.dart
│   │   │       ├── s3_client.dart
│   │   │       └── azure_blob_client.dart
├── application/
│   ├── services/
│   │   ├── storage/
│   │   │   ├── storage_service.dart
│   │   │   └── cloud/
│   │   │       ├── s3_service.dart
│   │   │       └── azure_blob_service.dart
```

## 接口定义

```dart
// storage_strategy_interface.dart
abstract class IStorageStrategy {
  Future<String> saveFile(List<int> bytes, String path);
  Future<void> deleteFile(String path);
  Future<List<int>> readFile(String path);
  Future<bool> fileExists(String path);
}

// cloud_client_interface.dart
abstract class ICloudClient {
  Future<String> uploadFile(List<int> bytes, String path);
  Future<void> deleteFile(String path);
  Future<List<int>> downloadFile(String path);
  Future<bool> fileExists(String path);
}
```

## 实现类

### 本地存储

```dart
// local_storage_strategy.dart
class LocalStorageStrategy implements IStorageStrategy {
  final PathHelper pathHelper;

  LocalStorageStrategy(this.pathHelper);

  @override
  Future<String> saveFile(List<int> bytes, String path) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return path;
  }

  // 其他方法实现...
}
```

### 云存储

```dart
// cloud_storage_strategy.dart
class CloudStorageStrategy implements IStorageStrategy {
  final ICloudClient cloudClient;

  CloudStorageStrategy(this.cloudClient);

  @override
  Future<String> saveFile(List<int> bytes, String path) async {
    return await cloudClient.uploadFile(bytes, path);
  }

  // 其他方法实现...
}

// s3_client.dart
class S3Client implements ICloudClient {
  final S3Service s3Service;

  S3Client(this.s3Service);

  @override
  Future<String> uploadFile(List<int> bytes, String path) async {
    return await s3Service.upload(bytes, path);
  }

  // 其他方法实现...
}

// azure_blob_client.dart
class AzureBlobClient implements ICloudClient {
  final AzureBlobService azureService;

  AzureBlobClient(this.azureService);

  @override
  Future<String> uploadFile(List<int> bytes, String path) async {
    return await azureService.upload(bytes, path);
  }

  // 其他方法实现...
}
```

## 依赖注入配置

```dart
final storageStrategyProvider = Provider<IStorageStrategy>((ref) {
  final config = ref.read(appConfigProvider);
  
  if (config.useCloudStorage) {
    final cloudClient = ref.read(cloudClientProvider);
    return CloudStorageStrategy(cloudClient);
  } else {
    final pathHelper = ref.read(pathHelperProvider);
    return LocalStorageStrategy(pathHelper);
  }
});

final cloudClientProvider = Provider<ICloudClient>((ref) {
  final config = ref.read(appConfigProvider);
  
  if (config.cloudProvider == CloudProvider.aws) {
    return S3Client(ref.read(s3ServiceProvider));
  } else {
    return AzureBlobClient(ref.read(azureBlobServiceProvider));
  }
});
```

## 使用示例

```dart
class WorkImageService {
  final IStorageStrategy storageStrategy;

  WorkImageService(this.storageStrategy);

  Future<String> saveImage(List<int> imageBytes) async {
    final path = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await storageStrategy.saveFile(imageBytes, path);
  }
}
