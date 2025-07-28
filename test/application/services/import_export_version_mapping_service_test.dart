import 'package:charasgem/application/services/import_export_version_mapping_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportExportVersionMappingService', () {
    group('Application Version Mapping', () {
      test('should map application versions to data versions correctly', () {
        expect(ImportExportVersionMappingService.getDataVersionForApp('1.0.0'),
            equals('ie_v1'));
        expect(ImportExportVersionMappingService.getDataVersionForApp('1.1.0'),
            equals('ie_v2'));
        expect(ImportExportVersionMappingService.getDataVersionForApp('1.2.0'),
            equals('ie_v3'));
        expect(ImportExportVersionMappingService.getDataVersionForApp('1.3.0'),
            equals('ie_v4'));
      });

      test('should return latest version for unknown app versions', () {
        expect(ImportExportVersionMappingService.getDataVersionForApp('2.0.0'),
            equals('ie_v4'));
        expect(ImportExportVersionMappingService.getDataVersionForApp('0.9.0'),
            equals('ie_v1'));
      });

      test('should handle invalid version strings', () {
        expect(
            ImportExportVersionMappingService.getDataVersionForApp('invalid'),
            equals('ie_v1'));
        expect(ImportExportVersionMappingService.getDataVersionForApp(''),
            equals('ie_v1'));
      });
    });

    group('Database Version Mapping', () {
      test('should map database versions to data versions correctly', () {
        expect(ImportExportVersionMappingService.getDataVersionForDatabase(1),
            equals('ie_v1'));
        expect(ImportExportVersionMappingService.getDataVersionForDatabase(3),
            equals('ie_v2'));
        expect(ImportExportVersionMappingService.getDataVersionForDatabase(5),
            equals('ie_v3'));
        expect(ImportExportVersionMappingService.getDataVersionForDatabase(7),
            equals('ie_v4'));
      });

      test('should return appropriate version for edge cases', () {
        expect(ImportExportVersionMappingService.getDataVersionForDatabase(0),
            equals('ie_v1'));
        expect(ImportExportVersionMappingService.getDataVersionForDatabase(100),
            equals('ie_v4'));
      });
    });

    group('Compatibility Checking', () {
      test('should check compatibility between data versions correctly', () {
        // 相同版本应该兼容
        expect(
          ImportExportVersionMappingService.checkCompatibility(
              'ie_v4', 'ie_v4'),
          equals(ImportExportCompatibility.compatible),
        );

        // 旧版本到新版本应该可升级
        expect(
          ImportExportVersionMappingService.checkCompatibility(
              'ie_v1', 'ie_v4'),
          equals(ImportExportCompatibility.upgradable),
        );
        expect(
          ImportExportVersionMappingService.checkCompatibility(
              'ie_v2', 'ie_v4'),
          equals(ImportExportCompatibility.upgradable),
        );
        expect(
          ImportExportVersionMappingService.checkCompatibility(
              'ie_v3', 'ie_v4'),
          equals(ImportExportCompatibility.upgradable),
        );

        // 新版本到旧版本需要升级应用
        expect(
          ImportExportVersionMappingService.checkCompatibility(
              'ie_v4', 'ie_v1'),
          equals(ImportExportCompatibility.appUpgradeRequired),
        );
      });

      test('should handle invalid version combinations', () {
        expect(
          ImportExportVersionMappingService.checkCompatibility(
              'invalid', 'ie_v4'),
          equals(ImportExportCompatibility.incompatible),
        );
        expect(
          ImportExportVersionMappingService.checkCompatibility(
              'ie_v4', 'invalid'),
          equals(ImportExportCompatibility.incompatible),
        );
      });
    });

    group('Export Compatibility', () {
      test('should check export compatibility with app versions', () {
        // ie_v4 导出文件与 1.3.0 应用兼容
        expect(
          ImportExportVersionMappingService.checkExportCompatibility(
              'ie_v4', '1.3.0'),
          equals(ImportExportCompatibility.compatible),
        );

        // ie_v1 导出文件与 1.3.0 应用可升级
        expect(
          ImportExportVersionMappingService.checkExportCompatibility(
              'ie_v1', '1.3.0'),
          equals(ImportExportCompatibility.upgradable),
        );

        // ie_v4 导出文件与 1.0.0 应用需要升级应用
        expect(
          ImportExportVersionMappingService.checkExportCompatibility(
              'ie_v4', '1.0.0'),
          equals(ImportExportCompatibility.appUpgradeRequired),
        );
      });
    });

    group('Upgrade Suggestions', () {
      test('should provide meaningful upgrade suggestions', () {
        final suggestion1 =
            ImportExportVersionMappingService.getUpgradeSuggestion(
                'ie_v1', 'ie_v4');
        expect(suggestion1, contains('ie_v1'));
        expect(suggestion1, contains('ie_v4'));
        expect(suggestion1, isNotEmpty);

        final suggestion2 =
            ImportExportVersionMappingService.getUpgradeSuggestion(
                'ie_v2', 'ie_v3');
        expect(suggestion2, contains('ie_v2'));
        expect(suggestion2, contains('ie_v3'));
        expect(suggestion2, isNotEmpty);

        final suggestion3 =
            ImportExportVersionMappingService.getUpgradeSuggestion(
                'ie_v4', 'ie_v4');
        expect(suggestion3, contains('兼容'));
      });
    });

    group('Compatibility Descriptions', () {
      test('should provide descriptions for all compatibility types', () {
        final compatible =
            ImportExportVersionMappingService.getCompatibilityDescription(
          ImportExportCompatibility.compatible,
        );
        expect(compatible, isNotEmpty);
        expect(compatible, contains('兼容'));

        final upgradable =
            ImportExportVersionMappingService.getCompatibilityDescription(
          ImportExportCompatibility.upgradable,
        );
        expect(upgradable, isNotEmpty);
        expect(upgradable, contains('升级'));

        final appUpgrade =
            ImportExportVersionMappingService.getCompatibilityDescription(
          ImportExportCompatibility.appUpgradeRequired,
        );
        expect(appUpgrade, isNotEmpty);
        expect(appUpgrade, contains('应用'));

        final incompatible =
            ImportExportVersionMappingService.getCompatibilityDescription(
          ImportExportCompatibility.incompatible,
        );
        expect(incompatible, isNotEmpty);
        expect(incompatible, contains('不兼容'));
      });
    });

    group('Utility Methods', () {
      test('should return all supported data versions', () {
        final versions =
            ImportExportVersionMappingService.getAllSupportedDataVersions();

        expect(versions, isNotEmpty);
        expect(versions, contains('ie_v1'));
        expect(versions, contains('ie_v2'));
        expect(versions, contains('ie_v3'));
        expect(versions, contains('ie_v4'));
        expect(versions.length, equals(4));
      });

      test('should return version mapping information', () {
        final mappingInfo =
            ImportExportVersionMappingService.getVersionMappingInfo();

        expect(mappingInfo, isNotEmpty);
        expect(mappingInfo.containsKey('appVersionMapping'), isTrue);
        expect(mappingInfo.containsKey('databaseVersionMapping'), isTrue);
        expect(mappingInfo.containsKey('compatibilityMatrix'), isTrue);

        final appMapping = mappingInfo['appVersionMapping'] as Map;
        expect(appMapping, isNotEmpty);
        expect(appMapping.containsKey('1.0.0'), isTrue);
        expect(appMapping.containsKey('1.3.0'), isTrue);

        final dbMapping = mappingInfo['databaseVersionMapping'] as Map;
        expect(dbMapping, isNotEmpty);

        final compatMatrix = mappingInfo['compatibilityMatrix'] as Map;
        expect(compatMatrix, isNotEmpty);
        expect(compatMatrix.containsKey('ie_v4'), isTrue);
      });

      test('should validate mapping consistency', () {
        final isConsistent =
            ImportExportVersionMappingService.validateMappingConsistency();
        expect(isConsistent, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle null and empty inputs gracefully', () {
        expect(
          ImportExportVersionMappingService.checkCompatibility('', ''),
          equals(ImportExportCompatibility.incompatible),
        );

        expect(
          ImportExportVersionMappingService.getUpgradeSuggestion('', ''),
          isNotEmpty,
        );
      });

      test('should handle version comparison edge cases', () {
        // 测试版本比较的边界情况
        expect(
          ImportExportVersionMappingService.checkCompatibility(
              'ie_v1', 'ie_v1'),
          equals(ImportExportCompatibility.compatible),
        );

        expect(
          ImportExportVersionMappingService.checkCompatibility(
              'ie_v2', 'ie_v1'),
          equals(ImportExportCompatibility.appUpgradeRequired),
        );
      });

      test('should maintain consistency across different methods', () {
        // 确保不同方法之间的一致性
        const appVersion = '1.2.0';
        final dataVersion =
            ImportExportVersionMappingService.getDataVersionForApp(appVersion);

        expect(dataVersion, equals('ie_v3'));

        final compatibility =
            ImportExportVersionMappingService.checkExportCompatibility(
          dataVersion,
          appVersion,
        );

        expect(compatibility, equals(ImportExportCompatibility.compatible));
      });
    });

    group('Performance Tests', () {
      test('should perform version lookups efficiently', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          ImportExportVersionMappingService.getDataVersionForApp('1.3.0');
          ImportExportVersionMappingService.checkCompatibility(
              'ie_v1', 'ie_v4');
        }

        stopwatch.stop();

        // 1000次操作应该在100ms内完成
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
