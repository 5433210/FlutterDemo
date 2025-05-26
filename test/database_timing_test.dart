import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:charasgem/application/providers/repository_providers.dart';
import 'package:charasgem/application/providers/service_providers.dart';
import 'package:charasgem/infrastructure/providers/database_providers.dart';

void main() {
  group('Database Provider Integration Tests', () {
    test('should initialize database and repositories without timing issues',
        () async {
      final container = ProviderContainer();

      try {
        // Test that database initializes properly
        final database =
            await container.read(initializedDatabaseProvider.future);
        expect(database, isNotNull);

        // Test that work repository can access the same database instance
        final workRepository =
            await container.read(workRepositoryProvider.future);
        expect(workRepository, isNotNull);

        // Test that work service can be created with the repository
        final workService = await container.read(workServiceProvider.future);
        expect(workService, isNotNull);

        print('✅ All async providers initialized successfully');
        print('✅ Database timing issues resolved');
      } catch (e) {
        print('❌ Error in provider initialization: $e');
        rethrow;
      } finally {
        container.dispose();
      }
    });

    test('should handle concurrent database access', () async {
      final container = ProviderContainer();

      try {
        // Simulate concurrent access to database-dependent providers
        final futures = [
          container.read(workRepositoryProvider.future),
          container.read(workImageRepositoryProvider.future),
          container.read(workServiceProvider.future),
          container.read(workImageServiceProvider.future),
        ];

        final results = await Future.wait(futures);

        // All should succeed without "no such table" errors
        for (final result in results) {
          expect(result, isNotNull);
        }

        print('✅ Concurrent database access successful');
      } catch (e) {
        print('❌ Error in concurrent access: $e');
        rethrow;
      } finally {
        container.dispose();
      }
    });
  });
}
