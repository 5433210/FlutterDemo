import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PathHelper {
  static Future<String> getWorkDirectory(String workId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'works', workId);
  }

  static Future<String> getWorkThumbnailPath(String workId) async {
    final workDir = await getWorkDirectory(workId);
    return path.join(workDir, 'thumbnail.jpg');
  }
}