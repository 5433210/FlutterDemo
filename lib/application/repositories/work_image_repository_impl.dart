import '../../domain/models/work/work_image.dart';
import '../../domain/repositories/repositories.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../utils/date_time_helper.dart';

class WorkImageRepositoryImpl implements WorkImageRepository {
  final DatabaseInterface _db;

  WorkImageRepositoryImpl(this._db);

  @override
  Future<WorkImage> create(String workId, WorkImage image) async {
    // 检查是否已存在相同路径的图片
    final existing = await _db.query('work_images', {
      'where': [
        {'field': 'workId', 'op': '=', 'val': workId},
        {'field': 'original_path', 'op': '=', 'val': image.originalPath},
      ],
      'limit': 1,
    });

    AppLogger.info('检查图片是否已存在', tag: 'WorkImageRepository', data: {
      'workId': workId,
      'originalPath': image.originalPath,
      'exists': existing.isNotEmpty,
      'createTime': DateTimeHelper.toStorageFormat(image.createTime),
      'updateTime': DateTimeHelper.toStorageFormat(image.updateTime),
    });

    if (existing.isNotEmpty) {
      AppLogger.info('已存在图片的时间信息', tag: 'WorkImageRepository', data: {
        'existingCreateTime': existing.first['createTime'],
        'existingUpdateTime': existing.first['updateTime'],
      });
      return _mapToWorkImage(existing.first);
    }

    // 创建新记录
    final row = _mapToRow(image, workId);
    AppLogger.debug('准备保存新图片', tag: 'WorkImageRepository', data: {
      'row': row,
    });

    await _db.set('work_images', image.id, row);
    return image;
  }

  @override
  Future<List<WorkImage>> createMany(
      String workId, List<WorkImage> images) async {
    AppLogger.debug('批量创建图片', tag: 'WorkImageRepository', data: {
      'workId': workId,
      'count': images.length,
      'createTimes': images
          .map((img) => DateTimeHelper.toStorageFormat(img.createTime))
          .toList(),
    });

    // 检查并过滤重复图片
    final uniqueImages = <WorkImage>[];
    final existingPaths = <String>{};

    // 获取已存在的图片路径
    final existing = await _db.query('work_images', {
      'where': [
        {'field': 'workId', 'op': '=', 'val': workId},
      ],
    });
    existingPaths.addAll(existing.map((e) => e['original_path'] as String));

    AppLogger.debug('已存在图片路径', tag: 'WorkImageRepository', data: {
      'paths': existingPaths.toList(),
    });

    // 过滤出不重复的图片
    for (final image in images) {
      if (!existingPaths.contains(image.originalPath)) {
        uniqueImages.add(image);
      } else {
        AppLogger.debug('跳过重复图片', tag: 'WorkImageRepository', data: {
          'originalPath': image.originalPath,
          'createTime': DateTimeHelper.toStorageFormat(image.createTime),
        });
      }
    }

    AppLogger.debug('过滤重复图片完成', tag: 'WorkImageRepository', data: {
      'originalCount': images.length,
      'uniqueCount': uniqueImages.length,
    });

    if (uniqueImages.isNotEmpty) {
      final data = Map.fromEntries(
        uniqueImages.map((img) => MapEntry(img.id, _mapToRow(img, workId))),
      );
      await _db.setMany('work_images', data);
    }

    // 返回所有图片，包括已存在的
    return getAllByWorkId(workId);
  }

  @override
  Future<void> delete(String workId, String imageId) async {
    AppLogger.debug('删除图片', tag: 'WorkImageRepository', data: {
      'workId': workId,
      'imageId': imageId,
    });
    await _db.delete('work_images', imageId);
  }

  @override
  Future<void> deleteMany(String workId, List<String> imageIds) async {
    AppLogger.debug('批量删除图片', tag: 'WorkImageRepository', data: {
      'workId': workId,
      'count': imageIds.length,
    });
    await _db.deleteMany('work_images', imageIds);
  }

  @override
  Future<WorkImage?> get(String imageId) async {
    final result = await _db.get('work_images', imageId);
    if (result != null) {
      AppLogger.debug('获取单个图片', tag: 'WorkImageRepository', data: {
        'imageId': imageId,
        'createTime': result['createTime'],
        'updateTime': result['updateTime'],
      });
    }
    return result != null ? _mapToWorkImage(result) : null;
  }

