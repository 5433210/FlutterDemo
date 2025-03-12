# 存储系统扩展设计

## 1. 存储位置扩展

### 1.1 存储位置类型

```typescript
enum StorageLocation {
  local,      // 应用本地目录
  external,   // 外部存储（如外接硬盘）
  cloud,      // 云存储
  network,    // 网络存储（如NAS）
}

class StorageConfig {
  final StorageLocation location;
  final String basePath;
  final Map<String, dynamic> options;  // 位置特定配置
}
```

### 1.2 存储服务工厂

```typescript
abstract class StorageServiceFactory {
  StorageService create(StorageConfig config);
}

class LocalStorageFactory implements StorageServiceFactory {
  StorageService create(StorageConfig config) {
    return StorageService(basePath: config.basePath);
  }
}

class CloudStorageFactory implements StorageServiceFactory {
  StorageService create(StorageConfig config) {
    // 实现云存储服务
  }
}
```

## 2. 路径策略扩展

### 2.1 路径生成策略

```typescript
abstract class PathStrategy {
  String getWorkPath(String workId);
  String getImagePath(String workId, String imageId);
  String getCoverPath(String workId);
  String getTempPath();
}

class LocalPathStrategy implements PathStrategy {
  final String basePath;
  
  String getWorkPath(String workId) => 
    '$basePath/works/$workId';
}

class CloudPathStrategy implements PathStrategy {
  final String bucket;
  final String prefix;
  
  String getWorkPath(String workId) => 
    '$bucket/$prefix/works/$workId';
}
```

### 2.2 文件访问模式

```typescript
enum AccessMode {
  direct,     // 直接文件系统访问
  streaming,  // 流式访问
  cached,     // 本地缓存
}

class FileAccess {
  final AccessMode mode;
  final String path;
  final Map<String, dynamic> metadata;
}
```

## 3. 缓存策略扩展

### 3.1 缓存配置

```typescript
class CacheConfig {
  final bool enabled;
  final String localPath;
  final int maxSize;
  final Duration maxAge;
  final List<String> patterns;  // 缓存匹配规则
}
```

### 3.2 缓存策略

```typescript
abstract class CacheStrategy {
  Future<File> getCached(String path);
  Future<void> cache(String path, File file);
  Future<void> invalidate(String path);
  Future<void> clear();
}

class LRUCacheStrategy implements CacheStrategy {
  final CacheConfig config;
  // LRU缓存实现
}
```

## 4. 同步策略扩展

### 4.1 同步模式

```typescript
enum SyncMode {
  manual,     // 手动同步
  auto,       // 自动同步
  scheduled,  // 计划同步
}

class SyncConfig {
  final SyncMode mode;
  final Duration interval;
  final List<String> patterns;  // 同步匹配规则
}
```

### 4.2 同步策略

```typescript
abstract class SyncStrategy {
  Future<void> sync(String path);
  Future<void> syncWork(String workId);
  Future<SyncStatus> checkStatus(String path);
}
```

## 5. 实现示例

### 5.1 混合存储服务

```typescript
class HybridStorageService implements StorageService {
  final Map<StorageLocation, StorageService> services;
  final PathStrategy pathStrategy;
  final CacheStrategy cacheStrategy;
  final SyncStrategy syncStrategy;
  
  Future<String> saveFile(File file, String path) async {
    // 根据路径选择合适的存储服务
    final location = determineLocation(path);
    final service = services[location];
    
    // 保存文件
    final savedPath = await service.saveFile(file, path);
    
    // 更新缓存
    await cacheStrategy.cache(path, file);
    
    // 触发同步
    await syncStrategy.sync(path);
    
    return savedPath;
  }
}
```

### 5.2 Provider配置

```typescript
final storageConfigProvider = Provider<StorageConfig>((ref) {
  return StorageConfig(
    location: StorageLocation.local,
    basePath: getAppDataPath(),
    options: {}
  );
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final config = ref.watch(storageConfigProvider);
  final factory = getStorageFactory(config.location);
  return factory.create(config);
});
```

## 6. 扩展建议

### 6.1 接口设计

- 保持接口简单，隐藏复杂性
- 支持异步操作
- 提供进度和状态回调
- 错误处理标准化

### 6.2 配置设计

- 支持运行时配置
- 分环境配置
- 可覆盖默认值
- 支持配置热更新

### 6.3 性能考虑

- 智能缓存策略
- 并发操作控制
- 批量操作优化
- 资源使用监控

### 6.4 安全考虑

- 访问权限控制
- 数据加密支持
- 安全传输
- 审计日志
