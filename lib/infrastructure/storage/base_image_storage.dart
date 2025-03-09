import 'dart:io';

import '../../domain/services/image_storage_interface.dart';
import '../../utils/path_helper.dart';

class BaseImageStorage implements IImageStorage {
  @override
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  Future<String> getAppDataPath() async {
    return await PathHelper.getAppDataPath();
  }

  @override
  Future<String> saveTempFile(List<int> bytes) async {
    final tempDir = await PathHelper.getTempDirectory();
    final path = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.tmp';
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
