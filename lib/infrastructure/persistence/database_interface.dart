abstract class DatabaseInterface {
  Future<void> initialize();
  Future<void> close();
  
  // Work operations
  Future<String> insertWork(Map<String, dynamic> work);
  Future<Map<String, dynamic>?> getWork(String id);
  Future<List<Map<String, dynamic>>> getWorks({
    String? style,
    String? author,
    String? name,      
    String? tool,        // Add tool parameter
    List<String>? tags,
    DateTime? fromDateImport,
    DateTime? toDateImport,
    DateTime? fromDateCreation,
    DateTime? toDateCreation,
    DateTime? fromDateUpdate,
    DateTime? toDateUpdate,
    int? limit,
    int? offset,
    String? sortBy,
    bool descending = true,
  });
  Future<void> updateWork(String id, Map<String, dynamic> work);
  Future<void> deleteWork(String id);
  Future<bool> workExists(String id);
  Future<int> getWorksCount({
    String? style,
    String? author,
    String? name,
    String? tool,        // Add tool parameter
    List<String>? tags,
    DateTime? fromDateImport,
    DateTime? toDateImport,
    DateTime? fromDateCreation,
    DateTime? toDateCreation,
    DateTime? fromDateUpdate,    
    DateTime? toDateUpdate 
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
}