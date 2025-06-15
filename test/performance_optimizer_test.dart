import 'package:charasgem/presentation/widgets/practice/memory_manager.dart';
import 'package:charasgem/presentation/widgets/practice/performance_monitor.dart';
import 'package:charasgem/presentation/widgets/practice/performance_optimizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryManager memoryManager;
  late PerformanceMonitor performanceMonitor;
  late SelfAdaptivePerformanceOptimizer optimizer;
  setUp(() {
    memoryManager = MemoryManager();
    performanceMonitor = PerformanceMonitor();
    optimizer = SelfAdaptivePerformanceOptimizer(
      memoryManager: memoryManager,
      performanceMonitor: performanceMonitor,
    );
  });

  group('SelfAdaptivePerformanceOptimizer', () {
    test('should initialize with default configuration', () {
      expect(optimizer.config, isNotNull);
      expect(optimizer.devicePerformanceLevel, DevicePerformanceLevel.medium);
    });

    test('should generate performance report', () {
      final report = optimizer.getPerformanceReport();

      expect(report, isNotNull);
      expect(report['devicePerformanceLevel'], isNotNull);
      expect(report['currentConfig'], isNotNull);
      expect(report['performanceMetrics'], isNotNull);
      expect(report['memoryMetrics'], isNotNull);
    });

    test('should apply new configuration', () {
      final newConfig = PerformanceOptimizationConfig.forLowPerformance();
      optimizer.applyConfiguration(newConfig);

      expect(optimizer.config.maxFrameRate, equals(30));
      expect(optimizer.config.renderQuality, equals(0.7));
      expect(optimizer.config.useLowQualityMode, isTrue);
    });

    test('should reset to default configuration', () {
      // First apply a different config
      optimizer.applyConfiguration(
          PerformanceOptimizationConfig.forLowPerformance());

      // Then reset to default
      optimizer.resetToDefault();

      // Should be back to medium performance config (default for test)
      expect(optimizer.config.maxFrameRate, equals(60));
      expect(optimizer.config.useLowQualityMode, isFalse);
    });

    test('should manually set device performance level', () {
      optimizer.setDevicePerformanceLevel(DevicePerformanceLevel.high);

      expect(optimizer.devicePerformanceLevel,
          equals(DevicePerformanceLevel.high));
      expect(optimizer.config.maxFrameRate, equals(60));
      expect(optimizer.config.renderQuality, equals(1.0));
    });
  });

  group('PerformanceOptimizationConfig', () {
    test('should create config for different performance levels', () {
      final lowConfig = PerformanceOptimizationConfig.forLowPerformance();
      final mediumConfig = PerformanceOptimizationConfig.forMediumPerformance();
      final highConfig = PerformanceOptimizationConfig.forHighPerformance();

      expect(lowConfig.maxFrameRate, equals(30));
      expect(mediumConfig.maxFrameRate, equals(60));
      expect(highConfig.maxFrameRate, equals(60));

      expect(lowConfig.renderQuality, lessThan(mediumConfig.renderQuality));
      expect(mediumConfig.renderQuality, lessThan(highConfig.renderQuality));
    });

    test('should create memory optimized configuration', () {
      final config = PerformanceOptimizationConfig.forMediumPerformance();
      final memoryOptimizedConfig = config.forHighMemoryPressure();

      expect(memoryOptimizedConfig.cacheLimit, lessThan(config.cacheLimit));
      expect(
          memoryOptimizedConfig.renderQuality, lessThan(config.renderQuality));
      expect(memoryOptimizedConfig.useLowQualityMode, isTrue);
    });

    test('should correctly convert to JSON', () {
      final config = PerformanceOptimizationConfig.forMediumPerformance();
      final json = config.toJson();

      expect(json['maxFrameRate'], equals(60));
      expect(json['renderQuality'], equals(0.9));
      expect(json['useLowQualityMode'], isFalse);
    });

    test('should create copy with overridden values', () {
      final config = PerformanceOptimizationConfig.forMediumPerformance();
      final copy = config.copyWith(
        maxFrameRate: 45,
        renderQuality: 0.8,
      );

      expect(copy.maxFrameRate, equals(45));
      expect(copy.renderQuality, equals(0.8));
      // Other values should remain the same
      expect(copy.cacheLimit, equals(config.cacheLimit));
    });
  });
}
