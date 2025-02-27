/// Repository interface for managing practices
abstract class PracticeRepository {
  /// Create a new practice
  Future<String> createPractice(Map<String, dynamic> practiceData);

  /// Delete a practice by ID
  Future<bool> deletePractice(String id);

  /// Get a practice by ID
  Future<Map<String, dynamic>?> getPractice(String id);

  /// Get practices with optional filters
  Future<List<Map<String, dynamic>>> getPractices({
    String? title,
    int? limit,
    int? offset,
  });

  /// Get the total count of practices
  Future<int> getPracticesCount();

  /// Update a practice
  Future<void> updatePractice(String id, Map<String, dynamic> practiceData);
}
