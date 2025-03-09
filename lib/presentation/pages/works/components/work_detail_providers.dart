import 'package:demo/domain/models/work/work_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the current image index in a work
final currentImageIndexProvider = StateProvider<int>((ref) {
  return 0;
});

/// Provider to make the currently loaded work available to child widgets
final currentWorkProvider = Provider<WorkEntity>((ref) {
  throw UnimplementedError('currentWorkProvider must be overridden');
});
