import 'dart:typed_data';

/// 集字图片服务接口
abstract class CharacterImageService {
  /// 清除所有图片缓存
  Future<void> clearAllImageCache();

  /// 获取可用的图片格式
  Future<Map<String, String>?> getAvailableFormat(String id,
      {bool preferThumbnail = false});

  /// 获取原始字符图片
  Future<Uint8List?> getCharacterImage(
      String id, String type, String format);

  /// 获取处理后的字符图片
  Future<Uint8List?> getProcessedCharacterImage(String characterId, String type,
      String format, Map<String, dynamic> transform);

  /// 检查图片是否存在
  Future<bool> hasCharacterImage(String id, String type, String format);
}
