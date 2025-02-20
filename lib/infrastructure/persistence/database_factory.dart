import 'database_interface.dart';
import 'sqlite/sqlite_database.dart';

enum DatabaseType {
  sqlite,
  // Add other database types here when needed
}

class DatabaseFactory {
  static DatabaseInterface create(DatabaseType type) {
    switch (type) {
      case DatabaseType.sqlite:
        return SqliteDatabase();
    }
  }
}