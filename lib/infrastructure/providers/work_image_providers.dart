import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/services/work/work_image_service.dart';
import '../../domain/models/work/work_image.dart';
import './image_processor_providers.dart';
import './storage_providers.dart';
import 'repository_providers.dart';

/// 作品首图 Provider
final workFirstImageProvider = FutureProvider.family<WorkImage?, String>(
  (ref, workId) async {
    final repository = ref.watch(workImageRepositoryProvider);
    return repository.findFirstByWorkId(workId);
  },
);

/// WorkImageService Provider
final workImageServiceProvider = Provider<WorkImageService>((ref) {
  return WorkImageService(
    storage: ref.watch(workImageStorageProvider),
    processor: ref.watch(workImageProcessorProvider),
  );
});

/// 作品图片列表 Provider
final workImagesProvider = FutureProvider.family<List<WorkImage>, String>(
  (ref, workId) async {
    final repository = ref.watch(workImageRepositoryProvider);
    return repository.findByWorkId(workId);
  },
);

/// 作品缩略图路径 Provider
final workThumbnailProvider = FutureProvider.family<String?, String>(
  (ref, workId) async {
    final firstImage = await ref.watch(workFirstImageProvider(workId).future);
    return firstImage?.thumbnailPath;
  },
);
