import 'package:flutter_riverpod/flutter_riverpod.dart';

final characterRefreshNotifierProvider =
    StateNotifierProvider<CharacterRefreshNotifier, DateTime>(
  (ref) => CharacterRefreshNotifier(),
);

class CharacterRefreshNotifier extends StateNotifier<DateTime> {
  RefreshEventType? _lastEventType;

  CharacterRefreshNotifier() : super(DateTime.now());

  RefreshEventType? get lastEventType => _lastEventType;

  void notifyEvent(RefreshEventType eventType) {
    _lastEventType = eventType;
    state = DateTime.now(); // Update state to trigger listeners
  }
}

enum RefreshEventType {
  characterSaved,
  characterDeleted,
  regionUpdated,
  eraseDataReloaded,
  pageChanged, // Add new event type for page changes
}
