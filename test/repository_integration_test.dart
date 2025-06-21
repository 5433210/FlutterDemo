import 'package:flutter_test/flutter_test.dart';

import '../lib/application/services/service_locator.dart';
import '../lib/domain/models/import_export/import_data_model.dart';
import '../lib/domain/services/export_service.dart';
import '../lib/domain/services/import_service.dart';

void main() {
  group('ServiceLocator基础功能测试', () {
    late ServiceLocator serviceLocator;

    setUp(() {
      serviceLocator = ServiceLocator();
    });

    tearDown(() {
      serviceLocator.dispose();
    });

    test('ServiceLocator基础初始化应该工作', () {
      // 使用基础初始化（不需要Repository）
      serviceLocator.initialize();
      
      // 验证基础服务注册状态
      expect(serviceLocator.isRegistered<ImportService>(), true);
      
      // 导出服务需要Repository，所以不会被注册
      expect(serviceLocator.isRegistered<ExportService>(), false);
      
      print('✅ ServiceLocator基础初始化成功');
    });

    test('ImportService应该可以通过ServiceLocator获取', () {
      serviceLocator.initialize();
      
      final importService = serviceLocator.get<ImportService>();
      
      expect(importService, isA<ImportService>());
      
      print('✅ ImportService获取成功');
    });

    test('ServiceLocator应该支持服务检查和异常处理', () {
      serviceLocator.initialize();
      
      // 测试isRegistered方法
      expect(serviceLocator.isRegistered<ImportService>(), true);
      expect(serviceLocator.isRegistered<ExportService>(), false);
      
      // 测试get方法 - 已注册的服务
      expect(() => serviceLocator.get<ImportService>(), returnsNormally);
      
      // 测试get方法 - 未注册的服务
      expect(() => serviceLocator.get<ExportService>(), throwsException);
      expect(() => serviceLocator.get<String>(), throwsException);
      
      print('✅ ServiceLocator服务检查功能正常');
    });

    test('ServiceLocator清理功能应该工作', () {
      serviceLocator.initialize();
      
      // 验证服务已注册
      expect(serviceLocator.isRegistered<ImportService>(), true);
      
      // 清理服务
      serviceLocator.dispose();
      
      // 验证服务已清理
      expect(serviceLocator.isRegistered<ImportService>(), false);
      
      print('✅ ServiceLocator清理功能正常');
    });
  });

  group('服务基础功能测试', () {
    test('ImportService基础功能应该工作', () async {
      final serviceLocator = ServiceLocator();
      serviceLocator.initialize();
      
      final importService = serviceLocator.get<ImportService>();
      
      // 测试基础方法
      expect(importService, isNotNull);
      
      // 测试getSupportedFormats方法
      final supportedFormats = importService.getSupportedFormats();
      expect(supportedFormats, isA<List<String>>());
      expect(supportedFormats, isNotEmpty);
      
      // 测试getDefaultOptions方法
      final defaultOptions = importService.getDefaultOptions();
      expect(defaultOptions, isA<ImportOptions>());
      
      serviceLocator.dispose();
      
      print('✅ ImportService基础功能正常');
    });

    test('ImportService验证功能应该处理无效文件', () async {
      final serviceLocator = ServiceLocator();
      serviceLocator.initialize();
      
      final importService = serviceLocator.get<ImportService>();
      final defaultOptions = importService.getDefaultOptions();
      
      // 测试validateImportFile方法（使用无效路径，应该返回失败结果）
      final validationResult = await importService.validateImportFile(
        '/invalid/path.zip',
        defaultOptions,
      );
      
      expect(validationResult.isValid, false);
      expect(validationResult.messages, isNotEmpty);
      
      serviceLocator.dispose();
      
      print('✅ ImportService验证功能正常');
    });
  });

  group('服务架构完整性测试', () {
    test('ServiceLocator架构设计应该合理', () {
      final serviceLocator = ServiceLocator();
      
      // 测试单例模式
      final serviceLocator2 = ServiceLocator();
      expect(identical(serviceLocator, serviceLocator2), true);
      
      // 测试初始化前的状态
      expect(serviceLocator.isRegistered<ImportService>(), false);
      
      // 测试初始化后的状态
      serviceLocator.initialize();
      expect(serviceLocator.isRegistered<ImportService>(), true);
      
      // 测试清理后的状态
      serviceLocator.dispose();
      expect(serviceLocator.isRegistered<ImportService>(), false);
      
      print('✅ ServiceLocator架构设计合理');
    });

    test('服务类型系统应该正确工作', () {
      final serviceLocator = ServiceLocator();
      serviceLocator.initialize();
      
      // 测试泛型类型检查
      final importService = serviceLocator.get<ImportService>();
      expect(importService.runtimeType.toString(), contains('ImportService'));
      
      serviceLocator.dispose();
      
      print('✅ 服务类型系统正常');
    });
  });
} 