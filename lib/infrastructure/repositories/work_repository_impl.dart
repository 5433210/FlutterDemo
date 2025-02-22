import 'package:demo/infrastructure/persistence/database_interface.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/character.dart';
import '../../domain/entities/work.dart';
import '../../domain/repositories/work_repository.dart';

class WorkRepositoryImpl implements WorkRepository {
  final DatabaseInterface _db;

  WorkRepositoryImpl(this._db);

  @override
  Future<String> insertWork(Work work) async {
    return await _db.insertWork(work.toMap());
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
    String? style,
    String? tool,
    DateTimeRange? importDateRange,
    DateTimeRange? creationDateRange,
    String? orderBy,
    bool descending = true,
  }) async {
    return _db.getWorks(
      name: query, // 查询同时搜索作品名称
      author: query, // 和作者
      style: style,
      tool: tool,
      fromDateImport: importDateRange?.start,
      toDateImport: importDateRange?.end,
      fromDateCreation: creationDateRange?.start,
      toDateCreation: creationDateRange?.end,
      sortBy: orderBy,
      descending: descending,
    );
  }

  @override
  Future<void> updateWork(Work work) async {
    await _db.updateWork(work.id!, work.toMap());
  }

  @override
  Future<void> deleteWork(String id) async {
    await _db.deleteWork(id);
  }

  @override
  Future<bool> workExists(String id) async {
    return await _db.workExists(id);
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
  Future<List<Character>> getCharactersByWorkId(String workId) async {
    final maps = await _db.getCharactersByWorkId(workId);
    return maps.map((map) => Character.fromMap(map)).toList();
  }
}
