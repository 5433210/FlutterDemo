import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/work_image_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/import_service.dart';
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
  
  return ExportServiceImpl(
    workRepository: workRepository,
    workImageRepository: workImageRepository,
    characterRepository: characterRepository,
    practiceRepository: practiceRepository,
  );
});

/// 导入服务Provider
final importServiceProvider = Provider<ImportService>((ref) {
  return ImportServiceImpl();
});

/// ServiceLocator Provider - 集成所有Repository
final serviceLocatorProvider = Provider<ServiceLocator>((ref) {
  final serviceLocator = ServiceLocator();
  
  // 使用实际的Repository实例初始化
  serviceLocator.initializeWithRepositories(
    workRepository: ref.watch(workRepositoryProvider),
    workImageRepository: ref.watch(workImageRepositoryProvider),
    characterRepository: ref.watch(characterRepositoryProvider),
    practiceRepository: ref.watch(practiceRepositoryProvider),
  );
  
  return serviceLocator;
});

/// 批量导入导出服务集合Provider
final batchOperationsServicesProvider = Provider<BatchOperationsServices>((ref) {
  return BatchOperationsServices(
    exportService: ref.watch(exportServiceProvider),
    importService: ref.watch(importServiceProvider),
    serviceLocator: ref.watch(serviceLocatorProvider),
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