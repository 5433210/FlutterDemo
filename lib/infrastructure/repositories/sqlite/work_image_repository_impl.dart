import 'package:uuid/uuid.dart';

import '../../../domain/models/work/work_image.dart';
import '../../../domain/repositories/work_image_repository.dart';
import '../../persistence/database_interface.dart';
import '../../persistence/models/database_query.dart';

class WorkImageRepositoryImpl implements WorkImageRepository {
  final DatabaseInterface _db;
  final _uuid = const Uuid();
  final String _table = 'work_images';

  WorkImageRepositoryImpl(this._db);

  @override
  Future<List<WorkImage>> batchCreate(
      String workId, List<WorkImageInput> inputs) async {
    final now = DateTime.now();
    final results = <WorkImage>[];
    var currentIndex = await getNextIndex(workId);

    final batchData = <String, Map<String, dynamic>>{};

    for (final input in inputs) {
      final id = _uuid.v4();
      batchData[id] = {
        'id': id,
        'workId': workId,
        'indexInWork': input.targetIndex ?? currentIndex++,
        'path': input.originalPath,
        'width': input.metadata.width,
        'height': input.metadata.height,
        'format': input.metadata.format,
        'size': input.metadata.size,
        'thumbnailPath': input.thumbnailPath ?? '',
        'createTime': now.millisecondsSinceEpoch,
        'updateTime': now.millisecondsSinceEpoch,
      };

      results.add(WorkImage(
        id: id,
        workId: workId,
        originalPath: input.originalPath,
        path: input.originalPath,
        thumbnailPath: input.thumbnailPath ?? '',
        index: input.targetIndex ?? currentIndex - 1,
        width: input.metadata.width,
        height: input.metadata.height,
        format: input.metadata.format,
        size: input.metadata.size,
        createTime: now,
        updateTime: now,
      ));
    }

    await _db.setMany(_table, batchData);
    return results;
  }

  @override
  Future<void> batchDelete(String workId, List<String> imageIds) async {
    await _db.deleteMany(_table, imageIds);
  }

  @override
  Future<WorkImage> create(String workId, WorkImageInput input) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final data = {
      'id': id,
      'workId': workId,
      'indexInWork': input.targetIndex ?? await getNextIndex(workId),
      'path': input.originalPath,
      'width': input.metadata.width,
      'height': input.metadata.height,
      'format': input.metadata.format,
      'size': input.metadata.size,
      'thumbnailPath': input.thumbnailPath ?? '',
      'createTime': now.millisecondsSinceEpoch,
      'updateTime': now.millisecondsSinceEpoch,
    };

    await _db.set(_table, id, data);

    final image = await findById(id);
    if (image == null) {
      throw Exception('Failed to create work image: $id');
    }
    return image;
  }

  @override
  Future<void> delete(String workId, String imageId) async {
    await _db.delete(_table, imageId);
  }

  @override
  Future<WorkImage?> findById(String imageId) async {
    final data = await _db.get(_table, imageId);
    if (data == null) return null;
    return _mapToWorkImage(data);
  }

  @override
  Future<List<WorkImage>> findByWorkId(String workId) async {
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
  Future<WorkImage?> findFirstByWorkId(String workId) async {
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
  Future<T> transaction<T>(Future<T> Function() action) async {
    // 直接执行，让数据库层处理事务
    return action();
  }

  @override
  Future<void> updateIndex(String workId, String imageId, int newIndex) async {
    // Get current index
    final image = await findById(imageId);
    if (image == null) return;
    final oldIndex = image.index;
    if (oldIndex == newIndex) return;

    // Update indexes
    final updateTime = DateTime.now().millisecondsSinceEpoch;

    if (oldIndex < newIndex) {
      await _db.rawUpdate('''
        UPDATE work_images
        SET indexInWork = indexInWork - 1,
            updateTime = ?
        WHERE workId = ?
          AND indexInWork > ?
          AND indexInWork <= ?
      ''', [updateTime, workId, oldIndex, newIndex]);
    } else {
      await _db.rawUpdate('''
        UPDATE work_images
        SET indexInWork = indexInWork + 1,
            updateTime = ?
        WHERE workId = ?
          AND indexInWork >= ?
          AND indexInWork < ?
      ''', [updateTime, workId, newIndex, oldIndex]);
    }

    // Update target image
    await _db.save(_table, imageId, {
      'indexInWork': newIndex,
      'updateTime': updateTime,
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
      createTime: DateTime.fromMillisecondsSinceEpoch(row['createTime'] as int),
      updateTime: DateTime.fromMillisecondsSinceEpoch(row['updateTime'] as int),
    );
  }
}
