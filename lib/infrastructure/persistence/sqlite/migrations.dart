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
    creationDate INTEGER,
    createTime INTEGER NOT NULL,
    updateTime INTEGER NOT NULL,
    tags TEXT,
    imageCount INTEGER DEFAULT 0
  );

  -- 角色表
  CREATE TABLE IF NOT EXISTS characters (
    id TEXT PRIMARY KEY,
    workId TEXT NOT NULL,
    char TEXT NOT NULL,
    region TEXT NOT NULL,
    tags TEXT,
    createTime INTEGER NOT NULL,
    updateTime INTEGER NOT NULL,
    FOREIGN KEY (workId) REFERENCES works (id) ON DELETE CASCADE
  );

  -- 字帖表
  CREATE TABLE IF NOT EXISTS practices (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    pages TEXT NOT NULL,
    tags TEXT,
    createTime INTEGER NOT NULL,
    updateTime INTEGER NOT NULL
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
    updateTime INTEGER NOT NULL
  );

  -- 创建索引
  CREATE INDEX IF NOT EXISTS idx_characters_workId ON characters(workId);
  CREATE INDEX IF NOT EXISTS idx_characters_char ON characters(char);
  ''',

  // 版本 2: 添加作品图片管理
  '''
  -- 创建作品图片表
  CREATE TABLE IF NOT EXISTS work_images (
    id TEXT PRIMARY KEY,
    workId TEXT NOT NULL,
    indexInWork INTEGER NOT NULL,
    path TEXT NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    format TEXT NOT NULL,
    size INTEGER NOT NULL,
    thumbnailPath TEXT,
    createTime INTEGER NOT NULL,
    updateTime INTEGER NOT NULL,
    FOREIGN KEY (workId) REFERENCES works (id) ON DELETE CASCADE
  );

  -- 创建索引
  CREATE INDEX IF NOT EXISTS idx_work_images_workId ON work_images(workId);
  CREATE INDEX IF NOT EXISTS idx_work_images_index ON work_images(workId, indexInWork);

  -- 添加首图ID和最后更新时间字段
  ALTER TABLE works 
  ADD COLUMN firstImageId TEXT REFERENCES work_images(id),
  ADD COLUMN lastImageUpdateTime INTEGER;

  -- 创建触发器：更新imageCount
  CREATE TRIGGER IF NOT EXISTS update_work_image_count
  AFTER INSERT OR DELETE ON work_images
  BEGIN
    UPDATE works 
    SET imageCount = (
      SELECT COUNT(*) 
      FROM work_images 
      WHERE workId = new.workId
    )
    WHERE id = new.workId;
  END;

  -- 创建触发器：更新firstImageId
  CREATE TRIGGER IF NOT EXISTS update_work_first_image
  AFTER INSERT OR DELETE OR UPDATE OF indexInWork ON work_images
  BEGIN
    UPDATE works 
    SET firstImageId = (
      SELECT id
      FROM work_images
      WHERE workId = new.workId
      ORDER BY indexInWork ASC
      LIMIT 1
    ),
    lastImageUpdateTime = strftime('%s', 'now') * 1000
    WHERE id = new.workId;
  END;
  ''',
];
