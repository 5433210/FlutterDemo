import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/work/work_image.dart';
import '../../infrastructure/providers/repository_providers.dart';

/// 第一张图片提供者
final firstWorkImageProvider = Provider.family<Future<WorkImage?>, String>(
  (ref, workId) async {
    final repository = ref.watch(workImageRepositoryProvider);
    return repository.getFirstByWorkId(workId);
  },
);

/// 作品图片列表提供者
final workImagesProvider = Provider.family<Future<List<WorkImage>>, String>(
  (ref, workId) async {
    final repository = ref.watch(workImageRepositoryProvider);
    return repository.getAllByWorkId(workId);
  },
);
