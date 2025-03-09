# 字符模型设计方案

## 目录结构

```
domain/
├── entities/
│   └── character.dart         // 数据库实体
└── models/
    └── character/
        ├── character_entity.dart     // 视图层字符实体
        ├── character_filter.dart     // 查询过滤条件
        ├── character_image.dart      // 图像相关
        └── character_metadata.dart   // 元数据模型
```

## 模型设计

### 1. Character (数据库实体)

```dart
class Character {
  final String? id;
  final String char;      // 汉字
  final String? pinyin;   // 拼音
  final String? workId;   // 作品ID
  final String? workName; // 作品名称
  final String? image;    // 图片路径
  final Map<String, dynamic>? sourceRegion; // 原始位置信息
  final Map<String, dynamic>? metadata;     // 元数据(包含style、tool等信息)
  final DateTime? createTime; 
  ...
}
```

### 2. CharacterEntity (视图实体)

```dart
class CharacterEntity extends Equatable {
  final String id;
  final String character;   // 汉字
  final String workId;     // 作品ID
  final String workName;   // 作品名称
  final String image;      // 图片路径
  final CharacterMetadata metadata; // 结构化的元数据
  final DateTime createTime;

  // 从数据库实体转换
  factory CharacterEntity.fromCharacter(Character character) {
    return CharacterEntity(
      id: character.id!,
      character: character.char,
      workId: character.workId ?? '',
      workName: character.workName ?? '',
      image: character.image ?? '',
      metadata: CharacterMetadata.fromJson(character.metadata ?? {}),
      createTime: character.createTime ?? DateTime.now(),
    );
  }
  ...
}
```

### 3. CharacterMetadata (元数据模型)

```dart
class CharacterMetadata extends Equatable {
  final String style;     // 书法风格
  final String tool;      // 书写工具
  final String? remark;   // 备注
  final Map<String, dynamic> region; // 区域信息
  
  // JSON序列化/反序列化支持
  factory CharacterMetadata.fromJson(Map<String, dynamic> json) {
    return CharacterMetadata(
      style: json['style'] ?? '',
      tool: json['tool'] ?? '',
      remark: json['remark'],
      region: json['region'] ?? {},
    );
  }
  ...
}
```

### 4. CharacterFilter (查询过滤)

```dart
class CharacterFilter extends Equatable {
  final String? searchQuery;
  final List<String> styles;
  final List<String> tools;
  final SortOption sortOption;
  ...
}
```

## 优势

1. 关注点分离
   - Character: 专注于数据持久化
   - CharacterEntity: 专注于视图层展示
   - CharacterMetadata: 专注于元数据管理
   - CharacterFilter: 专注于查询条件

2. 类型安全
   - 将JSON形式的metadata转换为强类型的CharacterMetadata
   - 提供类型安全的属性访问
   - 便于IDE代码补全和类型检查

3. 职责明确
   - entities目录: 数据库映射
   - models目录: 领域模型和视图模型
   - 清晰的转换方法便于数据流动

4. 易于扩展
   - 可以在不影响数据库结构的情况下扩展视图层功能
   - 可以单独添加新的元数据字段
   - 可以增加新的过滤条件

## 数据流动

1. 数据库 -> 应用层

```
Character(DB) -> CharacterEntity -> UI
```

2. 应用层 -> 数据库

```
UI -> CharacterEntity -> Character(DB)
```

3. 查询流程

```
UI -> CharacterFilter -> Repository -> DB -> Character[] -> CharacterEntity[] -> UI
```

## 后续规划

1. 添加验证逻辑
2. 实现缓存机制
3. 添加事件通知
4. 支持批量操作
5. 添加数据迁移方案
