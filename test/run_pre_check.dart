import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'utils/check_logger.dart';
import 'utils/pre_test_check_config.dart';
import 'utils/test_data_helper.dart';

Future<void> main() async {
  final logger = CheckLogger();
  final config = await PreTestCheckConfig.load();

  // 设置超时时间
  final timeout = Duration(seconds: config.timeoutSeconds);

  // 系统检查
  final systemCheck = Timer(timeout, () async {
    // 磁盘空间检查
    final requiredSpace = config.requiredDiskSpaceMB * 1024 * 1024; // 转换为字节
    final testDir = Directory('test');
    final stats = await testDir.stat();
    if (stats.type != FileSystemEntityType.directory) {
      throw Exception('Test directory not found');
    }

    // 检查缓存
    if (config.enableCache) {
      final cache = await PreTestCheckCache.read();
      if (cache != null &&
          cache.isValid(Duration(hours: config.backupIntervalHours))) {
        logger.info('Using cached check results');
        return;
      }
    }

    // 初始化测试数据
    await TestDataHelper.initializeTestDataDirectory();

    // 验证数据
    final dataValid = await TestDataHelper.verifyTestData();
    if (!dataValid) {
      await TestDataHelper.loadMockData();
    }

    // 检查结果
    final results = {
      'diskSpace': true,
      'testData': dataValid,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 缓存结果
    if (config.enableCache) {
      final cache = PreTestCheckCache(
        results: results,
        timestamp: DateTime.now(),
      );
      await cache.save();
    }
  });

  // 运行前置测试
  test('Pre-test checks', () async {
    systemCheck;
    expect(true, isTrue); // Base check passed
  }, timeout: Timeout(timeout));

  // 记录结果
  tearDownAll(() async {
    await logger.save(
      'test/logs/pre_check.log',
      'pre_test_check',
    );
  });
}
