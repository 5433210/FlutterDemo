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
    DateTimeRange? dateRange,
    bool descending = true,
    String? orderBy,
    String? query,
    List<String>? styles,
    List<String>? tools,
  }) async {
    final maps = await _db.getWorks();
    return maps;
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
    String? style,
    String? author,
    List<String>? tags,
  }) async {
    return await _db.getWorksCount(
      style: style,
      author: author,
      tags: tags, // Add missing tags parameter
    );
  }

  @override
  Future<List<Character>> getCharactersByWorkId(String workId) async {
    final maps = await _db.getCharactersByWorkId(workId);
    return maps.map((map) => Character.fromMap(map)).toList();
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseTransaction) action) async {
    return await _db.transaction(action);
  }
}