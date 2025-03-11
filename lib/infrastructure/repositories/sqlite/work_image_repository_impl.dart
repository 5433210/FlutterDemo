import 'package:uuid/uuid.dart';

import '../../../domain/models/work/work_image.dart';
import '../../../domain/repositories/work_image_repository.dart';
import '../../../utils/date_time_helper.dart';
import '../../persistence/database_interface.dart';
import '../../persistence/models/database_query.dart';

class WorkImageRepositoryImpl implements WorkImageRepository {
  final DatabaseInterface _db;
  final _uuid = const Uuid();
  final String _table = 'work_images';

  WorkImageRepositoryImpl(this._db);

  @override
  Future<WorkImage> create(String workId, WorkImage image) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final data = {
      'id': id,
      'workId': workId,
      'indexInWork':
          image.index == -1 ? await getNextIndex(workId) : image.index,
      'path': image.originalPath,
      'width': image.width,
      'height': image.height,
      'format': image.format,
      'size': image.size,
      'thumbnailPath': image.thumbnailPath,
      'createTime': DateTimeHelper.toStorageFormat(now),
      'updateTime': DateTimeHelper.toStorageFormat(now),
    };

    await _db.set(_table, id, data);

    final created = await get(id);
    if (created == null) {
      throw Exception('Failed to create work image: $id');
    }
    return created;
  }

  @override
  Future<List<WorkImage>> createMany(
      String workId, List<WorkImage> images) async {
    final now = DateTime.now();
    final results = <WorkImage>[];
    var currentIndex = await getNextIndex(workId);

    final batchData = <String, Map<String, dynamic>>{};

    for (final image in images) {
      final id = _uuid.v4();
      batchData[id] = {
        'id': id,
        'workId': workId,
        'indexInWork': image.index == -1 ? currentIndex++ : image.index,
        'path': image.originalPath,
        'width': image.width,
        'height': image.height,
        'format': image.format,
        'size': image.size,
        'thumbnailPath': image.thumbnailPath,
        'createTime': DateTimeHelper.toStorageFormat(now),
        'updateTime': DateTimeHelper.toStorageFormat(now),
      };

      results.add(image.copyWith(
        id: id,
        workId: workId,
        createTime: now,
        updateTime: now,
      ));
    }

    await _db.setMany(_table, batchData);
    return results;
  }

  @override
  Future<void> delete(String workId, String imageId) async {
    await _db.delete(_table, imageId);
  }

  @override
  Future<void> deleteMany(String workId, List<String> imageIds) async {
    await _db.deleteMany(_table, imageIds);
  }

  @override
  Future<WorkImage?> get(String imageId) async {
    final data = await _db.get(_table, imageId);
    if (data == null) return null;
    return _mapToWorkImage(data);
  }

  @override
  Future<List<WorkImage>> getAllByWorkId(String workId) async {
    final query = DatabaseQuery(
      conditions: [
        DatabaseQueryCondition(
          field: 'workId',
          operator: '=',
          value: workId,
        ),
      ],
      orderBy: 'indexInWork ASC',
    );

    final results = await _db.query(_table, query.toJson());
    return results.map((row) => _mapToWorkImage(row)).toList();
  }

  @override
  Future<WorkImage?> getFirstByWorkId(String workId) async {
    final query = DatabaseQuery(
      conditions: [
        DatabaseQueryCondition(
          field: 'workId',
          operator: '=',
          value: workId,
        ),
      ],
      orderBy: 'indexInWork ASC',
      limit: 1,
    );

    final results = await _db.query(_table, query.toJson());
    if (results.isEmpty) return null;
    return _mapToWorkImage(results.first);
  }

  @override
  Future<int> getNextIndex(String workId) async {
    final result = await _db.rawQuery('''
      SELECT COALESCE(MAX(indexInWork), -1) + 1 as nextIndex
      FROM work_images
      WHERE workId = ?
    ''', [workId]);

    return result.first['nextIndex'] as int;
  }

  @override
  Future<List<WorkImage>> saveMany(List<WorkImage> images) async {
    final now = DateTime.now();
    final batch = <String, Map<String, dynamic>>{};

    // 先获取已有记录以保留 createTime
    final existingData =
        await Future.wait(images.map((img) => _db.get(_table, img.id)));

    for (var i = 0; i < images.length; i++) {
      final image = images[i];
      final existing = existingData[i];

      batch[image.id] = {
        'id': image.id,
        'workId': image.workId,
        'indexInWork': image.index,
        'path': image.originalPath,
        'width': image.width,
        'height': image.height,
        'format': image.format,
        'size': image.size,
        'thumbnailPath': image.thumbnailPath,
        // 如果记录已存在，使用原有的 createTime，否则使用当前时间
        'createTime':
            existing?['createTime'] ?? DateTimeHelper.toStorageFormat(now),
        'updateTime': DateTimeHelper.toStorageFormat(now),
      };
    }

    await _db.setMany(_table, batch);
    return images.map((img) => img.copyWith(updateTime: now)).toList();
  }

  @override
  Future<void> updateIndex(String workId, String imageId, int newIndex) async {
    // Get current index
    final image = await get(imageId);
    if (image == null) return;
    final oldIndex = image.index;
    if (oldIndex == newIndex) return;

    // Update indexes
    final now = DateTime.now();

    if (oldIndex < newIndex) {
      await _db.rawUpdate('''
        UPDATE work_images
        SET indexInWork = indexInWork - 1,
            updateTime = ?
        WHERE workId = ?
          AND indexInWork > ?
          AND indexInWork <= ?
      ''', [DateTimeHelper.toStorageFormat(now), workId, oldIndex, newIndex]);
    } else {
      await _db.rawUpdate('''
        UPDATE work_images
        SET indexInWork = indexInWork + 1,
            updateTime = ?
        WHERE workId = ?
          AND indexInWork >= ?
          AND indexInWork < ?
      ''', [DateTimeHelper.toStorageFormat(now), workId, newIndex, oldIndex]);
    }

    // Update target image
    await _db.save(_table, imageId, {
      'indexInWork': newIndex,
      'updateTime': DateTimeHelper.toStorageFormat(now),
    });
  }

  WorkImage _mapToWorkImage(Map<String, dynamic> row) {
    return WorkImage(
      id: row['id'] as String,
      workId: row['workId'] as String,
      originalPath: row['path'] as String,
      path: row['path'] as String,
      thumbnailPath: row['thumbnailPath'] as String,
      index: row['indexInWork'] as int,
      width: row['width'] as int,
      height: row['height'] as int,
      format: row['format'] as String,
      size: row['size'] as int,
      createTime:
          DateTimeHelper.fromStorageFormat(row['createTime'] as String)!,
      updateTime:
          DateTimeHelper.fromStorageFormat(row['updateTime'] as String)!,
    );
  }
}
