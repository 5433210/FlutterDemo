/// SQLite数据库迁移脚本 - 版本 21
const migrationScript21 = '''

-- 1. 为 works 表添加 metadata 字段
ALTER TABLE works ADD COLUMN metadata TEXT;

-- 2. 为 characters 表添加 metadata 字段
ALTER TABLE characters ADD COLUMN metadata TEXT;

-- 3. 初始化现有记录的 metadata 字段为空的 JSON 对象
UPDATE works SET metadata = '{}' WHERE metadata IS NULL;
UPDATE characters SET metadata = '{}' WHERE metadata IS NULL;

-- 4. 创建索引以提高基于元数据的查询性能
CREATE INDEX IF NOT EXISTS idx_works_metadata ON works(metadata);
CREATE INDEX IF NOT EXISTS idx_characters_metadata ON characters(metadata);

-- 5. 更新 CharacterView 视图以包含新的 metadata 字段
DROP VIEW IF EXISTS CharacterView;
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
  c.metadata,
  w.style,
  w.tool,
  w.title,
  w.author,
  w.metadata AS workMetadata
FROM 
  characters c
LEFT JOIN
  works w ON c.workId = w.id;

''';
