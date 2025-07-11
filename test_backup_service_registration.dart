import 'package:flutter_test/flutter_test.dart';

import 'lib/application/services/enhanced_backup_service.dart';
import 'lib/application/services/service_locator.dart';
import 'lib/infrastructure/storage/local_storage.dart';

void main() {
  test('ServiceLocator应该在基础初始化中注册EnhancedBackupService', () async {
    // 创建一个新的ServiceLocator实例
    final serviceLocator = ServiceLocator();
    final storage = LocalStorage(basePath: './test_data');

    // 调用基础初始化
    serviceLocator.initializeBasic(storage: storage);

    // 检查EnhancedBackupService是否已注册
    expect(serviceLocator.isRegistered<EnhancedBackupService>(), isTrue,
        reason: 'EnhancedBackupService应该在基础初始化中被注册');

    // 尝试获取服务
    final backupService = serviceLocator.get<EnhancedBackupService>();
    expect(backupService, isNotNull);
  });
}
