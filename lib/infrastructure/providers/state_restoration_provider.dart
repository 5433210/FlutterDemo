import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/state_restoration_service.dart';
import 'shared_preferences_provider.dart';

final stateRestorationProvider = Provider<StateRestorationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  try {
    return StateRestorationService(prefs);
  } catch (e) {
    throw StateError('SharedPreferences not initialized');
  }
});
