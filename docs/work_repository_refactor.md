# Work Repository Refactor Plan

## 问题描述

当前WorkRepositoryImpl在保存WorkEntity到数据库时，没有过滤掉那些不属于work表的字段。具体来说，WorkEntity中的以下字段在work表中不存在：

- images (List<WorkImage>)
- collectedChars (List<CharacterEntity>)

## 修改计划

### 1. 添加_toTableJson私有方法

在WorkRepositoryImpl类中添加新的私有方法，用于处理实体到数据库的映射：

```dart
Map<String, dynamic> _toTableJson(WorkEntity work) {
  return {
    'id': work.id,
    'title': work.title,
    'author': work.author,
    'style': work.style.value,
    'tool': work.tool.value,
    'remark': work.remark,
    'creationDate': work.creationDate.millisecondsSinceEpoch,
    'createTime': work.createTime.millisecondsSinceEpoch,
    'updateTime': work.updateTime.millisecondsSinceEpoch,
    'lastImageUpdateTime': work.lastImageUpdateTime?.millisecondsSinceEpoch,
    'status': work.status.name,
    'firstImageId': work.firstImageId,
    'tags': work.tags.join(','),
    'imageCount': work.imageCount
  };
}
```

### 2. 修改相关方法

需要修改以下方法，将直接使用toJson()改为使用_toTableJson():

1. create方法:

```dart
Future<WorkEntity> create(WorkEntity work) async {
  await _db.set(_table, work.id, _toTableJson(work));
  return work;
}
```

2. save方法:

```dart
Future<WorkEntity> save(WorkEntity work) async {
  final now = DateTime.now();
  final updated = work.copyWith(updateTime: now);
  await _db.save(_table, work.id, _toTableJson(updated));
  return updated;
}
```

3. saveMany方法:

```dart
Future<List<WorkEntity>> saveMany(List<WorkEntity> works) async {
  final now = DateTime.now();
  final updates = {
    for (final work in works)
      work.id: _toTableJson(work.copyWith(updateTime: now))
  };

  await _db.saveMany(_table, updates);
  return works.map((w) => w.copyWith(updateTime: now)).toList();
}
```

## 下一步操作

1. 切换到Code模式实现上述修改
2. 确保所有字段映射正确
3. 进行必要的测试，确保修改不会影响现有功能

## 预期结果

1. 只有work表中定义的字段会被保存到数据库
2. 避免了不必要的数据存储
3. 提高了代码的可维护性和健壮性
