import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/database_factory.dart';
import '../persistence/database_interface.dart';

final databaseProvider = Provider<DatabaseInterface>((ref) {
  final database = DatabaseFactory.create(DatabaseType.sqlite);

  ref.onDispose(() async {
    await database.close();
  });

  database.initialize();
  return database;
});
