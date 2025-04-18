/// SQLite数据库迁移脚本
const migrations = [
  // 版本 1: 创建基础表结构
  '''
  -- 作品表
  CREATE TABLE IF NOT EXISTS works (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT,
    style TEXT,
    tool TEXT,
    remark TEXT,
    creationDate TEXT,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL,
    tags TEXT,
    status TEXT NOT NULL DEFAULT 'draft',
    imageCount INTEGER DEFAULT 0
  );

  -- 角色表
  CREATE TABLE IF NOT EXISTS characters (
    id TEXT PRIMARY KEY,
    workId TEXT NOT NULL,
    pageId TEXT NOT NULL,
    character TEXT NOT NULL,
    region TEXT NOT NULL,
    tags TEXT,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL,
    FOREIGN KEY (workId) REFERENCES works (id) ON DELETE CASCADE
  );

  -- 字帖表
  CREATE TABLE IF NOT EXISTS practices (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    pages TEXT NOT NULL,
    tags TEXT,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL
  );

  -- 标签表
  CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT
  );

  -- 设置表
  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updateTime TEXT NOT NULL
  );

  -- 创建索引
  CREATE INDEX IF NOT EXISTS idx_characters_workId ON characters(workId);
  CREATE INDEX IF NOT EXISTS idx_characters_char ON characters(character);
  ''',

  // 版本 2: 添加作品图片管理 - 表和索引
  '''
  CREATE TABLE IF NOT EXISTS work_images (
    id TEXT PRIMARY KEY,
    workId TEXT NOT NULL,
    indexInWork INTEGER NOT NULL,
    path TEXT NOT NULL,
    original_path TEXT,
    thumbnail_path TEXT,
    format TEXT NOT NULL,
    size INTEGER NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    createTime TEXT NOT NULL,
    updateTime TEXT NOT NULL,
    FOREIGN KEY (workId) REFERENCES works (id) ON DELETE CASCADE
  )
  ''',

  '''
  CREATE INDEX IF NOT EXISTS idx_work_images_workId ON work_images(workId);
  CREATE INDEX IF NOT EXISTS idx_work_images_index ON work_images(workId, indexInWork);
  CREATE INDEX IF NOT EXISTS idx_work_images_original_path ON work_images(workId, original_path);
  CREATE UNIQUE INDEX IF NOT EXISTS idx_work_images_unique_path 
  ON work_images(workId, original_path)
  WHERE original_path IS NOT NULL;
  ''',

  // 版本 2: 添加作品字段
  '''
  ALTER TABLE works ADD COLUMN firstImageId TEXT REFERENCES work_images(id);
  ALTER TABLE works ADD COLUMN lastImageUpdateTime TEXT;
  ''',

  // 版本 2: 添加触发器
  '''
  CREATE TRIGGER IF NOT EXISTS update_work_image_count_insert 
  AFTER INSERT ON work_images
  BEGIN
    UPDATE works 
    SET imageCount = (
      SELECT COUNT(*) 
      FROM work_images 
      WHERE workId = NEW.workId
    )
    WHERE id = NEW.workId;
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS update_work_image_count_delete 
  AFTER DELETE ON work_images
  BEGIN
    UPDATE works 
    SET imageCount = (
      SELECT COUNT(*) 
      FROM work_images 
      WHERE workId = OLD.workId
    )
    WHERE id = OLD.workId;
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_insert 
  AFTER INSERT ON work_images
  BEGIN
    UPDATE works 
    SET firstImageId = (
      SELECT id
      FROM work_images
      WHERE workId = NEW.workId
      ORDER BY indexInWork ASC
      LIMIT 1
    ),
    lastImageUpdateTime = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
    WHERE id = NEW.workId;
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_update 
  AFTER UPDATE OF indexInWork ON work_images
  BEGIN
    UPDATE works 
    SET firstImageId = (
      SELECT id
      FROM work_images
      WHERE workId = NEW.workId
      ORDER BY indexInWork ASC
      LIMIT 1
    ),
    lastImageUpdateTime = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
    WHERE id = NEW.workId;
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS update_work_first_image_on_delete 
  AFTER DELETE ON work_images
  BEGIN
    UPDATE works 
    SET firstImageId = (
      SELECT id FROM work_images WHERE workId = OLD.workId ORDER BY indexInWork ASC LIMIT 1
    ),
    lastImageUpdateTime = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
    WHERE id = OLD.workId;
  END;
  ''',

  // 版本 5: 添加字符收藏功能
  '''
  ALTER TABLE characters ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0;
  ALTER TABLE characters ADD COLUMN note TEXT;
  ''',

  // 版本 6: 添加临时工作项
  '''
  INSERT OR IGNORE INTO works (
    id,
    title,
    author,
    status,
    createTime,
    updateTime
  ) VALUES (
    'temp',
    '临时工作项',
    'system',
    'draft',
    datetime('now'),
    datetime('now')
  );
  ''',

  /// 版本 7: 添加CharacterView视图
  '''
  CREATE VIEW IF NOT EXISTS CharacterView AS
  SELECT 
    c.id,
    c.character,
    c.isFavorite,    
    c.createTime AS collectionTime,
    c.updateTime,
    c.pageId,
    c.workId,
    c.tags,
    c.region,
    c.note,
    w.style,
    w.tool,
    w.title,
    w.author,
    w.creationDate As creationTime
  FROM 
    characters c
  LEFT JOIN 
    works w ON c.workId = w.id;
  ''',
];
