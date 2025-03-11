# WorkImageRepository 重构计划

## 背景

为了保持代码库的一致性和简洁性，需要重构 WorkImageRepository 的接口设计。

## 重构内容

### 1. 接口命名统一

将方法名改为更符合项目规范的形式：

| 原方法名 | 新方法名 | 说明 |
|---------|---------|------|
| findById | get | 统一使用简单明确的命名 |
| findByWorkId | getAllByWorkId | 与 getAll 命名保持一致 |
| findFirstByWorkId | getFirstByWorkId | 保持 get 前缀 |
| batchCreate | createMany | 统一使用 many 后缀 |
| batchDelete | deleteMany | 统一使用 many 后缀 |

### 2. 接口简化

1. 移除 transaction 方法：数据库层已经处理了事务，接口中不需要暴露
2. 移除 close 方法：资源清理应该在数据库层统一处理
3. 直接使用 WorkImage 作为参数，在数据库操作前处理字段

### 3. 重构后的接口定义

```dart
abstract class WorkImageRepository {
  /// 创建图片记录
  Future<WorkImage> create(String workId, WorkImage image);

  /// 批量创建
  Future<List<WorkImage>> createMany(String workId, List<WorkImage> images);

  /// 删除图片
  Future<void> delete(String workId, String imageId);

  /// 批量删除
  Future<void> deleteMany(String workId, List<String> imageIds);

  /// 获取图片
  Future<WorkImage?> get(String imageId);

  /// 获取作品的所有图片
  Future<List<WorkImage>> getAllByWorkId(String workId);

  /// 获取作品的第一张图片
  Future<WorkImage?> getFirstByWorkId(String workId);

  /// 获取下一个可用的索引号
  Future<int> getNextIndex(String workId);

  /// 批量更新
  Future<List<WorkImage>> saveMany(List<WorkImage> images);

  /// 更新图片索引
  Future<void> updateIndex(String workId, String imageId, int newIndex);
}
```

### 4. 实现说明

在实现类中处理字段：

1. 创建时处理：id、createTime、updateTime 等
2. 更新时处理：updateTime
3. 保持其他字段不变

## 影响范围

需要修改的文件：

1. domain/repositories/work_image_repository.dart
2. infrastructure/repositories/sqlite/work_image_repository_impl.dart
3. application/services/work/work_image_service.dart

## 下一步计划

1. 实施代码修改
2. 运行测试确保功能正常
3. 进行代码审查
