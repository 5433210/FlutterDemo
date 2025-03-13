import 'dart:async';

import 'package:demo/domain/enums/work_style.dart';
import 'package:demo/domain/enums/work_tool.dart';
import 'package:demo/domain/models/work/work_entity.dart';
import 'package:demo/infrastructure/persistence/database_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试环境清理
Future<void> cleanupTestEnvironment() async {
  // 清理测试资源
}

/// 初始化测试环境
Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
}

/// 异步断言助手
class AsyncTestHelper {
  static Future<void> expectWithTimeout<T>(
    Future<T> Function() operation,
    dynamic matcher, {
    Duration timeout = const Duration(seconds: 5),
    String? description,
  }) async {
    try {
      final result = await operation().timeout(timeout);
      expect(result, matcher, reason: description);
    } on TimeoutException {
      fail('Operation timed out after ${timeout.inSeconds} seconds');
    }
  }

  /// 等待条件满足
  static Future<void> waitUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (!condition()) {
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException(
            'Condition not met within ${timeout.inSeconds} seconds');
      }
      await Future.delayed(interval);
    }
  }
}

/// 测试数据库预设
class DatabasePreset {
  static Future<void> setupTestWorks(
    DatabaseInterface db,
    List<WorkEntity> works,
  ) async {
    for (final work in works) {
      await db.save('works', work.id, work.toJson());
    }
  }

  static Future<void> verifyWorks(
    DatabaseInterface db,
    List<WorkEntity> expectedWorks,
  ) async {
    final actual = await db.getAll('works');
    expect(actual.length, equals(expectedWorks.length));

    for (final expected in expectedWorks) {
      final stored = await db.get('works', expected.id);
      expect(stored, isNotNull);
      expect(stored!['title'], equals(expected.title));
    }
  }
}

/// 测试数据生成器
class TestDataGenerator {
  static WorkEntity createTestWork({
    String? id,
    String title = 'Test Work',
  }) {
    final now = DateTime.now();
    return WorkEntity(
      id: id ?? 'test_work_${now.millisecondsSinceEpoch}',
      title: title,
      author: 'Test Author',
      style: WorkStyle.regular, // 使用正确的枚举值
      tool: WorkTool.brush, // 使用正确的枚举值
      creationDate: now,
      createTime: now,
      updateTime: now,
    );
  }

  static List<WorkEntity> createTestWorks(int count) {
    return List.generate(
      count,
      (i) => createTestWork(id: 'test_work_$i', title: 'Test Work $i'),
    );
  }
}
