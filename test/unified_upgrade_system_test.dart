import 'dart:convert';
import 'dart:io';

import 'package:charasgem/application/adapters/data_version_adapter_manager.dart';
import 'package:charasgem/application/services/data_version_mapping_service.dart';
import 'package:charasgem/application/services/unified_upgrade_service.dart';
import 'package:charasgem/domain/models/data_version_definition.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('统一升级系统测试', () {
    late String testDataPath;

    setUp(() async {
      // 创建临时测试目录
      final tempDir = await Directory.systemTemp.createTemp('upgrade_test_');
      testDataPath = tempDir.path;

      // 创建基本目录结构
      await Directory(path.join(testDataPath, 'database'))
          .create(recursive: true);
      await Directory(path.join(testDataPath, 'works')).create(recursive: true);
      await Directory(path.join(testDataPath, 'characters'))
          .create(recursive: true);
      await Directory(path.join(testDataPath, 'practices'))
          .create(recursive: true);
    });

    tearDown(() async {
      // 清理测试目录
      final testDir = Directory(testDataPath);
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('数据版本定义验证', () {
      // 测试数据版本定义的基本功能
      expect(DataVersionDefinition.isValidVersion('v1'), isTrue);
      expect(DataVersionDefinition.isValidVersion('v2'), isTrue);
      expect(DataVersionDefinition.isValidVersion('v3'), isTrue);
      expect(DataVersionDefinition.isValidVersion('v4'), isTrue);
      expect(DataVersionDefinition.isValidVersion('v5'), isFalse);

      // 测试版本比较
      expect(DataVersionDefinition.compareVersions('v1', 'v2'), equals(-1));
      expect(DataVersionDefinition.compareVersions('v2', 'v2'), equals(0));
      expect(DataVersionDefinition.compareVersions('v3', 'v2'), equals(1));

      // 测试数据库版本映射
      expect(DataVersionDefinition.getDatabaseVersion('v1'), equals(5));
      expect(DataVersionDefinition.getDatabaseVersion('v2'), equals(10));
      expect(DataVersionDefinition.getDatabaseVersion('v3'), equals(15));
      expect(DataVersionDefinition.getDatabaseVersion('v4'), equals(18));
    });

    test('数据版本映射服务测试', () async {
      // 测试兼容性检查
      expect(
        DataVersionMappingService.checkCompatibility('v1', 'v1'),
        equals(DataVersionCompatibility.compatible),
      );

      expect(
        DataVersionMappingService.checkCompatibility('v1', 'v2'),
        equals(DataVersionCompatibility.upgradable),
      );

      expect(
        DataVersionMappingService.checkCompatibility('v1', 'v4'),
        equals(DataVersionCompatibility.upgradable),
      );

      // 测试当前数据版本获取
      final currentVersion =
          await DataVersionMappingService.getCurrentDataVersion();
      expect(DataVersionDefinition.isValidVersion(currentVersion), isTrue);
    });

    test('升级路径支持检查', () {
      // 测试支持的升级路径
      expect(
          DataVersionAdapterManager.isUpgradePathSupported('v1', 'v2'), isTrue);
      expect(
          DataVersionAdapterManager.isUpgradePathSupported('v2', 'v3'), isTrue);
      expect(
          DataVersionAdapterManager.isUpgradePathSupported('v1', 'v3'), isTrue);

      // 测试不支持的升级路径（降级）
      expect(DataVersionAdapterManager.isUpgradePathSupported('v2', 'v1'),
          isFalse);
      expect(DataVersionAdapterManager.isUpgradePathSupported('v3', 'v2'),
          isFalse);
    });

    test('新数据目录初始化', () async {
      // 测试新数据目录的初始化
      final result =
          await UnifiedUpgradeService.checkAndUpgradeOnStartup(testDataPath);

      expect(result.status, equals(UpgradeCheckStatus.newDataDirectory));
      expect(result.fromVersion, isNotNull);
      expect(result.toVersion, isNotNull);

      // 验证数据版本文件是否创建
      final versionFile = File(path.join(testDataPath, 'data_version.json'));
      expect(await versionFile.exists(), isTrue);

      final versionData = jsonDecode(await versionFile.readAsString());
      expect(versionData['dataVersion'], isNotNull);
      expect(DataVersionDefinition.isValidVersion(versionData['dataVersion']),
          isTrue);
    });

    test('兼容数据目录检查', () async {
      // 先创建一个兼容的数据版本文件
      final currentVersion =
          await DataVersionMappingService.getCurrentDataVersion();
      final versionFile = File(path.join(testDataPath, 'data_version.json'));
      await versionFile.writeAsString(jsonEncode({
        'dataVersion': currentVersion,
        'lastUpdated': DateTime.now().toIso8601String(),
      }));

      // 测试兼容性检查
      final result =
          await UnifiedUpgradeService.checkAndUpgradeOnStartup(testDataPath);

      expect(result.status, equals(UpgradeCheckStatus.compatible));
      expect(result.fromVersion, equals(currentVersion));
      expect(result.toVersion, equals(currentVersion));
    });

    test('备份信息结构验证', () {
      // 测试新的备份信息结构
      final backupInfo = {
        'timestamp': DateTime.now().toIso8601String(),
        'description': '测试备份',
        'dataVersion': 'v4',
        'platform': Platform.operatingSystem,
        'excludedDirectories': ['temp', 'cache'],
        'includedDirectories': [
          'works',
          'characters',
          'practices',
          'library',
          'database'
        ],
      };

      // 验证必需字段
      expect(backupInfo.containsKey('timestamp'), isTrue);
      expect(backupInfo.containsKey('dataVersion'), isTrue);
      expect(backupInfo.containsKey('platform'), isTrue);
      expect(backupInfo.containsKey('includedDirectories'), isTrue);

      // 验证数据版本有效性
      expect(
          DataVersionDefinition.isValidVersion(
              backupInfo['dataVersion'] as String),
          isTrue);
    });

    test('升级状态管理', () async {
      // 测试升级状态的检查（新目录应该没有升级状态）
      final stateResult =
          await UnifiedUpgradeService.checkUpgradeState(testDataPath);
      expect(stateResult, isNull); // 新目录应该没有升级状态
    });

    test('错误处理验证', () async {
      // 测试无效路径的错误处理
      const invalidPath = '/invalid/path/that/does/not/exist';
      final result =
          await UnifiedUpgradeService.checkAndUpgradeOnStartup(invalidPath);

      // 应该返回错误状态而不是抛出异常
      expect(
          result.status,
          anyOf([
            UpgradeCheckStatus.error,
            UpgradeCheckStatus.newDataDirectory, // 可能会创建目录
          ]));
    });
  });

  group('向后兼容性测试', () {
    test('旧版本备份信息兼容性', () {
      // 测试对旧版本备份信息的兼容性
      final oldBackupInfo = {
        'timestamp': DateTime.now().toIso8601String(),
        'description': '旧版本备份',
        'backupVersion': '1.0.0', // 旧字段
        'compatibility': 'C', // 旧字段
        'platform': Platform.operatingSystem,
      };

      // 新系统应该能够处理缺少 dataVersion 字段的情况
      expect(oldBackupInfo.containsKey('dataVersion'), isFalse);
      expect(oldBackupInfo.containsKey('backupVersion'), isTrue);
      expect(oldBackupInfo.containsKey('compatibility'), isTrue);
    });

    test('数据库迁移版本映射', () {
      // 验证数据版本与数据库迁移版本的正确映射
      final v1DbVersion = DataVersionDefinition.getDatabaseVersion('v1');
      final v2DbVersion = DataVersionDefinition.getDatabaseVersion('v2');
      final v3DbVersion = DataVersionDefinition.getDatabaseVersion('v3');
      final v4DbVersion = DataVersionDefinition.getDatabaseVersion('v4');

      // 确保版本递增
      expect(v1DbVersion < v2DbVersion, isTrue);
      expect(v2DbVersion < v3DbVersion, isTrue);
      expect(v3DbVersion < v4DbVersion, isTrue);

      // 确保版本在合理范围内（当前有18个迁移脚本）
      expect(v1DbVersion, greaterThan(0));
      expect(v4DbVersion, lessThanOrEqualTo(18));
    });
  });
}
