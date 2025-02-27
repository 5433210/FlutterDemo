import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/entities/practice.dart';
import '../../infrastructure/logging/logger.dart';

/// Provider for practice detail
final practiceDetailProvider = StateNotifierProvider.autoDispose<
    PracticeDetailNotifier, AsyncValue<Practice?>>((ref) {
  return PracticeDetailNotifier(ref);
});

/// Practice detail notifier
class PracticeDetailNotifier extends StateNotifier<AsyncValue<Practice?>> {
  final Ref ref;

  PracticeDetailNotifier(this.ref) : super(const AsyncValue.loading());

  /// Delete practice
  Future<bool> deletePractice(String id) async {
    try {
      final success =
          await ref.read(practiceServiceProvider).deletePractice(id);
      if (success) {
        state = const AsyncValue.data(null);
      }
      return success;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to delete practice',
        tag: 'PracticeDetailNotifier',
        error: e,
        stackTrace: stack,
        data: {'id': id},
      );
      rethrow;
    }
  }

  /// Get practice by ID
  Future<Practice?> getPractice(String id) async {
    try {
      state = const AsyncValue.loading();

      final practice = await ref.read(practiceServiceProvider).getPractice(id);

      state = AsyncValue.data(practice);
      return practice;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to get practice',
        tag: 'PracticeDetailNotifier',
        error: e,
        stackTrace: stack,
        data: {'id': id},
      );
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
