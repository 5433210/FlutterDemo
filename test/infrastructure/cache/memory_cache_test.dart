import 'package:charasgem/infrastructure/cache/implementations/memory_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryCache', () {
    late MemoryCache<String, String> cache;

    setUp(() {
      cache = MemoryCache<String, String>(capacity: 3);
    });

    test('should store and retrieve values', () async {
      await cache.put('key1', 'value1');
      final result = await cache.get('key1');

      expect(result, equals('value1'));
    });

    test('should return null for non-existent keys', () async {
      final result = await cache.get('non-existent');

      expect(result, isNull);
    });

    test('should respect capacity limit', () async {
      await cache.put('key1', 'value1');
      await cache.put('key2', 'value2');
      await cache.put('key3', 'value3');
      await cache.put('key4', 'value4'); // This should evict key1

      final result1 = await cache.get('key1');
      final result2 = await cache.get('key2');

      expect(result1, isNull);
      expect(result2, equals('value2'));
    });

    test('should update access order on get', () async {
      await cache.put('key1', 'value1');
      await cache.put('key2', 'value2');
      await cache.put('key3', 'value3');

      // Access key1, making it the most recently used
      await cache.get('key1');

      // Add a new item, which should evict key2 instead of key1
      await cache.put('key4', 'value4');

      final result1 = await cache.get('key1');
      final result2 = await cache.get('key2');

      expect(result1, equals('value1'));
      expect(result2, isNull);
    });

    test('should clear all items', () async {
      await cache.put('key1', 'value1');
      await cache.put('key2', 'value2');

      await cache.clear();

      final result1 = await cache.get('key1');
      final result2 = await cache.get('key2');

      expect(result1, isNull);
      expect(result2, isNull);
    });

    test('should invalidate specific items', () async {
      await cache.put('key1', 'value1');
      await cache.put('key2', 'value2');

      await cache.invalidate('key1');

      final result1 = await cache.get('key1');
      final result2 = await cache.get('key2');

      expect(result1, isNull);
      expect(result2, equals('value2'));
    });

    test('should report correct size', () async {
      expect(await cache.size(), equals(0));

      await cache.put('key1', 'value1');
      expect(await cache.size(), equals(1));

      await cache.put('key2', 'value2');
      expect(await cache.size(), equals(2));

      await cache.invalidate('key1');
      expect(await cache.size(), equals(1));

      await cache.clear();
      expect(await cache.size(), equals(0));
    });

    test('should check if key exists', () async {
      await cache.put('key1', 'value1');

      expect(await cache.containsKey('key1'), isTrue);
      expect(await cache.containsKey('key2'), isFalse);
    });
  });
}
