import 'package:flutter/material.dart';

import '../entities/character.dart';
import '../entities/work.dart';

abstract class WorkRepository {
  Future<void> deleteWork(String id);
  Future<List<Character>> getCharactersByWorkId(String workId);
  Future<Work?> getWork(String id);
  Future<List<Map<String, dynamic>>> getWorks({
    String? query,
    String? style,
    String? tool,
    DateTimeRange? creationDateRange,
    String? orderBy,
    bool descending = true,
  });
  Future<int> getWorksCount({
    String? query,
    String? style,
    String? tool,
    DateTimeRange? creationDateRange,
  });
  Future<String> insertWork(Work work);
  Future<void> updateWork(Work work);
  Future<bool> workExists(String id);
}
