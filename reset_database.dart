import 'dart:io';

import 'package:path/path.dart' as path;

/// 重置数据库的脚本
/// 运行方式：dart reset_database.dart
void main() async {
  print('🔄 开始重置数据库...');

  // 可能的数据库路径
  final possiblePaths = [
    'database.db',
    'charasgem.db',
    path.join('build', 'database.db'),
    path.join('build', 'charasgem.db'),
    path.join('windows', 'database.db'),
    path.join('windows', 'charasgem.db'),
  ];

  var deletedCount = 0;

  for (final dbPath in possiblePaths) {
    final file = File(dbPath);
    if (await file.exists()) {
      try {
        await file.delete();
        print('✅ 已删除: $dbPath');
        deletedCount++;
      } catch (e) {
        print('❌ 删除失败: $dbPath - $e');
      }
    }

    // 也检查WAL和SHM文件
    final walFile = File('$dbPath-wal');
    final shmFile = File('$dbPath-shm');

    if (await walFile.exists()) {
      try {
        await walFile.delete();
        print('✅ 已删除: $dbPath-wal');
      } catch (e) {
        print('❌ 删除失败: $dbPath-wal - $e');
      }
    }

    if (await shmFile.exists()) {
      try {
        await shmFile.delete();
        print('✅ 已删除: $dbPath-shm');
      } catch (e) {
        print('❌ 删除失败: $dbPath-shm - $e');
      }
    }
  }

  if (deletedCount == 0) {
    print('ℹ️ 没有找到数据库文件');
  } else {
    print('✅ 数据库重置完成！删除了 $deletedCount 个文件');
    print('ℹ️ 现在可以重新运行应用，数据库将重新创建');
  }
}
