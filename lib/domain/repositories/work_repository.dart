import 'package:flutter/material.dart';
import '../entities/character.dart';
import '../entities/work.dart';

abstract class WorkRepository {
  Future<String> insertWork(Work work);
  Future<Work?> getWork(String id);
  Future<List<Map<String, dynamic>>> getWorks({
    String? query,
    String? style,
    String? tool,
    DateTimeRange? importDateRange,
    DateTimeRange? creationDateRange,
    String? orderBy,
    bool descending = true,
  });
  Future<void> updateWork(Work work);
  Future<void> deleteWork(String id);
  Future<bool> workExists(String id);    
  Future<int> getWorksCount({
   String? query,
    String? style,
    String? tool,
    DateTimeRange? importDateRange,
    DateTimeRange? creationDateRange,
  });
  Future<List<Character>> getCharactersByWorkId(String workId);
}

