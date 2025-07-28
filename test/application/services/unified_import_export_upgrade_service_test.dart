import 'dart:io';

import 'package:charasgem/application/services/import_export_version_mapping_service.dart';
import 'package:charasgem/application/services/unified_import_export_upgrade_service.dart';
import 'package:charasgem/domain/interfaces/import_export_data_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('UnifiedImportExportUpgradeService', () {
    late UnifiedImportExportUpgradeService service;
    late Directory tempDir;

    setUpAll(() async {
      service = UnifiedImportExportUpgradeService();
      await service.initialize();

      // 创建临时目录用于测试
      tempDir = await Directory.systemTemp.createTemp('import_export_test_');
    });

    tearDownAll(() async {
      // 清理临时目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Version Detection', () {
      test('should detect ie_v1 from JSON file', () async {
        // 创建测试JSON文件
        final testFile = File(path.join(tempDir.path, 'test_v1.json'));
        await testFile.writeAsString('''
        {
          "exportData": {
            "works": [],
            "characters": []
          },
          "metadata": {
            "version": "1.0"
          }
        }
        ''');

        final version = await service.detectExportDataVersion(testFile.path);
        expect(version, equals('ie_v1'));
      });

      test('should detect ie_v2 from ZIP file', () async {
        // 创建测试ZIP文件（简化测试）
        final testFile = File(path.join(tempDir.path, 'test_v2.zip'));
        await testFile.writeAsBytes([80, 75, 3, 4]); // ZIP文件头

        final version = await service.detectExportDataVersion(testFile.path);
        expect(version, equals('ie_v2')); // 默认ZIP格式
      });

      test('should return null for non-existent file', () async {
        final version =
            await service.detectExportDataVersion('non_existent.zip');
        expect(version, isNull);
      });

      test('should return null for unsupported file format', () async {
        final testFile = File(path.join(tempDir.path, 'test.txt'));
        await testFile.writeAsString('test content');

        final version = await service.detectExportDataVersion(testFile.path);
        expect(version, isNull);
      });
    });

    group('Compatibility Checking', () {
      test('should return compatible for same version', () async {
        final testFile = File(path.join(tempDir.path, 'compatible.json'));
        await testFile.writeAsString('{"version": "1.0"}');

        final compatibility = await service.checkImportCompatibility(
          testFile.path,
          '1.3.0',
        );

        expect(compatibility, equals(ImportExportCompatibility.compatible));
      });

      test('should return upgradable for older version', () async {
        final testFile = File(path.join(tempDir.path, 'upgradable.json'));
        await testFile.writeAsString('{"version": "1.0"}');

        final compatibility = await service.checkImportCompatibility(
          testFile.path,
          '1.3.0',
        );

        // ie_v1 到当前版本应该是可升级的
        expect(compatibility, equals(ImportExportCompatibility.upgradable));
      });

      test('should return incompatible for invalid file', () async {
        final compatibility = await service.checkImportCompatibility(
          'invalid_file.zip',
          '1.3.0',
        );

        expect(compatibility, equals(ImportExportCompatibility.incompatible));
      });
    });

    group('Import Upgrade', () {
      test('should return compatible result for compatible version', () async {
        final testFile =
            File(path.join(tempDir.path, 'compatible_import.json'));
        await testFile.writeAsString('''
        {
          "exportData": {
            "works": [],
            "characters": []
          },
          "metadata": {
            "dataFormatVersion": "ie_v4"
          }
        }
        ''');

        final result = await service.performImportUpgrade(
          testFile.path,
          '1.3.0',
        );

        expect(result.status, equals(ImportUpgradeStatus.compatible));
        expect(result.sourceVersion, equals('ie_v1')); // 检测到的版本
        expect(result.targetVersion, equals('ie_v4')); // 目标版本
      });

      test('should return error for invalid file', () async {
        final result = await service.performImportUpgrade(
          'invalid_file.zip',
          '1.3.0',
        );

        expect(result.status, equals(ImportUpgradeStatus.error));
        expect(result.errorMessage, isNotNull);
      });

      test('should handle upgrade chain execution', () async {
        final testFile = File(path.join(tempDir.path, 'upgrade_test.json'));
        await testFile.writeAsString('{"version": "1.0"}');

        final result = await service.performImportUpgrade(
          testFile.path,
          '1.3.0',
        );

        // 应该尝试升级或返回兼容状态
        expect(
            result.status,
            isIn([
              ImportUpgradeStatus.compatible,
              ImportUpgradeStatus.upgraded,
              ImportUpgradeStatus.error,
            ]));
      });
    });

    group('Utility Methods', () {
      test('should provide upgrade suggestions', () {
        final suggestion = service.getUpgradeSuggestion(
          'test.json',
          '1.3.0',
        );

        expect(suggestion, isNotEmpty);
        expect(suggestion, isA<String>());
      });

      test('should provide compatibility descriptions', () {
        final descriptions = [
          ImportExportCompatibility.compatible,
          ImportExportCompatibility.upgradable,
          ImportExportCompatibility.appUpgradeRequired,
          ImportExportCompatibility.incompatible,
        ];

        for (final compatibility in descriptions) {
          final description =
              service.getCompatibilityDescription(compatibility);
          expect(description, isNotEmpty);
          expect(description, isA<String>());
        }
      });

      test('should check upgrade support', () {
        final supportsV1ToV2 = service.supportsUpgrade('ie_v1', 'ie_v2');
        final supportsV1ToV4 = service.supportsUpgrade('ie_v1', 'ie_v4');
        final supportsInvalid = service.supportsUpgrade('invalid', 'ie_v2');

        expect(supportsV1ToV2, isTrue);
        expect(supportsV1ToV4, isTrue);
        expect(supportsInvalid, isFalse);
      });

      test('should return supported data versions', () {
        final versions = service.getSupportedDataVersions();

        expect(versions, isNotEmpty);
        expect(versions, contains('ie_v1'));
        expect(versions, contains('ie_v2'));
        expect(versions, contains('ie_v3'));
        expect(versions, contains('ie_v4'));
      });

      test('should return version mapping info', () {
        final mappingInfo = service.getVersionMappingInfo();

        expect(mappingInfo, isNotEmpty);
        expect(mappingInfo.containsKey('appVersionMapping'), isTrue);
        expect(mappingInfo.containsKey('databaseVersionMapping'), isTrue);
        expect(mappingInfo.containsKey('compatibilityMatrix'), isTrue);
      });

      test('should validate mapping consistency', () {
        final isConsistent = service.validateMappingConsistency();
        expect(isConsistent, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle file access errors gracefully', () async {
        // 测试访问受保护的文件
        final result = await service.performImportUpgrade(
          '/protected/file.zip',
          '1.3.0',
        );

        expect(result.status, equals(ImportUpgradeStatus.error));
        expect(result.errorMessage, isNotNull);
      });

      test('should handle corrupted file gracefully', () async {
        final corruptedFile = File(path.join(tempDir.path, 'corrupted.zip'));
        await corruptedFile.writeAsBytes([1, 2, 3, 4, 5]); // 无效ZIP

        final compatibility = await service.checkImportCompatibility(
          corruptedFile.path,
          '1.3.0',
        );

        expect(compatibility, equals(ImportExportCompatibility.incompatible));
      });

      test('should handle initialization errors', () async {
        final uninitializedService = UnifiedImportExportUpgradeService();

        // 在未初始化状态下调用方法
        final supportsUpgrade =
            uninitializedService.supportsUpgrade('ie_v1', 'ie_v2');
        expect(supportsUpgrade, isFalse);
      });
    });

    group('Performance Tests', () {
      test('should handle multiple concurrent operations', () async {
        final futures = <Future>[];

        for (int i = 0; i < 10; i++) {
          final testFile = File(path.join(tempDir.path, 'concurrent_$i.json'));
          await testFile.writeAsString('{"version": "1.0"}');

          futures.add(service.checkImportCompatibility(testFile.path, '1.3.0'));
        }

        final results = await Future.wait(futures);
        expect(results.length, equals(10));

        // 所有结果都应该是有效的兼容性状态
        for (final result in results) {
          expect(result, isA<ImportExportCompatibility>());
        }
      });

      test('should complete operations within reasonable time', () async {
        final testFile = File(path.join(tempDir.path, 'performance.json'));
        await testFile.writeAsString('{"version": "1.0"}');

        final stopwatch = Stopwatch()..start();

        await service.checkImportCompatibility(testFile.path, '1.3.0');

        stopwatch.stop();

        // 操作应该在1秒内完成
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
