import 'dart:typed_data';

import 'package:charasgem/application/repositories/practice_repository_impl.dart';
import 'package:charasgem/infrastructure/persistence/database_interface.dart';
import 'package:flutter_test/flutter_test.dart';

// 简单的内存数据库实现用于测试
class MockDatabase implements DatabaseInterface {
  final Map<String, Map<String, dynamic>> _data = {};

  @override
  Future<void> clear(String table) async {
    _data.removeWhere((key, value) => key.startsWith('${table}_'));
  }

  @override
  Future<void> close() async {}

  @override
  Future<int> count(String tableName, [Map<String, dynamic>? query]) async {
    return _data.length;
  }

  @override
  Future<void> delete(String tableName, String id) async {
    _data.remove('${tableName}_$id');
  }

  @override
  Future<void> deleteMany(String tableName, List<String> ids) async {
    for (final id in ids) {
      _data.remove('${tableName}_$id');
    }
  }

  @override
  Future<Map<String, dynamic>?> get(String tableName, String id) async {
    return _data['${tableName}_$id'];
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String tableName) async {
    return _data.entries
        .where((e) => e.key.startsWith('${tableName}_'))
        .map((e) => e.value)
        .toList();
  }

  @override
  Future<void> initialize() async {
    // Mock implementation - do nothing
  }

  @override
  Future<List<Map<String, dynamic>>> query(
      String tableName, Map<String, dynamic> queryParams) async {
    // 简单实现：返回所有匹配表名的数据
    return _data.entries
        .where((e) => e.key.startsWith('${tableName}_'))
        .map((e) => e.value)
        .toList();
  }

