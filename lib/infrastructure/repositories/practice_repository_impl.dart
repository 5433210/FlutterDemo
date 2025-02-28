import 'package:uuid/uuid.dart';

import '../../domain/repositories/practice_repository.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/persistence/database_interface.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  // 字帖表名定义为常量，便于维护
  static const String _tableName = 'practices';
  final DatabaseInterface _db;

  final _uuid = const Uuid();

  PracticeRepositoryImpl(this._db);

  @override
  Future<String> createPractice(Map<String, dynamic> data) async {
    try {
      // 生成唯一ID
      final id = _uuid.v4();
      data['id'] = id;

      // 设置创建和更新时间
      final now = DateTime.now().toIso8601String();
      data['createTime'] = now;
      data['updateTime'] = now;

      // 使用DatabaseInterface的insertPractice方法，而不是直接insert
      await _db.insertPractice(data);

      return id;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to create practice',
        tag: 'PracticeRepositoryImpl',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<bool> deletePractice(String id) async {
    try {
      // 使用DatabaseInterface的deletePractice方法
      await _db.deletePractice(id);
      return true;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to delete practice',
        tag: 'PracticeRepositoryImpl',
        error: e,
        stackTrace: stack,
        data: {'id': id},
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getPractice(String id) async {
    try {
      // 使用DatabaseInterface的getPractice方法
      return await _db.getPractice(id);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to get practice',
        tag: 'PracticeRepositoryImpl',
        error: e,
        stackTrace: stack,
        data: {'id': id},
      );
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPractices({
    String? title,
    int? limit,
    int? offset,
  }) async {
    try {
      // 使用DatabaseInterface的getPractices方法
      return await _db.getPractices(
        title: title,
        limit: limit,
        offset: offset,
      );
    } catch (e, stack) {
      AppLogger.error(
        'Failed to get practices',
        tag: 'PracticeRepositoryImpl',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<bool> updatePractice(String id, Map<String, dynamic> data) async {
    try {
      // 更新修改时间
      data['updateTime'] = DateTime.now().toIso8601String();

      // 删除ID，防止意外修改ID
      data.remove('id');

      // 使用DatabaseInterface的updatePractice方法
      await _db.updatePractice(id, data);
      return true;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to update practice',
        tag: 'PracticeRepositoryImpl',
        error: e,
        stackTrace: stack,
        data: {'id': id},
      );
      rethrow;
    }
  }
}
