import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/persistence/database_factory.dart';
import '../../../infrastructure/storage/storage_interface.dart';

class AppInitializationService {
  final IStorage _storage;

  AppInitializationService(this._storage);

  Future<void> initialize() async {
    try {
      AppLogger.info('开始应用程序初始化', tag: 'Init');

      // 确保所需目录存在
      await _initializeDirectories();

      // 初始化数据库
      await _initializeDatabase();

      AppLogger.info('应用程序初始化完成', tag: 'Init');
    } catch (e, stack) {
      AppLogger.error(
        '应用程序初始化失败',
        tag: 'Init',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> _initializeDatabase() async {
    AppLogger.debug('初始化数据库', tag: 'Init');

    final dbConfig = const DatabaseConfig(name: 'app.db');
    await DatabaseFactory.create(dbConfig);

    AppLogger.debug('数据库初始化完成', tag: 'Init');
  }

  Future<void> _initializeDirectories() async {
    AppLogger.debug('初始化目录结构', tag: 'Init');

    // 获取并创建目录
    final appDataDir = _storage.getAppDataPath();
    final tempDir = await _storage.getTempPath();

    await Future.wait([
      _storage.ensureDirectoryExists(appDataDir),
      _storage.ensureDirectoryExists(tempDir.path),
    ]);

    AppLogger.debug('目录结构初始化完成', tag: 'Init', data: {
      'appDataDir': appDataDir,
      'tempDir': tempDir.path,
    });
  }
}
