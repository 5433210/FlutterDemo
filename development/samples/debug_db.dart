import 'dart:io';

void main() async {
  const dbPath = 'charas_gem.db';
  if (await File(dbPath).exists()) {
    print('Database exists at: $dbPath');
    final size = await File(dbPath).length();
    print('Size: $size bytes');
  } else {
    print('Database not found at: $dbPath');
    // Check other possible locations
    final alternatives = [
      'build/charas_gem.db',
      'data/charas_gem.db',
      '../charas_gem.db',
    ];
    for (final path in alternatives) {
      if (await File(path).exists()) {
        print('Found database at: $path');
        break;
      }
    }
  }
}
