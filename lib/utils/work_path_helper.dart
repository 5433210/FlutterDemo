import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class WorkPathHelper {
  static Future<String> getThumbnailPath(String workId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final workDir = path.join(appDir.path, 'works', workId);
    return path.join(workDir, 'thumbnail.jpg');
  }

  static Future<bool> thumbnailExists(String workId) async {
    final thumbnailPath = await getThumbnailPath(workId);
    return File(thumbnailPath).existsSync();
  }
}