abstract class IImageStorage {
  /// 删除文件（通用）
  Future<void> deleteFile(String path);

  /// 检查文件是否存在（通用）
  Future<bool> fileExists(String path);

  /// 保存临时文件（通用）
  Future<String> saveTempFile(List<int> bytes);
}
