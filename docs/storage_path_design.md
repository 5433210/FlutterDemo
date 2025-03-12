# 存储路径设计文档

## 1. 基础路径结构

```
{appDataDir}/            # 应用数据根目录
├── assets/           # 应用资源文件
│   └── placeholders/ # 占位图片
├── works/           # 作品相关文件
│   ├── {workId}/   # 单个作品目录
│   │   ├── cover/  # 封面图片目录
│   │   │   ├── imported.png    # 处理后的封面（首页）
│   │   │   └── thumbnail.jpg   # 封面缩略图
│   │   ├── images/  # 作品图片目录
│   │   │   ├── {imageId}/      # 图片目录（使用数据库ID）
│   │   │   │   ├── original.{ext}  # 原始图片
│   │   │   │   ├── imported.png    # 导入处理图
│   │   │   │   └── thumbnail.jpg   # 缩略图
│   │   │   └── ...
│   │   └── metadata.json      # 作品基本信息
│   └── ...
├── cache/          # 缓存目录
│   └── temp/      # 临时文件目录
└── config/        # 配置目录
    └── settings.json  # 应用设置
```

## 2. 路径设计原则

### 2.1 分层存储
- 每个作品一个独立目录
- 每张图片一个独立目录
- 图片ID直接使用数据库ID
- 排序等元数据由数据库维护

### 2.2 命名规范
- 目录名使用小写单词
- 使用数据库ID作为目录名
- 固定的文件命名约定
- 明确的文件用途标识

### 2.3 图片版本管理
- 保留原始图片
- 统一的处理格式（PNG/JPG）
- 自动更新关联图片

## 3. 关键路径说明

### 3.1 作品图片资源
```typescript
// 图片目录
works/{workId}/images/{imageId}/

// 原始图片
works/{workId}/images/{imageId}/original.{ext}

// 导入处理图
works/{workId}/images/{imageId}/imported.png

// 缩略图
works/{workId}/images/{imageId}/thumbnail.jpg
```

### 3.2 封面图片
```typescript
// 首页导入图作为封面
works/{workId}/cover/imported.png

// 封面缩略图
works/{workId}/cover/thumbnail.jpg
```

### 3.3 临时文件
```typescript
// 临时文件
cache/temp/{timestamp}_{random}.tmp
```

## 4. 文件命名策略

### 4.1 图片文件
- original.{ext}: 保留原始格式
- imported.png: 统一PNG格式
- thumbnail.jpg: 统一JPG格式

### 4.2 封面图片
- 直接使用首页的imported.png
- 生成对应的thumbnail.jpg

### 4.3 元数据文件
- metadata.json: 仅包含基本信息
- 排序等信息在数据库维护

## 5. 路径生成规则

### 5.1 图片相关
```typescript
getImageDir(workId: string, imageId: string): string {
    return `works/${workId}/images/${imageId}`;
}

getOriginalPath(workId: string, imageId: string, ext: string): string {
    return `works/${workId}/images/${imageId}/original.${ext}`;
}

getImportedPath(workId: string, imageId: string): string {
    return `works/${workId}/images/${imageId}/imported.png`;
}

getThumbnailPath(workId: string, imageId: string): string {
    return `works/${workId}/images/${imageId}/thumbnail.jpg`;
}
```

### 5.2 封面相关
```typescript
getCoverImportedPath(workId: string): string {
    return `works/${workId}/cover/imported.png`;
}

getCoverThumbnailPath(workId: string): string {
    return `works/${workId}/cover/thumbnail.jpg`;
}
```

## 6. 维护策略

### 6.1 文件管理
- 使用数据库ID关联文件
- 文件操作与数据库同步
- 保持文件系统整洁

### 6.2 封面管理
- 自动同步首页图片
- 维护缩略图更新
- 保持封面最新状态

### 6.3 空间管理
- 及时清理临时文件
- 删除时清理所有相关文件
- 定期优化存储空间

### 6.4 错误处理
- 文件缺失检查
- 处理失败回滚
- 自动重试机制

### 6.5 性能优化
- 路径生成缓存
- 批量操作优化
- 异步处理队列
