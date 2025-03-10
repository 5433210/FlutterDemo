import 'dart:math' as math;

import 'package:test/test.dart';

import '../utils/alert_notifier.dart';
import 'resource_predictor.dart';

void main() {
  late TestAlertNotifier notifier;
  late ResourcePredictor predictor;

  setUp(() {
    notifier = TestAlertNotifier(
      config: AlertConfig(
        maxAlerts: 100,
        enableNotifications: true,
      ),
    );

    predictor = ResourcePredictor(
      notifier: notifier,
      config: const PredictorConfig(
        historyWindow: 100,
        predictionInterval: Duration(minutes: 15),
        confidenceThreshold: 0.8,
      ),
    );
  });

  tearDown(() {
    predictor.reset();
    notifier.dispose();
  });

  group('基础功能测试', () {
    test('添加资源使用记录', () {
      final usage = ResourceUsage(
        type: ResourceType.cpu,
        resource: 'test-cpu',
        value: 50.0,
        timestamp: DateTime.now(),
      );

      predictor.addUsage(usage);
      final prediction = predictor.getPrediction('test-cpu');

      expect(prediction, isNull); // 数据点不足，还没有预测
    });

    test('重置特定资源', () {
      final usage = ResourceUsage(
        type: ResourceType.memory,
        resource: 'test-memory',
        value: 1024.0,
        timestamp: DateTime.now(),
      );

      predictor.addUsage(usage);
      predictor.resetResource('test-memory');

      final prediction = predictor.getPrediction('test-memory');
      expect(prediction, isNull);
    });
  });

  group('趋势分析测试', () {
    test('线性增长趋势', () {
      final now = DateTime.now();
      const resource = 'trend-test';

      // 添加线性增长数据
      for (var i = 0; i < 20; i++) {
        predictor.addUsage(ResourceUsage(
          type: ResourceType.cpu,
          resource: resource,
          value: 50.0 + i * 2.0, // 每次增加2
          timestamp: now.add(Duration(minutes: i * 5)),
        ));
      }

      final prediction = predictor.getPrediction(resource);
      expect(prediction, isNotNull);
      expect(prediction!.context['trend'], greaterThan(0)); // 正向趋势
      expect(prediction.confidence, greaterThan(0.8)); // 高置信度
    });

    test('稳定值趋势', () {
      final now = DateTime.now();
      const resource = 'stable-test';

      // 添加稳定数据（有少量波动）
      for (var i = 0; i < 20; i++) {
        predictor.addUsage(ResourceUsage(
          type: ResourceType.memory,
          resource: resource,
          value: 1024.0 + (i % 2 == 0 ? 10 : -10), // 小幅波动
          timestamp: now.add(Duration(minutes: i * 5)),
        ));
      }

      final prediction = predictor.getPrediction(resource);
      expect(prediction, isNotNull);
      expect(prediction!.context['trend'].abs(), lessThan(0.1)); // 接近零的趋势
      expect(prediction.confidence, greaterThan(0.9)); // 很高的置信度
    });
  });

  group('季节性检测测试', () {
    test('周期性模式', () {
      final now = DateTime.now();
      const resource = 'seasonal-test';

      // 添加周期性数据
      for (var i = 0; i < 50; i++) {
        final value = 100.0 + 30.0 * math.sin(i * math.pi / 12); // 24小时周期
        predictor.addUsage(ResourceUsage(
          type: ResourceType.cpu,
          resource: resource,
          value: value,
          timestamp: now.add(Duration(hours: i)),
        ));
      }

      final prediction = predictor.getPrediction(resource);
      expect(prediction, isNotNull);
      expect(prediction!.context['seasonal_period'], isNot(0)); // 检测到周期
      expect(
          prediction.context['seasonal_strength'], greaterThan(0.5)); // 较强的季节性
    });
  });

  group('告警测试', () {
    test('预测置信度低告警', () {
      var alertReceived = false;
      notifier.addListener((alert) {
        if (alert.level == AlertLevel.warning) {
          alertReceived = true;
        }
      });

      final now = DateTime.now();
      const resource = 'unstable-test';

      // 添加高度不稳定的数据
      for (var i = 0; i < 20; i++) {
        predictor.addUsage(ResourceUsage(
          type: ResourceType.cpu,
          resource: resource,
          value: 50.0 + (i * 10 * (i % 2 == 0 ? 1 : -1)), // 剧烈波动
          timestamp: now.add(Duration(minutes: i * 5)),
        ));
      }

      expect(alertReceived, isTrue);
    });

    test('资源使用量显著增加告警', () {
      var alertReceived = false;
      notifier.addListener((alert) {
        if (alert.level == AlertLevel.error) {
          alertReceived = true;
        }
      });

      final now = DateTime.now();
      const resource = 'spike-test';

      // 添加正常数据
      for (var i = 0; i < 15; i++) {
        predictor.addUsage(ResourceUsage(
          type: ResourceType.memory,
          resource: resource,
          value: 1024.0 + (i * 2),
          timestamp: now.add(Duration(minutes: i * 5)),
        ));
      }

      // 添加突增数据
      for (var i = 15; i < 20; i++) {
        predictor.addUsage(ResourceUsage(
          type: ResourceType.memory,
          resource: resource,
          value: 2048.0 + (i * 100), // 显著增加
          timestamp: now.add(Duration(minutes: i * 5)),
        ));
      }

      expect(alertReceived, isTrue);
    });
  });

  group('预测窗口测试', () {
    test('预测窗口自适应', () {
      final now = DateTime.now();
      const resource = 'window-test';

      // 添加稳定数据
      for (var i = 0; i < 20; i++) {
        predictor.addUsage(ResourceUsage(
          type: ResourceType.cpu,
          resource: resource,
          value: 50.0 + (i * 0.1),
          timestamp: now.add(Duration(minutes: i * 5)),
        ));
      }

      final prediction1 = predictor.getPrediction(resource);
      expect(prediction1, isNotNull);

      // 添加波动数据
      for (var i = 20; i < 40; i++) {
        predictor.addUsage(ResourceUsage(
          type: ResourceType.cpu,
          resource: resource,
          value: 50.0 + (i * 5 * (i % 2 == 0 ? 1 : -1)),
          timestamp: now.add(Duration(minutes: i * 5)),
        ));
      }

      final prediction2 = predictor.getPrediction(resource);
      expect(prediction2, isNotNull);

      // 不稳定数据应该有更短的预测窗口
      expect(prediction2!.predictionWindow.inMinutes,
          lessThan(prediction1!.predictionWindow.inMinutes));
    });
  });
}

typedef AlertDataCallback = void Function(AlertData alert);

/// 扩展AlertNotifier以支持测试监听
class TestAlertNotifier extends AlertNotifier {
  final List<AlertDataCallback> _listeners = [];

  TestAlertNotifier({required super.config});

  void addListener(AlertDataCallback listener) {
    _listeners.add(listener);
  }

  @override
  void notify(AlertData alert) {
    super.notify(alert);
    for (final listener in _listeners) {
      listener(alert);
    }
  }
}
