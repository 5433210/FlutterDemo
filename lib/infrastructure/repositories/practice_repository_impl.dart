import 'dart:convert';

import '../../domain/repositories/practice_repository.dart';
import '../logging/logger.dart';
import '../persistence/sqlite/sqlite_database.dart';

/// Implementation of the PracticeRepository interface using SQLite
class PracticeRepositoryImpl implements PracticeRepository {
  final SqliteDatabase _db;

  PracticeRepositoryImpl(this._db);

  @override
  Future<String> createPractice(Map<String, dynamic> practiceData) async {
    try {
      AppLogger.debug('Creating practice in repository',
          tag: 'PracticeRepositoryImpl',
          data: {'title': practiceData['title']});

      final id = await _db.insertPractice(practiceData);

      AppLogger.debug('Practice created in repository',
          tag: 'PracticeRepositoryImpl',
          data: {'id': id, 'title': practiceData['title']});
      return id;
    } catch (e, stack) {
      AppLogger.error('Failed to create practice in repository',
          tag: 'PracticeRepositoryImpl',
          error: e,
          stackTrace: stack,
          data: {'practiceData': practiceData});
      rethrow;
    }
  }

  @override
  Future<bool> deletePractice(String id) async {
    try {
      AppLogger.debug('Deleting practice in repository',
          tag: 'PracticeRepositoryImpl', data: {'id': id});

      final count = await _db.deletePractice(id);
      final success = count > 0;

      AppLogger.debug('Practice deleted from repository',
          tag: 'PracticeRepositoryImpl', data: {'id': id, 'success': success});

      return success;
    } catch (e, stack) {
      AppLogger.error('Failed to delete practice from repository',
          tag: 'PracticeRepositoryImpl',
          error: e,
          stackTrace: stack,
          data: {'id': id});
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getPractice(String id) async {
    try {
      AppLogger.debug('Getting practice from repository',
          tag: 'PracticeRepositoryImpl', data: {'id': id});

      final practice = await _db.getPractice(id);

      if (practice != null) {
        AppLogger.debug('Got practice from repository',
            tag: 'PracticeRepositoryImpl',
            data: {'id': id, 'title': practice['title']});

        return _normalizePracticeData(practice);
      }

      AppLogger.debug('Practice not found in repository',
          tag: 'PracticeRepositoryImpl', data: {'id': id});

      return null;
    } catch (e, stack) {
      AppLogger.error('Failed to get practice from repository',
          tag: 'PracticeRepositoryImpl',
          error: e,
          stackTrace: stack,
          data: {'id': id});
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPractices({
    String? title,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.debug('Getting practices from repository',
          tag: 'PracticeRepositoryImpl',
          data: {'title': title, 'limit': limit, 'offset': offset});

      final practices = await _db.getPractices(
        title: title,
        limit: limit,
        offset: offset,
      );

      final result = practices.map(_normalizePracticeData).toList();

      AppLogger.debug('Got practices from repository',
          tag: 'PracticeRepositoryImpl', data: {'count': result.length});

      return result;
    } catch (e, stack) {
      AppLogger.error('Failed to get practices from repository',
          tag: 'PracticeRepositoryImpl', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<int> getPracticesCount() async {
    try {
      final count = await _db.getPracticesCount();
      return count;
    } catch (e, stack) {
      AppLogger.error('Failed to get practices count',
          tag: 'PracticeRepositoryImpl', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> updatePractice(
      String id, Map<String, dynamic> practiceData) async {
    try {
      AppLogger.debug('Updating practice in repository',
          tag: 'PracticeRepositoryImpl',
          data: {'id': id, 'title': practiceData['title']});

      await _db.updatePractice(id, practiceData);

      AppLogger.debug('Practice updated in repository',
          tag: 'PracticeRepositoryImpl',
          data: {'id': id, 'title': practiceData['title']});
    } catch (e, stack) {
      AppLogger.error('Failed to update practice in repository',
          tag: 'PracticeRepositoryImpl',
          error: e,
          stackTrace: stack,
          data: {'id': id, 'practiceData': practiceData});
      rethrow;
    }
  }

  /// Decode metadata from storage format
  Map<String, dynamic>? _decodeMetadata(String? metadataJson) {
    if (metadataJson == null || metadataJson.isEmpty) return null;
    return jsonDecode(metadataJson) as Map<String, dynamic>;
  }

  /// Decode pages from storage format
  List<dynamic> _decodePracticePages(String? pagesJson) {
    if (pagesJson == null || pagesJson.isEmpty) return [];
    return jsonDecode(pagesJson) as List<dynamic>;
  }

  /// Encode metadata to storage format
  String _encodeMetadata(Map<String, dynamic> metadata) {
    return jsonEncode(metadata);
  }

  /// Encode pages to storage format
  String _encodePages(List<dynamic> pages) {
    return jsonEncode(pages);
  }

  /// Normalize practice data from database
  Map<String, dynamic> _normalizePracticeData(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'title': data['title'],
      'pages': _decodePracticePages(data['pages']),
      'createTime': data['createTime'],
      'updateTime': data['updateTime'],
      'metadata': _decodeMetadata(data['metadata']),
    };
  }
}
