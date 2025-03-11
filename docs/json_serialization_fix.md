# JSON序列化命名统一方案

## 问题描述

当前系统在实体类与数据库之间的字段命名不一致：

- 数据库使用驼峰命名：creationDate, createTime, updateTime
- JSON序列化使用下划线命名：creation_date, create_time, update_time

## 解决方案

统一使用驼峰命名风格，需要修改以下内容：

1. 在 WorkEntity 类上添加 @JsonSerializable 注解：

```dart
@freezed
@JsonSerializable(fieldRename: FieldRename.none)  // 禁用自动字段重命名
class WorkEntity with _$WorkEntity {
  // ...
}
```

2. 更新现有的 @JsonKey 注解：

```dart
// 修改前：
@JsonKey(name: 'creation_date')
required DateTime creationDate,

// 修改后：
required DateTime creationDate,  // 不需要特殊注解，直接使用字段名
```

## 实施步骤

1. 添加 @JsonSerializable 注解并设置 fieldRename: FieldRename.none
2. 移除不必要的 @JsonKey 注解
3. 运行 build_runner 重新生成序列化代码：

```bash
flutter pub run build_runner build
```

## 优势

1. 保持与数据库命名一致
2. 减少配置代码
3. 符合Dart/Flutter的通用命名约定
4. 提高代码可维护性

## 后续工作

如果其他实体类也有类似问题，应用相同的修复方案保持一致性。
