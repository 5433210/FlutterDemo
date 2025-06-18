import 'dart:convert';

import '../../../domain/enums/sort_field.dart';
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
      // 添加JSON类型检查并处理非数组或空值情况
      final result = await _database.rawQuery(
        '''SELECT DISTINCT value AS tag
           FROM $_viewName, json_each($_viewName.tags)
           WHERE json_valid($_viewName.tags)
           AND json_type($_viewName.tags) = 'array'
           AND $_viewName.tags IS NOT NULL
           AND $_viewName.tags != '[]' ''',
      );

      final tags = result.map((row) => row['tag'] as String).toList();
      tags.sort(); // 对标签进行排序
      return tags;
    } catch (e) {
      AppLogger.error('Failed to get all tags',
          tag: 'CharacterViewRepository', error: e);
      return [];
    }
  }

  @override
  Future<CharacterView?> getCharacterById(String id) async {
    final characters = await getCharactersByIds([id]);
    return characters.isEmpty ? null : characters.first;
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
        '''SELECT COUNT(*) as count
           FROM $_viewName
           $query''',
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

  /// 批量获取指定ID的字符数据
  @override
  Future<List<CharacterView>> getCharactersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      // 构建IN查询的占位符
      final placeholders = List.filled(ids.length, '?').join(',');
      final query = 'SELECT * FROM $_viewName WHERE id IN ($placeholders)';

      AppLogger.debug('开始批量查询字符', tag: 'CharacterViewRepository', data: {
        'query': query,
        'ids': ids,
      });

      final results = await _database.rawQuery(query, ids);

      AppLogger.debug('获取字符数据结果', tag: 'CharacterViewRepository', data: {
        'requestedCount': ids.length,
        'returnedCount': results.length,
        'firstRow': results.isNotEmpty
            ? {
                'id': results.first['id'],
                'character': results.first['character'],
                'workId': results.first['workId'],
              }
            : null,
      });

      // 转换每个结果行
      final characters = <CharacterView>[];
      for (final row in results) {
        try {
          final character = _mapToCharacterView(row);
          characters.add(character);
        } catch (e) {
          AppLogger.error(
            '字符数据转换失败',
            tag: 'CharacterViewRepository',
            error: e,
            data: {'row': row},
          );
        }
      }

      AppLogger.debug('字符数据转换完成', tag: 'CharacterViewRepository', data: {
        'convertedCount': characters.length,
        'characters': characters
            .map((c) => {
                  'id': c.id,
                  'character': c.character,
                  'workId': c.workId,
                })
            .toList(),
      });

      return characters;
    } catch (e) {
      AppLogger.error('批量获取字符数据失败',
          tag: 'CharacterViewRepository', error: e, data: {'ids': ids});
      return [];
    }
  }

  @override
  Future<CharacterStats> getCharacterStats() async {
    try {
      // Get total count
      final totalCountResult = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM $_viewName',
      );
      final totalCount = (totalCountResult.first['count'] as int?) ?? 0;

      // Get favorite count
      final favoriteCountResult = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM $_viewName WHERE isFavorite = 1',
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
    final args = <dynamic>[]; // Search text filter
    if (filter.searchText != null && filter.searchText!.isNotEmpty) {
      conditions.add(
          '(character LIKE ? OR title LIKE ? OR author LIKE ? OR tags LIKE ?)');
      final searchPattern = '%${filter.searchText}%';
      args.addAll([searchPattern, searchPattern, searchPattern, searchPattern]);
    }

    // Favorite filter
    if (filter.isFavorite == true) {
      conditions.add('isFavorite = 1');
    }

    // Work ID filter
    if (filter.workId != null) {
      conditions.add('workId = ?');
      args.add(filter.workId);
    } // Writing tools filter
    if (filter.tool != null) {
      conditions.add('tool = ?');
      args.add(filter.tool!);
    }

    // Calligraphy styles filter
    if (filter.style != null) {
      conditions.add('style = ?');
      args.add(filter.style!);
    }

    // Creation date filter
    final creationDateRange = filter.creationDateRange;
    if (creationDateRange != null) {
      conditions.add('date(creationTime) >= date(?)');
      args.add(creationDateRange.start.toIso8601String());
      conditions.add('date(creationTime) <= date(?)');
      args.add(creationDateRange.end.toIso8601String());
    }

    // Collection date filter
    final collectionDateRange = filter.collectionDateRange;
    if (collectionDateRange != null) {
      conditions.add('date(collectionTime) >= date(?)');
      args.add(collectionDateRange.start.toIso8601String());
      conditions.add('date(collectionTime) <= date(?)');
      args.add(collectionDateRange.end.toIso8601String());
    }

    // Tags filter
    if (filter.tags.isNotEmpty) {
      conditions.add('(');
      for (int i = 0; i < filter.tags.length; i++) {
        if (i > 0) {
          conditions.add('OR');
        }
        conditions.add(
            'json_valid(tags) AND json_type(tags) = \'array\' AND tags IS NOT NULL AND tags != \'[]\' AND EXISTS (SELECT 1 FROM json_each(tags) WHERE value = ?)');
        args.add(filter.tags[i]);
      }
      conditions.add(')');
    }

    if (conditions.isEmpty) {
      return ('', []);
    }

    return ('WHERE ${conditions.join(' AND ')}', args);
  }

  /// Get calligraphy style counts
  Future<Map<String, int>> _getCalligraphyStyleCounts() async {
    try {
      final result = await _database.rawQuery(
        '''SELECT style, COUNT(*) AS count
           FROM $_viewName
           GROUP BY style''',
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
    final fieldMap = {
      SortField.author: 'author',
      SortField.createTime: 'collectionTime',
      SortField.title: 'title',
      SortField.updateTime: 'updateTime',
      SortField.style: 'style',
      SortField.tool: 'tool',
    };
    return fieldMap[field] ?? 'collectionTime';
  }

  /// Get tag usage counts
  Future<Map<String, int>> _getTagCounts() async {
    try {
      final result = await _database.rawQuery(
        '''SELECT value AS tag, COUNT(*) AS count
           FROM $_viewName, json_each($_viewName.tags)
           WHERE json_valid($_viewName.tags)
           AND json_type($_viewName.tags) = 'array'
           AND $_viewName.tags IS NOT NULL
           AND $_viewName.tags != '[]'
           GROUP BY value
           ORDER BY value''',
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
      final result = await _database.rawQuery(
        '''SELECT tool, COUNT(*) AS count
           FROM $_viewName
           GROUP BY tool''',
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
    AppLogger.debug(
      '开始映射字符数据',
      tag: 'CharacterViewRepository',
      data: {
        'id': map['id'],
        'character': map['character'],
        'workId': map['workId'],
      },
    );

    try {
      // 解析并验证必需字段
      final id =
          map['id'] as String? ?? (throw const FormatException('字符ID不能为空'));
      final character = map['character'] as String? ??
          (throw const FormatException('字符内容不能为空'));
      final workId =
          map['workId'] as String? ?? (throw const FormatException('作品ID不能为空'));
      final title = map['title'] as String? ?? '';

      // 解析标签
      List<String> tags = [];
      if (map['tags'] != null) {
        final tagString = map['tags'] as String;
        if (tagString.isNotEmpty) {
          try {
            if (tagString.startsWith('[') && tagString.endsWith(']')) {
              tags = (jsonDecode(tagString) as List).cast<String>();
            } else {
              tags = tagString.split(',').map((e) => e.trim()).toList();
            }
            AppLogger.debug(
              '标签解析成功',
              tag: 'CharacterViewRepository',
              data: {'tags': tags},
            );
          } catch (e) {
            AppLogger.warning(
              '标签解析失败',
              tag: 'CharacterViewRepository',
              error: e,
              data: {'tagString': tagString},
            );
          }
        }
      } // 解析日期时间
      DateTime collectionTime;
      try {
        collectionTime = DateTime.parse(map['collectionTime'] as String);
      } catch (e) {
        AppLogger.warning(
          '收集时间解析失败，使用当前时间',
          tag: 'CharacterViewRepository',
          error: e,
        );
        collectionTime = DateTime.now();
      }

      // 解析区域信息
      CharacterRegion region;
      try {
        region = map['region'] != null
            ? CharacterRegion.fromJson(jsonDecode(map['region'] as String))
            : CharacterRegion.fromJson({});
      } catch (e) {
        AppLogger.warning(
          '区域信息解析失败',
          tag: 'CharacterViewRepository',
          error: e,
          data: {'region': map['region']},
        );
        region = CharacterRegion.fromJson({});
      }
      final view = CharacterView(
        id: id,
        character: character,
        workId: workId,
        title: title,
        author: map['author'] as String?,
        collectionTime: collectionTime,
        isFavorite: (map['isFavorite'] as int?) == 1,
        tags: tags,
        pageId: map['pageId'] as String? ?? '',
        updateTime: map['updateTime'] != null
            ? DateTime.parse(map['updateTime'] as String)
            : DateTime.now(),
        region: region,
        tool: map['tool'] as String?,
        style: map['style'] as String?,
      );

      AppLogger.debug(
        '字符数据映射完成',
        tag: 'CharacterViewRepository',
        data: {
          'id': view.id,
          'character': view.character,
          'workId': view.workId,
          'tagCount': view.tags.length,
        },
      );

      return view;
    } catch (e) {
      AppLogger.error(
        '字符数据映射失败',
        tag: 'CharacterViewRepository',
        error: e,
        data: map,
      );
      rethrow;
    }
  }
}
