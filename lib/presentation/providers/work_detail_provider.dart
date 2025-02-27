import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/entities/work.dart';

/// Provider for the work detail
final workDetailProvider =
    StateNotifierProvider<WorkDetailNotifier, AsyncValue<Work?>>((ref) {
  return WorkDetailNotifier(ref);
});

/// Work detail view model
class WorkDetailNotifier extends StateNotifier<AsyncValue<Work?>> {
  final workService = workServiceProvider;

  final Ref ref;

  WorkDetailNotifier(this.ref) : super(const AsyncValue.loading());

  /// Get work by ID
  Future<Work?> getWork(String workId) async {
    try {
      // Update state to loading
      state = const AsyncValue.loading();

      // Get work details from service
      final work = await ref.read(workServiceProvider).getWork(workId);

      // Update state on success
      state = AsyncValue.data(work);

      return work;
    } catch (e, stackTrace) {
      // Handle error state
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}
