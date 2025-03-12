import 'package:demo/infrastructure/storage/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../infrastructure/storage/storage_interface.dart';
import '../logging/logger.dart';

/// 存储路径 Provider
final storagePathProvider = Provider<String>((ref) {
  final state = ref.watch(_storagePathStateProvider);
  return state.when(
    data: (path) => path,
    loading: () => throw Exception('Storage path not initialized'),
    error: (err, stack) => throw Exception('Failed to get storage path: $err'),
  );
});

/// 本地存储实现 Provider
final storageProvider = Provider<IStorage>((ref) {
  final basePath = ref.watch(storagePathProvider);

  return StorageService(basePath: basePath);
});

/// 存储服务状态Provider
final storageStateProvider =
    StateNotifierProvider<StorageStateNotifier, bool>((ref) {
  return StorageStateNotifier(ref.watch(storageProvider));
});

/// 存储路径状态 Provider
final _storagePathStateProvider = FutureProvider<String>((ref) async {
  AppLogger.debug('初始化存储路径', tag: 'Storage');

  final appDir = await getApplicationDocumentsDirectory();
  final storagePath = path.join(appDir.path, 'storage');

  AppLogger.debug(
    '存储路径初始化完成',
    tag: 'Storage',
    data: {'path': storagePath},
  );

  return storagePath;
});

/// 存储服务状态管理器
class StorageStateNotifier extends StateNotifier<bool> {
  final IStorage _storage;

  StorageStateNotifier(this._storage) : super(false) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final appDataDir = await _storage.getAppDataPath();
      final tempDir = await _storage.getTempDirectory();

      await Future.wait([
        _storage.ensureDirectoryExists(appDataDir),
        _storage.ensureDirectoryExists(tempDir.path),
      ]);

      state = true;
      AppLogger.info('存储服务初始化完成', tag: 'Storage');
    } catch (e, stack) {
      AppLogger.error(
        '存储服务初始化失败',
        error: e,
        stackTrace: stack,
        tag: 'Storage',
      );
      state = false;
    }
  }
}
