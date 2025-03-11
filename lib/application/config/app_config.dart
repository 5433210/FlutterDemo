class AppConfig {
  // 应用名称
  static String get appName => '书法集字';

  // 缓存目录名
  static String get cacheFolder => 'cache';

  // 数据存储路径
  static String get dataPath => 'data';

  // 数据库文件名
  static String get dbFilename => 'works.db';

  // 最大文件大小限制 (20MB)
  static int get maxImageSize => 20 * 1024 * 1024;

  static int get optimizedImageHeight => 1080;

  static int get optimizedImageQuality => 85;

  // 图片优化设置
  static int get optimizedImageWidth => 1920;

  // 存储目录名
  static String get storageFolder => 'storage';
  // 临时文件目录名
  static String get tempFolder => 'temp';
  static int get thumbnailQuality => 85;

  // 缩略图目录名
  static String get thumbnailsFolder => 'thumbnails';
  // 缩略图设置
  static int get thumbnailSize => 256;

  // 作品存储目录名
  static String get worksFolder => 'works';
}