  @override
  Future<int> rawDelete(String sql, [List<Object?>? args]) async {
    // Mock implementation - return 1 indicating one row affected
    return 1;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<Object?>? args]) async {
    // Mock implementation - return empty list
    return [];
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? args]) async {
    // Mock implementation - return 1 indicating one row affected
    return 1;
  }

  @override
  Future<void> save(
      String tableName, String id, Map<String, dynamic> data) async {
    _data['${tableName}_$id'] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> saveMany(
      String tableName, Map<String, Map<String, dynamic>> dataMap) async {
    for (final entry in dataMap.entries) {
      _data['${tableName}_${entry.key}'] =
          Map<String, dynamic>.from(entry.value);
    }
  }

  @override
  Future<void> set(
      String tableName, String id, Map<String, dynamic> data) async {
    _data['${tableName}_$id'] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> setMany(
      String table, Map<String, Map<String, dynamic>> data) async {
    for (final entry in data.entries) {
      _data['${table}_${entry.key}'] = Map<String, dynamic>.from(entry.value);
    }
  }

  @override
  Future<void> update(
      String tableName, String id, Map<String, dynamic> data) async {
    final key = '${tableName}_$id';
    if (_data.containsKey(key)) {
      _data[key]!.addAll(data);
    }
  }
}

void main() {
  group('Practice Image Data Integration Test', () {
    late PracticeRepositoryImpl repository;

    setUp(() {
      final db = MockDatabase();
      repository = PracticeRepositoryImpl(db);
    });

    tearDown(() {
      repository.close();
    });

    test('should integrate image data management in practice save/load cycle',
        () async {
      // Arrange - 创建包含图像数据的字帖
      final pages = [
        {
          'id': 'page-1',
          'elements': [
            {
              'id': 'text-element-1',
              'type': 'text',
              'content': {'text': '普通文本元素'},
            },
            {
              'id': 'image-element-1',
              'type': 'image',
              'content': {
                'imageUrl': 'file://path/to/test.png',
                'rawImageData': Uint8List.fromList([10, 20, 30, 40, 50]),
                'transformedImageData': Uint8List.fromList([6, 7, 8, 9, 10]),
                'binarizedImageData': Uint8List.fromList([1, 2, 3, 4, 5]),
                'isBinarizationEnabled': true,
                'isTransformApplied': true,
                'binaryThreshold': 150,
                'cropX': 10.0,
                'cropY': 20.0,
                'fitMode': 'contain',
                'opacity': 0.8,
              },
            },
          ],
        },
      ];

      // Act - 保存字帖（应该应用智能图像数据管理）
      final result = await repository.savePracticeRaw(
        id: 'test-practice-123',
        title: '图像数据集成测试',
        pages: pages,
      );

      // Assert - 验证保存成功
      expect(result['id'], equals('test-practice-123'));
      expect(result['title'], equals('图像数据集成测试'));

      // Act - 加载字帖（应该应用智能图像数据恢复）
      final loadedPractice = await repository.loadPractice('test-practice-123');

      // Assert - 验证加载成功且数据完整
      expect(loadedPractice, isNotNull);
      expect(loadedPractice!['id'], equals('test-practice-123'));
      expect(loadedPractice['title'], equals('图像数据集成测试'));
      expect(loadedPractice['pages'], isA<List>());

      final loadedPages = loadedPractice['pages'] as List;
      expect(loadedPages.length, equals(1));

      final page = loadedPages[0] as Map<String, dynamic>;
      expect(page['elements'], isA<List>());

      final elements = page['elements'] as List;
      expect(elements.length, equals(2));

      // 验证文本元素未被修改
      final textElement = elements[0] as Map<String, dynamic>;
      expect(textElement['type'], equals('text'));
      expect(textElement['content']['text'], equals('普通文本元素'));

      // 验证图像元素应用了智能数据管理
      final imageElement = elements[1] as Map<String, dynamic>;
      expect(imageElement['type'], equals('image'));
      expect(imageElement['content'], isA<Map<String, dynamic>>());

      final imageContent = imageElement['content'] as Map<String, dynamic>;

      // Debug: 打印实际的imageContent内容
      print('DEBUG: imageContent keys: ${imageContent.keys.toList()}');
      print('DEBUG: isEditingMode = ${imageContent['isEditingMode']}');
      print(
          'DEBUG: canAdjustBinarization = ${imageContent['canAdjustBinarization']}');
      print(
          'DEBUG: binarizedImageData = ${imageContent['binarizedImageData']}');

      // 应该恢复了编辑能力
      expect(imageContent['isEditingMode'], isTrue);
      expect(imageContent['canAdjustBinarization'], isTrue);
      expect(imageContent['canRevertToOriginal'], isTrue);

      // 应该恢复了二值化数据和参数
      expect(imageContent['binarizedImageData'], isNotNull);
      expect(imageContent['isBinarizationEnabled'], isTrue);
      expect(imageContent['binaryThreshold'], equals(150));
      expect(imageContent['cropX'], equals(10.0));
      expect(imageContent['cropY'], equals(20.0));

      // UI属性应该保留
      expect(imageContent['fitMode'], equals('contain'));
      expect(imageContent['opacity'], equals(0.8));

      // 临时数据应该被清理
      expect(imageContent['finalImageData'], isNull);
      expect(imageContent['finalImageDataSource'], isNull);
      expect(imageContent['processingMetadata'], isNull);
    });

    test('should handle practice without image elements normally', () async {
      // Arrange - 创建不包含图像元素的字帖
      final pages = [
        {
          'id': 'page-1',
          'elements': [
            {
              'id': 'text-element-1',
              'type': 'text',
              'content': {'text': '第一个文本'},
            },
            {
              'id': 'text-element-2',
              'type': 'text',
              'content': {'text': '第二个文本'},
            },
          ],
        },
      ];

      // Act - 保存和加载
      await repository.savePracticeRaw(
        id: 'text-only-practice',
        title: '纯文本字帖',
        pages: pages,
      );

      final loadedPractice =
          await repository.loadPractice('text-only-practice');

      // Assert - 验证纯文本字帖正常工作
      expect(loadedPractice, isNotNull);
      expect(loadedPractice!['id'], equals('text-only-practice'));

      final loadedPages = loadedPractice['pages'] as List;
      final elements =
          (loadedPages[0] as Map<String, dynamic>)['elements'] as List;

      expect(elements.length, equals(2));
      expect(elements[0]['type'], equals('text'));
      expect(elements[1]['type'], equals('text'));
    });

    test('should gracefully handle errors in image data processing', () async {
      // Arrange - 创建包含异常图像数据的字帖
      final pages = [
        {
          'id': 'page-1',
          'elements': [
            {
              'id': 'image-element-error',
              'type': 'image',
              'content': {
                // 创建会导致处理错误的内容
                'rawImageData': 'invalid-data-type',
                'isBinarizationEnabled': 'not-a-boolean',
              },
            },
          ],
        },
      ];

      // Act & Assert - 应该能保存和加载，不抛出异常
      expect(() async {
        await repository.savePracticeRaw(
          id: 'error-test-practice',
          title: '错误处理测试',
          pages: pages,
        );

        final loadedPractice =
            await repository.loadPractice('error-test-practice');
        expect(loadedPractice, isNotNull);
      }, returnsNormally);
    });
  });
}
