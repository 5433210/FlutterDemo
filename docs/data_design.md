# 数据设计文档

本文件描述了 Demo App 的数据设计，包括数据结构、存储方案、数据库模式、数据关系、验证规则和性能考虑。

## 1. 数据结构

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

### 2.  核心业务数据

### 2.1 书法作品 (Work)

```json
{
  "id": "string",              // UUID
  "createTime": "datetime",    //ISO 8601格式
  "updateTime": "datetime",    //ISO 8601格式
  "name": "string",            // 作品名称(必填)
  "author": "string",          // 作者
  "style": "string",           // 书法风格
  "tool": "string",            // 书写工具
  "imageCount": "number",      // 图片总数  
  "creationDate": "datetime",  // 创作时间
  "remark":"string",          // 备注
  "images":[ {
    "index":"number",       // 序号
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
      "index": "number",      //作品页号
      "x": "number",
      "y": "number", 
      "width": "number",
      "height": "number"
    },
    "createTime": "datetime"   // 采集时间
  }],
  "metadata": {
    "tags": ["string"],                    // 可选，标签数组
  }
}
```

### 2.2 集字 (Character)

```json
{
  "id": "string",              // UUID
  "createTime": "datetime",
  "updateTime": "datetime",
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
    "tags": ["string"],                    // 可选，标签数组
  },
  "usage": [{                 // 使用记录
    "practiceId": "string",   // 字帖ID      
  }],
}
```

### 2.3 字帖 (Practice)

```json
{
  "id": "string",            // UUID
  "createTime": "datetime",
  "updateTime": "datetime",
  "title": "string",        // 字帖标题  
  "status": "string",      // draft/completed
  "pages": [{
    "index": "number",    // 页面序号
    "size": {                   // 页面尺寸
      "unit":"string",            // 尺寸单位
      "resUnit":"string",        // 分辨率单位
      "resUnitValue":"number",     // 分辨率单位值
      "width": "number",           // 毫米
      "height": "number",           // A4纸张
    }, 
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
          "geometry": {        // 位置和尺寸
            "x": "number",
            "y": "number",
            "width": "number",
            "height": "number",
            "rotation": "number"
          },
          "style": {         // 样式属性
            "opacity": "number",  // 不透明度
            "visible": "boolean"  // 是否可见
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
                    "color": "string",
                    "opacity": "number",
                },
            }],
          
            // 当type为text时
            "text": {
                "content": "string",
                "fontFamily": "string",
                "fontSize": "number",
                "color": "string",
                "alignment": "string",
            },
            
            // 当type为image时
            "image": {
                "path":"path",
            }
          }
        }]
    }]
  }],
  "metadata": {
    "tags": ["string"]
  }
}
```

## 3. 存储方案

### 3.1 文件存储

