import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import '../utils/alerts/alert_config.dart';
import '../utils/alerts/alert_notifier.dart';
import '../utils/alerts/alert_types.dart';

void main() {
  late AlertNotifier notifier;
  final alerts = <AlertRecord>[];

  setUp(() {
    notifier = AlertNotifier(
      config: const AlertConfig(
        maxHistorySize: 100,
        enableFileLogging: true,
        enableConsoleOutput: true,
        suppressionTimeMinutes: 1,
      ),
    );
  });

  tearDown(() {
    notifier.dispose();
    alerts.clear();
  });

  group('基本告警功能', () {
    test('发送告警', () async {
      await notifier.alert(
        type: 'test',
        message: 'Test alert',
        level: AlertLevel.info,
      );

      expect(notifier.getHistory(), hasLength(1));
      expect(
        notifier.getHistory().first.message,
        equals('Test alert'),
      );
    });

    test('清除告警', () async {
      await notifier.alert(
        type: 'test1',
        message: 'Warning alert',
        level: AlertLevel.warning,
      );

      await notifier.alert(
        type: 'test2',
        message: 'Error alert',
        level: AlertLevel.error,
      );

      expect(notifier.getHistory(), hasLength(2));
      expect(notifier.getHistory().first.level, equals(AlertLevel.error));
    });

    test('告警限制', () async {
      final limitedNotifier = AlertNotifier(
        config: const AlertConfig(
          maxHistorySize: 2,
          enableConsoleOutput: true,
        ),
      );

      // 按照优先级顺序发送警报
      await limitedNotifier.alert(
        type: 'test3',
        message: 'Third alert',
        level: AlertLevel.error,
      );

      await limitedNotifier.alert(
        type: 'test2',
        message: 'Second alert',
        level: AlertLevel.warning,
      );

      await limitedNotifier.alert(
        type: 'test1',
        message: 'First alert',
        level: AlertLevel.info,
      );

      expect(limitedNotifier.getHistory(), hasLength(2));
      final levels = limitedNotifier.getHistory().map((a) => a.level).toList();
      expect(levels, equals([AlertLevel.error, AlertLevel.warning]));

      limitedNotifier.dispose();
    });
  });

  group('告警节流', () {
    test('时间节流', () async {
      // 发送第一条警报
      await notifier.alert(
        type: 'test',
        message: 'First alert',
        level: AlertLevel.info,
      );

      expect(notifier.getHistory(), hasLength(1));
      expect(notifier.getHistory().first.message, equals('First alert'));

      // 尝试发送相同类型的第二条警报（应该被抑制）
      await notifier.alert(
        type: 'test',
        message: 'Second alert',
        level: AlertLevel.info,
      );

      expect(notifier.getHistory(), hasLength(1));
      expect(notifier.getHistory().first.message, equals('First alert'));

      // 等待抑制时间结束（2分钟，确保超过配置的1分钟）
      await Future.delayed(const Duration(minutes: 2));

      // 发送第三条警报（应该被允许）
      await notifier.alert(
        type: 'test',
        message: 'Third alert',
        level: AlertLevel.info,
      );

      expect(notifier.getHistory(), hasLength(2));
      expect(notifier.getHistory().last.message, equals('Third alert'));
    });
  });

  group('文件记录', () {
    test('警报记录', () async {
      final tempDir = await Directory.systemTemp.createTemp('alert_test_');

      try {
        final persistentNotifier = AlertNotifier(
          config: AlertConfig(
            enableFileLogging: true,
            alertsPath: tempDir.path,
          ),
        );

        await persistentNotifier.alert(
          type: 'test',
          message: 'Test alert',
          level: AlertLevel.error,
          details: {'code': 404},
        );

        // 等待文件写入
        await Future.delayed(const Duration(milliseconds: 100));

        final files = tempDir.listSync().where((f) => f.path.endsWith('.json'));
        expect(files, hasLength(1));

        final content = await File(files.first.path).readAsString();
        expect(content, contains('"type":"test"'));
        expect(content, contains('"message":"Test alert"'));

        persistentNotifier.dispose();
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
