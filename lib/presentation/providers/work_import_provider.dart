import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/work_import_view_model.dart';
import '../viewmodels/states/work_import_state.dart';
import '../../application/providers/service_providers.dart';

final workImportProvider =
    StateNotifierProvider.autoDispose<WorkImportViewModel, WorkImportState>(
        (ref) {
  final workService = ref.watch(workServiceProvider);
  final imageService = ref.watch(imageServiceProvider);
  return WorkImportViewModel(
    workService,
    imageService,
  );
});
