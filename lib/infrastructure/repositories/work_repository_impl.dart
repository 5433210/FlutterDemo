import 'package:flutter/material.dart';

import '../../domain/entities/character.dart';
import '../../domain/entities/work.dart';
import '../../domain/repositories/work_repository.dart';
import '../../infrastructure/logging/logger.dart';
import '../persistence/database_interface.dart';

class WorkRepositoryImpl implements WorkRepository {
  final DatabaseInterface _db;

  WorkRepositoryImpl(this._db);

  @override
  Future<void> deleteWork(String id) async {
    await _db.deleteWork(id);
  }

  @override
  Future<List<Character>> getCharactersByWorkId(String workId) async {
    final maps = await _db.getCharactersByWorkId(workId);
    return maps.map((map) => Character.fromMap(map)).toList();
  }

  @override
  Future<Work?> getWork(String id) async {
    final map = await _db.getWork(id);
    if (map == null) return null;
    return Work.fromMap(map);
  }

  @override
  Future<List<Map<String, dynamic>>> getWorks({
    String? query,
    String? style, // 注意这里的参数
    String? tool,
    DateTimeRange? creationDateRange,
    String? orderBy,
    bool descending = true,
  }) async {
    debugPrint('Repository - querying works:'); // 添加日志
    debugPrint('- style: $style'); // 添加日志
    debugPrint('- tool: $tool'); // 添加日志

    return await _db.getWorks(
      query: query,
      style: style, // 确保这些参数正确传递给数据库
      tool: tool,
      creationDateRange: creationDateRange,
      orderBy: orderBy,
      descending: descending,
    );
  }

  @override
  Future<int> getWorksCount({
    String? query,
    String? style,
    String? tool,
    DateTimeRange? importDateRange,
    DateTimeRange? creationDateRange,
  }) async {
    return await _db.getWorksCount(
      name: query,
      author: query,
      style: style,
      tool: tool,
      fromDateImport: importDateRange?.start,
      toDateImport: importDateRange?.end,
      fromDateCreation: creationDateRange?.start,
      toDateCreation: creationDateRange?.end,
    );
  }

  @override
  Future<String> insertWork(Work work) async {
    try {
      AppLogger.debug('Inserting work', tag: 'WorkRepository');
      final id = await _db.insertWork(work.toMap());
      AppLogger.info('Work inserted successfully',
          tag: 'WorkRepository', data: {'workId': id});
      return id;
    } catch (e, stack) {
      AppLogger.error('Failed to insert work',
          tag: 'WorkRepository', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> updateWork(Work work) async {
    await _db.updateWork(work.id!, work.toMap());
  }

  @override
  Future<bool> workExists(String id) async {
    return await _db.workExists(id);
  }
}
