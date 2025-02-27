import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/work.dart';

/// Provider for the current image index in a work
final currentImageIndexProvider = StateProvider<int>((ref) {
  return 0;
});

/// Provider to make the currently loaded work available to child widgets
final currentWorkProvider = Provider<Work>((ref) {
  throw UnimplementedError('currentWorkProvider must be overridden');
});
