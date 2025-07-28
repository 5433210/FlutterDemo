import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/work_image_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/import_service.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../infrastructure/storage/storage_interface.dart';
import 'backup_service.dart';
import 'enhanced_backup_service.dart';
import 'export_service_impl.dart';
import 'file_picker_service.dart';
import 'import_service_impl.dart';

/// 简化的服务定位器
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// 注册服务
  void register<T>(T service) {
    _services[T] = service;
  }

  /// 获取服务
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered');
    }
    return service as T;
  }

  /// 初始化所有服务
  Future<void> initializeWithRepositories({
    required WorkRepository workRepository,
    required WorkImageRepository workImageRepository,
    required CharacterRepository characterRepository,
    required PracticeRepository practiceRepository,
    required IStorage storage,
    DatabaseInterface? database,
  }) async {
    // 注册Repository实例
    register<WorkRepository>(workRepository);
    register<WorkImageRepository>(workImageRepository);
    register<CharacterRepository>(characterRepository);
    register<PracticeRepository>(practiceRepository);
    register<IStorage>(storage);

    // 注册备份相关服务 (不再依赖数据库)
    final backupService = BackupService(storage: storage);
    await backupService.initialize(); // 初始化备份服务
    register<BackupService>(backupService);
    register<EnhancedBackupService>(
        EnhancedBackupService(backupService: backupService));

    // 注册文件选择器服务
    register<FilePickerService>(FilePickerServiceImpl());

    // 注册导出服务 (使用实际的Repository和存储)
    register<ExportService>(ExportServiceImpl(
      workRepository: workRepository,
      workImageRepository: workImageRepository,
      characterRepository: characterRepository,
      practiceRepository: practiceRepository,
      storage: storage,
    ));

    // 注册导入服务
    register<ImportService>(ImportServiceImpl(
      workImageRepository: workImageRepository,
      workRepository: workRepository,
      characterRepository: characterRepository,
      storageBasePath: storage.getAppDataPath(),
    ));
  }

  /// 基础初始化（不需要Repository的情况）
  Future<void> initialize({IStorage? storage}) async {
    // 注册文件选择器服务
    register<FilePickerService>(FilePickerServiceImpl());

    // 注册导入服务
    register<ImportService>(ImportServiceImpl());

    // 如果提供了存储接口，注册备份相关服务
    if (storage != null) {
      register<IStorage>(storage);
      final backupService = BackupService(storage: storage);
      await backupService.initialize(); // 初始化备份服务
      register<BackupService>(backupService);
      register<EnhancedBackupService>(
          EnhancedBackupService(backupService: backupService));
    }

    // 导出服务需要Repository，暂时不注册
    // register<ExportService>(ExportServiceImpl(...));
  }

  /// 同步基础初始化（用于降级场景，尝试注册备份服务但不进行异步初始化）
  void initializeBasic({IStorage? storage}) {
    // 注册文件选择器服务
    register<FilePickerService>(FilePickerServiceImpl());

    // 注册导入服务
    register<ImportService>(ImportServiceImpl());

    // 如果提供了存储接口，注册存储和备份相关服务
    if (storage != null) {
      register<IStorage>(storage);

      // 注册备份服务（降级模式：不进行异步初始化）
      try {
        final backupService = BackupService(storage: storage);
        // 不调用 initialize()，直接注册
        register<BackupService>(backupService);
        register<EnhancedBackupService>(
            EnhancedBackupService(backupService: backupService));
      } catch (e) {
        // 如果备份服务注册失败，记录错误但继续
        AppLogger.warning('备份服务降级注册失败', tag: 'ServiceLocator', error: e);
      }
    }

    // 导出服务需要Repository，暂时不注册
    // register<ExportService>(ExportServiceImpl(...));
  }

  /// 检查服务是否已注册
  bool isRegistered<T>() {
    return _services.containsKey(T);
  }

  /// 清理所有服务
  void dispose() {
    _services.clear();
  }
}