  @override
  Future<List<WorkImage>> getAllByWorkId(String workId) async {
    final results = await _db.query('work_images', {
      'where': [
        {'field': 'workId', 'op': '=', 'val': workId}
      ],
      'orderBy': 'indexInWork ASC',
    });

    AppLogger.debug('获取作品所有图片', tag: 'WorkImageRepository', data: {
      'workId': workId,
      'count': results.length,
      'records': results
          .map((row) => {
                'id': row['id'],
                'originalPath': row['original_path'],
                'createTime': row['createTime'],
                'updateTime': row['updateTime'],
              })
          .toList(),
    });

    return results.map((row) => _mapToWorkImage(row)).toList();
  }

  @override
  Future<WorkImage?> getFirstByWorkId(String workId) async {
    final results = await _db.query('work_images', {
      'where': [
        {'field': 'workId', 'op': '=', 'val': workId}
      ],
      'orderBy': 'indexInWork ASC',
      'limit': 1,
    });
    return results.isNotEmpty ? _mapToWorkImage(results.first) : null;
  }

  @override
  Future<int> getNextIndex(String workId) async {
    final results = await _db.query('work_images', {
      'where': [
        {'field': 'workId', 'op': '=', 'val': workId}
      ],
      'orderBy': 'indexInWork DESC',
      'limit': 1,
    });
    return (results.isNotEmpty
        ? (_mapToWorkImage(results.first).index + 1)
        : 0);
  }

  @override
  Future<List<WorkImage>> saveMany(List<WorkImage> images) async {
    AppLogger.debug('批量保存图片', tag: 'WorkImageRepository', data: {
      'count': images.length,
      'times': images
          .map((img) => {
                'id': img.id,
                'createTime': DateTimeHelper.toStorageFormat(img.createTime),
                'updateTime': DateTimeHelper.toStorageFormat(img.updateTime),
              })
          .toList(),
    });

    if (images.isEmpty) return [];

    final data = Map.fromEntries(
      images.map((img) => MapEntry(img.id, _mapToRow(img, img.workId))),
    );
    await _db.setMany('work_images', data);
    return images;
  }

  @override
  Future<void> updateIndex(String workId, String imageId, int index) async {
    AppLogger.debug('更新图片索引', tag: 'WorkImageRepository', data: {
      'workId': workId,
      'imageId': imageId,
      'newIndex': index,
      'updateTime': DateTimeHelper.getCurrentUtc(),
    });

    await _db.save('work_images', imageId, {
      'indexInWork': index,
      'updateTime': DateTimeHelper.getCurrentUtc(),
    });
  }

  Map<String, dynamic> _mapToRow(WorkImage image, String workId) {
    final row = {
      'workId': workId,
      'libraryItemId': image.libraryItemId,
      'path': image.path,
      'original_path': image.originalPath,
      'thumbnail_path': image.thumbnailPath,
      'format': image.format,
      'size': image.size,
      'width': image.width,
      'height': image.height,
      'indexInWork': image.index,
      'createTime': DateTimeHelper.toStorageFormat(image.createTime),
      'updateTime': DateTimeHelper.toStorageFormat(image.updateTime),
    };

    AppLogger.debug('转换为数据库行', tag: 'WorkImageRepository', data: {
      'imageId': image.id,
      'row': row,
    });

    return row;
  }

  WorkImage _mapToWorkImage(Map<String, dynamic> row) {
    AppLogger.debug('映射数据库记录', tag: 'WorkImageRepository', data: {
      'record': row,
    });

    return WorkImage(
      id: row['id'] as String,
      workId: row['workId'] as String,
      libraryItemId: row['libraryItemId'] as String?,
      path: row['path'] as String,
      originalPath: row['original_path'] as String,
      thumbnailPath: row['thumbnail_path'] as String,
      format: row['format'] as String,
      size: row['size'] as int,
      width: row['width'] as int,
      height: row['height'] as int,
      index: row['indexInWork'] as int,
      createTime:
          DateTimeHelper.fromStorageFormat(_safeGetTime(row, 'createTime')) ??
              DateTime.now(),
      updateTime:
          DateTimeHelper.fromStorageFormat(_safeGetTime(row, 'updateTime')) ??
              DateTime.now(),
    );
  }

  String? _safeGetTime(Map<String, dynamic> row, String key) {
    final value = row[key];
    AppLogger.debug('读取时间字段', tag: 'WorkImageRepository', data: {
      'field': key,
      'value': value,
      'type': value?.runtimeType.toString(),
    });
    return value as String?;
  }
}
