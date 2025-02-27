import '../../domain/entities/practice.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../infrastructure/logging/logger.dart';

/// Service for managing practices
class PracticeService {
  final PracticeRepository _repository;

  PracticeService(this._repository);

  /// Create a new practice
  Future<String> createPractice(Practice practice) async {
    try {
      AppLogger.info('Creating new practice',
          tag: 'PracticeService', data: {'title': practice.title});

      final id = await _repository.createPractice(practice.toJson());

      AppLogger.info('Practice created successfully',
          tag: 'PracticeService', data: {'id': id, 'title': practice.title});

      return id;
    } catch (e, stack) {
      AppLogger.error('Failed to create practice',
          tag: 'PracticeService',
          error: e,
          stackTrace: stack,
          data: {'practice': practice.title});
      rethrow;
    }
  }

  /// Delete a practice by ID
  Future<bool> deletePractice(String id) async {
    try {
      AppLogger.info('Deleting practice',
          tag: 'PracticeService', data: {'id': id});

      final result = await _repository.deletePractice(id);

      AppLogger.info('Practice deleted successfully',
          tag: 'PracticeService', data: {'id': id, 'success': result});

      return result;
    } catch (e, stack) {
      AppLogger.error('Failed to delete practice',
          tag: 'PracticeService',
          error: e,
          stackTrace: stack,
          data: {'id': id});
      rethrow;
    }
  }

  /// Get practice by ID
  Future<Practice?> getPractice(String id) async {
    try {
      AppLogger.debug('Getting practice by id',
          tag: 'PracticeService', data: {'id': id});

      final practice = await _repository.getPractice(id);
      if (practice == null) {
        AppLogger.debug('Practice not found',
            tag: 'PracticeService', data: {'id': id});
        return null;
      }

      AppLogger.debug('Practice found',
          tag: 'PracticeService', data: {'id': id, 'title': practice['title']});

      return Practice.fromJson(practice);
    } catch (e, stack) {
      AppLogger.error('Failed to get practice',
          tag: 'PracticeService',
          error: e,
          stackTrace: stack,
          data: {'id': id});
      rethrow;
    }
  }

  /// Get all practices with optional filtering
  Future<List<Practice>> getPractices({
    String? title,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.debug('Getting practices',
          tag: 'PracticeService',
          data: {'title': title, 'limit': limit, 'offset': offset});

      final practices = await _repository.getPractices(
        title: title,
        limit: limit,
        offset: offset,
      );

      final result = practices
          .map((practiceData) => Practice.fromJson(practiceData))
          .toList();

      AppLogger.debug('Got ${result.length} practices', tag: 'PracticeService');

      return result;
    } catch (e, stack) {
      AppLogger.error('Failed to get practices',
          tag: 'PracticeService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Update a practice
  Future<void> updatePractice(Practice practice) async {
    try {
      if (practice.id == null) {
        throw ArgumentError('Practice ID cannot be null when updating');
      }

      AppLogger.info('Updating practice',
          tag: 'PracticeService',
          data: {'id': practice.id, 'title': practice.title});

      await _repository.updatePractice(practice.id!, practice.toJson());

      AppLogger.info('Practice updated successfully',
          tag: 'PracticeService',
          data: {'id': practice.id, 'title': practice.title});
    } catch (e, stack) {
      AppLogger.error('Failed to update practice',
          tag: 'PracticeService',
          error: e,
          stackTrace: stack,
          data: {'id': practice.id, 'title': practice.title});
      rethrow;
    }
  }
}
