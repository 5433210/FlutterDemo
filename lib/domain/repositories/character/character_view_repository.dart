import '../../models/character/character_filter.dart';
import '../../models/character/character_view.dart';

/// Character statistics used in filter panel
class CharacterStats {
  /// Total number of characters
  final int totalCount;

  /// Number of favorite characters
  final int favoriteCount;

  /// Count of characters by tag
  final Map<String, int> tagCounts;

  /// Count of characters by calligraphy style
  final Map<String, int> calligraphyStyleCounts;

  /// Count of characters by writing tool
  final Map<String, int> writingToolCounts;

  /// Constructor
  CharacterStats({
    required this.totalCount,
    required this.favoriteCount,
    required this.tagCounts,
    required this.calligraphyStyleCounts,
    required this.writingToolCounts,
  });
}

/// Repository interface for accessing character view data
abstract class CharacterViewRepository {
  /// Delete a character
  Future<bool> deleteCharacter(String id);

  /// Delete multiple characters
  Future<bool> deleteCharacters(List<String> ids);

  /// Get all unique tags used by characters
  Future<List<String>> getAllTags();

  /// Get a specific character by ID
  Future<CharacterView?> getCharacterById(String id);

  /// Get characters based on filter criteria with pagination
  Future<PaginatedResult<CharacterView>> getCharacters({
    required CharacterFilter filter,
    required int page,
    required int pageSize,
  });

  /// Get multiple characters by their IDs
  Future<List<CharacterView>> getCharactersByIds(List<String> ids);

  /// Get character statistics for filter panel
  Future<CharacterStats> getCharacterStats();

  /// Get characters related to the specified character (from same work)
  Future<List<CharacterView>> getRelatedCharacters(String characterId,
      {int limit = 10});

  /// Search characters by simplified character
  Future<List<CharacterView>> searchBySimplifiedCharacter(String character,
      {int limit = 20});

  /// Toggle favorite status of a character
  Future<bool> toggleFavorite(String id);
}

/// Paginated result container
class PaginatedResult<T> {
  /// Items in current page
  final List<T> items;

  /// Total number of items across all pages
  final int totalCount;

  /// Current page number (1-based)
  final int currentPage;

  /// Number of items per page
  final int pageSize;

  /// Constructor
  PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });

  /// Check if there is a next page
  bool get hasNextPage => currentPage < totalPages;

  /// Check if there is a previous page
  bool get hasPreviousPage => currentPage > 1;

  /// Calculate total number of pages
  int get totalPages => (totalCount / pageSize).ceil();
}
