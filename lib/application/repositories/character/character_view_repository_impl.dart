import 'dart:convert';

import 'package:demo/domain/enums/sort_field.dart';

import '../../../domain/enums/work_style.dart';
import '../../../domain/enums/work_tool.dart';
import '../../../domain/models/character/character_filter.dart';
import '../../../domain/models/character/character_region.dart'
    show CharacterRegion;
import '../../../domain/models/character/character_view.dart';
import '../../../domain/repositories/character/character_view_repository.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/persistence/database_interface.dart';

/// Implementation of the CharacterViewRepository interface
class CharacterViewRepositoryImpl implements CharacterViewRepository {
  static const String _viewName = 'CharacterView';
  final DatabaseInterface _database;
  final CharacterRepository _characterRepository;

  /// Constructor
  CharacterViewRepositoryImpl(this._database, this._characterRepository);

  @override
  Future<bool> deleteCharacter(String id) async {
    try {
      await _characterRepository.delete(id);
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete character',
          tag: 'CharacterViewRepository', error: e, data: {'id': id});
      return false;
    }
  }

  @override
  Future<bool> deleteCharacters(List<String> ids) async {
    try {
      await _characterRepository.deleteMany(ids);
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete characters',
          tag: 'CharacterViewRepository', error: e, data: {'ids': ids});
      return false;
    }
  }

  @override
  Future<List<String>> getAllTags() async {
    try {
      // This query needs to be adjusted based on how tags are stored
      // Assuming tags are stored in a JSON array column
      final result = await _database.rawQuery(
        'SELECT DISTINCT value AS tag FROM Characters, json_each(Characters.tags)',
      );

      return result.map((row) => row['tag'] as String).toList();
    } catch (e) {
      AppLogger.error('Failed to get all tags',
          tag: 'CharacterViewRepository', error: e);
      return [];
    }
  }

  @override
  Future<CharacterView?> getCharacterById(String id) async {
    try {
      final result = await _database.rawQuery(
        'SELECT * FROM $_viewName WHERE id = ?',
        [id],
      );

      if (result.isEmpty) {
        return null;
      }

      return _mapToCharacterView(result.first);
    } catch (e) {
      AppLogger.error('Failed to get character by id',
          tag: 'CharacterViewRepository', error: e, data: {'id': id});
      return null;
    }
  }

  @override
  Future<PaginatedResult<CharacterView>> getCharacters({
    required CharacterFilter filter,
    required int page,
    required int pageSize,
  }) async {
    try {
      final queryResult = _buildFilterQuery(filter);
      final query = queryResult.$1;
      final args = queryResult.$2;

      // Add sorting
      final sortField = _getSortFieldName(filter.sortOption.field);
      final sortDirection = filter.sortOption.descending ? 'DESC' : 'ASC';
      final orderBy = ' ORDER BY $sortField $sortDirection';

      // Add pagination
      final offset = (page - 1) * pageSize;
      final limit = ' LIMIT $pageSize OFFSET $offset';

      // Execute query for current page data
      final results = await _database.rawQuery(
        'SELECT * FROM $_viewName $query$orderBy$limit',
        args,
      );

      // Execute count query for total records
      final countResult = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM $_viewName $query',
        args,
      );
      final totalCount = (countResult.first['count'] as int?) ?? 0;

      // Map results to character views
      final characters = results.map(_mapToCharacterView).toList();

      return PaginatedResult<CharacterView>(
        items: characters,
        totalCount: totalCount,
        currentPage: page,
        pageSize: pageSize,
      );
    } catch (e) {
      AppLogger.error('Failed to get characters',
          tag: 'CharacterViewRepository', error: e);
      return PaginatedResult<CharacterView>(
        items: [],
        totalCount: 0,
        currentPage: page,
        pageSize: pageSize,
      );
    }
  }

  @override
  Future<CharacterStats> getCharacterStats() async {
    try {
      // Get total count
      final totalCountResult = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM Characters',
      );
      final totalCount = (totalCountResult.first['count'] as int?) ?? 0;

      // Get favorite count
      final favoriteCountResult = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM Characters WHERE isFavorite = 1',
      );
      final favoriteCount = (favoriteCountResult.first['count'] as int?) ?? 0;

      // Get tag counts
      final tagCounts = await _getTagCounts();

      // Get calligraphy style counts
      final styleCounts = await _getCalligraphyStyleCounts();

      // Get writing tool counts
      final toolCounts = await _getWritingToolCounts();

      return CharacterStats(
        totalCount: totalCount,
        favoriteCount: favoriteCount,
        tagCounts: tagCounts,
        calligraphyStyleCounts: styleCounts,
        writingToolCounts: toolCounts,
      );
    } catch (e) {
      AppLogger.error('Failed to get character stats',
          tag: 'CharacterViewRepository', error: e);
      return CharacterStats(
        totalCount: 0,
        favoriteCount: 0,
        tagCounts: {},
        calligraphyStyleCounts: {},
        writingToolCounts: {},
      );
    }
  }

  @override
  Future<List<CharacterView>> getRelatedCharacters(String characterId,
      {int limit = 10}) async {
    try {
      // First get the workId of the character
      final character = await getCharacterById(characterId);
      if (character == null) return [];

      // Then get other characters from the same work
      final results = await _database.rawQuery(
        'SELECT * FROM $_viewName WHERE workId = ? AND id != ? LIMIT ?',
        [character.workId, characterId, limit],
      );

      return results.map(_mapToCharacterView).toList();
    } catch (e) {
      AppLogger.error('Failed to get related characters',
          tag: 'CharacterViewRepository',
          error: e,
          data: {'characterId': characterId});
      return [];
    }
  }

  @override
  Future<List<CharacterView>> searchBySimplifiedCharacter(String character,
      {int limit = 20}) async {
    try {
      final results = await _database.rawQuery(
        'SELECT * FROM $_viewName WHERE character LIKE ? LIMIT ?',
        ['%$character%', limit],
      );

      return results.map(_mapToCharacterView).toList();
    } catch (e) {
      AppLogger.error('Failed to search by simplified character',
          tag: 'CharacterViewRepository',
          error: e,
          data: {'character': character});
      return [];
    }
  }

  @override
  Future<bool> toggleFavorite(String id) async {
    try {
      // Get current character
      final character = await _characterRepository.findById(id);
      if (character == null) return false;

      // Toggle favorite status
      final updated = character.copyWith(isFavorite: !character.isFavorite);
      await _characterRepository.save(updated);

      return true;
    } catch (e) {
      AppLogger.error('Failed to toggle favorite',
          tag: 'CharacterViewRepository', error: e, data: {'id': id});
      return false;
    }
  }

  // Helper methods

  /// Build SQL query from filter
  (String, List<dynamic>) _buildFilterQuery(CharacterFilter filter) {
    final conditions = <String>[];
    final args = <dynamic>[];

    // Search text filter
    if (filter.searchText != null && filter.searchText!.isNotEmpty) {
      conditions.add('(character LIKE ? OR workName LIKE ? OR author LIKE ?)');
      final searchPattern = '%${filter.searchText}%';
      args.addAll([searchPattern, searchPattern, searchPattern]);
    }

    // Favorite filter
    if (filter.isFavorite == true) {
      conditions.add('isFavorite = 1');
    }

    // Work ID filter
    if (filter.workId != null) {
      conditions.add('workId = ?');
      args.add(filter.workId);
    }

    // Writing tools filter
    if (filter.tool != null) {
      conditions.add('tool = ?');
      args.add(filter.tool);
    }

    // Calligraphy styles filter
    if (filter.style != null) {
      conditions.add('style = ?');
      args.add(filter.style);
    }

    // Creation date filter
    final creationDateRange = filter.creationDateRange;
    if (creationDateRange != null) {
      conditions.add('creationTime >= ?');
      args.add(creationDateRange.start.toIso8601String());
      conditions.add('creationTime <= ?');
      args.add(creationDateRange.end.toIso8601String());
    }

    // Collection date filter
    final collectionDateRange = filter.collectionDateRange;
    if (collectionDateRange != null) {
      conditions.add('collectionTime >= ?');
      args.add(collectionDateRange.start.toIso8601String());
      conditions.add('collectionTime <= ?');
      args.add(collectionDateRange.end.toIso8601String());
    }

    // Tags filter
    if (filter.tags.isNotEmpty) {
      // This assumes tags are stored as JSON and can be searched with JSON functions
      // May need adjustment based on actual database implementation
      conditions.addAll(filter.tags.map((_) => 'tags LIKE ?'));
      args.addAll(filter.tags.map((tag) => '%$tag%'));
    }

    if (conditions.isEmpty) {
      return ('', []);
    }

    return ('WHERE ${conditions.join(' AND ')}', args);
  }

  /// Get calligraphy style counts
  Future<Map<String, int>> _getCalligraphyStyleCounts() async {
    try {
      // This query needs to be adjusted based on how styles are stored
      final result = await _database.rawQuery(
        'SELECT calligraphyStyle AS style, COUNT(*) AS count FROM Characters GROUP BY calligraphyStyle',
      );

      final styleCounts = <String, int>{};
      for (final row in result) {
        if (row['style'] != null) {
          styleCounts[row['style'] as String] = row['count'] as int;
        }
      }
      return styleCounts;
    } catch (e) {
      AppLogger.error('Failed to get calligraphy style counts',
          tag: 'CharacterViewRepository', error: e);
      return {};
    }
  }

  /// Get SQL field name from sort field enum
  String _getSortFieldName(SortField field) {
    switch (field) {
      case SortField.author:
        return 'author';
      case SortField.createTime:
        return 'collectionTime';
      case SortField.creationDate:
        return 'creationTime';
      case SortField.title:
        return 'title';
      case SortField.updateTime:
        return 'updateTime';
      case SortField.style:
        return 'style';
      case SortField.tool:
        return 'tool';
      default:
        return 'collectionTime';
    }
  }

  /// Get tag usage counts
  Future<Map<String, int>> _getTagCounts() async {
    try {
      // This query needs to be adjusted based on how tags are stored
      final result = await _database.rawQuery(
        'SELECT value AS tag, COUNT(*) AS count FROM Characters, json_each(Characters.tags) GROUP BY value',
      );

      final tagCounts = <String, int>{};
      for (final row in result) {
        tagCounts[row['tag'] as String] = row['count'] as int;
      }
      return tagCounts;
    } catch (e) {
      AppLogger.error('Failed to get tag counts',
          tag: 'CharacterViewRepository', error: e);
      return {};
    }
  }

  /// Get writing tool counts
  Future<Map<String, int>> _getWritingToolCounts() async {
    try {
      // This query needs to be adjusted based on how writing tools are stored
      final result = await _database.rawQuery(
        'SELECT writingTool AS tool, COUNT(*) AS count FROM Characters GROUP BY writingTool',
      );

      final toolCounts = <String, int>{};
      for (final row in result) {
        if (row['tool'] != null) {
          toolCounts[row['tool'] as String] = row['count'] as int;
        }
      }
      return toolCounts;
    } catch (e) {
      AppLogger.error('Failed to get writing tool counts',
          tag: 'CharacterViewRepository', error: e);
      return {};
    }
  }

  /// Map database row to CharacterView
  CharacterView _mapToCharacterView(Map<String, dynamic> map) {
    // Parse tags from JSON string if needed
    List<String> tags = [];
    if (map['tags'] != null) {
      // This assumes tags are stored as a string that can be parsed as a list
      // Adjust based on actual storage format
      final tagString = map['tags'] as String;
      if (tagString.isNotEmpty) {
        try {
          if (tagString.startsWith('[') && tagString.endsWith(']')) {
            // Handle JSON array format
            tags = (jsonDecode(tagString) as List).cast<String>();
          } else {
            // Handle comma-separated format
            tags = tagString.split(',').map((e) => e.trim()).toList();
          }
        } catch (e) {
          AppLogger.warning('Failed to parse tags',
              tag: 'CharacterViewRepository',
              error: e,
              data: {'tagString': tagString});
        }
      }
    }

    return CharacterView(
        id: map['id'] as String,
        character: map['character'] as String,
        workId: map['workId'] as String,
        title: map['title'] as String,
        author: map['author'] as String?,
        creationTime: map['creationTime'] != null
            ? DateTime.parse(map['creationTime'] as String)
            : null,
        collectionTime: DateTime.parse(map['collectionTime'] as String),
        isFavorite: (map['isFavorite'] as int?) == 1,
        tags: tags,
        pageId: map['pageId'] as String? ?? '',
        updateTime: map['updateTime'] != null
            ? DateTime.parse(map['updateTime'] as String)
            : DateTime.now(),
        region: map['region'] != null
            ? CharacterRegion.fromJson(jsonDecode(map['region'] as String))
            : CharacterRegion.fromJson({}),
        tool: WorkTool.fromString(map['tool'] as String),
        style: WorkStyle.fromString(map['style'] as String));
  }
}
