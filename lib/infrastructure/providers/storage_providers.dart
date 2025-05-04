import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../infrastructure/storage/storage_interface.dart';
import '../logging/logger.dart';
import '../storage/local_storage.dart';

/// 获取已初始化的存储实例
final initializedStorageProvider = Provider<IStorage>((ref) {
  final storageState = ref.watch(storageProvider);
  return storageState.when(
    data: (storage) => storage,
    loading: () => throw StateError('Storage service not initialized'),
    error: (err, stack) =>
        throw StateError('Storage initialization failed: $err'),
  );
});

/// 存储服务 Provider
/// 提供应用的存储服务实例，负责初始化和管理存储资源
final storageProvider = FutureProvider<IStorage>((ref) async {
  AppLogger.debug('初始化存储服务', tag: 'Storage');

  try {
    // 1. 获取存储路径
    final appDir = await getApplicationDocumentsDirectory();
    final storagePath = path.join(appDir.path, 'storage');

    // 2. 创建存储服务实例
    final storage = LocalStorage(basePath: storagePath);

    // 3. 初始化目录结构
    await _initializeStorageStructure(storage);

    AppLogger.info('存储服务初始化完成', tag: 'Storage');
    return storage;
  } catch (e, stack) {
    AppLogger.error('存储服务初始化失败', error: e, stackTrace: stack, tag: 'Storage');
    rethrow;
  }
});

/// 创建存储服务所需的基础目录结构
Future<void> _initializeStorageStructure(IStorage storage) async {
  final appDataDir = storage.getAppDataPath();
  final tempDir = await storage.createTempDirectory();

  // 创建所需的目录结构
  await Future.wait([
    storage.ensureDirectoryExists(appDataDir),
    storage.ensureDirectoryExists(path.join(appDataDir, 'works')),
    storage.ensureDirectoryExists(path.join(appDataDir, 'cache')),
    storage.ensureDirectoryExists(path.join(appDataDir, 'config')),
    storage.ensureDirectoryExists(path.join(appDataDir, 'temp')),
    storage.ensureDirectoryExists(tempDir.path),
  ]);

  AppLogger.debug('存储目录结构创建完成', tag: 'Storage');
}
