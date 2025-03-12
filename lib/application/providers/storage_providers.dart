import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../infrastructure/image/image_processor_impl.dart';
import '../../infrastructure/providers/repository_providers.dart';
import '../../infrastructure/storage/storage_service.dart';
import '../services/storage/work_storage_service.dart';
import '../services/work/work_image_service.dart';

/// 应用根目录Provider
final appRootDirectoryProvider = FutureProvider<String>((ref) async {
  final appDir = await getApplicationDocumentsDirectory();
  return path.join(appDir.path, 'ArtisticCom');
});

/// 缓存路径Provider
final cachePathProvider = Provider<String>((ref) {
  final rootPath = ref.watch(appRootDirectoryProvider).value ?? '';
  return path.join(rootPath, 'cache');
});

/// 图片处理器Provider
final imageProcessorProvider = Provider<ImageProcessorImpl>((ref) {
  final tempPath = ref.watch(tempDirectoryProvider);
  return ImageProcessorImpl(cachePath: tempPath);
});

/// 存储路径Provider
final storagePathProvider =
    Provider.family<String, String>((ref, relativePath) {
  final rootPath = ref.watch(appRootDirectoryProvider).value ?? '';
  return path.join(rootPath, relativePath);
});

/// 存储服务Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  final basePath = ref.watch(appRootDirectoryProvider).value ?? '';
  return StorageService(basePath: basePath);
});

/// 临时目录Provider
final tempDirectoryProvider = Provider<String>((ref) {
  final rootPath = ref.watch(appRootDirectoryProvider).value ?? '';
  return path.join(rootPath, 'cache', 'temp');
});

/// 缩略图缓存路径Provider
final thumbnailCachePathProvider = Provider<String>((ref) {
  final cachePath = ref.watch(cachePathProvider);
  return path.join(cachePath, 'thumbnails');
});

/// 作品封面路径Provider
final workCoverPathProvider = Provider.family<String, String>((ref, workId) {
  final workPath = ref.watch(workPathProvider(workId));
  return path.join(workPath, 'cover');
});

/// 作品图片路径Provider
final workImagePathProvider =
    Provider.family<String, ({String workId, String imageId})>((ref, params) {
  final workPath = ref.watch(workPathProvider(params.workId));
  return path.join(workPath, 'images', params.imageId);
});

/// 作品图片服务Provider
final workImageServiceProvider = Provider<WorkImageService>((ref) {
  final storage = ref.watch(workStorageServiceProvider);
  final processor = ref.watch(imageProcessorProvider);
  final repository = ref.watch(workImageRepositoryProvider);
  return WorkImageService(
    storage: storage,
    processor: processor,
    repository: repository,
  );
});

/// 作品路径Provider
final workPathProvider = Provider.family<String, String>((ref, workId) {
  final rootPath = ref.watch(appRootDirectoryProvider).value ?? '';
  return path.join(rootPath, 'works', workId);
});

/// 作品存储服务Provider
final workStorageServiceProvider = Provider<WorkStorageService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return WorkStorageService(storage: storage);
});
