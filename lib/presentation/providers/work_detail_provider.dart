import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/entities/work.dart';
import '../../infrastructure/logging/logger.dart';

/// Provider for the current image index in a work
final currentWorkImageIndexProvider = StateProvider<int>((ref) {
  return 0;
});

/// Provider for the work detail
final workDetailProvider =
    StateNotifierProvider<WorkDetailNotifier, AsyncValue<Work?>>((ref) {
  return WorkDetailNotifier(ref);
});

/// Work detail view model
class WorkDetailNotifier extends StateNotifier<AsyncValue<Work?>> {
  final Ref ref;

  WorkDetailNotifier(this.ref) : super(const AsyncValue.loading());

  /// Get work by ID - without immediately updating state
  Future<Work?> fetchWork(String workId) async {
    try {
      return await ref.read(workServiceProvider).getWork(workId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch work',
        tag: 'WorkDetailNotifier',
        error: e,
        stackTrace: stackTrace,
        data: {'workId': workId},
      );
      rethrow;
    }
  }

  /// Load work by ID - updates the provider state
  Future<void> loadWork(String workId) async {
    try {
      // Update state to loading
      state = const AsyncValue.loading();

      // Get work details from service
      final work = await ref.read(workServiceProvider).getWork(workId);

      // Update state on success
      state = AsyncValue.data(work);
    } catch (e, stackTrace) {
      // Handle error state
      state = AsyncValue.error(e, stackTrace);
      AppLogger.error(
        'Failed to load work',
        tag: 'WorkDetailNotifier',
        error: e,
        stackTrace: stackTrace,
        data: {'workId': workId},
      );
    }
  }
}
