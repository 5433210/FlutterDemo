import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/work_image_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/import_service.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/providers/database_providers.dart' as db_providers;
import '../../infrastructure/providers/storage_providers.dart';
import '../services/export_service_impl.dart';
import '../services/import_service_impl.dart';
import '../services/service_locator.dart';
import 'repository_providers.dart';

/// 导出服务Provider - 使用实际的Repository依赖
final exportServiceProvider = Provider<ExportService>((ref) {
  final workRepository = ref.watch(workRepositoryProvider);
  final workImageRepository = ref.watch(workImageRepositoryProvider);
  final characterRepository = ref.watch(characterRepositoryProvider);
  final practiceRepository = ref.watch(practiceRepositoryProvider);
  final storage = ref.watch(initializedStorageProvider);

  return ExportServiceImpl(
    workRepository: workRepository,
    workImageRepository: workImageRepository,
    characterRepository: characterRepository,
    practiceRepository: practiceRepository,
    storage: storage,
  );
});

/// 导入服务Provider
final importServiceProvider = Provider<ImportService>((ref) {
  final workImageRepository = ref.watch(workImageRepositoryProvider);
  final workRepository = ref.watch(workRepositoryProvider);
  final characterRepository = ref.watch(characterRepositoryProvider);

  // 获取存储基础路径 - 从存储服务获取
  final storage = ref.watch(initializedStorageProvider);
  final storageBasePath = storage.getAppDataPath();

  return ImportServiceImpl(
    workImageRepository: workImageRepository,
    workRepository: workRepository,
    characterRepository: characterRepository,
    storageBasePath: storageBasePath,
  );
});

/// ServiceLocator Provider - 集成所有Repository
final serviceLocatorProvider = FutureProvider<ServiceLocator>((ref) async {
  final serviceLocator = ServiceLocator();

  try {
    // 等待数据库初始化完成
    final database = await ref.watch(db_providers.databaseProvider.future);

    // 数据库已初始化，使用完整的初始化方法
    await serviceLocator.initializeWithRepositories(
      workRepository: ref.watch(workRepositoryProvider),
      workImageRepository: ref.watch(workImageRepositoryProvider),
      characterRepository: ref.watch(characterRepositoryProvider),
      practiceRepository: ref.watch(practiceRepositoryProvider),
      storage: ref.watch(initializedStorageProvider),
      database: database,
    );
  } catch (e) {
    // 数据库初始化失败，使用基础初始化但仍可提供备份服务
    final storage = ref.watch(initializedStorageProvider);
    await serviceLocator.initialize(storage: storage);

    // 记录详细的错误信息，便于调试
    AppLogger.error('数据库初始化失败，但备份服务仍可用',
        tag: 'ImportExportProviders', error: e);
    AppLogger.warning('用户可以使用备份功能，但其他功能可能受限', tag: 'ImportExportProviders');
  }

  return serviceLocator;
});

/// 同步版本的ServiceLocator Provider，用于向后兼容
final syncServiceLocatorProvider = Provider<ServiceLocator>((ref) {
  final serviceLocatorAsync = ref.watch(serviceLocatorProvider);
  return serviceLocatorAsync.when(
    data: (serviceLocator) => serviceLocator,
    loading: () {
      // 如果还在加载中，创建一个基础的ServiceLocator
      final serviceLocator = ServiceLocator();
      try {
        final storage = ref.watch(initializedStorageProvider);
        serviceLocator.initializeBasic(storage: storage);
      } catch (e) {
        // 如果存储也不可用，只做基础初始化
        serviceLocator.initializeBasic();
      }
      return serviceLocator;
    },
    error: (error, stackTrace) {
      // 如果出错，创建一个基础的ServiceLocator
      final serviceLocator = ServiceLocator();
      try {
        final storage = ref.watch(initializedStorageProvider);
        serviceLocator.initializeBasic(storage: storage);
      } catch (e) {
        // 如果存储也不可用，只做基础初始化
        serviceLocator.initializeBasic();
      }
      return serviceLocator;
    },
  );
});

/// 批量导入导出服务集合Provider
final batchOperationsServicesProvider =
    Provider<BatchOperationsServices>((ref) {
  return BatchOperationsServices(
    exportService: ref.watch(exportServiceProvider),
    importService: ref.watch(importServiceProvider),
    serviceLocator: ref.watch(syncServiceLocatorProvider),
  );
});

/// 批量操作服务集合类
class BatchOperationsServices {
  final ExportService exportService;
  final ImportService importService;
  final ServiceLocator serviceLocator;

  const BatchOperationsServices({
    required this.exportService,
    required this.importService,
    required this.serviceLocator,
  });

  /// 检查所有服务是否就绪
  bool get isReady {
    return serviceLocator.isRegistered<ExportService>() &&
        serviceLocator.isRegistered<ImportService>() &&
        serviceLocator.isRegistered<WorkRepository>() &&
        serviceLocator.isRegistered<CharacterRepository>();
  }

  /// 获取服务状态报告
  Map<String, bool> get serviceStatus {
    return {
      'ExportService': serviceLocator.isRegistered<ExportService>(),
      'ImportService': serviceLocator.isRegistered<ImportService>(),
      'WorkRepository': serviceLocator.isRegistered<WorkRepository>(),
      'CharacterRepository': serviceLocator.isRegistered<CharacterRepository>(),
      'WorkImageRepository': serviceLocator.isRegistered<WorkImageRepository>(),
      'PracticeRepository': serviceLocator.isRegistered<PracticeRepository>(),
    };
  }
}
