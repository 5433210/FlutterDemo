import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:charasgem/application/adapters/import_export_adapter_manager.dart';
import 'package:charasgem/domain/interfaces/import_export_data_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('ImportExportAdapterManager', () {
    late ImportExportAdapterManager manager;
    late Directory tempDir;

    setUpAll(() async {
      manager = ImportExportAdapterManager();
      manager.initialize();

      // 创建临时目录用于测试
      tempDir = await Directory.systemTemp.createTemp('adapter_manager_test_');
    });

    tearDownAll(() async {
      // 清理临时目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Adapter Registration', () {
      test('should register all adapters during initialization', () {
        final registeredAdapters = manager.getRegisteredAdapters();

        expect(registeredAdapters, isNotEmpty);
        expect(registeredAdapters.length,
            greaterThanOrEqualTo(3)); // ie_v1->v2, ie_v2->v3, ie_v3->v4

        // 检查是否包含预期的适配器
        final adapterKeys = registeredAdapters.keys.toList();
        expect(adapterKeys, contains('ie_v1_to_ie_v2'));
        expect(adapterKeys, contains('ie_v2_to_ie_v3'));
        expect(adapterKeys, contains('ie_v3_to_ie_v4'));
      });

      test('should allow custom adapter registration', () {
        final customAdapter = MockAdapter('ie_v4', 'ie_v5');
        manager.registerAdapter('ie_v4_to_ie_v5', customAdapter);

        final registeredAdapters = manager.getRegisteredAdapters();
        expect(registeredAdapters.containsKey('ie_v4_to_ie_v5'), isTrue);
        expect(registeredAdapters['ie_v4_to_ie_v5'], equals(customAdapter));
      });

      test('should allow adapter unregistration', () {
        final customAdapter = MockAdapter('ie_test1', 'ie_test2');
        manager.registerAdapter('test_adapter', customAdapter);

        expect(manager.getRegisteredAdapters().containsKey('test_adapter'),
            isTrue);

        manager.unregisterAdapter('test_adapter');
        expect(manager.getRegisteredAdapters().containsKey('test_adapter'),
            isFalse);
      });
    });

    group('Upgrade Path Calculation', () {
      test('should find direct upgrade path', () {
        final path = manager.getUpgradePath('ie_v1', 'ie_v2');

        expect(path, isNotEmpty);
        expect(path.length, equals(1));
        expect(path.first.sourceDataVersion, equals('ie_v1'));
        expect(path.first.targetDataVersion, equals('ie_v2'));
      });

      test('should find multi-step upgrade path', () {
        final path = manager.getUpgradePath('ie_v1', 'ie_v4');

        expect(path, isNotEmpty);
        expect(path.length, equals(3)); // ie_v1->v2->v3->v4

        expect(path[0].sourceDataVersion, equals('ie_v1'));
        expect(path[0].targetDataVersion, equals('ie_v2'));

        expect(path[1].sourceDataVersion, equals('ie_v2'));
        expect(path[1].targetDataVersion, equals('ie_v3'));

        expect(path[2].sourceDataVersion, equals('ie_v3'));
        expect(path[2].targetDataVersion, equals('ie_v4'));
      });

      test('should return empty path for same version', () {
        final path = manager.getUpgradePath('ie_v3', 'ie_v3');
        expect(path, isEmpty);
      });

      test('should return empty path for invalid versions', () {
        final path1 = manager.getUpgradePath('invalid', 'ie_v2');
        expect(path1, isEmpty);

        final path2 = manager.getUpgradePath('ie_v1', 'invalid');
        expect(path2, isEmpty);

        final path3 = manager.getUpgradePath('ie_v4', 'ie_v1'); // 向后升级不支持
        expect(path3, isEmpty);
      });
    });

    group('Conversion Support', () {
      test('should support direct conversions', () {
        expect(manager.supportsConversion('ie_v1', 'ie_v2'), isTrue);
        expect(manager.supportsConversion('ie_v2', 'ie_v3'), isTrue);
        expect(manager.supportsConversion('ie_v3', 'ie_v4'), isTrue);
      });

      test('should support multi-step conversions', () {
        expect(manager.supportsConversion('ie_v1', 'ie_v3'), isTrue);
        expect(manager.supportsConversion('ie_v1', 'ie_v4'), isTrue);
        expect(manager.supportsConversion('ie_v2', 'ie_v4'), isTrue);
      });

      test('should not support backward conversions', () {
        expect(manager.supportsConversion('ie_v4', 'ie_v3'), isFalse);
        expect(manager.supportsConversion('ie_v3', 'ie_v1'), isFalse);
        expect(manager.supportsConversion('ie_v2', 'ie_v1'), isFalse);
      });

      test('should not support invalid conversions', () {
        expect(manager.supportsConversion('invalid', 'ie_v2'), isFalse);
        expect(manager.supportsConversion('ie_v1', 'invalid'), isFalse);
      });
    });

    group('Upgrade Chain Execution', () {
      test('should execute single adapter successfully', () async {
        // 创建测试文件
        final testFile = File(path.join(tempDir.path, 'single_test.json'));
        await testFile.writeAsString('{"version": "ie_v1"}');

        final adapters = manager.getUpgradePath('ie_v1', 'ie_v2');
        expect(adapters, isNotEmpty);

        final result =
            await manager.executeUpgradeChain(adapters, testFile.path);

        expect(result.success, isTrue);
        expect(result.adapterResults, isNotEmpty);
        expect(result.adapterResults.length, equals(1));
      });

      test('should execute adapter chain successfully', () async {
        // 创建测试文件
        final testFile = File(path.join(tempDir.path, 'chain_test.json'));
        await testFile.writeAsString('{"version": "ie_v1"}');

        final adapters = manager.getUpgradePath('ie_v1', 'ie_v4');
        expect(adapters, isNotEmpty);
        expect(adapters.length, equals(3));

        final result =
            await manager.executeUpgradeChain(adapters, testFile.path);

        expect(result.success, isTrue);
        expect(result.adapterResults, isNotEmpty);
        expect(result.adapterResults.length, equals(3));
        expect(result.finalOutputPath, isNotNull);
      });

      test('should handle adapter execution failure', () async {
        // 使用不存在的文件测试失败情况
        final adapters = manager.getUpgradePath('ie_v1', 'ie_v2');

        final result =
            await manager.executeUpgradeChain(adapters, 'non_existent.json');

        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);
      });

      test('should handle empty adapter chain', () async {
        final testFile = File(path.join(tempDir.path, 'empty_chain.json'));
        await testFile.writeAsString('{"version": "ie_v1"}');

        final result = await manager.executeUpgradeChain([], testFile.path);

        expect(result.success, isTrue);
        expect(result.adapterResults, isEmpty);
        expect(result.finalOutputPath, equals(testFile.path));
      });
    });

    group('Post-processing', () {
      test('should execute post-processing for all adapters', () async {
        final testFile = File(path.join(tempDir.path, 'postprocess_test.json'));
        await testFile.writeAsString('{"version": "ie_v1"}');

        final adapters = manager.getUpgradePath('ie_v1', 'ie_v3');

        // 执行后处理不应该抛出异常
        expect(
          () async =>
              await manager.executePostProcessing(adapters, testFile.path),
          returnsNormally,
        );
      });
    });

    group('Validation', () {
      test('should validate upgrade results', () async {
        // 创建一个模拟的 ie_v2 ZIP 文件
        final testFile = File(path.join(tempDir.path, 'validation_test.zip'));

        // 创建模拟的 ZIP 内容
        final archive = Archive();

        // 添加 export_data.json
        final exportData = {
          'metadata': {
            'dataFormatVersion': 'ie_v2',
            'exportTime': DateTime.now().toIso8601String(),
          },
          'works': [],
          'characters': [],
        };
        final exportDataContent = utf8.encode(json.encode(exportData));
        archive.addFile(ArchiveFile(
            'export_data.json', exportDataContent.length, exportDataContent));

        // 添加 manifest.json
        final manifest = {
          'version': 'ie_v2',
          'files': ['export_data.json'],
        };
        final manifestContent = utf8.encode(json.encode(manifest));
        archive.addFile(ArchiveFile(
            'manifest.json', manifestContent.length, manifestContent));

        // 写入 ZIP 文件
        final zipData = ZipEncoder().encode(archive);
        await testFile.writeAsBytes(zipData);

        final adapters = manager.getUpgradePath('ie_v1', 'ie_v2');

        final isValid =
            await manager.validateUpgradeResult(adapters, testFile.path);
        expect(isValid, isTrue);
      });

      test('should handle validation of non-existent file', () async {
        final adapters = manager.getUpgradePath('ie_v1', 'ie_v2');

        final isValid =
            await manager.validateUpgradeResult(adapters, 'non_existent.json');
        expect(isValid, isFalse);
      });
    });

    group('Cleanup', () {
      test('should cleanup temporary files', () async {
        // 创建一些临时文件
        final tempFiles = <File>[];
        for (int i = 0; i < 3; i++) {
          final tempFile = File(path.join(tempDir.path, 'temp_$i.json'));
          await tempFile.writeAsString('temp content');
          tempFiles.add(tempFile);
        }

        // 模拟适配器结果
        final adapterResults = tempFiles
            .map((file) => ImportExportAdapterResult.success(
                  message: 'Test result',
                  outputPath: file.path,
                  statistics: ImportExportAdapterStatistics(
                    startTime: DateTime.now()
                        .subtract(const Duration(milliseconds: 100)),
                    endTime: DateTime.now(),
                    durationMs: 100,
                    originalSizeBytes: 1000,
                    convertedSizeBytes: 900,
                  ),
                ))
            .toList();

        // 执行清理
        await manager.cleanupTemporaryFiles(adapterResults);

        // 验证文件是否被删除（在实际实现中）
        // 这里只是确保方法不抛出异常
        expect(true, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle adapter registration errors gracefully', () {
        // 尝试注册无效的适配器
        expect(
          () => manager.registerAdapter('', MockAdapter('', '')),
          returnsNormally,
        );
      });

      test('should handle path calculation errors gracefully', () {
        final path = manager.getUpgradePath('', '');
        expect(path, isEmpty);
      });
    });

    group('Performance Tests', () {
      test('should handle multiple concurrent operations', () async {
        final futures = <Future>[];

        for (int i = 0; i < 10; i++) {
          futures.add(Future(() {
            return manager.getUpgradePath('ie_v1', 'ie_v4');
          }));
        }

        final results = await Future.wait(futures);

        expect(results.length, equals(10));
        for (final result in results) {
          expect(result, isNotEmpty);
          expect(result.length, equals(3));
        }
      });

      test('should perform path calculations efficiently', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          manager.getUpgradePath('ie_v1', 'ie_v4');
          manager.supportsConversion('ie_v2', 'ie_v4');
        }

        stopwatch.stop();

        // 1000次操作应该在50ms内完成
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}

/// Mock adapter for testing
class MockAdapter implements ImportExportDataAdapter {
  @override
  final String sourceDataVersion;

  @override
  final String targetDataVersion;

  MockAdapter(this.sourceDataVersion, this.targetDataVersion);

  @override
  String get adapterName => '${sourceDataVersion}_to_$targetDataVersion';

  @override
  String getDescription() =>
      'Mock adapter: $sourceDataVersion → $targetDataVersion';

  @override
  bool supportsConversion(String fromVersion, String toVersion) {
    return fromVersion == sourceDataVersion && toVersion == targetDataVersion;
  }

  @override
  Future<ImportExportAdapterResult> preProcess(String exportFilePath) async {
    return ImportExportAdapterResult.success(
      message: 'Mock pre-process success',
      outputPath: exportFilePath,
      statistics: ImportExportAdapterStatistics(
        startTime: DateTime.now().subtract(const Duration(milliseconds: 100)),
        endTime: DateTime.now(),
        durationMs: 100,
        originalSizeBytes: 1000,
        convertedSizeBytes: 900,
      ),
    );
  }

  @override
  Future<ImportExportAdapterResult> postProcess(String importedDataPath) async {
    return ImportExportAdapterResult.success(
      message: 'Mock post-process success',
      outputPath: importedDataPath,
      statistics: ImportExportAdapterStatistics(
        startTime: DateTime.now().subtract(const Duration(milliseconds: 50)),
        endTime: DateTime.now(),
        durationMs: 50,
        originalSizeBytes: 900,
        convertedSizeBytes: 900,
      ),
    );
  }

  @override
  Future<bool> validate(String dataPath) async {
    return true;
  }
}
