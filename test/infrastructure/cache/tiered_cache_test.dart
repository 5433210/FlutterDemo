import 'package:charasgem/infrastructure/cache/implementations/tiered_cache.dart';
import 'package:charasgem/infrastructure/cache/interfaces/i_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'tiered_cache_test.mocks.dart';

@GenerateMocks([ICache])
void main() {
  group('TieredCache', () {
    late MockICache<String, String> primaryCache;
    late MockICache<String, String> secondaryCache;
    late TieredCache<String, String> tieredCache;

    setUp(() {
      primaryCache = MockICache<String, String>();
      secondaryCache = MockICache<String, String>();
      tieredCache = TieredCache<String, String>(
        primaryCache: primaryCache,
        secondaryCache: secondaryCache,
      );
    });

    test('get should check primary cache first', () async {
      when(primaryCache.get('key')).thenAnswer((_) async => 'primary-value');

      final result = await tieredCache.get('key');

      expect(result, equals('primary-value'));
      verify(primaryCache.get('key')).called(1);
      verifyNever(secondaryCache.get('key'));
    });

    test('get should check secondary cache if primary cache misses', () async {
      when(primaryCache.get('key')).thenAnswer((_) async => null);
      when(secondaryCache.get('key'))
          .thenAnswer((_) async => 'secondary-value');

      final result = await tieredCache.get('key');

      expect(result, equals('secondary-value'));
      verify(primaryCache.get('key')).called(1);
      verify(secondaryCache.get('key')).called(1);
    });

    test('get should update primary cache when secondary cache hits', () async {
      when(primaryCache.get('key')).thenAnswer((_) async => null);
      when(secondaryCache.get('key'))
          .thenAnswer((_) async => 'secondary-value');

      await tieredCache.get('key');

      verify(primaryCache.put('key', 'secondary-value')).called(1);
    });

    test('get should return null if both caches miss', () async {
      when(primaryCache.get('key')).thenAnswer((_) async => null);
      when(secondaryCache.get('key')).thenAnswer((_) async => null);

      final result = await tieredCache.get('key');

      expect(result, isNull);
      verify(primaryCache.get('key')).called(1);
      verify(secondaryCache.get('key')).called(1);
    });

    test('put should update both caches', () async {
      await tieredCache.put('key', 'value');

      verify(primaryCache.put('key', 'value')).called(1);
      verify(secondaryCache.put('key', 'value')).called(1);
    });

    test('invalidate should remove from both caches', () async {
      await tieredCache.invalidate('key');

      verify(primaryCache.invalidate('key')).called(1);
      verify(secondaryCache.invalidate('key')).called(1);
    });

    test('clear should clear both caches', () async {
      await tieredCache.clear();

      verify(primaryCache.clear()).called(1);
      verify(secondaryCache.clear()).called(1);
    });

    test('size should return secondary cache size', () async {
      when(secondaryCache.size()).thenAnswer((_) async => 42);

      final result = await tieredCache.size();

      expect(result, equals(42));
      verify(secondaryCache.size()).called(1);
    });

    test('containsKey should check both caches', () async {
      when(primaryCache.containsKey('key')).thenAnswer((_) async => false);
      when(secondaryCache.containsKey('key')).thenAnswer((_) async => true);

      final result = await tieredCache.containsKey('key');

      expect(result, isTrue);
      verify(primaryCache.containsKey('key')).called(1);
      verify(secondaryCache.containsKey('key')).called(1);
    });
  });
}
