# 作品图片加载修复方案更新

## 问题分析

在梳理了整个图片处理流程后，发现关键问题在于：

1. WorkImageProcessor生成了正确的图片路径：
   - originalPath: 原始图片路径
   - path: 处理后的图片路径（压缩、调整大小后）

2. 但Repository实现错误地复用了同一个路径：

   ```dart
   originalPath: row['path'] as String,  // 错误
   path: row['path'] as String,         // 错误
   ```

3. UI组件（WorkImagePreview和CharacterExtractionPreview）都在使用path字段加载图片。

## 解决方案

1. 数据库修改 ✅
   - 添加original_path字段
   - 迁移现有数据

2. Repository修改
   - WorkImageRepositoryImpl需要正确使用original_path字段
   - 确保创建和读取时字段映射正确

3. 保持模型简单
   - 回退WorkImage模型的修改
   - path字段保持作为主要的图片路径
   - originalPath作为参考信息保存

## 实现步骤

1. 已完成：
   - 创建数据库迁移脚本，添加original_path字段
   - 维持WorkImage模型的简单结构

2. 待完成：
   - [ ] 更新WorkImageRepositoryImpl中的字段映射
   - [ ] 验证UI组件能正确显示图片
   - [ ] 测试图片导入和显示流程

## 注意事项

1. 路径使用规则
   - UI层统一使用path字段加载图片
   - originalPath仅作为参考信息保存
   - 导入时必须同时设置两个路径

2. 数据迁移
   - 现有记录的path字段值会被复制到original_path
   - 确保不会影响现有数据的访问

## 后续优化

1. 路径管理
   - 考虑添加路径验证
   - 可以添加路径存在性检查

2. 错误处理
   - 添加图片加载失败的重试机制
   - 改善错误提示信息
