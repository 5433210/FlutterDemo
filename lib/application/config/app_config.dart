import 'package:path/path.dart' as path;

class AppConfig {
  // Image related settings
  static const maxImagesPerWork = 10;
  static const maxImageSize = 20 * 1024 * 1024; // 20MB
  static const maxImageWidth = 4096;
  static const maxImageHeight = 4096;

  static const supportedImageFormats = ['jpg', 'jpeg', 'png'];

  // Image processing settings
  static const int optimizedImageWidth = 2048;
  static const int optimizedImageHeight = 2048;
  static const int optimizedImageQuality = 85;
  static const int thumbnailSize = 256;

  // Storage paths
  static const String workspacePath = 'workspace';
  static const String originalsPath = 'workspace/originals';
  static const String optimizedPath = 'workspace/optimized';
  static const String thumbnailsPath = 'workspace/thumbnails';

  // Supported file types
  static const List<String> supportedImageTypes = [
    '.jpg', '.jpeg', '.png', '.webp'
  ];

  // 更新路径配置
  static const String appDataFolder = 'data';
  static const String storageFolder = 'storage';
  static const String worksFolder = 'works';
  static const String thumbnailFile = 'thumbnail.jpg';

  // 修改 dataPath getter
  static String get dataPath {
    return path.join('C:\\Users\\wailik\\Documents', appDataFolder);
  }

  const AppConfig._();
}