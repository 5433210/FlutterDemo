import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/services/state_restoration_service.dart';
import 'shared_preferences_provider.dart';

final stateRestorationProvider = Provider<StateRestorationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StateRestorationService(prefs);
});
