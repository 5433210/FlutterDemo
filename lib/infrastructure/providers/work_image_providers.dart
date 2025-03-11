import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/work/work_image.dart';
import './repository_providers.dart';

/// 作品首图 Provider
final workFirstImageProvider = FutureProvider.family<WorkImage?, String>(
  (ref, workId) async {
    final repository = ref.watch(workImageRepositoryProvider);
    return repository.findFirstByWorkId(workId);
  },
);

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
