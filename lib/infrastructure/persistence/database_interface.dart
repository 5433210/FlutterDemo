import 'dart:async';

import 'package:flutter/material.dart';

abstract class DatabaseInterface {
  Future<void> close();
  Future<void> deleteCharacter(String id);

  Future<void> deletePractice(String id);
  Future<void> deleteWork(String id);

  Future<Map<String, dynamic>?> getCharacter(String id);

  Future<List<Map<String, dynamic>>> getCharactersByWorkId(String workId);
  Future<Map<String, dynamic>?> getPractice(String id);
  Future<List<Map<String, dynamic>>> getPractices({
    List<String>? characterIds,
    String? title,
    int? limit,
    int? offset,
  });
  Future<String?> getSetting(String key);

  Future<Map<String, dynamic>?> getWork(String id);
  Future<List<Map<String, dynamic>>> getWorks({
    String? query, // 添加查询参数
    String? style,
    String? tool,
    DateTimeRange? creationDateRange,
    String? orderBy,
    bool descending = true,
  });
  Future<int> getWorksCount(
      {String? style,
      String? author,
      String? name,
      String? tool, // Add tool parameter
      List<String>? tags,
      DateTime? fromDateImport,
      DateTime? toDateImport,
      DateTime? fromDateCreation,
      DateTime? toDateCreation,
      DateTime? fromDateUpdate,
      DateTime? toDateUpdate});
  Future<void> initialize();
  // Character operations
  Future<String> insertCharacter(Map<String, dynamic> character);

  // Practice operations
  Future<String> insertPractice(Map<String, dynamic> practice);
  // Work operations
  Future<String> insertWork(Map<String, dynamic> work);
  // Settings operations
  Future<void> setSetting(String key, String value);
  Future<void> updateCharacter(String id, Map<String, dynamic> character);
  Future<void> updatePractice(String id, Map<String, dynamic> practice);

  Future<void> updateWork(String id, Map<String, dynamic> work);
  Future<bool> workExists(String id);
}
