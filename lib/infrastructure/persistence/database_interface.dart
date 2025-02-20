abstract class DatabaseInterface {
  Future<void> initialize();
  Future<void> close();
  
  // Work operations
  Future<String> insertWork(Map<String, dynamic> work);
  Future<Map<String, dynamic>?> getWork(String id);
  Future<List<Map<String, dynamic>>> getWorks({
    String? style,
    String? author,
    List<String>? tags,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
    String? sortBy,
    bool descending,
  });
  Future<void> updateWork(String id, Map<String, dynamic> work);
  Future<void> deleteWork(String id);
  Future<bool> workExists(String id);
  Future<int> getWorksCount({
    String? style,
    String? author,
    List<String>? tags,
  });
  
  // Character operations
  Future<String> insertCharacter(Map<String, dynamic> character);
  Future<Map<String, dynamic>?> getCharacter(String id);
  Future<List<Map<String, dynamic>>> getCharactersByWorkId(String workId);
  Future<void> updateCharacter(String id, Map<String, dynamic> character);
  Future<void> deleteCharacter(String id);
  
  // Practice operations
  Future<String> insertPractice(Map<String, dynamic> practice);
  Future<Map<String, dynamic>?> getPractice(String id);
  Future<List<Map<String, dynamic>>> getPractices({
    List<String>? characterIds,
    String? title,
    int? limit,
    int? offset,
  });
  Future<void> updatePractice(String id, Map<String, dynamic> practice);
  Future<void> deletePractice(String id);
  
  // Settings operations
  Future<void> setSetting(String key, String value);
  Future<String?> getSetting(String key);

  Future<T> transaction<T>(Future<T> Function(DatabaseTransaction) action);
}

abstract class DatabaseTransaction {
  Future<void> insertWork(Map<String, dynamic> work);
  Future<void> insertCharacter(Map<String, dynamic> character);
  Future<void> insertPractice(Map<String, dynamic> practice);
  Future<void> updateWork(String id, Map<String, dynamic> work);
  Future<void> deleteWork(String id);
}