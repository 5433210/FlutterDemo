import 'package:demo/infrastructure/storage/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../infrastructure/storage/storage_interface.dart';
import '../logging/logger.dart';

/// 存储路径 Provider
final storagePathProvider = FutureProvider<String>((ref) async {
  try {
    return await ref.watch(_storagePathStateProvider.future);
  } catch (e, stack) {
    AppLogger.error('获取存储路径失败', error: e, stackTrace: stack, tag: 'Storage');
    rethrow;
  }
});

/// 本地存储实现 Provider
final storageProvider = FutureProvider<IStorage>((ref) async {
  final basePath = await ref.watch(storagePathProvider.future);
  final storage = StorageService(basePath: basePath);

  // 确保基础目录结构已创建
  await _initializeStorageStructure(storage);

  AppLogger.info('存储服务初始化完成', tag: 'Storage');
  return storage;
});

/// 存储路径状态 Provider
final _storagePathStateProvider = FutureProvider<String>((ref) async {
  AppLogger.debug('初始化存储路径', tag: 'Storage');

  final appDir = await getApplicationDocumentsDirectory();
  final storagePath = path.join(appDir.path, 'storage');

  AppLogger.debug('存储路径初始化完成', tag: 'Storage', data: {'path': storagePath});

  return storagePath;
});

/// 创建基础存储目录结构
Future<void> _initializeStorageStructure(IStorage storage) async {
  try {
    final appDataDir = await storage.getAppDataPath();
    final tempDir = await storage.getTempDirectory();

    await Future.wait([
      storage.ensureDirectoryExists(appDataDir),
      storage.ensureDirectoryExists(path.join(appDataDir, 'works')),
      storage.ensureDirectoryExists(path.join(appDataDir, 'cache')),
      storage.ensureDirectoryExists(path.join(appDataDir, 'config')),
      storage.ensureDirectoryExists(tempDir.path),
    ]);

    AppLogger.debug('存储目录结构初始化完成', tag: 'Storage');
  } catch (e, stack) {
    AppLogger.error('创建存储目录结构失败', error: e, stackTrace: stack, tag: 'Storage');
    rethrow;
  }
}
