import 'package:test/test.dart';

import 'utils/check_logger.dart';
import 'utils/test_data_helper.dart';

/// 冒烟测试
void main() {
  late CheckLogger logger;

  setUpAll(() async {
    logger = CheckLogger();
    await logger.save();
  });

  test('System check', () async {
    // Initialize test data
    await TestDataHelper.initializeTestDataDirectory();

    // Verify basic test data
    final hasData = await TestDataHelper.verifyTestData();
    if (!hasData) {
      await TestDataHelper.loadMockData();
    }

    // Load test data
    final works = await TestDataHelper.getTestWorks();
    final chars = await TestDataHelper.getTestCharacters();

    expect(works, isNotEmpty);
    expect(chars, isNotEmpty);

    // Create backup
    final backupPath = await TestDataHelper.backupTestData();
    expect(backupPath, isNotEmpty);

    logger.info('Smoke test passed', {
      'works': works.length,
      'characters': chars.length,
      'backup': backupPath,
    });
  });
}

/// 系统资源检查结果
class ResourceCheckResult {
  final bool passed;
  final String message;
  final Map<String, dynamic> metrics;

  const ResourceCheckResult({
    required this.passed,
    required this.message,
    this.metrics = const {},
  });
}
