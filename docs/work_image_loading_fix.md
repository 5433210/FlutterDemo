# 作品图片加载预览功能修复方案

## 问题描述

### 当前问题

- 作品详情页和编辑页的作品图片显示异常
- 增加workimage表后相关处理逻辑发生变化，导致图片路径处理不当

### 问题分析

1. 路径混淆
   - 当前实现中originalPath和path字段指向相同路径
   - 缺少对处理后图片路径的明确区分

2. 存储结构问题
   - 文件系统存储和数据库存储之间缺乏清晰的映射关系
   - 路径管理逻辑不清晰

## 解决方案

### 1. 数据模型调整

修改WorkImage模型，优化路径字段设计：

```dart
class WorkImage {
  String originalPath;    // 原图路径
  String importedPath;    // 导入处理后的图片路径
  String thumbnailPath;   // 缩略图路径
  // ... 其他字段
}
```

### 2. 数据库修改

添加imported_path字段：

```sql
ALTER TABLE work_images 
ADD COLUMN imported_path TEXT NOT NULL DEFAULT '';
```

### 3. UI层改进

设计新的图片查看组件，支持图片源切换：

```dart
class WorkImageViewer extends StatefulWidget {
  final WorkImage workImage;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 图片源切换控件
        Row(
          children: [
            RadioListTile(
              title: Text('原图'),
              value: workImage.originalPath,
              // ...
            ),
            RadioListTile(
              title: Text('优化后'),
              value: workImage.importedPath,
              // ...
            ),
          ],
        ),
        // 图片显示
        Image.file(
          File(selectedPath),
          // ...
        ),
      ],
    );
  }
}
```

## 实施步骤

### 第一阶段：数据层修改

1. 更新WorkImage模型
2. 修改数据库结构
3. 更新Repository实现

### 第二阶段：业务层调整

1. WorkImageService保持不变
2. 确保导入流程正确生成importedPath

### 第三阶段：UI层优化

1. 实现新的WorkImageViewer组件
2. 在作品详情页和编辑页集成新组件
3. 添加图片源切换功能

## 优势

1. 清晰的数据结构
   - 明确区分原图和处理后的图片
   - 去除了动态path字段，简化了模型

2. 灵活的UI控制
   - UI层可以完全控制显示哪个版本的图片
   - 用户可以根据需要切换图片源

3. 简化的业务逻辑
   - 业务层不需要关心path的切换
   - 减少了状态管理的复杂性

## 注意事项

1. 性能考虑
   - 图片加载时机的优化
   - 缓存策略的调整

2. 用户体验
   - 添加图片加载状态提示
   - 处理图片加载失败的情况

3. 向后兼容
   - 保持对旧版本数据的支持
   - 平滑迁移策略

## 后续优化建议

1. 缓存优化
   - 实现图片预加载
   - 优化内存使用

2. 错误处理
   - 完善错误提示
   - 添加重试机制

3. 性能监控
   - 添加图片加载性能监控
   - 收集用户使用数据

## 结论

通过此次修改，我们将:

1. 优化了数据结构，使路径管理更加清晰
2. 提供了更好的用户体验，支持图片源切换
3. 简化了代码结构，便于后续维护
