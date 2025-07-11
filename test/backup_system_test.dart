// 备份系统功能测试
// 这个文件用于测试新的备份系统功能是否正常工作

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// 导入相关数据模型
import 'package:charasgem/domain/models/backup_models.dart';

void main() {
  group('备份系统测试', () {
    late String testBackupPath;

    setUp(() async {
      // 为测试创建临时目录
      final tempDir = Directory.systemTemp.createTempSync('backup_test_');
      testBackupPath = tempDir.path;
    });

    tearDown(() async {
      // 清理测试目录
      if (Directory(testBackupPath).existsSync()) {
        await Directory(testBackupPath).delete(recursive: true);
      }
    });

    test('备份位置信息序列化测试', () {
      final location = BackupLocation(
        path: '/test/path',
        createdTime: DateTime.now(),
        description: '测试备份位置',
        version: '1.0',
      );

      final json = location.toJson();
      final restored = BackupLocation.fromJson(json);

      expect(restored.path, equals(location.path));
      expect(restored.description, equals(location.description));
      expect(restored.version, equals(location.version));
    });

    test('备份条目序列化测试', () {
      final entry = BackupEntry(
        id: 'test_001',
        filename: 'backup_test.zip',
        fullPath: '/test/path/backup_test.zip',
        size: 1024,
        createdTime: DateTime.now(),
        checksum: 'test_checksum',
        appVersion: '1.0.0',
        description: '测试备份',
        location: 'current',
      );

      final json = entry.toJson();
      final restored = BackupEntry.fromJson(json);

      expect(restored.id, equals(entry.id));
      expect(restored.filename, equals(entry.filename));
      expect(restored.fullPath, equals(entry.fullPath));
      expect(restored.size, equals(entry.size));
      expect(restored.location, equals(entry.location));
    });

    test('备份注册表序列化测试', () {
      final location = BackupLocation(
        path: '/test/path',
        createdTime: DateTime.now(),
        description: '测试备份位置',
      );

      final entries = [
        BackupEntry(
          id: 'test_001',
          filename: 'backup_test.zip',
          fullPath: '/test/path/backup_test.zip',
          size: 1024,
          createdTime: DateTime.now(),
          description: '测试备份',
          location: 'current',
        ),
      ];

      final registry = BackupRegistry(
        location: location,
        backups: entries,
      );

      final json = registry.toJson();
      final restored = BackupRegistry.fromJson(json);

      expect(restored.backups.length, equals(1));
      expect(restored.backups.first.id, equals('test_001'));
      expect(restored.statistics.totalBackups, equals(1));
    });

    test('旧数据路径信息序列化测试', () {
      final legacyPath = LegacyDataPath(
        id: 'legacy_001',
        path: '/old/path',
        switchedTime: DateTime.now(),
        sizeEstimate: 2048,
        status: 'pending_cleanup',
        description: '旧数据路径',
      );

      final json = legacyPath.toJson();
      final restored = LegacyDataPath.fromJson(json);

      expect(restored.id, equals(legacyPath.id));
      expect(restored.path, equals(legacyPath.path));
      expect(restored.sizeEstimate, equals(legacyPath.sizeEstimate));
      expect(restored.status, equals(legacyPath.status));
    });

    test('备份建议对象测试', () {
      final recommendation = BackupRecommendation(
        needsBackupPath: true,
        recommendBackup: true,
        reason: '测试建议',
      );

      expect(recommendation.needsBackupPath, isTrue);
      expect(recommendation.recommendBackup, isTrue);
      expect(recommendation.reason, equals('测试建议'));
    });

    test('备份选择枚举测试', () {
      expect(BackupChoice.values.length, equals(3));
      expect(BackupChoice.values.contains(BackupChoice.cancel), isTrue);
      expect(BackupChoice.values.contains(BackupChoice.skipBackup), isTrue);
      expect(BackupChoice.values.contains(BackupChoice.createBackup), isTrue);
    });

    test('数据路径切换异常测试', () {
      final exception = DataPathSwitchException('测试异常');
      expect(exception.message, equals('测试异常'));
      expect(exception.toString(), equals('DataPathSwitchException: 测试异常'));
    });
  });

  group('备份统计功能测试', () {
    test('备份统计计算测试', () {
      final entries = [
        BackupEntry(
          id: 'test_001',
          filename: 'backup_001.zip',
          fullPath: '/test/backup_001.zip',
          size: 1024,
          createdTime: DateTime.now().subtract(const Duration(hours: 2)),
          description: '测试备份1',
          location: 'current',
        ),
        BackupEntry(
          id: 'test_002',
          filename: 'backup_002.zip',
          fullPath: '/old/backup_002.zip',
          size: 2048,
          createdTime: DateTime.now().subtract(const Duration(hours: 1)),
          description: '测试备份2',
          location: 'legacy',
        ),
      ];

      final location = BackupLocation(
        path: '/test/path',
        createdTime: DateTime.now(),
        description: '测试备份位置',
      );

      final registry = BackupRegistry(
        location: location,
        backups: entries,
      );

      expect(registry.statistics.totalBackups, equals(2));
      expect(registry.statistics.currentLocationBackups, equals(1));
      expect(registry.statistics.legacyLocationBackups, equals(1));
      expect(registry.statistics.totalSize, equals(3072));
      expect(registry.statistics.lastBackupTime, isNotNull);
    });

    test('空备份列表统计测试', () {
      final location = BackupLocation(
        path: '/test/path',
        createdTime: DateTime.now(),
        description: '测试备份位置',
      );

      final registry = BackupRegistry(
        location: location,
        backups: [],
      );

      expect(registry.statistics.totalBackups, equals(0));
      expect(registry.statistics.currentLocationBackups, equals(0));
      expect(registry.statistics.legacyLocationBackups, equals(0));
      expect(registry.statistics.totalSize, equals(0));
      expect(registry.statistics.lastBackupTime, isNull);
    });
  });

  group('备份注册表操作测试', () {
    test('添加备份条目测试', () {
      final location = BackupLocation(
        path: '/test/path',
        createdTime: DateTime.now(),
        description: '测试备份位置',
      );

      final registry = BackupRegistry(
        location: location,
        backups: [],
      );

      final entry = BackupEntry(
        id: 'test_001',
        filename: 'backup_test.zip',
        fullPath: '/test/backup_test.zip',
        size: 1024,
        createdTime: DateTime.now(),
        description: '测试备份',
        location: 'current',
      );

      registry.addBackup(entry);

      expect(registry.backups.length, equals(1));
      expect(registry.backups.first.id, equals('test_001'));
    });

    test('移除备份条目测试', () {
      final location = BackupLocation(
        path: '/test/path',
        createdTime: DateTime.now(),
        description: '测试备份位置',
      );

      final entry = BackupEntry(
        id: 'test_001',
        filename: 'backup_test.zip',
        fullPath: '/test/backup_test.zip',
        size: 1024,
        createdTime: DateTime.now(),
        description: '测试备份',
        location: 'current',
      );

      final registry = BackupRegistry(
        location: location,
        backups: [entry],
      );

      expect(registry.backups.length, equals(1));

      registry.removeBackup('test_001');

      expect(registry.backups.length, equals(0));
    });

    test('查找备份条目测试', () {
      final location = BackupLocation(
        path: '/test/path',
        createdTime: DateTime.now(),
        description: '测试备份位置',
      );

      final entry = BackupEntry(
        id: 'test_001',
        filename: 'backup_test.zip',
        fullPath: '/test/backup_test.zip',
        size: 1024,
        createdTime: DateTime.now(),
        description: '测试备份',
        location: 'current',
      );

      final registry = BackupRegistry(
        location: location,
        backups: [entry],
      );

      final found = registry.getBackup('test_001');
      expect(found, isNotNull);
      expect(found!.id, equals('test_001'));

      final notFound = registry.getBackup('not_exist');
      expect(notFound, isNull);
    });
  });
}
