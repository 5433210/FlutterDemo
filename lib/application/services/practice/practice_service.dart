import '../../../domain/repositories/practice_repository.dart';
import '../../../domain/value_objects/practice/practice_entity.dart';
import '../../../infrastructure/logging/logger.dart';

/// 字帖服务类，处理字帖相关业务逻辑
class PracticeService {
  final PracticeRepository _repository;

  PracticeService(this._repository);

  /// 创建新字帖
  Future<String> createPractice(PracticeEntity practice) async {
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

  /// 删除字帖
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

  /// 获取单个字帖
  Future<PracticeEntity?> getPractice(String id) async {
    try {
      AppLogger.debug('Getting practice by id',
          tag: 'PracticeService', data: {'id': id});

      final practiceData = await _repository.getPractice(id);

      if (practiceData == null) {
        return null;
      }

      // 将原始数据转换为PracticeEntity值对象
      return PracticeEntity.fromJson(practiceData);
    } catch (e, stack) {
      AppLogger.error('Failed to get practice',
          tag: 'PracticeService',
          error: e,
          stackTrace: stack,
          data: {'id': id});
      rethrow;
    }
  }

  /// 获取多个字帖
  Future<List<PracticeEntity>> getPractices({
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
          .map((practiceData) => PracticeEntity.fromJson(practiceData))
          .toList();

      AppLogger.debug('Got ${result.length} practices', tag: 'PracticeService');

      return result;
    } catch (e, stack) {
      AppLogger.error('Failed to get practices',
          tag: 'PracticeService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 更新字帖
  Future<void> updatePractice(PracticeEntity practice) async {
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
