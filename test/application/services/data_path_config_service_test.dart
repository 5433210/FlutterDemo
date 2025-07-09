import 'dart:convert';
import 'dart:io';

import 'package:charasgem/domain/models/config/data_path_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataPathConfig Model Tests', () {
    test('should create default config correctly', () {
      final config = DataPathConfig.defaultConfig();

      expect(config.useDefaultPath, isTrue);
      expect(config.customPath, isNull);
      expect(config.requiresRestart, isFalse);
    });

    test('should create custom path config correctly', () {
      const customPath = '/custom/path';
      final config = DataPathConfig.withCustomPath(customPath);

      expect(config.useDefaultPath, isFalse);
      expect(config.customPath, equals(customPath));
      expect(config.requiresRestart, isTrue);
    });

    test('should serialize and deserialize correctly', () {
      const customPath = '/custom/path';
      final originalConfig = DataPathConfig.withCustomPath(customPath);

      // 序列化
      final json = originalConfig.toJson();

      // 反序列化
      final deserializedConfig = DataPathConfig.fromJson(json);

      expect(deserializedConfig.useDefaultPath,
          equals(originalConfig.useDefaultPath));
      expect(deserializedConfig.customPath, equals(originalConfig.customPath));
      expect(deserializedConfig.requiresRestart,
          equals(originalConfig.requiresRestart));
    });

    test('should copy with modifications correctly', () {
      final originalConfig = DataPathConfig.defaultConfig();

      final modifiedConfig = originalConfig.copyWith(
        useDefaultPath: false,
        customPath: '/new/path',
        requiresRestart: true,
      );

      expect(modifiedConfig.useDefaultPath, isFalse);
      expect(modifiedConfig.customPath, equals('/new/path'));
      expect(modifiedConfig.requiresRestart, isTrue);

      // 原始配置应该保持不变
      expect(originalConfig.useDefaultPath, isTrue);
    });

    test('should handle equality correctly', () {
      final config1 = DataPathConfig.defaultConfig();
      final config2 = DataPathConfig.defaultConfig();
      final config3 = DataPathConfig.withCustomPath('/custom');

      expect(config1 == config2, isTrue);
      expect(config1 == config3, isFalse);
      expect(config1.hashCode == config2.hashCode, isTrue);
    });

    test('should return correct string representation', () {
      final config = DataPathConfig.withCustomPath('/test/path');
      final str = config.toString();

      expect(str, contains('DataPathConfig'));
      expect(str, contains('useDefaultPath: false'));
      expect(str, contains('customPath: /test/path'));
      expect(str, contains('requiresRestart: true'));
    });
  });

  group('File Operations Tests', () {
    late Directory testDir;

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp('data_path_test_');
    });

    tearDown(() async {
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('should write and read JSON config correctly', () async {
      final config = DataPathConfig.withCustomPath(testDir.path);
      final configFile = File(path.join(testDir.path, 'test_config.json'));

      // 写入配置
      await configFile.writeAsString(jsonEncode(config.toJson()));

      // 读取配置
      final content = await configFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final readConfig = DataPathConfig.fromJson(json);

      expect(readConfig.useDefaultPath, equals(config.useDefaultPath));
      expect(readConfig.customPath, equals(config.customPath));
      expect(readConfig.requiresRestart, equals(config.requiresRestart));
    });
  });
}
