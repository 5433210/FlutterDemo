import 'dart:io';

import '../../infrastructure/storage/storage_interface.dart';

abstract class IWorkImageStorage implements IStorage {
  /// 删除作品图片（Work专用）
  Future<void> deleteWorkImage(String workId, String imagePath);

  /// 获取作品所有图片路径（Work专用）
  Future<List<String>> getWorkImages(String workId);

  /// 保存作品图片（Work专用）
  Future<String> saveWorkImage(String workId, File image);
}