```p
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

### 3.2 数据库模式

采用 SQLite 作为本地存储解决方案，主要包括以下表：

- works
- characters
- practices
- settings

各表之间通过外键建立关联：

- 一个作品 (works) 可对应多个集字 (characters)
- 一个集字 (characters) 可多次被字帖 (practices) 使用（通过引用使用记录）

#### 3.2.1 表：works

用于存储书法作品的元数据及多图信息

| 字段名称         | 类型        | 描述                                  |
|------------------|-------------|---------------------------------------|
| id               | TEXT (PK)  | 作品唯一标识（UUID）                  |
| name             | TEXT        | 作品名称（必填，1-50字符）            |
| author           | TEXT        | 作者                                  |
| style            | TEXT        | 书法风格                              |
| tool             | TEXT        | 书写工具                              |
| creationDate     | DATETIME    | 创作日期                              |
| createTime      | INTEGER    | 创建时间                              |
| updateTime      | INTEGER    | 修改时间                              |
| metadata         | TEXT        | JSON文本 |

#### 3.2.2 表：characters

用于存储从作品中提取的集字信息

| 字段名称         | 类型         | 描述                                               |
|------------------|--------------|----------------------------------------------------|
| id               | TEXT (PK)   | 集字唯一标识（UUID）                                |
| workId           | TEXT         | 外键，关联到 works.id                             |
| simplified       | TEXT         | 简体字（必填，必须为单个汉字）                      |
| traditional      | TEXT         | 繁体字（可选）                                     |
| style            | TEXT         | 书法风格（可继承或覆盖作品风格）                    |
| tool             | TEXT         | 书写工具（可继承或覆盖作品工具）                    |
| sourceRegion     | TEXT         | JSON对象，包含 index, x, y, width, height          |
| image            | TEXT         | JSON对象，包含处理后图片路径、缩略图路径及尺寸信息    |
| usage     | TEXT         | JSON对象，包含使用了该集字的字帖集合          |
| createTime      | INTEGER    | 创建时间                              |
| updateTime      | INTEGER    | 修改时间                              |
| metadata         | TEXT         | JSON文本                 |

#### 3.2.3 表：practices

用于存储字帖的数据

| 字段名称         | 类型         | 描述                                              |
|------------------|--------------|---------------------------------------------------|
| id               | TEXT (PK)   | 字帖唯一标识（UUID）                               |
| title            | TEXT         | 字帖标题（必填，1-100字符）                        |
| status           | TEXT         | 字帖状态（例如："draft" 或 "completed"）          |
| pages            | TEXT         | JSON数组，描述各页面内容 |
| createTime      | INTEGER    | 创建时间                              |
| updateTime      | INTEGER    | 修改时间                              |
| metadata         | TEXT         | JSON文本      |

#### 3.2.5 表：settings

用于存储应用配置（单条记录或键值对表）

| 字段名称 | 类型        | 描述                                  |
|----------|-------------|---------------------------------------|
| key      | TEXT (PK)  | 设置项标识                            |
| value    | TEXT       | JSON文本或纯文本的配置信息             |

## 4. 数据关系与索引设计

### 4.1 关系

- **作品与集字**：一对多，works.id → characters.workId
- **集字与字帖**：多对多关系，字帖中通过 JSON 数组引用集字 id

### 4.2 索引设计

为提高查询效率建议在以下字段上建立索引：

- works 表：id (主键)，name，author，creationDate
- characters 表：id (主键)，workId, simplified
- practices 表：id (主键)，title，status
- settings 表：key

## 5. 数据验证与业务约束

### 5.1 字段验证

- 作品名称: 1-50字符
- 集字的 simplified 字段必须为单个汉字
- 字帖标题: 1-100字符

### 5.2 业务规则

- 集字必须关联到有效的作品
- 字帖必须使用有效的作品

## 6. 性能考虑

### 6.1 缓存策略

- 图片缓存: 最大1GB
- 预览缓存: 最大500MB
- 自动清理: 超过7天未访问

### 6.2 批量操作

- 批量导入: 限制单次最多100张
- 批量导出: 限制单次最多1000个
- 列表加载: 分页加载，每页20条

## 7. JSON 结构规范

### 7.1 公共结构

#### metadata 字段结构

```json
{
  "createTime": "2024-02-20T10:00:00Z",  // ISO 8601格式
  "updateTime": "2024-02-20T10:30:00Z",  
  "tags": ["string"],                    // 可选，标签数组
}
```

### 7.1 作品表 (works)

### 7.2 集字表 (characters)

#### sourceRegion 字段结构

```json
{
  "index": 0,           // 图片序号，对应works/{workId}/pictures/{index}
  "x": 100,            // 左上角x坐标
  "y": 100,            // 左上角y坐标
  "width": 200,        // 区域宽度
  "height": 200,       // 区域高度
}
```

#### image 字段结构

```json
{
  "path": "chars/{workId}/{charId}/char.png",    // 相对路径
  "thumbnail": "chars/{workId}/{charId}/thumbnail.jpg",
  "size": {
    "width": 200,      // 像素宽度
    "height": 200      // 像素高度
  },  
}
```

#### usage 字段结构

```json
{
  [{                 // 使用记录
    "practiceId": "string",   // 字帖ID      
  }]
}
```

### 7.3 字帖表 (practices)

#### pages 字段结构

```json
[{
  "index": 0,                // 页面序号
  "size": {                   // 页面尺寸
    "unit":"mm",            // 尺寸单位
    "resUnit":"ppi",        // 分辨率单位
    "resUnitValue":300,     // 分辨率单位值
    "width": 210,           // 毫米
    "height": 297           // A4纸张
  }, 
  "layers": [{              // 图层数组
    "index": 0,            // 图层序号
    "name": "背景",        // 图层名称
    "type": "background",  // background/content
    "visible": true,       // 是否可见
    "locked": false,       // 是否锁定
    "opacity": 1.0,        // 不透明度(0-1)
    "elements": [{         // 元素数组
      "id": "uuid",       // 元素唯一标识
      "type": "chars",    // chars/text/image
      "geometry": {       // 位置和尺寸
        "x": 50,         // 左上角x坐标(mm)
        "y": 50,         // 左上角y坐标(mm)
        "width": 100,    // 宽度(mm)
        "height": 100,   // 高度(mm)
        "rotation": 0    // 旋转角度
      },
      "style": {         // 样式属性
        "opacity": 1.0,  // 不透明度
        "visible": true  // 是否可见
      },
      "content": {       // 内容(根据type不同而不同)
        "chars": [{      // type=chars时的结构
          "charId": "uuid",
          "position": {
            "offsetX": 0,
            "offsetY": 0
          },
          "transform": {
            "scaleX": 1.0,
            "scaleY": 1.0,
            "rotation": 0
          },
          "style": {
            "color": "#000000",
            "opacity": 1.0
          }
        }],
        "text": {        // type=text时的结构
          "content": "string",
          "fontFamily": "string",
          "fontSize": 12,
          "color": "#000000",
          "alignment": "left",
        },
        "image": {       // type=image时的结构
          "path": "string",
          }
        }
    }]
  }]
}]
```
