import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/work_image_processing_interface.dart';
import '../image/work_image_processor.dart';
import './storage_providers.dart';

/// 作品图片处理器 Provider
final workImageProcessorProvider = Provider<IWorkImageProcessing>((ref) {
  final storage = ref.watch(storageProvider);
  final workImageStorage = ref.watch(workImageStorageProvider);
  return WorkImageProcessor(storage, workImageStorage);
});
