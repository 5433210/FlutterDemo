# 数据结构设计文档

## 1. 系统配置数据

### 1.1 应用配置 (AppConfig)

```json
{
  "theme": {
    "mode": "enum",              // 主题模式: light/dark/system
    "color": "string",           // 主题颜色值
    "scale": "number"            // 界面缩放比例(0.75-1.5)
  },
  "view": {
    "defaultMode": "enum",       // 默认视图模式: grid/list
    "thumbnailSize": "number"    // 缩略图尺寸: 100/150/200
  },
  "language": "string",          // 界面语言: zh_CN/en_US
  "storage": {
    "workDir": "string",         // 作品存储路径
    "tempDir": "string",         // 临时文件路径
    "exportDir": "string",       // 导出路径
    "autoCleanup": {
      "enabled": "boolean",
      "interval": "string",      // week/month/quarter
      "maxCacheSize": "number"   // MB
    }
  },
  "backup": {
    "enabled": "boolean",
    "interval": "string",        // daily/weekly/monthly
    "keepCount": "number",
    "localPath": "string",
    "cloudEnabled": "boolean"
  }
}
```

### 1.2 用户界面状态 (UiState)

```json
{
  "currentModule": "string",     // 当前模块标识
  "listViews": {
    "works": {
      "viewMode": "string",     // grid/list
      "sortBy": "string",       // name/date/etc
      "filters": {
        "style": ["string"],
        "tool": ["string"],
        "dateRange": {
          "start": "datetime",
          "end": "datetime"
        }
      }
    }
    // ... 其他列表视图状态
  },
  "navigation": {
    "history": ["string"],      // 导航历史记录
    "current": "string"         // 当前路径
  }
}
```

## 2. 核心业务数据

### 2.1 书法作品 (Work)

```json
{
  "id": "string",               // UUID
  "name": "string",            // 作品名称(必填)
  "author": "string",          // 作者
  "style": "string",           // 书法风格
  "tool": "string",            // 书写工具
  "creationDate": "datetime",  // 创作时间
  "images":[ {
    "original": {
      "path": "string",        // 原图路径
      "width": "number",       // 原始宽度
      "height": "number",      // 原始高度
      "format": "string",      // 图片格式
      "size": "number"         // 文件大小(bytes)
    },
    "imported": {
      "path": "string",        // 导入后路径
      "width": "number",       // 导入后宽度
      "height": "number",      // 导入后高度
      "format": "string",      // 图片格式
      "size": "number"         // 文件大小(bytes)
    },
    "thumbnail": {
      "path": "string",        // 缩略图路径
      "width": "number",
      "height": "number"
    }
  }],
  "collectedChars": [{         // 已采集汉字列表
    "id": "string",            // 集字ID
    "region": {                // 在原图中的位置
      "x": "number",
      "y": "number", 
      "width": "number",
      "height": "number"
    },
    "createTime": "datetime"   // 采集时间
  }],
  "metadata": {
    "createTime": "datetime",  // 记录创建时间
    "updateTime": "datetime",  // 最后修改时间
    "remarks": "string"        // 备注说明
  }
}
```

### 2.2 集字 (Character)

```json
{
  "id": "string",              // UUID
  "workId": "string",         // 所属作品ID
  "char": {
    "simplified": "string",    // 简体字(必填)
    "traditional": "string"    // 繁体字(可选)
  },
  "style": "string",          // 继承或覆盖作品风格
  "tool": "string",           // 继承或覆盖作品工具
  "sourceRegion": {           // 原图区域
    "index": "number",
    "x": "number",
    "y": "number",
    "width": "number", 
    "height": "number"
  },
  "image": {
    "path": "string",         // 处理后图片路径
    "thumbnail": "string",    // 缩略图路径
    "size": {
      "width": "number",
      "height": "number"
    }
  },
  "metadata": {
    "createTime": "datetime",
    "updateTime": "datetime",
    "remarks": "string"       // 备注
  },
  "usage": [{                 // 使用记录
    "practiceId": "string",   // 字帖ID 
    "templateId": "string",   // 模板ID
    "useTime": "datetime"     // 使用时间
  }]
}
```

### 2.3 字帖 (Practice)

```json
{
  "id": "string",            // UUID
  "title": "string",        // 字帖标题
  "templateId": "string",   // 使用的模板ID
  "status": "string",      // draft/completed
  "pages": [{
    "index": "number",    // 对应模板页面
    "layers": [{             // 图层列表
      "index": "number",      // 图层序号
      "name": "string",      // 图层名称 
      "type": "string",      // background/content
      "visible": "boolean",
      "locked": "boolean",
      "opacity": "number",   // 0-1
        "elements": [{
          "id": "string",      // 元素ID
          "type": "string",    // chars/text/image
          "geometry": {
            "x": "number",
            "y": "number",
            "width": "number",
            "height": "number",
            "rotation": "number"
          },
          "content": {
          // 当type为chars时
            "chars": [{
                "charId": "string",
                "position": {      // 相对位置                
                    "offsetX": "number", // 相对偏移量
                    "offsetY": "number"
                },
                "transform": {
                    "scaleX": "number",
                    "scaleY": "number",
                    "rotation": "number"
                },
                "style": {
                "color": "string"
                }
            }],
          
            // 当type为text时
            "text": {
                "text":"string"
            }
            
            // 当type为image时
            "image": {
                "path":"path"
            }
          }
        }]
    }]
  }],
  "metadata": {
    "createTime": "datetime",
    "updateTime": "datetime",
    "description": "string",
    "printCount": "number",
    "tags": ["string"]
  }
}
```

## 3. 存储结构

```json
/storage
  /works                    // 作品存储
    /{workId}/      
      thumbnail.jpg         // 缩略图
      metadata.json         // 作品元数据
      pictures/{index}/      // 顺序号
        original.{ext}        // 原始图片
        imported.png        //导入的图片        
  /chars                    // 集字存储
    /{workId}/
      /{charId}/
        char.png           // 处理后图片
        thumbnail.jpg         // 缩略图
        metadata.json     // 集字元数据
  /practices            // 字帖存储
    /{practiceId}/
      practice.json     // 字帖数据
      thumbnail.jpg      // 缩略图
      pages/           // 页面资源
  /temp               // 临时文件
  /backup            // 备份文件
```

## 4. 索引设计

### 4.1 主要索引

- 作品索引: id, name, author, style, tool, createTime
- 集字索引: id, workId, simplified, style, tool
- 模板索引: id, name, type, tags
- 字帖索引: id, title, templateId, status, createTime

### 4.2 关联关系

- 作品 -> 集字: 一对多
- 集字 -> 字帖: 多对多
- 模板 -> 字帖: 一对多

## 5. 数据验证规则

### 5.1 字段验证

- 作品名称: 1-50字符
- 集字简体: 必须是单个汉字
- 模板名称: 1-30字符
- 字帖标题: 1-100字符

### 5.2 业务规则

- 集字必须关联到有效的作品
- 字帖必须使用有效的模板
- 删除作品时必须处理关联的集字
- 删除模板时必须确认没有关联的字帖

## 6. 性能考虑

### 6.1 缓存策略

- 图片缓存: 最大1GB
- 预览缓存: 最大500MB
- 自动清理: 超过7天未访问

### 6.2 批量操作

- 批量导入: 限制单次最多100张
- 批量导出: 限制单次最多1000个
- 列表加载: 分页加载，每页20条
