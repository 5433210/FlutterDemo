import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../application/services/work/work_image_service.dart';
import '../viewmodels/states/work_import_state.dart';
import '../viewmodels/work_import_view_model.dart';

final workImportProvider =
    StateNotifierProvider<WorkImportViewModel, WorkImportState>((ref) {
  final workService = ref.watch(workServiceProvider);
  final imageService = ref.watch(workImageServiceProvider);
  return WorkImportViewModel(workService, imageService);
});
