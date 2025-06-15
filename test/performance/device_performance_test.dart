import 'package:charasgem/presentation/widgets/practice/memory_manager.dart';
import 'package:charasgem/presentation/widgets/practice/performance_monitor.dart';
import 'package:charasgem/presentation/widgets/practice/performance_optimizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DevicePerformanceDetector Tests', () {
    test('设备性能检测应该返回有效的性能等级', () async {
      print('\n🧪 测试开始：设备性能检测');

      final stopwatch = Stopwatch()..start();
      final performanceLevel =
          await DevicePerformanceDetector.detectDevicePerformance();
      stopwatch.stop();

      print('📊 设备性能检测结果：');
      print('   检测耗时: ${stopwatch.elapsedMilliseconds}ms');
      print('   性能等级: $performanceLevel');

      // 验证返回值有效
      expect(performanceLevel, isA<DevicePerformanceLevel>());
      expect(DevicePerformanceLevel.values.contains(performanceLevel), isTrue);

      // 检测时间应该在合理范围内
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: '性能检测不应超过5秒');

      print('✅ 设备性能检测测试通过\n');
    });

    test('不同性能等级配置应该有明显区别', () {
      print('\n🧪 测试开始：性能配置差异化');

      final lowConfig = PerformanceOptimizationConfig.forLowPerformance();
      final mediumConfig = PerformanceOptimizationConfig.forMediumPerformance();
      final highConfig = PerformanceOptimizationConfig.forHighPerformance();

      print('📊 配置对比：');
      print(
          '   低性能: 帧率=${lowConfig.maxFrameRate}, 质量=${lowConfig.renderQuality}');
      print(
          '   中等性能: 帧率=${mediumConfig.maxFrameRate}, 质量=${mediumConfig.renderQuality}');
      print(
          '   高性能: 帧率=${highConfig.maxFrameRate}, 质量=${highConfig.renderQuality}');

      // 验证配置递进关系
      expect(lowConfig.renderQuality, lessThan(mediumConfig.renderQuality));
      expect(mediumConfig.renderQuality,
          lessThanOrEqualTo(highConfig.renderQuality));
      expect(
          lowConfig.maxFrameRate, lessThanOrEqualTo(mediumConfig.maxFrameRate));

      print('✅ 性能配置差异化测试通过\n');
    });

    test('自适应性能优化器应该正确初始化', () async {
      print('\n🧪 测试开始：自适应性能优化器初始化');

      final memoryManager = MemoryManager();
      final performanceMonitor = PerformanceMonitor();

      // 先检测设备性能
      final detectedLevel =
          await DevicePerformanceDetector.detectDevicePerformance();
      print('📊 检测到设备性能: $detectedLevel');

      final optimizer = SelfAdaptivePerformanceOptimizer(
        memoryManager: memoryManager,
        performanceMonitor: performanceMonitor,
      );

      print('📊 优化器状态：');
      print('   设备性能等级: ${optimizer.devicePerformanceLevel}');
      print('   当前配置: ${optimizer.config.toJson()}');

      // 验证初始化
      expect(optimizer.devicePerformanceLevel, equals(detectedLevel));
      expect(optimizer.config, isNotNull);

      // 获取性能报告
      final report = optimizer.getPerformanceReport();
      expect(report, isNotNull);
      expect(report['devicePerformanceLevel'], isNotNull);
      expect(report['currentConfig'], isNotNull);

      print('✅ 自适应性能优化器初始化测试通过\n');

      optimizer.dispose();
    });

    test('自适应优化器应该能够正确调整配置', () async {
      print('\n🧪 测试开始：自适应配置调整');

      final memoryManager = MemoryManager();
      final performanceMonitor = PerformanceMonitor();

      final optimizer = SelfAdaptivePerformanceOptimizer(
        memoryManager: memoryManager,
        performanceMonitor: performanceMonitor,
      );

      print('📊 测试配置调整：');

      // 测试手动设置高性能
      optimizer.setDevicePerformanceLevel(DevicePerformanceLevel.high);
      print('   设置为高性能: ${optimizer.config.renderQuality}');
      expect(optimizer.devicePerformanceLevel, DevicePerformanceLevel.high);
      expect(optimizer.config.renderQuality, greaterThan(0.8));

      // 测试手动设置低性能
      optimizer.setDevicePerformanceLevel(DevicePerformanceLevel.low);
      print('   设置为低性能: ${optimizer.config.renderQuality}');
      expect(optimizer.devicePerformanceLevel, DevicePerformanceLevel.low);
      expect(optimizer.config.renderQuality, lessThan(0.8));

      // 测试重置配置
      optimizer.resetToDefault();
      print('   重置后: ${optimizer.devicePerformanceLevel}');
      expect(optimizer.devicePerformanceLevel,
          DevicePerformanceLevel.low); // 最后设置的值

      print('✅ 自适应配置调整测试通过\n');

      optimizer.dispose();
    });

    test('内存压力优化应该正确工作', () async {
      print('\n🧪 测试开始：内存压力优化');

      final memoryManager = MemoryManager();
      final performanceMonitor = PerformanceMonitor();

      final optimizer = SelfAdaptivePerformanceOptimizer(
        memoryManager: memoryManager,
        performanceMonitor: performanceMonitor,
      );

      final originalConfig = optimizer.config;
      print('📊 原始配置: 渲染质量=${originalConfig.renderQuality}');

      // 手动触发内存优化
      optimizer.optimizeForMemory();

      print('📊 内存优化后配置检查完成');

      // 获取性能报告验证
      final report = optimizer.getPerformanceReport();
      expect(report['memoryMetrics'], isNotNull);
      expect(report['adaptationState'], isNotNull);

      print('✅ 内存压力优化测试通过\n');

      optimizer.dispose();
    });
  });

  group('PerformanceOptimizationConfig Tests', () {
    test('配置应该支持正确的JSON序列化', () {
      print('\n🧪 测试开始：配置JSON序列化');

      final config = PerformanceOptimizationConfig.forMediumPerformance();
      final json = config.toJson();

      print('📊 配置JSON: $json');

      // 验证关键字段存在
      expect(json['maxFrameRate'], isNotNull);
      expect(json['renderQuality'], isNotNull);
      expect(json['enableViewportCulling'], isNotNull);

      print('✅ 配置JSON序列化测试通过\n');
    });

    test('高内存压力配置应该降低资源使用', () {
      print('\n🧪 测试开始：高内存压力配置');

      final normalConfig = PerformanceOptimizationConfig.forMediumPerformance();
      final memoryConfig = normalConfig.forHighMemoryPressure();

      print('📊 配置对比：');
      print(
          '   正常: 质量=${normalConfig.renderQuality}, 缓存=${normalConfig.cacheLimit}');
      print(
          '   内存压力: 质量=${memoryConfig.renderQuality}, 缓存=${memoryConfig.cacheLimit}');

      // 内存压力配置应该降低资源使用
      expect(memoryConfig.renderQuality,
          lessThanOrEqualTo(normalConfig.renderQuality));
      expect(
          memoryConfig.cacheLimit, lessThanOrEqualTo(normalConfig.cacheLimit));
      expect(memoryConfig.useLowQualityMode, isTrue);

      print('✅ 高内存压力配置测试通过\n');
    });
  });

  group('性能等级集成测试', () {
    test('完整的性能检测到配置应用流程', () async {
      print('\n🧪 测试开始：完整性能优化流程');

      // 1. 检测设备性能
      final detectedLevel =
          await DevicePerformanceDetector.detectDevicePerformance();
      print('📊 第1步 - 设备性能检测: $detectedLevel');

      // 2. 创建自适应优化器
      final memoryManager = MemoryManager();
      final performanceMonitor = PerformanceMonitor();

      final optimizer = SelfAdaptivePerformanceOptimizer(
        memoryManager: memoryManager,
        performanceMonitor: performanceMonitor,
      );

      print('📊 第2步 - 优化器创建完成: ${optimizer.devicePerformanceLevel}');

      // 3. 验证配置匹配
      final config = optimizer.config;
      print(
          '📊 第3步 - 配置验证: 帧率=${config.maxFrameRate}, 质量=${config.renderQuality}');

      // 4. 生成性能报告
      final report = optimizer.getPerformanceReport();
      print('📊 第4步 - 性能报告生成完成');

      // 验证完整流程
      expect(optimizer.devicePerformanceLevel, equals(detectedLevel));
      expect(config, isNotNull);
      expect(report, isNotNull);
      expect(report['devicePerformanceLevel'],
          contains(detectedLevel.toString().split('.').last));

      print('✅ 完整性能优化流程测试通过\n');

      optimizer.dispose();
    });
  });
}
