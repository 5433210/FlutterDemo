import 'package:test/test.dart';
import '../lib/domain/models/compatibility/version_compatibility.dart';
import '../lib/application/services/compatibility/version_compatibility_service.dart';

void main() {
  group('版本兼容性测试', () {
    late VersionCompatibilityService service;

    setUp(() {
      service = VersionCompatibilityService();
    });

    test('版本兼容性信息创建和序列化', () {
      final now = DateTime.now();
      final migrationStep = MigrationStep(
        title: '测试迁移步骤',
        description: '这是一个测试迁移步骤',
        isRequired: true,
        estimatedMinutes: 10,
      );

      final compatibilityInfo = VersionCompatibilityInfo(
        version: '1.0.0',
        minCompatibleVersion: '1.0.0',
        maxCompatibleVersion: '2.0.0',
        apiCompatibility: CompatibilityLevel.full,
        dataCompatibility: CompatibilityLevel.full,
        description: '测试版本',
        incompatibleFeatures: ['feature1'],
        migrationSteps: [migrationStep],
        createdAt: now,
        updatedAt: now,
      );

      // 测试序列化
      final map = compatibilityInfo.toMap();
      expect(map['version'], equals('1.0.0'));
      expect(map['apiCompatibility'], equals('full'));

      // 测试反序列化
      final restored = VersionCompatibilityInfo.fromMap(map);
      expect(restored.version, equals('1.0.0'));
      expect(restored.apiCompatibility, equals(CompatibilityLevel.full));
      expect(restored.migrationSteps.length, equals(1));
    });

    test('版本比较功能', () {
      final compatibilityInfo = VersionCompatibilityInfo(
        version: '2.0.0',
        minCompatibleVersion: '1.5.0',
        maxCompatibleVersion: '3.0.0',
        apiCompatibility: CompatibilityLevel.full,
        dataCompatibility: CompatibilityLevel.full,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 测试兼容性检查
      expect(compatibilityInfo.isCompatibleWith('1.8.0'), isTrue);
      expect(compatibilityInfo.isCompatibleWith('2.5.0'), isTrue);
      expect(compatibilityInfo.isCompatibleWith('1.4.0'), isFalse);
      expect(compatibilityInfo.isCompatibleWith('3.1.0'), isFalse);
    });

    test('兼容性报告生成', () {
      final compatibilityInfo = VersionCompatibilityInfo(
        version: '2.0.0',
        minCompatibleVersion: '1.5.0',
        apiCompatibility: CompatibilityLevel.partial,
        dataCompatibility: CompatibilityLevel.full,
        incompatibleFeatures: ['oldApi'],
        migrationSteps: [
          MigrationStep(
            title: '更新API',
            description: '更新到新API',
            isRequired: true,
            estimatedMinutes: 30,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final report = compatibilityInfo.getCompatibilityReport('1.8.0');
      
      expect(report.sourceVersion, equals('2.0.0'));
      expect(report.targetVersion, equals('1.8.0'));
      expect(report.isCompatible, isTrue);
      expect(report.overallCompatibility, equals(CompatibilityLevel.partial));
      expect(report.requiredMigrationSteps.length, equals(1));
      expect(report.estimatedMigrationTime, equals(30));
    });

    test('兼容性级别枚举', () {
      expect(CompatibilityLevel.fromString('full'), equals(CompatibilityLevel.full));
      expect(CompatibilityLevel.fromString('partial'), equals(CompatibilityLevel.partial));
      expect(CompatibilityLevel.fromString('incompatible'), equals(CompatibilityLevel.incompatible));
      expect(CompatibilityLevel.fromString('unknown'), equals(CompatibilityLevel.unknown));
      expect(CompatibilityLevel.fromString('invalid'), equals(CompatibilityLevel.unknown));

      expect(CompatibilityLevel.full.displayName, equals('完全兼容'));
      expect(CompatibilityLevel.partial.displayName, equals('部分兼容'));
      expect(CompatibilityLevel.incompatible.displayName, equals('不兼容'));
      expect(CompatibilityLevel.unknown.displayName, equals('未知'));
    });

    test('迁移步骤', () {
      final step = MigrationStep(
        title: '数据库迁移',
        description: '迁移数据库模式',
        isRequired: true,
        estimatedMinutes: 15,
        documentationUrl: 'https://docs.example.com',
      );

      final map = step.toMap();
      expect(map['title'], equals('数据库迁移'));
      expect(map['isRequired'], isTrue);
      expect(map['estimatedMinutes'], equals(15));

      final restored = MigrationStep.fromMap(map);
      expect(restored.title, equals('数据库迁移'));
      expect(restored.isRequired, isTrue);
      expect(restored.estimatedMinutes, equals(15));
    });

    test('版本兼容性服务基础功能', () async {
      // 测试加载配置
      await service.loadCompatibilityConfig();
      
      // 测试检查兼容性（应该找到默认的1.0.0版本）
      final report = await service.checkVersionCompatibility('1.0.0', '1.0.0');
      expect(report.isCompatible, isTrue);
      expect(report.sourceVersion, equals('1.0.0'));
      expect(report.targetVersion, equals('1.0.0'));
      
      // 测试未知版本
      final unknownReport = await service.checkVersionCompatibility('999.0.0', '1.0.0');
      expect(unknownReport.isCompatible, isFalse);
      expect(unknownReport.apiCompatibility, equals(CompatibilityLevel.unknown));
    });
  });
} 