import 'package:flutter/material.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../entities/character.dart';
import '../entities/work.dart';

abstract class WorkRepository {
  Future<String> insertWork(Work work);
  Future<Work?> getWork(String id);
  Future<List<Map<String, dynamic>>> getWorks({
    String? query,
    List<String>? styles,
    List<String>? tools,
    DateTimeRange? dateRange,
    String? orderBy,
    bool descending = true,
  });
  Future<void> updateWork(Work work);
  Future<void> deleteWork(String id);
  Future<bool> workExists(String id);
  Future<int> getWorksCount({
    String? style,
    String? author,
    List<String>? tags,
  });
  Future<List<Character>> getCharactersByWorkId(String workId);
  Future<T> transaction<T>(Future<T> Function(DatabaseTransaction) action);
}

