import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../check_logger.dart';
import 'alert_config.dart';
import 'alert_notifier.dart';
import 'alert_types.dart';

void main() {
  late AlertNotifier notifier;
  late Directory tempDir;
  late AlertConfig config;

  setUp(() async {
    // 创建临时目录用于测试
    tempDir = await Directory.systemTemp.createTemp('alert_test_');

    // 创建测试配置
    config = AlertConfig(
      suppressionTimeMinutes: 1,
      enableDesktopNotifications: false,
      alertsPath: path.join(tempDir.path, 'alerts'),
    );

    notifier = AlertNotifier(
      config: config,
      logger: CheckLogger.instance,
    );
  });

  tearDown(() async {
    // 清理测试目录
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
    notifier.dispose();
  });

  group('基本功能测试', () {
    test('发送警报', () async {
      await notifier.alert(
        type: 'test',
        message: 'Test alert',
        level: AlertLevel.info,
      );

      final history = notifier.getHistory();
      expect(history, hasLength(1));
      expect(history.first.type, equals('test'));
      expect(history.first.message, equals('Test alert'));
      expect(history.first.level, equals(AlertLevel.info));
    });

    test('警报抑制', () async {
      // 第一次警报
      await notifier.alert(
        type: 'test',
        message: 'Test alert 1',
        level: AlertLevel.warning,
      );

      // 抑制该类型的警报
      notifier.suppressAlert('test');

      // 尝试发送第二次警报
      await notifier.alert(
        type: 'test',
        message: 'Test alert 2',
        level: AlertLevel.warning,
      );

      final history = notifier.getHistory();
      expect(history, hasLength(1));
      expect(history.first.message, equals('Test alert 1'));
    });

    test('取消抑制', () async {
      notifier.suppressAlert('test');
      notifier.unsuppressAlert('test');

      await notifier.alert(
        type: 'test',
        message: 'Test alert',
        level: AlertLevel.info,
      );

      final history = notifier.getHistory();
      expect(history, hasLength(1));
    });
  });

  group('文件记录测试', () {
    test('写入警报文件', () async {
      await notifier.alert(
        type: 'test',
        message: 'Test alert',
        level: AlertLevel.error,
        details: {'code': 404},
      );

      // 检查警报目录是否创建
      final alertDir = Directory(config.alertsPath);
      expect(alertDir.existsSync(), isTrue);

      // 检查是否生成警报文件
      final files = alertDir.listSync();
      expect(files, hasLength(1));

      // 验证文件内容
      final content = await File(files.first.path).readAsString();
      expect(content, contains('"type":"test"'));
      expect(content, contains('"level":"AlertLevel.error"'));
      expect(content, contains('"code":404'));
    });
  });

  group('优先级队列测试', () {
    test('警报优先级排序', () async {
      // 发送不同级别的警报
      await notifier.alert(
        type: 'test1',
        message: 'Info alert',
        level: AlertLevel.info,
      );

      await notifier.alert(
        type: 'test2',
        message: 'Critical alert',
        level: AlertLevel.critical,
      );

      await notifier.alert(
        type: 'test3',
        message: 'Warning alert',
        level: AlertLevel.warning,
      );

      final history = notifier.getHistory();
      expect(history[0].level, equals(AlertLevel.critical));
      expect(history[1].level, equals(AlertLevel.warning));
      expect(history[2].level, equals(AlertLevel.info));
    });

    test('最大历史记录限制', () async {
      // 创建带有小历史记录限制的配置
      final limitedConfig = AlertConfig(
        maxHistorySize: 2,
        alertsPath: path.join(tempDir.path, 'alerts'),
      );

      final limitedNotifier = AlertNotifier(
        config: limitedConfig,
        logger: CheckLogger.instance,
      );

      // 发送三个警报
      await limitedNotifier.alert(
        type: 'test1',
        message: 'First alert',
        level: AlertLevel.info,
      );

      await limitedNotifier.alert(
        type: 'test2',
        message: 'Second alert',
        level: AlertLevel.info,
      );

      await limitedNotifier.alert(
        type: 'test3',
        message: 'Third alert',
        level: AlertLevel.info,
      );

      final history = limitedNotifier.getHistory();
      expect(history, hasLength(2));
      expect(history.last.message, equals('Third alert'));
    });
  });

  group('压力测试', () {
    test('快速发送多个警报', () async {
      final alerts = List.generate(
          100,
          (i) => notifier.alert(
                type: 'test$i',
                message: 'Test alert $i',
                level: AlertLevel.info,
              ));

      await Future.wait(alerts);

      final history = notifier.getHistory();
      expect(history, hasLength(100));
    });
  });
}
