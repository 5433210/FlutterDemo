import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/work_image_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/import_service.dart';
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
  void initializeWithRepositories({
    required WorkRepository workRepository,
    required WorkImageRepository workImageRepository,
    required CharacterRepository characterRepository,
    required PracticeRepository practiceRepository,
  }) {
    // 注册Repository实例
    register<WorkRepository>(workRepository);
    register<WorkImageRepository>(workImageRepository);
    register<CharacterRepository>(characterRepository);
    register<PracticeRepository>(practiceRepository);
    
    // 注册文件选择器服务
    register<FilePickerService>(FilePickerServiceImpl());
    
    // 注册导出服务 (使用实际的Repository)
    register<ExportService>(ExportServiceImpl(
      workRepository: workRepository,
      workImageRepository: workImageRepository,
      characterRepository: characterRepository,
      practiceRepository: practiceRepository,
    ));
    
    // 注册导入服务
    register<ImportService>(ImportServiceImpl());
  }

  /// 基础初始化（不需要Repository的情况）
  void initialize() {
    // 注册文件选择器服务
    register<FilePickerService>(FilePickerServiceImpl());
    
    // 注册导入服务
    register<ImportService>(ImportServiceImpl());
    
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